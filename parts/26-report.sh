report_user-info(){ ## <user_id|username|email>: Quick overview of a Galaxy user in your system
	handle_help "$@" <<-EOF
		This command lets you quickly find out information about a user. The output is formatted as markdown by default.

		    $ gxadmin report user-info helena-rasche
		    # Galaxy User 580

		      Property | Value
		    ---------- | -----
		            ID | helena-rasche (id=580) hxr@informatik.uni-freiburg.de
		       Created | 2017-07-26 14:47:37.575484
		    Properties | ext=f deleted=f purged=f active=t
		    Disk Usage | 137 GB

		    ## Groups/Roles

		    Groups: training-freiburg-rnaseq-2018, training-emc2018
		    Roles: admin, Backofen

		    ## Recent Jobs

		    Tool ID                      | Status | Created                    | Exit Code | Runtime
		    ----                         | ----   | ----                       | ---       | ----
		    Grep1                        | ok     | 2019-01-21 07:27:24.472706 | 0         | 00:01:19
		    CONVERTER_fasta_to_tabular   | ok     | 2019-01-21 07:27:24.339862 | 0         | 00:03:34
		    secure_hash_message_digest   | ok     | 2019-01-18 16:43:44.262265 | 0         | 00:00:08
		    CONVERTER_gz_to_uncompressed | ok     | 2019-01-18 10:18:23.99171  | 0         | 00:10:02
		    upload1                      | ok     | 2019-01-18 08:44:24.955622 | 0         | 01:11:07
		    echo_main_env                | ok     | 2019-01-17 16:45:04.019233 | 0         | 00:00:29
		    secure_hash_message_digest   | ok     | 2019-01-17 16:03:21.33665  | 0         | 00:00:07
		    secure_hash_message_digest   | ok     | 2019-01-17 16:03:20.937433 | 0         | 00:00:09

		    ## Largest Histories

		    History ID | Name                         | Size
		    ----       | ----                         | ----
		    20467      | imported: RNASEQ             | 52 GB
		    94748      | imported: ChIP-seq           | 49 GB
		    94761      | reduced history-export problem |   49 GB
		    102448     | Wheat Genome                 | 42 GB
		    38923      | imported: Zooplankton        | 29 GB
		    64974      | imported: 65991-A            | 17 GB
		    20488      | Unnamed history              | 15 GB
		    19414      | Unnamed history              | 12 GB
		    92407      | Testing                      | 11 GB
		    60522      | example1/wf3-shed-tools.ga   | 5923 MB
	EOF

	# Metada
	read -r -d '' qstr <<-EOF
		SELECT
			username, id, email, create_time AT TIME ZONE 'UTC' as create_time, external, deleted, purged, active, pg_size_pretty(disk_usage)
		FROM
			galaxy_user
		WHERE
			(galaxy_user.email = '$1' or galaxy_user.username = '$1' or galaxy_user.id = CAST(REGEXP_REPLACE(COALESCE('$1','0'), '[^0-9]+', '0', 'g') AS INTEGER))
	EOF
	results=$(query_tsv "$qstr")
	user_id=$(echo "$results" | awk '{print $2}')

	if [[ -z "$user_id" ]]; then
		error "Unknown user"
		exit 1
	fi

	# Groups
	read -r -d '' qstr <<-EOF
		select string_agg(galaxy_group.name, ', ') from user_group_association, galaxy_group where user_id = $user_id and user_group_association.group_id = galaxy_group.id
	EOF
	group_membership=$(query_tsv "$qstr")

	read -r -d '' qstr <<-EOF
		select string_agg(role.name, ', ') from user_role_association, role where user_id = $user_id and user_role_association.role_id = role.id and role.type not in ('private', 'sharing')
	EOF
	role_membership=$(query_tsv "$qstr")

	# Recent jobs
	read -r -d '' qstr <<-EOF
		SELECT
			job.id, tool_id, state, create_time AT TIME ZONE 'UTC' as create_time, exit_code, metric_value::text::interval
		FROM
			job, job_metric_numeric
		WHERE
			job.user_id = $user_id and job.id = job_metric_numeric.job_id and metric_name = 'runtime_seconds' order by job.id desc limit 10
	EOF
	recent_jobs=$(query_tsv "$qstr")
	recent_jobs2=$(printf "ID\tTool ID\tStatus\tCreated\tExit Code\tRuntime\n----\t----\t----\t----\t---\t----\n%s" "$recent_jobs" | sed 's/\t/\t | \t/g' | column -t -s'	')

	# running jobs
	read -r -d '' qstr <<-EOF
		SELECT
			id, tool_id, tool_version, handler, destination_id, state, create_time AT TIME ZONE 'UTC' as create_time, now() AT TIME ZONE 'UTC' - create_time  AT TIME ZONE 'UTC' as runtime
		FROM
			job
		WHERE
			job.user_id = $user_id and job.state in ('running', 'queued', 'new') order by job.id desc
	EOF
	running_jobs=$(query_tsv "$qstr")
	running_jobs2=$(printf "Tool ID\tTool Version\tHandler\tDestination\tState\tCreated\tRuntime\n----\t----\t----\t----\t----\t---\t----\n%s" "$running_jobs" | sed 's/\t/\t | \t/g' | column -t -s'	')

	# Recent workflows
	read -r -d '' qstr <<-EOF
		SELECT
			workflow_invocation.id,
			workflow_invocation.create_time,
			state,
			scheduler,
			handler,
			substring(workflow.name, 0, 20) AS workflow,
			substring(history.name, 0, 20) AS history
		FROM
			workflow_invocation
			JOIN workflow ON workflow_invocation.workflow_id = workflow.id
			JOIN history ON workflow_invocation.history_id = history.id
		WHERE
			history.user_id = $user_id
		ORDER BY
			create_time DESC
		LIMIT
			5
	EOF
	recent_wf=$(query_tsv "$qstr")
	recent_wf=$(printf "ID\tCreated\tState\tScheduler\tHandler\tWorkflow\tHistory\n----\t----\t----\t----\t----\t----\t----\n%s" "$recent_wf" | sed 's/\t/\t | \t/g' | column -t -s'	')

	# Largest Histories
	read -r -d '' qstr <<-EOF
		SELECT
			history.id, history.name, pg_size_pretty(sum(COALESCE(dataset.total_size, 0))) AS size, history.deleted, history.purged
		FROM
			history
			LEFT JOIN history_dataset_association ON history.id = history_dataset_association.history_id
			LEFT JOIN dataset ON history_dataset_association.dataset_id = dataset.id
		WHERE
			history.user_id = $user_id
		GROUP BY
			history.id, history.name
		ORDER BY
			sum(COALESCE(dataset.total_size, 0)) DESC
		LIMIT
			10
	EOF
	largest_histories=$(query_tsv "$qstr")
	largest_histories=$(printf "History ID\tName\tSize\tDeleted\tPurged\n----\t----\t----\t----\t----\n%s" "$largest_histories" | sed 's/\t/\t | \t/g' | column -t -s'	')

	read -r -d '' template <<EOF
# Galaxy User $user_id

  Property | Value
---------- | -----
        ID | %s (id=%s) %s
   Created | %s %s
Properties | ext=%s deleted=%s purged=%s active=%s
Disk Usage | %s %s

## Groups/Roles

Groups: %s
Roles: %s

## Recent Jobs

%s

## Running Jobs

%s

## Recent Workflow Invocations

%s

## Largest Histories

%s
\n
EOF
	# shellcheck disable=SC2086
	# shellcheck disable=SC2059
	printf "$template" $results "$group_membership" "$role_membership" "$recent_jobs2" "$running_jobs2" "$recent_wf" "$largest_histories"
}

