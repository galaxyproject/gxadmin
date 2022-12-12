# Some unlisted functions that are probably not useful as things people might
# want to query (and thus have cluttering their query menu), but should be
# shared because that's the purpose of gxadmin, sharing all of these weird
# queries that we have :)

query_memory-and-cpu-on-same-node() {
	handle_help "$@" <<-EOF
		Helena needed to check the reported values of memory/cpu over a series
		of jobs on a specific host, to debug what went wrong with the cgroup
		metrics.

		TODO(hxr): find some way to note "unlisted" functions and let people do the help for them?
	EOF

	assert_count $# 1 "Missing host name"
	host="$1"

	read -r -d '' QUERY <<-EOF
		SELECT
			jmn_a.metric_value AS "memory.memsw.max_usage_in_bytes",
			jmn_b.metric_value AS "cpuacct.usage",
			job.update_time
		FROM
			job_metric_numeric AS jmn_a, job_metric_numeric AS jmn_b, job
		WHERE
			jmn_a.job_id
			IN (
					SELECT
						job_id
					FROM
						job_metric_text
					WHERE
						metric_value = '$host'
					ORDER BY
						job_id DESC
					LIMIT
						200
				)
			AND jmn_a.metric_name = 'memory.memsw.max_usage_in_bytes'
			AND jmn_b.job_id
				IN (
						SELECT
							job_id
						FROM
							job_metric_text
						WHERE
							metric_value = '$host'
						ORDER BY
							job_id DESC
						LIMIT
							200
					)
			AND jmn_b.metric_name = 'cpuacct.usage'
			AND jmn_a.job_id = job.id
			AND jmn_b.job_id = job.id
		ORDER BY
			job.create_time DESC
	EOF
}


query_cpu-tools-month() {
	handle_help "$@" <<-EOF
		Tool Performance Tracking: CPU by Month-Year.
	EOF

	assert_count $# 1 "Missing host name"
	host="$1"

	read -r -d '' QUERY <<-EOF
		WITH cpu_usage AS (
			SELECT
				DISTINCT job_id,
				destination_id,
				metric_value AS cpu_usage_seconds
			FROM
				job_metric_numeric
		)
		SELECT
			TO_CHAR(job.create_time, 'YYYY-MM') AS date,
			job.tool_id,
			cpu_usage.destination_id,
			ROUND(AVG(cpu_usage.cpu_usage_seconds), 0) AS avg_cpu_time_seconds
		FROM
			job
			JOIN cpu_usage ON job.id = cpu_usage.job_id
		GROUP BY
			date,
			job.tool_id
		ORDER BY
			date ASC,
			avg_cpu_time_seconds DESC
	EOF
}
