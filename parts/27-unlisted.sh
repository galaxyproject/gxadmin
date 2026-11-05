# Some unlisted functions that are probably not useful as things people might
# want to query (and thus have cluttering their query menu), but should be
# shared because that's the purpose of gxadmin, sharing all of these weird
# queries that we have :)

query_memory-and-cpu-on-same-node() { ##? <hostname>: Memory and CPU cgroup metrics for jobs that ran on a given host
	handle_help "$@" <<-EOF
		Returns the reported "memory.memsw.max_usage_in_bytes" and
		"cpuacct.usage" cgroup metric values for the most recent jobs that ran
		on the given hostname. Useful for debugging what went wrong with
		cgroup metrics on a specific node.

		The hostname must match the value stored in the "hostname" job metric.
		Up to 200 recent jobs from that host are considered.

		$ gxadmin query memory-and-cpu-on-same-node worker-04
		  memory.memsw.max_usage_in_bytes | cpuacct.usage |      update_time
		----------------------------------+---------------+---------------------
		                   1234567890     |  98765432100  | 2023-01-18 14:05:14
		                   2345678901     |  87654321009  | 2023-01-18 14:05:16
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

