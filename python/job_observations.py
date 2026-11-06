# Extract job and metric data from Galaxy's database.

import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

FORMAT_VERSION = 1
COLUMNS = {
	'jobs': ['job_id', 'create_time', 'update_time', 'state_raw', 'tool_id_raw', 'tool_version', 'galaxy_version', 'destination_id', 'handler', 'runner_name', 'user_id', 'exit_code', 'copied_from_job_id', 'imported'],
	'numeric_metrics': ['metric_id', 'job_id', 'plugin', 'metric_name', 'metric_value_raw'],
}
ALLOWLIST = [
	['core', 'runtime_seconds'],
	['core', 'galaxy_slots'],
	['core', 'galaxy_memory_mb'],
	['core', 'start_epoch'],
	['core', 'end_epoch'],
	['core', 'resubmission_count'],
	['cgroup', 'cpuacct.usage'],
	['cgroup', 'cpu.stat.usage_usec'],
	['cgroup', 'cpu.stat.user_usec'],
	['cgroup', 'cpu.stat.system_usec'],
	['cgroup', 'memory.max_usage_in_bytes'],
	['cgroup', 'memory.peak'],
	['cgroup', 'memory.memsw.max_usage_in_bytes'],
	['cgroup', 'memory.limit_in_bytes'],
	['cgroup', 'memory.memsw.limit_in_bytes'],
	['cgroup', 'memory.max'],
	['cgroup', 'memory.failcnt'],
	['cgroup', 'memory.events.oom'],
	['cgroup', 'memory.events.oom_kill'],
	['cgroup', 'memory.oom_control.oom_kill'],
	['cgroup', 'memory.oom_control.oom_kill_disable'],
	['cgroup', 'memory.oom_control.under_oom'],
	['cpuinfo', 'processor_count'],
	['meminfo', 'memtotal'],
	['meminfo', 'swaptotal'],
]
DEFAULTS = {'maxRows': 50000, 'maxRangeWidth': 50000, 'maxOutputBytes': 268435456, 'maxRuntimeSeconds': 600, 'statementTimeoutMs': 120000, 'lockTimeoutMs': 3000}
TIMESTAMP = "'YYYY-MM-DD\"T\"HH24:MI:SS.US\"Z\"'"


def encode(value):
	return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode("utf-8")


def selection_sql(request):
	s = request["selection"]
	if s["entity"] != "jobs":
		raise ValueError("unsupported_selection")
	if s["mode"] == "id_range":
		lo, hi = int(s["lowExclusive"]), int(s["highInclusive"])
		if hi < lo or hi - lo > request["maxRangeWidth"]:
			raise ValueError("unbounded_selection")
		return f"j.id > {lo} AND j.id <= {hi}"
	if s["mode"] == "id_list":
		ids = [int(x) for x in s["ids"]]
		if not ids or len(ids) > request["maxRows"]:
			raise ValueError("invalid_id_list")
		return "j.id IN (" + ",".join(map(str, ids)) + ")"
	raise ValueError("unsupported_selection")


def psql(sql, directory, runtime):
	try:
		p = subprocess.run(["psql", "-X", "-qAt", "-v", "ON_ERROR_STOP=1"], input=sql.encode("utf-8"), cwd=directory,
			stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, timeout=runtime,
			env={**os.environ, "PGAPPNAME": "gxadmin.job-observations", "PGOPTIONS": os.environ.get("PGOPTIONS", "") + " -c default_transaction_read_only=on"})
	except subprocess.TimeoutExpired:
		raise ValueError("source_budget_exceeded")
	if p.returncode:
		sys.stderr.write(p.stderr.decode("utf-8", "replace"))
		raise ValueError("source_query_failed")


def preflight_sql():
	return """SELECT json_build_object('postgresqlVersion',current_setting('server_version'),
	'galaxyRelease',(SELECT galaxy_version FROM public.job WHERE galaxy_version IS NOT NULL AND galaxy_version ~ '^[0-9]+[.][0-9]+' ORDER BY id DESC LIMIT 1))
	\\g source.json
	"""


def capability(directory):
	source = json.loads((directory / "source.json").read_text())
	release = re.match(r"(\d+)\.(\d+)", source.get("galaxyRelease") or "")
	if not release or tuple(map(int, release.group(1, 2))) < (26, 1):
		raise ValueError("unsupported_galaxy_release")
	return {"formatVersion": FORMAT_VERSION, "galaxyRelease": source["galaxyRelease"], "postgresqlVersion": source["postgresqlVersion"],
		"timestampInterpretation": "UTC", "components": {n: {"schemaVersion": 1, "columns": cols, "status": "supported"} for n, cols in COLUMNS.items()},
		"numericMetricAllowList": ALLOWLIST, "textMetrics": [], "runnerSourceColumn": "job.job_runner_name",
		"exporterBuild": hashlib.sha256(SCRIPT_BYTES).hexdigest(), "gxadminVersion": os.environ.get("GXADMIN_EXPORT_VERSION", "unknown")}