report_job-info(){ ## <id>: Information about a specific job
	handle_help "$@" <<-EOF
		    $ gxadmin report job-info 1
		     tool_id | state | username |        create_time         | job_runner_name | job_runner_external_id
		    ---------+-------+----------+----------------------------+-----------------+------------------------
		     upload1 | ok    | admin    | 2012-12-06 16:34:27.492711 | local:///       | 9347
	EOF

	assert_count $# 1 "Missing Job ID"
	username=$(gdpr_safe galaxy_user.username username)
	job_id=$1

	###       ###
	#  JOB INFO #
	###       ###

	read -r -d '' qstr <<-EOF
		SELECT
			job.tool_id,
			job.state,
			job.handler,
			job.create_time AT TIME ZONE 'UTC' as create_time,
			(now() AT TIME ZONE 'UTC' - job.create_time)::interval,
			COALESCE(job.job_runner_name, '?'),
			COALESCE(job.job_runner_external_id, '?')
		FROM job
		WHERE job.id = $job_id
	EOF
	results=$(query_tsv "$qstr")
	read -r -d '' template <<EOF
# Galaxy Job $job_id

Property      | Value
------------- | -----
         Tool | %s
        State | %s
      Handler | %s
      Created | %s %s (%s %s %s ago)
Job Runner/ID | %s / %s
EOF
	# shellcheck disable=SC2059
	# shellcheck disable=SC2086
	printf "$template"  $results

	###       ###
	# USER INFO #
	###       ###

	read -r -d '' qstr <<-EOF
		SELECT
			$username,
			job.user_id
		FROM job, galaxy_user
		WHERE job.id = $job_id AND job.user_id = galaxy_user.id
	EOF
	job_owner=$(query_tsv "$qstr")
	# shellcheck disable=SC2183
	# shellcheck disable=SC2086
	printf "\n        Owner | %s (id=%s)\n\n" $job_owner


	###         ###
	# DEST PARAMS #
	###         ###
	read -r -d '' qstr <<-EOF
		SELECT convert_from(destination_params::bytea, 'UTF8')
		FROM job
		WHERE job.id = $job_id
	EOF
	results=$(query_tsv "$qstr")
	printf "## Destination Parameters\n\n"
	# shellcheck disable=SC2016
	tbl=$(echo "$results" | jq -S '. | to_entries[] | [.key, .value] | @tsv' -r | sed 's/\t/\t`/g;s/$/`/g')
	# shellcheck disable=SC2059
	printf "Key\tValue\n---\t---\n$tbl" | sed 's/\t/\t | \t/g' | column -t -s'	'

	###          ###
	# DEPENDENCIES #
	###          ###
	read -r -d '' qstr <<-EOF
		SELECT convert_from(dependencies::bytea, 'UTF8')
		FROM job
		WHERE job.id = $job_id
	EOF
	results=$(query_tsv "$qstr")
	printf "\n## Dependencies\n\n"
	tbl=$(echo "$results" | jq -S '.[] | [.name, .version, .dependency_type, .cacheable, .exact, .environment_path, .model_class] | @tsv' -r)
	# shellcheck disable=SC2059
	printf "Name\tVersion\tDependency Type\tCacheable\tExact\tEnvironment Path\tModel Class\n----\t-------\t---------------\t---------\t-----\t----------------\t-----------\n$tbl\n" | sed 's/\t/\t | \t/g'       #| column -t -s'	'

	###        ###
	# JOB PARAMS #
	###        ###
	read -r -d '' qstr <<-EOF
		SELECT j.name, j.value
		FROM job_parameter j
		WHERE j.job_id = $job_id
	EOF
	results=$(query_tsv "$qstr")
	printf "\n## Tool Parameters\n\n"
	# shellcheck disable=SC2059
	printf "Name\tSettings\n---------\t------------------------------------\n$results\n\n" | sed 's/\t/\t | \t/g' | sed 's/[\"\`]//g'

	###      ###
	#  INPUTS  #
	###      ###
	read -r -d '' qstr <<-EOF
	SELECT
		jtod.job_id,
	    hda.name,
	    hda.extension,
	    hda.id,
	    hda.state,
	    hda.deleted,
	    hda.purged,
	    ds.id,
	    ds.state,
	    ds.deleted,
	    ds.purged,
	    pg_size_pretty(ds.total_size)
	FROM
	    job_to_input_dataset AS jtid,
		history_dataset_association AS hda,
		dataset AS ds,
		job_to_output_dataset as jtod
	WHERE
	    jtid.job_id = $1
		AND jtid.dataset_id = hda.id
		AND hda.dataset_id = ds.id
		AND jtod.dataset_id = ds.id
	EOF
	input_ds=$(query_tsv "$qstr")
	input_ds_tbl=$(printf "Job ID\tName\tExtension\thda-id\thda-state\thda-deleted\thda-purged\tds-id\tds-state\tds-deleted\tds-purged\tSize\n----\t----\t----\t----\t----\t----\t----\t----\t----\t----\t----\t----\n%s" "$input_ds" | sed 's/\t/\t | \t/g' )      #| column -t -s'	')

	###       ###
	#  OUTPUTS  #
	###       ###
	read -r -d '' qstr <<-EOF
	SELECT
	    hda.name,
	    hda.extension,
	    hda.id,
	    hda.state,
	    hda.deleted,
	    hda.purged,
	    ds.id,
	    ds.state,
	    ds.deleted,
	    ds.purged,
	    pg_size_pretty(ds.total_size)
	FROM
	    job_to_output_dataset AS jtod,
		history_dataset_association AS hda,
		dataset AS ds
	WHERE
	    jtod.job_id = $1
		AND jtod.dataset_id = hda.id
		AND hda.dataset_id = ds.id
	EOF
	output_ds=$(query_tsv "$qstr")
	output_ds_tbl=$(printf "Name\tExtension\thda-id\thda-state\thda-deleted\thda-purged\tds-id\tds-state\tds-deleted\tds-purged\tSize\n----\t----\t----\t----\t----\t----\t----\t----\t----\t----\t----\n%s" "$output_ds" | sed 's/\t/\t | \t/g' )          #| column -t -s'	')


	read -r -d '' template3 <<EOF

## Inputs

%s

## Outputs

%s

\n
EOF
	# shellcheck disable=SC2059
	printf "$template3" "$input_ds_tbl" "$output_ds_tbl"
}


