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
import time

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


def encode(value):
	return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode("utf-8")


def exact_id(value, positive=False):
	if not isinstance(value, str) or not re.fullmatch(r"0|[1-9][0-9]{0,18}", value):
		raise ValueError("invalid_int64")
	n = int(value)
	if n > 9223372036854775807 or (positive and n == 0):
		raise ValueError("invalid_int64")
	return n


def validate(request):
	if request.get("timestampInterpretation", "UTC") != "UTC":
		raise ValueError("verified_utc_interpretation_required")
	for key, default, low, high in [("maxRows", 50000, 1, 1000000), ("maxRangeWidth", 50000, 1, 1000000), ("maxOutputBytes", 268435456, 1024, 1073741824), ("maxRuntimeSeconds", 600, 1, 1800), ("statementTimeoutMs", 120000, 1, 120000), ("lockTimeoutMs", 3000, 1, 3000)]:
		request.setdefault(key, default)
		if type(request[key]) is not int or not low <= request[key] <= high:
			raise ValueError("invalid_budget")
	s = request["selection"]
	if s["entity"] != "jobs":
		raise ValueError("unsupported_selection")
	if s["mode"] == "id_range":
		lo, hi = exact_id(s["lowExclusive"]), exact_id(s["highInclusive"])
		if hi < lo or hi - lo > request["maxRangeWidth"]:
			raise ValueError("unbounded_selection")
		return f"j.id > {lo} AND j.id <= {hi}"
	if s["mode"] == "id_list":
		ids = [exact_id(x) for x in s["ids"]]
		if not ids or len(ids) > request["maxRows"] or len(set(ids)) != len(ids):
			raise ValueError("invalid_id_list")
		return "j.id IN (" + ",".join(map(str, ids)) + ")"
	raise ValueError("unsupported_selection")


def psql(sql, directory, runtime=180, byte_limit=16777216):
	with (directory / "source-errors.log").open("wb") as err:
		with tempfile.TemporaryFile() as source_input:
			source_input.write(sql.encode("utf-8"))
			source_input.seek(0)
			p = subprocess.Popen(["psql", "-X", "-qAt", "-v", "ON_ERROR_STOP=1"], cwd=directory,
				stdin=source_input, stdout=subprocess.DEVNULL, stderr=err,
				env={**os.environ, "PGAPPNAME": "gxadmin.job-observations", "PGOPTIONS": os.environ.get("PGOPTIONS", "") + " -c default_transaction_read_only=on"})
		start = time.monotonic()
		try:
			while p.poll() is None:
				if time.monotonic() - start > runtime or sum(f.stat().st_size for f in directory.iterdir() if f.is_file()) > byte_limit:
					raise ValueError("source_budget_exceeded")
				time.sleep(0.05)
			if p.returncode:
				sys.stderr.write((directory / "source-errors.log").read_text())
				raise ValueError("source_query_failed")
			if sum(f.stat().st_size for f in directory.iterdir() if f.is_file()) > byte_limit:
				raise ValueError("source_budget_exceeded")
		finally:
			if p.poll() is None:
				p.kill()
			p.wait()


def preflight_sql():
	return """SELECT json_build_object('postgresqlVersion',current_setting('server_version'),
	'galaxyRelease',(SELECT galaxy_version FROM public.job WHERE galaxy_version IS NOT NULL AND galaxy_version ~ '^[0-9]+[.][0-9]+' ORDER BY id DESC LIMIT 1),
	'columns',(SELECT json_agg(json_build_object('table',table_name,'name',column_name,'type',data_type) ORDER BY table_name,ordinal_position)
	FROM information_schema.columns WHERE table_schema='public' AND table_name IN ('job','job_metric_numeric')))
	\\g schema.json
	"""


def capability(directory, request):
	schema = json.loads((directory / "schema.json").read_text())
	columns = {(x["table"], x["name"]): x["type"] for x in schema["columns"] or []}
	mapping = {"job_id": "id", "state_raw": "state", "tool_id_raw": "tool_id", "runner_name": "job_runner_name"}
	for field in COLUMNS["jobs"]:
		if ("job", mapping.get(field, field)) not in columns:
			raise ValueError("unsupported_job_schema")
	for field in ["id", "job_id", "plugin", "metric_name", "metric_value"]:
		if ("job_metric_numeric", field) not in columns:
			raise ValueError("unsupported_metric_schema")
	release = re.match(r"(\d+)\.(\d+)", schema.get("galaxyRelease") or "")
	if not release or tuple(map(int, release.group(1, 2))) < (26, 1):
		raise ValueError("unsupported_galaxy_release")
	return {"formatVersion": FORMAT_VERSION, "galaxyRelease": schema["galaxyRelease"], "postgresqlVersion": schema["postgresqlVersion"],
		"timestampInterpretation": "UTC", "components": {n: {"schemaVersion": 1, "columns": cols, "status": "supported"} for n, cols in COLUMNS.items()},
		"numericMetricAllowList": ALLOWLIST, "textMetrics": [], "runnerSourceColumn": "job.job_runner_name",
		"exporterBuild": hashlib.sha256(SCRIPT_BYTES).hexdigest(), "gxadminVersion": os.environ.get("GXADMIN_EXPORT_VERSION", "unknown")}


