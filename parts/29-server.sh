registered_subcommands="$registered_subcommands server"
_server_short_help="Various overall statistics"
_server_long_help="
	'query' can be exchanged with 'tsvquery' or 'csvquery' for tab- and comma-separated variants.
	In some cases 'iquery' is supported for InfluxDB compatible output.
	In all cases 'explainquery' will show you the query plan, in case you need to optimise or index data. 'explainjsonquery' is useful with PEV: http://tatiyants.com/pev/
"


server_users() { ## : Count of different classifications of users
	meta <<-EOF
		ADDED: 12
	EOF
	handle_help "$@" <<-EOF
	EOF

	op="="
	if (( $# > 1 )); then
		op="$2"
	fi

	date_filter=""
	if (( $# > 0 )); then
		date_filter="WHERE date_trunc('day', create_time AT TIME ZONE 'UTC') $op '$1'::date"
	fi

	fields="count=4"
	tags="active=0;external=1;deleted=2;purged=3"

	read -r -d '' QUERY <<-EOF
		SELECT
			active, external, deleted, purged, count(*) as count
		FROM
			galaxy_user
		$date_filter
		GROUP BY
			active, external, deleted, purged
	EOF
}

server_users-with-oidc() { ##? [--op=<...>] [--date=<yyyy-mm-dd>] : How many users logged in with OIDC
	meta <<-EOF
		ADDED: 21
		AUTHORS: abretaud
	EOF
	handle_help "$@" <<-EOF
	EOF

	op="<="
	if [[ -n "$arg_op" ]]; then
		op="$arg_op"
	fi

	date_filter=""
	if [[ -n "$arg_date" ]]; then
		date_filter="WHERE date_trunc('day', galaxy_user.create_time AT TIME ZONE 'UTC') $op '$arg_date'::date"
	fi

	fields="count=1"
	tags="provider=0"

	read -r -d '' QUERY <<-EOF
		SELECT
			provider, count(distinct user_id)
		FROM
			oidc_user_authnz_tokens
			JOIN
				galaxy_user ON oidc_user_authnz_tokens.user_id = galaxy_user.id
		$date_filter
		GROUP BY provider
	EOF
}

server_groups() { ## : Counts of group memberships
	meta <<-EOF
		ADDED: 12
	EOF
	handle_help "$@" <<-EOF
	EOF

	op="="
	if (( $# > 1 )); then
		op="$2"
	fi

	date_filter=""
	if (( $# > 0 )); then
		date_filter="AND galaxy_group.create_time AT TIME ZONE 'UTC' <= '$1'::date AND date_trunc('day', user_group_association.create_time AT TIME ZONE 'UTC') $op '$1'::date"
	fi


	fields="count=1"
	tags="name=0"

	read -r -d '' QUERY <<-EOF
		SELECT
			galaxy_group.name, count(*)
		FROM
			galaxy_group, user_group_association
		WHERE
			user_group_association.group_id = galaxy_group.id
			$date_filter
		GROUP BY name
	EOF
}

server_datasets() { ## : Counts of datasets
	meta <<-EOF
		ADDED: 12
	EOF
	handle_help "$@" <<-EOF
	EOF

	op="="
	if (( $# > 1 )); then
		op="$2"
	fi

	date_filter=""
	if (( $# > 0 )); then
		date_filter="WHERE date_trunc('day', create_time AT TIME ZONE 'UTC') $op '$1'::date"
	fi

	fields="count=4;size=5"
	tags="state=0;deleted=1;purged=2;object_store_id=3"

	read -r -d '' QUERY <<-EOF
		SELECT
			COALESCE(state, '__unknown__'),
			deleted,
			purged,
			COALESCE(object_store_id, 'none'),
			count(*),
			sum(coalesce(dataset.total_size, dataset.file_size, 0))
		FROM
			dataset
		$date_filter
		GROUP BY
			state, deleted, purged, object_store_id
	EOF
}

server_hda() { ## : Counts of HDAs
	meta <<-EOF
		ADDED: 12
	EOF
	handle_help "$@" <<-EOF
	EOF

	op="="
	if (( $# > 1 )); then
		op="$2"
	fi

	date_filter=""
	if (( $# > 0 )); then
		date_filter="AND date_trunc('day', history_dataset_association.create_time AT TIME ZONE 'UTC') $op '$1'::date"
	fi

	fields="sum=2;avg=3;min=4;max=5;count=6"
	tags="extension=0;deleted=1"

	read -r -d '' QUERY <<-EOF
		SELECT
			COALESCE(history_dataset_association.extension, '__unknown__'),
			history_dataset_association.deleted,
			COALESCE(sum(dataset.file_size), 0),
			COALESCE(avg(dataset.file_size), 0)::bigint,
			COALESCE(min(dataset.file_size), 0),
			COALESCE(max(dataset.file_size), 0),
			count(*)
		FROM
			history_dataset_association, dataset
		WHERE
			history_dataset_association.dataset_id = dataset.id
			${date_filter}
		GROUP BY
			history_dataset_association.extension, history_dataset_association.deleted
	EOF
}

server_ts-repos() { ## : Counts of TS repos
	meta <<-EOF
		ADDED: 12
	EOF
	handle_help "$@" <<-EOF
	EOF

	op="="
	if (( $# > 1 )); then
		op="$2"
	fi

	date_filter=""
	if (( $# > 0 )); then
		date_filter="WHERE date_trunc('day', create_time AT TIME ZONE 'UTC') $op '$1'::date"
	fi

	fields="count=2"
	tags="tool_shed=0;owner=1"

	read -r -d '' QUERY <<-EOF
		SELECT
			tool_shed, owner, count(*)
		FROM
			tool_shed_repository
		$date_filter
		GROUP BY
			tool_shed, owner
		ORDER BY count desc
	EOF
}

server_histories() { ## : Counts of histories and sharing
	meta <<-EOF
		ADDED: 12
	EOF
	handle_help "$@" <<-EOF
	EOF

	op="="
	if (( $# > 1 )); then
		op="$2"
	fi

	date_filter=""
	if (( $# > 0 )); then
		date_filter="WHERE date_trunc('day', create_time AT TIME ZONE 'UTC') $op '$1'::date"
	fi

	fields="count=6"
	tags="deleted=0;purged=1;published=2;importable=3;importing=4;genome_build=5"

	read -r -d '' QUERY <<-EOF
		SELECT
			deleted, purged, published, importable, importing, COALESCE(genome_build, '__unknown__'), count(*)
		FROM history
		${date_filter}
		GROUP BY
			deleted, purged, published, importable, importing, genome_build
	EOF
}


server_jobs() { ## : Counts of jobs
	meta <<-EOF
		ADDED: 12
	EOF
	handle_help "$@" <<-EOF
	EOF

	op="="
	if (( $# > 1 )); then
		op="$2"
	fi

	date_filter=""
	if (( $# > 0 )); then
		date_filter="WHERE date_trunc('day', create_time AT TIME ZONE 'UTC') $op '$1'::date"
	fi

	fields="count=3"
	tags="state=0;job_runner_name=1;destination_id=2"

	read -r -d '' QUERY <<-EOF
		SELECT
			COALESCE(state, '__unknown__'),
			COALESCE(job_runner_name, '__unknown__'),
			COALESCE(destination_id, '__unknown__'), count(*)
		FROM
			job
		${date_filter}
		GROUP BY
			state, job_runner_name, destination_id
	EOF
}

server_allocated-cpu() { ## : CPU time per job runner
	meta <<-EOF
		ADDED: 12
	EOF
	handle_help "$@" <<-EOF
	EOF

	op="="
	if (( $# > 1 )); then
		op="$2"
	fi

	date_filter=""
	if (( $# > 0 )); then
		date_filter="AND date_trunc('day', job.create_time AT TIME ZONE 'UTC') $op '$1'::date"
	fi

	# TODO: here we select the hostname, don't do that.
	# Hack for EU's test vs main separation, both submitting job stats.
	# Solve by either running IN telegraf or doing it in the meta functions
	fields="cpu_seconds=1"
	tags="job_runner_name=0;host=2"

	read -r -d '' QUERY <<-EOF
		SELECT
			job.job_runner_name,
			round(sum(a.metric_value * b.metric_value), 2) AS cpu_seconds,
			'$HOSTNAME' as host
		FROM
			job_metric_numeric AS a,
			job_metric_numeric AS b,
			job
		WHERE
			b.job_id = a.job_id
			AND a.job_id = job.id
			AND a.metric_name = 'runtime_seconds'
			AND b.metric_name = 'galaxy_slots'
			${date_filter}
		GROUP BY
			job.job_runner_name
	EOF
}

server_allocated-gpu() { ## : GPU time per job runner
	meta <<-EOF
		ADDED: 14
	EOF
	handle_help "$@" <<-EOF
	EOF

	op="="
	if (( $# > 1 )); then
		op="$2"
	fi

	date_filter=""
	if (( $# > 0 )); then
		date_filter="AND date_trunc('day', job.create_time AT TIME ZONE 'UTC') $op '$1'::date"
	fi

	fields="gpu_seconds=1"
	tags="job_runner_name=0"

	read -r -d '' QUERY <<-EOF
		SELECT
			job.job_runner_name,
			round(sum(a.metric_value * length(replace(b.metric_value, ',', ''))), 2) AS gpu_seconds
		FROM
			job_metric_numeric AS a,
			job_metric_text AS b,
			job
		WHERE
			b.job_id = a.job_id
			AND a.job_id = job.id
			AND a.metric_name = 'runtime_seconds'
			AND b.metric_name = 'CUDA_VISIBLE_DEVICES'
			${date_filter}
		GROUP BY
			job.job_runner_name
	EOF
}

server_workflows() { ## : Counts of workflows
	meta <<-EOF
		ADDED: 12
	EOF
	handle_help "$@" <<-EOF
	EOF

	op="="
	if (( $# > 1 )); then
		op="$2"
	fi

	date_filter=""
	if (( $# > 0 )); then
		date_filter="WHERE date_trunc('day', create_time AT TIME ZONE 'UTC') $op '$1'::date"
	fi

	fields="count=3"
	tags="deleted=0;importable=1;published=2"

	read -r -d '' QUERY <<-EOF
		SELECT
			deleted, importable, published, count(*)
		FROM
			stored_workflow
		${date_filter}
		GROUP BY
			deleted, importable, published
	EOF
}

server_workflow-invocations() { ## : Counts of workflow invocations
	meta <<-EOF
		ADDED: 12
	EOF
	handle_help "$@" <<-EOF
	EOF

	op="="
	if (( $# > 1 )); then
		op="$2"
	fi

	date_filter=""
	if (( $# > 0 )); then
		date_filter="WHERE date_trunc('day', create_time AT TIME ZONE 'UTC') $op '$1'::date"
	fi

	fields="count=2"
	tags="scheduler=0;handler=1"

	read -r -d '' QUERY <<-EOF
		SELECT
			COALESCE(scheduler, '__unknown__'),
			COALESCE(handler, '__unknown__'),
			count(*)
		FROM
			workflow_invocation
		${date_filter}
		GROUP BY
			scheduler, handler
	EOF
}

server_groups-disk-usage() { ## [YYYY-MM-DD] [=, <=, >= operators]: Retrieve an approximation of the disk usage for groups
	meta <<-EOF
		ADDED: 14
	EOF
	handle_help "$@" <<-EOF
	EOF

	op="="
	if (( $# > 1 )); then
		op="$2"
	fi

	date_filter=""
	if (( $# > 0 )); then
		date_filter="AND date_trunc('day', dataset.create_time AT TIME ZONE 'UTC') $op '$1'::date"
	fi

	groupname=$(gdpr_safe galaxy_group.name group_name 'Anonymous')

	fields="storage_usage=1"
	tags="group_name=0"

	read -r -d '' QUERY <<-EOF
		SELECT $groupname,
			sum(coalesce(dataset.total_size, dataset.file_size, 0)) as "storage_usage"
		FROM dataset,
			galaxy_group,
			user_group_association,
			history_dataset_association,
			history
		WHERE NOT dataset.purged
			AND dataset.id = history_dataset_association.dataset_id
			AND history_dataset_association.history_id = history.id
			AND history.user_id = user_group_association.user_id
			AND user_group_association.group_id = galaxy_group.id
			$date_filter
		GROUP BY galaxy_group.name
	EOF
}

server_groups-allocated-cpu() { ## [YYYY-MM-DD] [=, <=, >= operators]: Retrieve an approximation of the CPU allocation for groups
	meta <<-EOF
		ADDED: 14
	EOF
	handle_help "$@" <<-EOF
	EOF

	op="="
	if (( $# > 1 )); then
		op="$2"
	fi

	date_filter=""
	if (( $# > 0 )); then
		date_filter="AND date_trunc('day', job.create_time AT TIME ZONE 'UTC') $op '$1'::date"
	fi

	groupname=$(gdpr_safe galaxy_group.name group_name 'Anonymous')

	fields="cpu_seconds=1"
	tags="group_name=0"

	read -r -d '' QUERY <<-EOF
		WITH jobs_info AS (
			SELECT job.user_id,
				round(sum(a.metric_value * b.metric_value), 2) AS cpu_seconds
			FROM job_metric_numeric AS a,
				job_metric_numeric AS b,
				job
			WHERE job.id = a.job_id
				AND job.id = b.job_id
				AND a.metric_name = 'runtime_seconds'
				AND b.metric_name = 'galaxy_slots'
				$date_filter
			GROUP BY job.user_id
		), user_job_info AS (
			SELECT user_id,
				sum(cpu_seconds) AS cpu_seconds
			FROM jobs_info
			GROUP BY user_id
		)
		SELECT $groupname,
			round(sum(user_job_info.cpu_seconds), 2) as cpu_seconds
		FROM user_job_info,
			galaxy_group,
			user_group_association
		WHERE user_job_info.user_id = user_group_association.user_id
			AND user_group_association.group_id = galaxy_group.id
		GROUP BY galaxy_group.name

	EOF
}

server_groups-allocated-gpu() { ## [YYYY-MM-DD] [=, <=, >= operators]: Retrieve an approximation of the GPU allocation for groups
	meta <<-EOF
		ADDED: 14
	EOF
	handle_help "$@" <<-EOF
	EOF

	op="="
	if (( $# > 1 )); then
		op="$2"
	fi

	date_filter=""
	if (( $# > 0 )); then
		date_filter="AND date_trunc('day', job.create_time AT TIME ZONE 'UTC') $op '$1'::date"
	fi

	groupname=$(gdpr_safe galaxy_group.name group_name 'Anonymous')

	fields="gpu_seconds=1"
	tags="group_name=0"

	read -r -d '' QUERY <<-EOF
		WITH jobs_info AS (
			SELECT job.user_id,
				round(sum(a.metric_value * length(replace(b.metric_value, ',', ''))), 2) AS gpu_seconds
			FROM job_metric_numeric AS a,
				job_metric_text AS b,
				job
			WHERE job.id = a.job_id
				AND job.id = b.job_id
				AND a.metric_name = 'runtime_seconds'
				AND b.metric_name = 'CUDA_VISIBLE_DEVICES'
				$date_filter
			GROUP BY job.user_id
		), user_job_info AS (
			SELECT user_id,
				sum(gpu_seconds) AS gpu_seconds
			FROM jobs_info
			GROUP BY user_id
		)
		SELECT $groupname,
			round(sum(user_job_info.gpu_seconds), 2) as gpu_seconds
		FROM user_job_info,
			galaxy_group,
			user_group_association
		WHERE user_job_info.user_id = user_group_association.user_id
			AND user_group_association.group_id = galaxy_group.id
		GROUP BY galaxy_group.name
	EOF
}

server_workflow-trace-archive-metrics() { ## : [Workflow Trace Archive] Export numeric metrics
	meta <<-EOF
		ADDED: 17
	EOF
	handle_help "$@" <<-EOF
		Helper for WTA
	EOF

	read -r -d '' QUERY <<-EOF
		SELECT * FROM job_metric_numeric
	EOF
}

server_workflow-trace-archive-jobs() { ## : [Workflow Trace Archive] Export jobs
	meta <<-EOF
		ADDED: 17
	EOF
	handle_help "$@" <<-EOF
		Helper for WTA
	EOF

	read -r -d '' QUERY <<-EOF
		SELECT
			id,
			create_time,
			update_time,
			tool_id,
			tool_version,
			state,
			runner_name,
			job_runner_name,
			imported,
			object_store_id,
			handler,
			exit_code,
			destination_id,
			copied_from_job_id,
			dynamic_tool_id,
			galaxy_version
		FROM
			job
	EOF
}

server_workflow-trace-archive-workflows() { ## : [Workflow Trace Archive] Export workflows
	meta <<-EOF
		ADDED: 17
	EOF
	handle_help "$@" <<-EOF
		Helper for WTA
	EOF

	read -r -d '' QUERY <<-EOF
		SELECT
			id,
			create_time,
			update_time,
			stored_workflow_id,
			has_cycles,
			has_errors,
			parent_workflow_id,
			uuid
		FROM workflow
	EOF
}

server_workflow-trace-archive-workflow-invocations() { ## : [Workflow Trace Archive] Export workflow invocations
	meta <<-EOF
		ADDED: 17
	EOF
	handle_help "$@" <<-EOF
		Helper for WTA
	EOF

	read -r -d '' QUERY <<-EOF
		SELECT
			id,
			create_time,
			update_time,
			workflow_id,
			state,
			scheduler,
			handler
		FROM workflow_invocation
	EOF
}

server_workflow-trace-archive-workflow-steps() { ## : [Workflow Trace Archive] Export workflow steps
	meta <<-EOF
		ADDED: 17
	EOF
	handle_help "$@" <<-EOF
		Helper for WTA
	EOF

	read -r -d '' QUERY <<-EOF
		SELECT id,
			create_time,
			update_time,
			workflow_id,
			type,
			tool_id,
			tool_version,
			order_index,
			subworkflow_id,
			dynamic_tool_id
		FROM workflow_step
	EOF
}

server_workflow-trace-archive-workflow-invocation-steps() { ## : [Workflow Trace Archive] Export workflow invocation steps
	meta <<-EOF
		ADDED: 17
	EOF
	handle_help "$@" <<-EOF
		Helper for WTA
	EOF

	read -r -d '' QUERY <<-EOF
		SELECT
			id,  create_time,  update_time,  workflow_invocation_id,
			workflow_step_id,  job_id,  state
		FROM workflow_invocation_step
	EOF
}

server_workflow-trace-archive-workflow-connections() { ## : [Workflow Trace Archive] Export workflow connections
	meta <<-EOF
		ADDED: 17
	EOF
	handle_help "$@" <<-EOF
		Helper for WTA
	EOF

	read -r -d '' QUERY <<-EOF
		SELECT
			id, output_step_id, input_step_input_id, output_name, input_subworkflow_step_id
		FROM workflow_step_connection
	EOF
}
server_workflow-trace-archive-workflow-step-input() { ## : [Workflow Trace Archive] Export workflow step-input
	meta <<-EOF
		ADDED: 17
	EOF
	handle_help "$@" <<-EOF
		Helper for WTA
	EOF

	read -r -d '' QUERY <<-EOF
		SELECT
			id, workflow_step_id, name
		FROM workflow_step_input
	EOF
}