report_assigned-to-handler(){ ## <handler>: Report what items are assigned to a handler currently.
	handle_help "$@" <<-EOF
	EOF

	assert_count $# 1 "Missing Handler ID"
	printf "# Handler %s\n\n" "$1"

	# Jerbs
	printf "## Jobs\n\n"
	read -r -d '' qstr <<-EOF
		SELECT
			id, create_time, tool_id, state, object_store_id, user_id
		FROM job
		WHERE handler = '$1' and state in ('new', 'queued', 'running')
		ORDER BY create_time DESC
	EOF
	output_ds=$(query_tsv "$qstr")
	printf "ID\tCreate Time\tTool ID\tState\tObject Store\tUser ID\n----\t----\t----\t----\t----\t----\n%s" "$output_ds" | sed 's/\t/\t | \t/g' | column -t -s'	'


	# Workflows
	printf "## Workflows\n\n"
	read -r -d '' qstr <<-EOF
		SELECT
			id, create_time, workflow_id, history_id, state, scheduler, uuid
		FROM workflow_invocation
		WHERE handler = '$1' and state = 'new'
	EOF
	output_ds=$(query_tsv "$qstr")
	printf "ID\tCreate Time\tWorkflow ID\tHistory ID\tState\tScheduler\tUUID\n----\t----\t----\t----\t----\t----\t----\n%s" "$output_ds" | sed 's/\t/\t | \t/g' | column -t -s'	'
}