def export(request, output):
	request = {**DEFAULTS, **request}
	where = selection_sql(request)
	if output.exists():
		raise ValueError("output_already_exists")
	output.parent.mkdir(parents=True, exist_ok=True)
	work = Path(tempfile.mkdtemp(prefix=".job-observations-", dir=output.parent))
	try:
		fields = ["j.id AS job_id", f"to_char(j.create_time,{TIMESTAMP}) AS create_time", f"to_char(j.update_time,{TIMESTAMP}) AS update_time", "j.state AS state_raw", "j.tool_id AS tool_id_raw", "j.tool_version", "j.galaxy_version", "j.destination_id", "j.handler", "j.job_runner_name AS runner_name", "j.user_id", "j.exit_code", "j.copied_from_job_id", "j.imported"]
		pairs = ",".join(f"('{p}','{n}')" for p, n in ALLOWLIST)
		selects = {"jobs": "SELECT " + ",".join(fields) + " FROM job j WHERE " + where + " ORDER BY j.id",
			"numeric_metrics": "SELECT m.id AS metric_id,m.job_id,m.plugin,m.metric_name,m.metric_value::text AS metric_value_raw FROM job_metric_numeric m JOIN job j ON j.id=m.job_id WHERE (" + where + ") AND (m.plugin,m.metric_name) IN (" + pairs + ") ORDER BY m.id"}
		sql = "BEGIN ISOLATION LEVEL REPEATABLE READ READ ONLY;\nSET LOCAL search_path=public,pg_catalog;\nSET LOCAL timezone='UTC';\n"
		sql += f"SET LOCAL statement_timeout={int(request['statementTimeoutMs'])};\nSET LOCAL lock_timeout={int(request['lockTimeoutMs'])};\n"
		sql += preflight_sql()
		sql += f"SELECT json_build_object('observedAt',to_char(transaction_timestamp() AT TIME ZONE 'UTC',{TIMESTAMP}),'snapshotId',pg_current_snapshot()::text)\n\\g snapshot.json\n"
		for name, select in selects.items():
			sql += "COPY (" + select + ") TO STDOUT WITH (FORMAT csv,HEADER true,ENCODING 'UTF8')\n\\g " + name + ".csv\n\\set " + name + "_rows :ROW_COUNT\n"
		sql += "SELECT json_build_object('jobs',:jobs_rows,'numeric_metrics',:numeric_metrics_rows)\n\\g counts.json\nCOMMIT;\n"
		psql(sql, work, request["maxRuntimeSeconds"])
		cap = capability(work)
		snapshot = json.loads((work / "snapshot.json").read_text())
		counts = json.loads((work / "counts.json").read_text())
		if counts["jobs"] > request["maxRows"]:
			raise ValueError("row_budget_exceeded")
		for file in ["source.json", "snapshot.json", "counts.json"]:
			(work / file).unlink()
		metadata = {"formatVersion": FORMAT_VERSION, "selection": request["selection"],
			"observedAt": snapshot["observedAt"], "snapshotId": snapshot["snapshotId"], "capabilities": cap, "rows": counts}
		(work / "metadata.json").write_bytes(encode(metadata))
		if sum(f.stat().st_size for f in work.iterdir()) > request["maxOutputBytes"]:
			raise ValueError("output_budget_exceeded")
		os.rename(work, output)
		return metadata
	finally:
		if work.exists():
			shutil.rmtree(work)


def main():
	mode = sys.argv[1]
	if mode == "export":
		if len(sys.argv) == 5:
			request = {"selection": {"entity": "jobs", "mode": "id_range", "lowExclusive": sys.argv[2], "highInclusive": sys.argv[3]}}
			output = sys.argv[4]
		else:
			request, output = json.loads(Path(sys.argv[2]).read_text()), sys.argv[3]
		export(request, Path(output).resolve())
		return
	with tempfile.TemporaryDirectory(prefix="gxadmin-observations-") as tmp:
		work = Path(tmp)
		sql = "BEGIN ISOLATION LEVEL REPEATABLE READ READ ONLY;\nSET LOCAL statement_timeout='30s';\nSET LOCAL lock_timeout='3s';\n" + preflight_sql()
		if mode == "bounds":
			sql += "SELECT json_build_object('entity','jobs','maxId',COALESCE(max(id),0)::text) FROM public.job\n\\g bounds.json\n"
		sql += "COMMIT;\n"
		psql(sql, work, 60)
		print(encode(json.loads((work / "bounds.json").read_text()) if mode == "bounds" else capability(work)).decode())


SCRIPT_BYTES = os.environ.get("GXADMIN_OBSERVATION_PROGRAM", "job-observation-export-v1").encode()
if __name__ == "__main__":
	try:
		main()
	except Exception as exc:
		print("Exception running job observations:", type(exc).__name__, str(exc), file=sys.stderr)
		sys.exit(1)
