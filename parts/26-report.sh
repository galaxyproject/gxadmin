registered_subcommands="$registered_subcommands report"
_report_short_help="Various (rich) reports. Consider https://github.com/ttscoff/mdless for easier reading in the terminal! Or | pandoc | lynx -stdin"


align_cols() {
	#cat | sed 's/\t/\t | /g' | column -t -s'	'
	cat | sed 's/\t/ | /g'
}

report_group-info(){ ## <group_id|groupname>: Quick overview of a Galaxy group in your system
	handle_help "$@" <<-EOF
		This command lets you quickly find out information about a Galaxy group. The output is formatted as markdown by default.
		Consider [mdless](https://github.com/ttscoff/mdless) for easier reading in the terminal!
		    $ gxadmin report group-info Backofen
			# Galaxy Group 18
			      Property | Value
			-------------- | -----
			            ID | Backofen (id=1)
			       Created | 2013-02-25 15:58:10.691672+01
			    Properties | deleted=f
			    Group size | 8
			Number of jobs | 1630
			    Disk usage | 304 GB
			Data generated | 6894 GB
			     CPU years | 4.07

			## Member stats
			Username | Email | User ID | Active | Disk Usage | Number of jobs | CPU years
			---- | ---- | ---- | ---- | --- | ---- | ---- | ----
			bgruening | bgruening@gmail.com | 25 | t | 265 GB | 1421 | 1.14
			helena-rasche | hxr@informatik.uni-freiburg.de | 122 | t | 37 GB | 113 | 2.91
			videmp | videmp@informatik.uni-freiburg.de | 46 | t | 1383 MB | 96 | 0.02
	EOF

	# Metada
	read -r -d '' qstr <<-EOF
		SELECT
			g.name, g.id, g.create_time AT TIME ZONE 'UTC' as create_time, g.deleted, count(distinct ug.id)
		FROM
			galaxy_group AS g, user_group_association AS ug
		WHERE
			g.id=ug.group_id AND (g.name='$1' or g.id= CAST(REGEXP_REPLACE(COALESCE('$1','0'), '[^0-9]+', '0', 'g') AS INTEGER))
		GROUP BY g.id
	EOF
	results=$(query_tsv "$qstr")
	group_id=$(echo "$results" | awk '{print $2}')

	if [[ -z "$group_id" ]]; then
		error "Unknown group"
		exit 1
	fi

	# Group total number of jobs
	read -r -d '' qstr <<-EOF
		SELECT
			count(j.*)
		FROM
			galaxy_user u 
			INNER JOIN job j ON u.id=j.user_id 
			INNER JOIN user_group_association ug ON ug.user_id=j.user_id
		WHERE
			ug.group_id=$group_id
	EOF
	g_total_n_jobs=$(query_tsv "$qstr")

	# Group total disk usage
	read -r -d '' qstr <<-EOF
		SELECT
			pg_size_pretty(SUM(u.disk_usage))
		FROM
			galaxy_user u, user_group_association ug
		WHERE
			u.id=ug.user_id AND ug.group_id=$group_id
	EOF
	g_total_disk_usage=$(query_tsv "$qstr")

	# Group total data generated
	read -r -d '' qstr <<-EOF
		SELECT
			pg_size_pretty(COALESCE(SUM(total_size), 0))
		FROM
			(SELECT d.total_size FROM galaxy_user u,history_dataset_association hda JOIN history h ON h.id = hda.history_id JOIN dataset d ON hda.dataset_id = d.id  WHERE h.user_id IN (SELECT user_id FROM user_group_association WHERE group_id=$group_id) AND d.id NOT IN (SELECT dataset_id FROM library_dataset_dataset_association) GROUP BY d.id) AS sizes
	EOF
	g_total_data_generated=$(query_tsv "$qstr")

	# Group total CPU years
	read -r -d '' qstr <<-EOF
		SELECT
			GREATEST(round(sum((a.metric_value * b.metric_value) / 3600 / 24 / 365), 2), 0.00)
		FROM
			job j FULL OUTER JOIN galaxy_user u ON j.user_id = u.id INNER JOIN user_group_association ug ON u.id=ug.user_id LEFT JOIN job_metric_numeric a ON a.job_id=j.id LEFT JOIN job_metric_numeric b ON a.job_id=b.job_id
		WHERE
			(a.metric_name = 'runtime_seconds' OR a.metric_value is NULL) AND (b.metric_name = 'galaxy_slots' OR b.metric_value is NULL) AND group_id=$group_id
	EOF
	g_total_cup_years=$(query_tsv "$qstr")

	# Group members stats
	read -r -d '' qstr <<-EOF
		SELECT
			u.username, u.email, u.id, u.active, pg_size_pretty(u.disk_usage), count(j.*), GREATEST(round(sum((a.metric_value * b.metric_value) / 3600 / 24 / 365), 2), 0.00)
		FROM
			job j FULL OUTER JOIN galaxy_user u ON j.user_id = u.id INNER JOIN user_group_association ug ON u.id=ug.user_id LEFT JOIN job_metric_numeric a ON a.job_id=j.id LEFT JOIN job_metric_numeric b ON a.job_id=b.job_id
		WHERE
			(a.metric_name = 'runtime_seconds' OR a.metric_value is NULL) AND (b.metric_name = 'galaxy_slots' OR b.metric_value is NULL) AND group_id=$group_id
		GROUP BY
			u.id
		ORDER BY
			u.username
	EOF
	member_stats=$(query_tsv "$qstr")
	member_stats_w_header=$(printf "Username\tEmail\tUser ID\tActive\tDisk Usage\tNumber of jobs\tCPU years\n----\t----\t----\t----\t---\t----\t----\n%s" "$member_stats" | align_cols)

	read -r -d '' template <<EOF
# Galaxy Group $group_id
           Property | Value
           -------- | ----
                 ID | %s (id=%s)
            Created | %s %s
         Properties | deleted=%s
         Group size | %s
     Number of jobs | %s
         Disk usage | %s %s
     Data generated | %s %s
          CPU years | %s

## Individual Member stats
%s
\n
EOF
	# shellcheck disable=SC2086
	# shellcheck disable=SC2059
	printf "$template" $results $g_total_n_jobs $g_total_disk_usage $g_total_data_generated $g_total_cup_years "$member_stats_w_header"
}

report_user-info(){ ## <user_id|username|email>: Quick overview of a Galaxy user in your system
	handle_help "$@" <<-EOF
		This command lets you quickly find out information about a user. The output is formatted as markdown by default.

		Consider [mdless](https://github.com/ttscoff/mdless) for easier reading in the terminal!

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
	recent_jobs2=$(printf "ID\tTool ID\tStatus\tCreated\tExit Code\tRuntime\n----\t----\t----\t----\t---\t----\n%s" "$recent_jobs" | align_cols)

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
	running_jobs2=$(printf "Tool ID\tTool Version\tHandler\tDestination\tState\tCreated\tRuntime\n----\t----\t----\t----\t----\t---\t----\n%s" "$running_jobs" | align_cols)

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
			25
	EOF
	recent_wf=$(query_tsv "$qstr")
	recent_wf=$(printf "ID\tCreated\tState\tScheduler\tHandler\tWorkflow\tHistory\n----\t----\t----\t----\t----\t----\t----\n%s" "$recent_wf" | align_cols)

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
	largest_histories=$(printf "History ID\tName\tSize\tDeleted\tPurged\n----\t----\t----\t----\t----\n%s" "$largest_histories" | align_cols)

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
      Created | %s %s
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
	results=$(query_tsv_json "$qstr")
	printf "## Destination Parameters\n\n"
	# shellcheck disable=SC2016
	tbl=$(echo "$results" | jq -S '. | to_entries[] | [.key, .value] | @tsv' -r | sed 's/\t/\t`/g;s/$/`/g')
	# shellcheck disable=SC2059
	printf "Key\tValue\n---\t---\n$tbl" | align_cols

	###          ###
	# DEPENDENCIES #
	###          ###
	read -r -d '' qstr <<-EOF
		SELECT convert_from(dependencies::bytea, 'UTF8')
		FROM job
		WHERE job.id = $job_id
	EOF
	results=$(query_tsv_json "$qstr")
	printf "\n## Dependencies\n\n"
	tbl=$(echo "$results" | jq -S '.[] | [.name, .version, .dependency_type, .cacheable, .exact, .environment_path, .model_class] | @tsv' -r)
	# shellcheck disable=SC2059
	printf "Name\tVersion\tDependency Type\tCacheable\tExact\tEnvironment Path\tModel Class\n----\t-------\t---------------\t---------\t-----\t----------------\t-----------\n$tbl\n" | align_cols

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
	printf "Name\tSettings\n-----\t------------\n$results\n\n" | sed 's/[\"\`]//g' | align_cols

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
	input_ds_tbl=$(printf "\nJob ID\tName\tExtension\thda-id\thda-state\thda-deleted\thda-purged\tds-id\tds-state\tds-deleted\tds-purged\tSize\n----\t----\t----\t----\t----\t----\t----\t----\t----\t----\t----\t----\n%s" "$input_ds" | align_cols)

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
	output_ds_tbl=$(printf "Name\tExtension\thda-id\thda-state\thda-deleted\thda-purged\tds-id\tds-state\tds-deleted\tds-purged\tSize\n----\t----\t----\t----\t----\t----\t----\t----\t----\t----\t----\n%s" "$output_ds" |  align_cols)


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
	printf "ID\tCreate Time\tTool ID\tState\tObject Store\tUser ID\n----\t----\t----\t----\t----\t----\n%s" "$output_ds" | align_cols


	# Workflows
	printf "## Workflows\n\n"
	read -r -d '' qstr <<-EOF
		SELECT
			id, create_time, workflow_id, history_id, state, scheduler, uuid
		FROM workflow_invocation
		WHERE handler = '$1' and state = 'new'
	EOF
	output_ds=$(query_tsv "$qstr")
	printf "ID\tCreate Time\tWorkflow ID\tHistory ID\tState\tScheduler\tUUID\n----\t----\t----\t----\t----\t----\t----\n%s" "$output_ds" | align_cols
}