def export(request, output):
	where = validate(request)
	if output.exists():
		raise ValueError("output_already_exists")
	output.parent.mkdir(parents=True, exist_ok=True)
	work = Path(tempfile.mkdtemp(prefix=".job-observations-", dir=output.parent))
	try:
		fields = ["j.id AS job_id", "to_char(j.create_time,'YYYY-MM-DD\"T\"HH24:MI:SS.US\"Z\"') AS create_time", "to_char(j.update_time,'YYYY-MM-DD\"T\"HH24:MI:SS.US\"Z\"') AS update_time", "j.state AS state_raw", "j.tool_id AS tool_id_raw", "j.tool_version", "j.galaxy_version", "j.destination_id", "j.handler", "j.job_runner_name AS runner_name", "j.user_id", "j.exit_code", "j.copied_from_job_id", "j.imported"]
		pairs = ",".join("(" + "'" + p + "','" + n + "'" + ")" for p, n in ALLOWLIST)
		sql = "BEGIN ISOLATION LEVEL REPEATABLE READ READ ONLY;\nSET LOCAL search_path=public,pg_catalog;\nSET LOCAL timezone='UTC';\n"
		sql += f"SET LOCAL statement_timeout={request['statementTimeoutMs']};\nSET LOCAL lock_timeout={request['lockTimeoutMs']};\n"
		sql += preflight_sql()
		sql += "SELECT json_build_object('observedAt',to_char(transaction_timestamp() AT TIME ZONE 'UTC','YYYY-MM-DD\"T\"HH24:MI:SS.US\"Z\"'),'snapshotId',pg_current_snapshot()::text)\n\\g snapshot.json\n"
		selects = {"jobs": "SELECT " + ",".join(fields) + " FROM job j WHERE " + where + " ORDER BY j.id",
			"numeric_metrics": "SELECT m.id AS metric_id,m.job_id,m.plugin,m.metric_name,m.metric_value::text AS metric_value_raw FROM job_metric_numeric m JOIN job j ON j.id=m.job_id WHERE (" + where + ") AND (m.plugin,m.metric_name) IN (" + pairs + ") ORDER BY m.id"}
		for name, select in selects.items():
			sql += "COPY (" + select + ") TO STDOUT WITH (FORMAT csv,HEADER true,ENCODING 'UTF8')\n\\g " + name + ".csv\n\\set " + name + "_rows :ROW_COUNT\n"
		sql += "SELECT json_build_object('jobs',:jobs_rows,'numeric_metrics',:numeric_metrics_rows)\n\\g counts.json\nCOMMIT;\n"
		psql(sql, work, request["maxRuntimeSeconds"], request["maxOutputBytes"])
		cap = capability(work, request)
		snapshot = json.loads((work / "snapshot.json").read_text())
		counts = json.loads((work / "counts.json").read_text())
		if counts["jobs"] > request["maxRows"]:
			raise ValueError("row_budget_exceeded")
		metadata = {"formatVersion": FORMAT_VERSION, "selection": request["selection"],
			"observedAt": snapshot["observedAt"], "snapshotId": snapshot["snapshotId"], "capabilities": cap, "rows": counts}
		for file in ["schema.json", "snapshot.json", "counts.json", "source-errors.log"]:
			(work / file).unlink()
		(work / "metadata.json").write_bytes(encode(metadata))
		if sum(f.stat().st_size for f in work.iterdir()) > request["maxOutputBytes"]:
			raise ValueError("output_budget_exceeded")
		for file in work.iterdir():
			with file.open("rb") as f:
				os.fsync(f.fileno())
		work_fd = os.open(work, os.O_RDONLY)
		try:
			os.fsync(work_fd)
		finally:
			os.close(work_fd)
		os.rename(work, output)
		directory_fd = os.open(output.parent, os.O_RDONLY)
		try:
			os.fsync(directory_fd)
		finally:
			os.close(directory_fd)
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
	request = {"timestampInterpretation": os.environ.get("GXADMIN_SOURCE_TIMEZONE", "UTC")}
	with tempfile.TemporaryDirectory(prefix="gxadmin-observations-") as tmp:
		work = Path(tmp)
		sql = "BEGIN ISOLATION LEVEL REPEATABLE READ READ ONLY;\nSET LOCAL statement_timeout='30s';\nSET LOCAL lock_timeout='3s';\n" + preflight_sql()
		if mode == "bounds":
			sql += "SELECT json_build_object('entity','jobs','maxId',COALESCE(max(id),0)::text) FROM public.job\n\\g bounds.json\n"
		sql += "COMMIT;\n"
		psql(sql, work, 60)
		validate({**request, "selection": {"entity": "jobs", "mode": "id_range", "lowExclusive": "0", "highInclusive": "0"}})
		print(encode(json.loads((work / "bounds.json").read_text()) if mode == "bounds" else capability(work, request)).decode())


SCRIPT_BYTES = os.environ.get("GXADMIN_OBSERVATION_PROGRAM", "job-observation-export-v1").encode()
if __name__ == "__main__":
	try:
		main()
	except Exception as exc:
		print("Exception running job observations:", type(exc).__name__, str(exc), file=sys.stderr)
		sys.exit(1)
