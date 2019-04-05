query_latest-users() { ## query latest-users: 40 recently registered users
	handle_help "$@" <<-EOF
		Returns 40 most recently registered users

		    $ gxadmin query latest-users
		     id |        create_time        | pg_size_pretty |   username    |             email
		    ----+---------------------------+----------------+---------------+--------------------------------
		      1 | 2018-10-05 11:40:42.90119 |                | helena-rasche | hxr@informatik.uni-freiburg.de
	EOF

	username=$(gdpr_safe username)
	email=$(gdpr_safe email)

	read -r -d '' QUERY <<-EOF
		SELECT
			id,
			create_time AT TIME ZONE 'UTC' as create_time,
			pg_size_pretty(disk_usage) as disk_usage,
			$username,
			$email,
			array_to_string(ARRAY(
				select galaxy_group.name from galaxy_group where id in (
					select group_id from user_group_association where user_group_association.user_id = galaxy_user.id
				)
			), ' ') as groups,
			active
		FROM galaxy_user
		ORDER BY create_time desc
		LIMIT 40
	EOF
}

query_tool-usage() { ## query tool-usage [weeks]: Counts of tool runs in the past weeks (default = all)
	handle_help "$@" <<-EOF
		    $ gxadmin tool-usage
		                                    tool_id                                 | count
		    ------------------------------------------------------------------------+--------
		     toolshed.g2.bx.psu.edu/repos/devteam/column_maker/Add_a_column1/1.1.0  | 958154
		     Grouping1                                                              | 638890
		     toolshed.g2.bx.psu.edu/repos/devteam/intersect/gops_intersect_1/1.0.0  | 326959
		     toolshed.g2.bx.psu.edu/repos/devteam/get_flanks/get_flanks1/1.0.0      | 320236
		     addValue                                                               | 313470
		     toolshed.g2.bx.psu.edu/repos/devteam/join/gops_join_1/1.0.0            | 312735
		     upload1                                                                | 103595
		     toolshed.g2.bx.psu.edu/repos/rnateam/graphclust_nspdk/nspdk_sparse/9.2 |  52861
		     Filter1                                                                |  43253
	EOF

	where=
	if (( $# > 0 )); then
		where="WHERE j.create_time > (now() - '$1 weeks'::interval)"
	fi

	fields="count=1"
	tags="tool_id=0"

	read -r -d '' QUERY <<-EOF
		SELECT
			j.tool_id, count(*) AS count
		FROM job j
		$where
		GROUP BY j.tool_id
		ORDER BY count DESC
	EOF
}

query_tool-popularity() { ## query tool-popularity [months|24]: Most run tools by month
	handle_help "$@" <<-EOF
		See most popular tools by month

		    $ ./gxadmin query tool-popularity 1
		              tool_id          |   month    | count
		    ---------------------------+------------+-------
		     circos                    | 2019-02-01 |    20
		     upload1                   | 2019-02-01 |    12
		     require_format            | 2019-02-01 |     9
		     circos_gc_skew            | 2019-02-01 |     7
		     circos_wiggle_to_scatter  | 2019-02-01 |     3
		     test_history_sanitization | 2019-02-01 |     2
		     circos_interval_to_tile   | 2019-02-01 |     1
		     __SET_METADATA__          | 2019-02-01 |     1
		    (8 rows)
	EOF

	fields="count=2"
	tags="tool_id=0;month=1"

	months=${1:-24}

	read -r -d '' QUERY <<-EOF
		SELECT
			tool_id,
			date_trunc('month', create_time AT TIME ZONE 'UTC')::date as month,
			count(*)
		FROM job
		WHERE create_time > (now() AT TIME ZONE 'UTC' - '$months months'::interval)
		GROUP BY tool_id, month
		ORDER BY month desc, count desc
	EOF
}

query_job-info() { ## query job-info <id>: Information about a specific job
	handle_help "$@" <<-EOF
		    $ gxadmin query job-info 1
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
	printf "\n        Owner | %s (id=%s)\n\n" $job_owner


	###         ###
	# DEST PARAMS #
	###         ###
	read -r -d '' qstr <<-EOF
		SELECT destination_params
		FROM job
		WHERE job.id = $job_id
	EOF
	results=$(query_tsv "$qstr")
	printf "## Destination Parameters\n\n"
	tbl=$(echo "$results" | python -c "$hexdecodelines" | jq -S '. | to_entries[] | [.key, .value] | @tsv' -r | sed 's/\t/\t`/g;s/$/`/g')
	printf "Key\tValue\n---\t---\n$tbl" | sed 's/\t/\t | \t/g' | column -t -s'	'

	###          ###
	# DEPENDENCIES #
	###          ###
	read -r -d '' qstr <<-EOF
		SELECT dependencies
		FROM job
		WHERE job.id = $job_id
	EOF
	results=$(query_tsv "$qstr")
	printf "\n## Dependencies\n\n"
	tbl=$(echo "$results" | python -c "$hexdecodelines" | jq -S '.[] | [.name, .version, .dependency_type, .cacheable, .exact, .environment_path, .model_class] | @tsv' -r)
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
	printf "$template3" "$input_ds_tbl" "$output_ds_tbl"
}

query_workflow-connections() { ## query workflow-connections [--all]: The connections of tools, from output to input, in the latest (or all) versions of user workflows
	handle_help "$@" <<-EOF
		This is used by the usegalaxy.eu tool prediction workflow, allowing for building models out of tool connections in workflows.

		    $ gxadmin query workflow-connections
		     wf_id |     wf_updated      | in_id |      in_tool      | in_tool_v | out_id |     out_tool      | out_tool_v
		    -------+---------------------+-------+-------------------+-----------+--------+-------------------+------------
		         3 | 2013-02-07 16:48:00 |     5 | Grep1             | 1.0.1     |     12 |                   |
		         3 | 2013-02-07 16:48:00 |     6 | Cut1              | 1.0.1     |      7 | Remove beginning1 | 1.0.0
		         3 | 2013-02-07 16:48:00 |     7 | Remove beginning1 | 1.0.0     |      5 | Grep1             | 1.0.1
		         3 | 2013-02-07 16:48:00 |     8 | addValue          | 1.0.0     |      6 | Cut1              | 1.0.1
		         3 | 2013-02-07 16:48:00 |     9 | Cut1              | 1.0.1     |      7 | Remove beginning1 | 1.0.0
		         3 | 2013-02-07 16:48:00 |    10 | addValue          | 1.0.0     |     11 | Paste1            | 1.0.0
		         3 | 2013-02-07 16:48:00 |    11 | Paste1            | 1.0.0     |      9 | Cut1              | 1.0.1
		         3 | 2013-02-07 16:48:00 |    11 | Paste1            | 1.0.0     |      8 | addValue          | 1.0.0
		         4 | 2013-02-07 16:48:00 |    13 | cat1              | 1.0.0     |     18 | addValue          | 1.0.0
		         4 | 2013-02-07 16:48:00 |    13 | cat1              | 1.0.0     |     20 | Count1            | 1.0.0
	EOF

	read -r -d '' wf_filter <<-EOF
	WHERE
		workflow.id in (
			SELECT
			 workflow.id
			FROM
			 stored_workflow
			LEFT JOIN
			 workflow on stored_workflow.latest_workflow_id = workflow.id
		)
	EOF
	if [[ $1 == "--all" ]]; then
		wf_filter=""
	fi

	read -r -d '' QUERY <<-EOF
		SELECT
			ws_in.workflow_id as wf_id,
			workflow.update_time AT TIME ZONE 'UTC' as wf_updated,
			wfc.input_step_id as in_id,
			ws_in.tool_id as in_tool,
			ws_in.tool_version as in_tool_v,
			wfc.output_step_id as out_id,
			ws_out.tool_id as out_tool,
			ws_out.tool_version as out_tool_v
		FROM
			workflow_step_connection wfc
		JOIN workflow_step ws_in  ON ws_in.id = wfc.input_step_id
		JOIN workflow_step ws_out ON ws_out.id = wfc.output_step_id
		JOIN workflow on ws_in.workflow_id = workflow.id
		$wf_filter
	EOF
}

query_datasets-created-daily() { ## query datasets-created-daily: The min/max/average/p95/p99 of total size of datasets created in a single day.
	handle_help "$@" <<-EOF
		    $ gxadmin query datasets-created-daily
		       min   |  avg   | perc_95 | perc_99 |  max
		    ---------+--------+---------+---------+-------
		     0 bytes | 338 GB | 1355 GB | 2384 GB | 42 TB
	EOF

	read -r -d '' QUERY <<-EOF
		WITH temp_queue_times AS
		(select
			date_trunc('day', create_time AT TIME ZONE 'UTC'),
			sum(total_size)
		from dataset
		group by date_trunc
		order by date_trunc desc)
		select
			pg_size_pretty(min(sum)) as min,
			pg_size_pretty(avg(sum)) as avg,
			pg_size_pretty(percentile_cont(0.95) WITHIN GROUP (ORDER BY sum) ::bigint) as perc_95,
			pg_size_pretty(percentile_cont(0.99) WITHIN GROUP (ORDER BY sum) ::bigint) as perc_99,
			pg_size_pretty(max(sum)) as max
		from temp_queue_times
	EOF
}

query_largest-collection() { ## query largest-collection: Returns the size of the single largest collection
	handle_help "$@" <<-EOF
	EOF

	fields="count=0"
	tags=""

	read -r -d '' QUERY <<-EOF
		WITH temp_table_collection_count AS (
			SELECT count(*)
			FROM dataset_collection_element
			GROUP BY dataset_collection_id
			ORDER BY count desc
		)
		select max(count) as count from temp_table_collection_count
	EOF
}

query_queue-time() { ## query queue-time <tool_id>: The average/95%/99% a specific tool spends in queue state.
	handle_help "$@" <<-EOF
		    $ gxadmin query queue-time toolshed.g2.bx.psu.edu/repos/nilesh/rseqc/rseqc_geneBody_coverage/2.6.4.3
		           min       |     perc_95     |     perc_99     |       max
		    -----------------+-----------------+-----------------+-----------------
		     00:00:15.421457 | 00:00:55.022874 | 00:00:59.974171 | 00:01:01.211995
	EOF

	assert_count $# 1 "Missing tool ID"

	read -r -d '' QUERY <<-EOF
		WITH temp_queue_times AS
		(select
			min(a.create_time - b.create_time) as queue_time
		from
			job_state_history as a
		inner join
			job_state_history as b
		on
			(a.job_id = b.job_id)
		where
			a.job_id in (select id from job where tool_id like '%$3%' and state = 'ok' and create_time > (now() AT TIME ZONE 'UTC' - '3 months'::interval))
			and a.state = 'running'
			and b.state = 'queued'
		group by
			a.job_id
		order by
			queue_time desc
		)
		select
			min(queue_time),
			percentile_cont(0.95) WITHIN GROUP (ORDER BY queue_time) as perc_95,
			percentile_cont(0.99) WITHIN GROUP (ORDER BY queue_time) as perc_99,
			max(queue_time)
		from temp_queue_times
	EOF
}

query_queue() { ## query queue: Brief overview of currently running jobs
	handle_help "$@" <<-EOF
		    $ gxadmin query queue
		                                tool_id                                |  state  | count
		    -------------------------------------------------------------------+---------+-------
		     toolshed.g2.bx.psu.edu/repos/iuc/unicycler/unicycler/0.4.6.0      | queued  |     9
		     toolshed.g2.bx.psu.edu/repos/iuc/dexseq/dexseq_count/1.24.0.0     | running |     7
		     toolshed.g2.bx.psu.edu/repos/nml/spades/spades/1.2                | queued  |     6
		     ebi_sra_main                                                      | running |     6
		     toolshed.g2.bx.psu.edu/repos/iuc/trinity/trinity/2.8.3            | queued  |     5
		     toolshed.g2.bx.psu.edu/repos/devteam/bowtie2/bowtie2/2.3.4.2      | running |     5
		     toolshed.g2.bx.psu.edu/repos/nml/spades/spades/3.11.1+galaxy1     | queued  |     4
		     toolshed.g2.bx.psu.edu/repos/iuc/mothur_venn/mothur_venn/1.36.1.0 | running |     2
		     toolshed.g2.bx.psu.edu/repos/nml/metaspades/metaspades/3.9.0      | running |     2
		     upload1                                                           | running |     2
	EOF

	fields="count=2"
	tags="tool_id=0;state=1"

	read -r -d '' QUERY <<-EOF
			SELECT tool_id, state, count(*)
			FROM job
			WHERE state in ('queued', 'running')
			GROUP BY tool_id, state
			ORDER BY count desc
	EOF
}

query_queue-overview() { ## query queue-overview [--short-tool-id]: View used mostly for monitoring
	handle_help "$@" <<-EOF
		Primarily for monitoring of queue. Optimally used with 'iquery' and passed to Telegraf.

		    $ gxadmin iquery queue-overview
		    queue-overview,tool_id=upload1,tool_version=0.0.1,state=running,handler=main.web.1,destination_id=condor,job_runner_name=condor,user=1 count=1

	EOF

	# Use full tool id by default
	tool_id="tool_id"
	if [[ $1 = --short-tool-id ]]; then
		tool_id="regexp_replace(tool_id, '.*toolshed.*/repos/', '')"
	fi

	# Include by default
	if [ -z "$GDPR_MODE"  ]; then
		user_id='user_id'
	else
		user_id="'0'"
	fi

	fields="count=6"
	tags="tool_id=0;tool_version=1;destination_id=2;handler=3;state=4;job_runner_name=5;user_id=7"

	read -r -d '' QUERY <<-EOF
		SELECT
			regexp_replace($tool_id, '/[0-9.a-z+-]+$', '') as tool_id,
			tool_version,
			COALESCE(destination_id, 'unknown'),
			COALESCE(handler, 'unknown'),
			state,
			COALESCE(job_runner_name, 'unknown'),
			count(*) as count,
			$user_id as user_id
		FROM job
		WHERE
			state = 'running' or state = 'queued' or state = 'new'
		GROUP BY
			tool_id, tool_version, destination_id, handler, state, job_runner_name, user_id
	EOF
}

query_queue-detail() { ## query queue-detail [--all]: Detailed overview of running and queued jobs
	handle_help "$@" <<-EOF
		    $ gxadmin query queue-detail
		      state  |   id    |  extid  |                                 tool_id                                   | username | time_since_creation
		    ---------+---------+---------+---------------------------------------------------------------------------+----------+---------------------
		     running | 4360629 | 229333  | toolshed.g2.bx.psu.edu/repos/bgruening/infernal/infernal_cmsearch/1.1.2.0 | xxxx     | 5 days 11:00:00
		     running | 4362676 | 230237  | toolshed.g2.bx.psu.edu/repos/iuc/mothur_venn/mothur_venn/1.36.1.0         | xxxx     | 4 days 18:00:00
		     running | 4364499 | 231055  | toolshed.g2.bx.psu.edu/repos/iuc/mothur_venn/mothur_venn/1.36.1.0         | xxxx     | 4 days 05:00:00
		     running | 4366604 | 5183013 | toolshed.g2.bx.psu.edu/repos/iuc/dexseq/dexseq_count/1.24.0.0             | xxxx     | 3 days 20:00:00
		     running | 4366605 | 5183016 | toolshed.g2.bx.psu.edu/repos/iuc/dexseq/dexseq_count/1.24.0.0             | xxxx     | 3 days 20:00:00
		     queued  | 4350274 | 225743  | toolshed.g2.bx.psu.edu/repos/iuc/unicycler/unicycler/0.4.6.0              | xxxx     | 9 days 05:00:00
		     queued  | 4353435 | 227038  | toolshed.g2.bx.psu.edu/repos/iuc/trinity/trinity/2.8.3                    | xxxx     | 8 days 08:00:00
		     queued  | 4361914 | 229712  | toolshed.g2.bx.psu.edu/repos/iuc/unicycler/unicycler/0.4.6.0              | xxxx     | 5 days -01:00:00
		     queued  | 4361812 | 229696  | toolshed.g2.bx.psu.edu/repos/iuc/unicycler/unicycler/0.4.6.0              | xxxx     | 5 days -01:00:00
		     queued  | 4361939 | 229728  | toolshed.g2.bx.psu.edu/repos/nml/spades/spades/1.2                        | xxxx     | 4 days 21:00:00
		     queued  | 4361941 | 229731  | toolshed.g2.bx.psu.edu/repos/nml/spades/spades/1.2                        | xxxx     | 4 days 21:00:00
	EOF

	d=""
	if [[ $1 == "--all" ]]; then
		d=", 'new'"
	fi

	username=$(gdpr_safe galaxy_user.username username)

	read -r -d '' QUERY <<-EOF
		SELECT
			job.state,
			job.id,
			job.job_runner_external_id as extid,
			job.tool_id,
			$username,
			(now() AT TIME ZONE 'UTC' - job.create_time) as time_since_creation,
			job.handler,
			job.job_runner_name,
			job.destination_id
		FROM job, galaxy_user
		WHERE
			state in ('running', 'queued'$d)
			AND job.user_id = galaxy_user.id
		ORDER BY
			state desc,
			time_since_creation desc
	EOF
}

query_runtime-per-user() { ## query runtime-per-user <email>: computation time of user (by email)
	handle_help "$@" <<-EOF
		    $ gxadmin query runtime-per-user hxr@informatik.uni-freiburg.de
		       sum
		    ----------
		     14:07:39
	EOF

	assert_count $# 1 "Missing user"

	read -r -d '' QUERY <<-EOF
			SELECT sum((metric_value || ' second')::interval)
			FROM job_metric_numeric
			WHERE job_id in (
				SELECT id
				FROM job
				WHERE user_id in (
					SELECT id
					FROM galaxy_user
					where email = '$1'
				)
			) AND metric_name = 'runtime_seconds'
	EOF
}

query_jobs-nonterminal() { ## query jobs-nonterminal [username|id|email]: Job info of nonterminal jobs separated by user
	handle_help "$@" <<-EOF
		You can request the user information by username, id, and user email

		    $ gxadmin query jobs-nonterminal helena-rasche
		       id    | tool_id             |  state  |        create_time         | runner | id     |     handler     | user_id
		    ---------+---------------------+---------+----------------------------+--------+--------+-----------------+---------
		     4760549 | featurecounts/1.6.3 | running | 2019-01-18 14:05:14.871711 | condor | 197549 | handler_main_7  | 599
		     4760552 | featurecounts/1.6.3 | running | 2019-01-18 14:05:16.205867 | condor | 197552 | handler_main_7  | 599
		     4760554 | featurecounts/1.6.3 | running | 2019-01-18 14:05:17.170157 | condor | 197580 | handler_main_8  | 599
		     4760557 | featurecounts/1.6.3 | running | 2019-01-18 14:05:18.25044  | condor | 197545 | handler_main_10 | 599
		     4760573 | featurecounts/1.6.3 | running | 2019-01-18 14:05:47.20392  | condor | 197553 | handler_main_2  | 599
		     4760984 | deseq2/2.11.40.4    | new     | 2019-01-18 14:56:37.700714 |        |        | handler_main_1  | 599
		     4766092 | deseq2/2.11.40.4    | new     | 2019-01-21 07:24:16.232376 |        |        | handler_main_5  | 599
		     4811598 | cuffnorm/2.2.1.2    | running | 2019-02-01 13:08:30.400016 | condor | 248432 | handler_main_0  | 599
		    (8 rows)

		You can also query all non-terminal jobs by all users

		    $ gxadmin query jobs-nonterminal | head
		       id    |  tool_id            |  state  |        create_time         | runner | id     |     handler     | user_id
		    ---------+---------------------+---------+----------------------------+--------+--------+-----------------+---------
		     4760549 | featurecounts/1.6.3 | running | 2019-01-18 14:05:14.871711 | condor | 197549 | handler_main_7  |     599
		     4760552 | featurecounts/1.6.3 | running | 2019-01-18 14:05:16.205867 | condor | 197552 | handler_main_7  |     599
		     4760554 | featurecounts/1.6.3 | running | 2019-01-18 14:05:17.170157 | condor | 197580 | handler_main_8  |     599
		     4760557 | featurecounts/1.6.3 | running | 2019-01-18 14:05:18.25044  | condor | 197545 | handler_main_10 |     599
		     4760573 | featurecounts/1.6.3 | running | 2019-01-18 14:05:47.20392  | condor | 197553 | handler_main_2  |     599
		     4760588 | featurecounts/1.6.3 | new     | 2019-01-18 14:11:03.766558 |        |        | handler_main_9  |      11
		     4760589 | featurecounts/1.6.3 | new     | 2019-01-18 14:11:05.895232 |        |        | handler_main_1  |      11
		     4760590 | featurecounts/1.6.3 | new     | 2019-01-18 14:11:07.328533 |        |        | handler_main_2  |      11
	EOF

	if (( $# > 0 )); then
		user_filter="(galaxy_user.email = '$1' or galaxy_user.username = '$1' or galaxy_user.id = CAST(REGEXP_REPLACE(COALESCE('$1','0'), '[^0-9]+', '0', 'g') AS INTEGER))"
	else
		user_filter="true"
	fi

	read -r -d '' QUERY <<-EOF
		SELECT
			job.id, job.tool_id, job.state, job.create_time AT TIME ZONE 'UTC', job.job_runner_name, job.job_runner_external_id, job.handler, job.user_id
		FROM
			job
		JOIN
			galaxy_user ON galaxy_user.id = job.user_id
		WHERE
			$user_filter AND job.state IN ('new', 'queued', 'running')
		ORDER BY job.id ASC
	EOF
}

query_jobs-per-user() { ## query jobs-per-user <email>: Number of jobs run by a specific user
	handle_help "$@" <<-EOF
		    $ gxadmin query jobs-per-user hxr@informatik.uni-freiburg.de
		     count
		    -------
		      1460
	EOF

	assert_count $# 1 "Missing user"
	read -r -d '' QUERY <<-EOF
			SELECT count(id)
			FROM job
			WHERE user_id in (
				SELECT id
				FROM galaxy_user
				WHERE email = '$1'
	EOF
}

query_recent-jobs() { ## query recent-jobs <hours>: Jobs run in the past <hours> (in any state)
	handle_help "$@" <<-EOF
		    $ gxadmin query recent-jobs 2.1
		       id    |     create_time     |      tool_id          | state |    username
		    ---------+---------------------+-----------------------+-------+-----------------
		     4383997 | 2018-10-05 16:07:00 | Filter1               | ok    |
		     4383994 | 2018-10-05 16:04:00 | echo_main_condor      | ok    |
		     4383993 | 2018-10-05 16:04:00 | echo_main_drmaa       | error |
		     4383992 | 2018-10-05 16:04:00 | echo_main_handler11   | ok    |
		     4383983 | 2018-10-05 16:04:00 | echo_main_handler2    | ok    |
		     4383982 | 2018-10-05 16:04:00 | echo_main_handler1    | ok    |
		     4383981 | 2018-10-05 16:04:00 | echo_main_handler0    | ok    |
	EOF

	assert_count $# 1 "Missing hours"

	username=$(gdpr_safe galaxy_user.username username)

	read -r -d '' QUERY <<-EOF
		SELECT
			job.id,
			job.create_time AT TIME ZONE 'UTC' as create_time,
			job.tool_id,
			job.state, $username
		FROM job, galaxy_user
		WHERE job.create_time > (now() AT TIME ZONE 'UTC' - '$1 hours'::interval) AND job.user_id = galaxy_user.id
		ORDER BY id desc
	EOF
}

query_training-list() { ## query training-list [--all]: List known trainings
	handle_help "$@" <<-EOF
		This module is specific to EU's implementation of Training Infrastructure as a Service. But this specifically just checks for all groups with the name prefix 'training-'

		    $ gxadmin query training
		           name       |  created
		    ------------------+------------
		     hts2018          | 2018-09-19
	EOF

	d1=""
	d2="AND deleted = false"
	if [[ $1 == "--all" ]]; then
		d1=", deleted"
		d2=""
	fi

	read -r -d '' QUERY <<-EOF
		SELECT
			substring(name from 10) as name,
			date_trunc('day', create_time AT TIME ZONE 'UTC')::date as created
			$d1
		FROM galaxy_group
		WHERE name like 'training-%' $d2
		ORDER BY create_time DESC
	EOF
}

query_training-members() { ## query training-members <tr_id>: List users in a specific training
	handle_help "$@" <<-EOF
		    $ gxadmin query training-members hts2018
		          username      |       joined
		    --------------------+---------------------
		     helena-rasche      | 2018-09-21 21:42:01
	EOF

	assert_count $# 1 "Missing Training ID"
	# Remove training- if they used it.
	ww=$(echo "$1" | sed 's/^training-//g')
	username=$(gdpr_safe galaxy_user.username username)

	read -r -d '' QUERY <<-EOF
			SELECT
				$username,
				date_trunc('second', user_group_association.create_time AT TIME ZONE 'UTC') as joined
			FROM galaxy_user, user_group_association, galaxy_group
			WHERE galaxy_group.name = 'training-$ww'
				AND galaxy_group.id = user_group_association.group_id
				AND user_group_association.user_id = galaxy_user.id
	EOF
}

query_training-members-remove() { ## query training-members-remove <training> <username> [YESDOIT]: Remove a user from a training
	handle_help "$@" <<-EOF
	EOF

	assert_count_ge $# 2 "Missing parameters"
	# Remove training- if they used it.
	ww=$(echo "$1" | sed 's/^training-//g')

	if (( $# == 3 )) && [[ "$3" == "YESDOIT" ]]; then
		results="$(query_tsv "$qstr")"
		uga_id=$(echo "$results" | awk -F'\t' '{print $1}')
		if (( uga_id > -1 )); then
			qstr="delete from user_group_association where id = $uga_id"
		fi
		echo $qstr
	else
		read -r -d '' QUERY <<-EOF
			SELECT
				user_group_association.id,
				galaxy_user.username,
				galaxy_group.name
			FROM
				user_group_association
			LEFT JOIN galaxy_user ON user_group_association.user_id = galaxy_user.id
			LEFT JOIN galaxy_group ON galaxy_group.id = user_group_association.group_id
			WHERE
				galaxy_group.name = 'training-$ww'
				AND galaxy_user.username = '$2'
		EOF
	fi
}

query_largest-histories() { ## query largest-histories: Largest histories in Galaxy
	handle_help "$@" <<-EOF
		Finds all jobs by people in that queue (including things they are executing that are not part of a training)

		    $ gxadmin query largest-histories
		     total_size | id | substring  | username
		    ------------+----+------------+----------
		     50 MB      |  6 | Unnamed hi | helena
		     41 MB      |  8 | Unnamed hi | helena
		     35 MB      |  9 | Unnamed hi | helena
		     27 MB      | 10 | Circos     | helena
		     3298 kB    |  2 | Tag Testin | helena
		     9936 bytes | 44 | test       | helena
		     413 bytes  | 45 | Unnamed hi | alice
	EOF

	username=$(gdpr_safe galaxy_user.username username)

	read -r -d '' QUERY <<-EOF
		SELECT
			pg_size_pretty(sum(coalesce(dataset.total_size, 0))) as total_size,
			history.id,
			substring(history.name, 1, 10),
			$username
		FROM
			dataset
			JOIN history_dataset_association on dataset.id = history_dataset_association.dataset_id
			JOIN history on history_dataset_association.history_id = history.id
			JOIN galaxy_user on history.user_id = galaxy_user.id
		GROUP BY history.id, history.name, history.user_id, galaxy_user.username
		ORDER BY sum(coalesce(dataset.total_size, 0)) DESC
	EOF
}

query_training-queue() { ## query training-queue <training_id>: Jobs currently being run by people in a given training
	handle_help "$@" <<-EOF
		Finds all jobs by people in that queue (including things they are executing that are not part of a training)

		    $ gxadmin query training-queue hts2018
		     state  |   id    | extid  | tool_id |   username    |       created
		    --------+---------+--------+---------+---------------+---------------------
		     queued | 4350274 | 225743 | upload1 |               | 2018-09-26 10:00:00
	EOF

	assert_count $# 1 "Missing Training ID"
	# Remove training- if they used it.
	ww=$(echo "$1" | sed 's/^training-//g')

	read -r -d '' QUERY <<-EOF
			SELECT
				job.state,
				job.id,
				job.job_runner_external_id AS extid,
				job.tool_id,
				galaxy_user.username,
				job.create_time AT TIME ZONE 'UTC' AS created
			FROM
				job, galaxy_user
			WHERE
				job.user_id = galaxy_user.id
				AND job.create_time > (now() AT TIME ZONE 'UTC' - '3 hours'::interval)
				AND galaxy_user.id
					IN (
							SELECT
								galaxy_user.id
							FROM
								galaxy_user, user_group_association, galaxy_group
							WHERE
								galaxy_group.name = 'training-$ww'
								AND galaxy_group.id = user_group_association.group_id
								AND user_group_association.user_id = galaxy_user.id
						)
			ORDER BY
				job.create_time ASC
	EOF
}

query_disk-usage() { ## query disk-usage [--nice]: Disk usage per object store.
	handle_help "$@" <<-EOF
		Query the different object stores referenced in your Galaxy database

		    $ gxadmin query disk-usage
		     object_store_id |      sum
		    -----------------+----------------
		     files8          | 88109503720067
		     files6          | 64083627169725
		     files9          | 53690953947700
		     files7          | 30657241908566

		Or you can supply the --nice flag, but this should not be used with iquery/InfluxDB

		    $ gxadmin query disk-usage --nice
		     object_store_id |   sum
		    -----------------+---------
		     files9          | 114 TB
		     files8          | 77 TB
		     files7          | 56 TB
		     files6          | 17 TB
	EOF

	fields="count=1"
	tags="object_store_id=0"

	size="sum(total_size)"
	if [[ $1 == "--nice" ]]; then
		size="pg_size_pretty(sum(total_size)) as sum"
	fi

	read -r -d '' QUERY <<-EOF
			SELECT
				object_store_id, $size
			FROM dataset
			WHERE NOT purged
			GROUP BY object_store_id
			ORDER BY sum(total_size) DESC
	EOF
}

query_user-info() { ## query user-info <user_id|username|email>: Quick overview of a Galaxy user in your system
	handle_help "$@" <<-EOF
		This command lets you quickly find out information about a user. The output is formatted as markdown by default.

		    $ gxadmin query user-info helena-rasche
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
			tool_id, state, create_time AT TIME ZONE 'UTC' as create_time, exit_code, metric_value::text::interval
		FROM
			job, job_metric_numeric
		WHERE
			job.user_id = $user_id and job.id = job_metric_numeric.job_id and metric_name = 'runtime_seconds' order by job.id desc limit 10
	EOF
	recent_jobs=$(query_tsv "$qstr")
	recent_jobs2=$(printf "Tool ID\tStatus\tCreated\tExit Code\tRuntime\n----\t----\t----\t---\t----\n%s" "$recent_jobs" | sed 's/\t/\t | \t/g' | column -t -s'	')

	# Recent workflows
	read -r -d '' qstr <<-EOF
		SELECT
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
	recent_wf=$(printf "Created\tState\tScheduler\tHandler\tWorkflow\tHistory\n----\t----\t----\t----\t----\t----\n%s" "$recent_wf" | sed 's/\t/\t | \t/g' | column -t -s'	')

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

## Recent Workflow Invocations

%s

## Largest Histories

%s
\n
EOF
	printf "$template" $results "$group_membership" "$role_membership" "$recent_jobs2" "$recent_wf" "$largest_histories"
}

query_users-count() { ## query users-count: Shows sums of active/external/deleted/purged accounts
	handle_help "$@" <<-EOF
		     active | external | deleted | purged | count
		    --------+----------+---------+--------+-------
		     f      | f        | f       | f      |   182
		     t      | f        | t       | t      |     2
		     t      | f        | t       | f      |     6
		     t      | f        | f       | f      |  2350
		     f      | f        | t       | t      |    36
	EOF

	fields="count=4"
	tags="active=0;external=1;deleted=2;purged=3"

	read -r -d '' QUERY <<-EOF
			SELECT
				active, external, deleted, purged, count(*) as count
			FROM
				galaxy_user
			GROUP BY
				active, external, deleted, purged
	EOF
}

query_tool-last-used-date() { ## query tool-last-used-date: When was the most recent invocation of every tool
	handle_help "$@" <<-EOF
		Example invocation:

		    $ gxadmin query tool-last-used-date
		             max         |          tool_id
		    ---------------------+---------------------------
		     2019-02-01 00:00:00 | test_history_sanitization
		     2018-12-01 00:00:00 | require_format
		     2018-11-01 00:00:00 | upload1
		    (3 rows)

		**WARNING**

		It is not truly every tool, there is no easy way to find the tools which have never been run.
	EOF

	read -r -d '' QUERY <<-EOF
		select max(date_trunc('month', create_time AT TIME ZONE 'UTC')), tool_id from job group by tool_id order by max desc
	EOF
}

query_users-total() { ## query users-total: Total number of Galaxy users (incl deleted, purged, inactive)
	handle_help "$@" <<-EOF
	EOF

	fields="count=0"
	tags=""

	read -r -d '' QUERY <<-EOF
			SELECT count(*) FROM galaxy_user
	EOF
}

query_groups-list() { ## query groups-list: List all groups known to Galaxy
	handle_help "$@" <<-EOF
	EOF

	fields="count=1"
	tags="group_name=0"

	read -r -d '' QUERY <<-EOF
			SELECT
				galaxy_group.name, count(*)
			FROM
				galaxy_group, user_group_association
			WHERE
				user_group_association.group_id = galaxy_group.id
			GROUP BY name
	EOF
}

query_collection-usage() { ## query collection-usage: Information about how many collections of various types are used
	handle_help "$@" <<-EOF
	EOF

	fields="count=1"
	tags="group_name=0"

	read -r -d '' QUERY <<-EOF
		SELECT
			dc.collection_type, count(*)
		FROM
			history_dataset_collection_association as hdca
		INNER JOIN
			dataset_collection as dc
			ON hdca.collection_id = dc.id
		GROUP BY
			dc.collection_type;
	EOF
}

query_ts-repos() { ## query ts-repos: Counts of toolshed repositories by toolshed and owner.
	handle_help "$@" <<-EOF
	EOF

	fields="count=2"
	tags="tool_shed=0;owner=1"

	read -r -d '' QUERY <<-EOF
			SELECT
				tool_shed, owner, count(*)
			FROM
				tool_shed_repository
			GROUP BY
				tool_shed, owner
	EOF
}

query_active-users() { ## query active-users [weeks]: Count of users who ran jobs in past 1 week (default = 1)
	handle_help "$@" <<-EOF
		Unique users who ran jobs in past week:

		    $ gxadmin query active-users
		     count
		    -------
		       220
		    (1 row)

		Or the monthly-active-users:

		    $ gxadmin query active-users 4
		     count
		    -------
		       555
		    (1 row)
	EOF

	weeks=1
	if (( $# > 0 )); then
		weeks=$1
	fi

	fields="count=1"
	tags="weeks=0"

	read -r -d '' QUERY <<-EOF
		SELECT
			$weeks as weeks,
			count(distinct user_id)
		FROM
			job
		WHERE
			job.create_time > (now() AT TIME ZONE 'UTC' - '$weeks weeks'::interval)
	EOF
}

query_tool-metrics() { ## query tool-metrics <tool_id> <metric_id> [--like]: See values of a specific metric
	handle_help "$@" <<-EOF
		A good way to use this is to fetch the memory usage of a tool and then
		do some aggregations. The following requires [data_hacks](https://github.com/bitly/data_hacks)

		    $ gxadmin tsvquery tool-metrics %rgrnastar/rna_star% memory.max_usage_in_bytes --like | \\
		        awk '{print \$1 / 1024 / 1024 / 1024}' | \\
		        histogram.py --percentage
		    # NumSamples = 441; Min = 2.83; Max = 105.88
		    # Mean = 45.735302; Variance = 422.952289; SD = 20.565804; Median 51.090900
		    # each ∎ represents a count of 1
		        2.8277 -    13.1324 [    15]: ∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎ (3.40%)
		       13.1324 -    23.4372 [    78]: ∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎ (17.69%)
		       23.4372 -    33.7419 [    47]: ∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎ (10.66%)
		       33.7419 -    44.0466 [    31]: ∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎ (7.03%)
		       44.0466 -    54.3514 [    98]: ∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎ (22.22%)
		       54.3514 -    64.6561 [   102]: ∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎ (23.13%)
		       64.6561 -    74.9608 [    55]: ∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎ (12.47%)
		       74.9608 -    85.2655 [    11]: ∎∎∎∎∎∎∎∎∎∎∎ (2.49%)
		       85.2655 -    95.5703 [     3]: ∎∎∎ (0.68%)
		       95.5703 -   105.8750 [     1]: ∎ (0.23%)
	EOF

	assert_count_ge $# 1 "Missing Tool ID"
	assert_count_ge $# 2 "Missing Metric ID (hint: tool-available-metrics)"

	tool_subquery="SELECT id FROM job WHERE tool_id = '$1'"
	if [[ "$3" == "--like" ]]; then
		tool_subquery="SELECT id FROM job WHERE tool_id like '$1'"
	fi

	read -r -d '' QUERY <<-EOF
		SELECT
			metric_value
		FROM job_metric_numeric
		WHERE
			metric_name = '$2'
			and
			job_id in (
				$tool_subquery
			)
	EOF
}

query_tool-available-metrics() { ## query tool-available-metrics <tool_id>: list all available metrics for a given tool
	handle_help "$@" <<-EOF
		Gives a list of available metrics, which can then be used to query.

		    [galaxy@sn04 galaxy]$ gxadmin query tool-available-metrics upload1
		                 metric_name
		    -------------------------------------
		     memory.stat.total_rss
		     memory.stat.total_swap
		     memory.stat.total_unevictable
		     memory.use_hierarchy
		     ...
	EOF

	assert_count $# 1 "Missing Tool ID"

	read -r -d '' QUERY <<-EOF
		SELECT
			distinct metric_name
		FROM job_metric_numeric
		WHERE job_id in (
			SELECT id FROM job WHERE tool_id = '$1'
		)
		ORDER BY metric_name asc
	EOF
}

query_monthly-data(){ ## query monthly-data [year]: Number of active users per month, running jobs
	handle_help "$@" <<-EOF
		Find out how much data was ingested or created by Galaxy during the past months.

		    $ gxadmin query monthly-data 2018
		     pg_size_pretty |        month
		    ----------------+---------------------
		     62 TB          | 2018-12-01 00:00:00
		     50 TB          | 2018-11-01 00:00:00
		     59 TB          | 2018-10-01 00:00:00
		     32 TB          | 2018-09-01 00:00:00
		     26 TB          | 2018-08-01 00:00:00
		     42 TB          | 2018-07-01 00:00:00
		     34 TB          | 2018-06-01 00:00:00
		     33 TB          | 2018-05-01 00:00:00
		     27 TB          | 2018-04-01 00:00:00
		     32 TB          | 2018-03-01 00:00:00
		     18 TB          | 2018-02-01 00:00:00
		     16 TB          | 2018-01-01 00:00:00
	EOF

	if (( $# > 0 )); then
		where="WHERE date_trunc('year', dataset.create_time AT TIME ZONE 'UTC') = '$1-01-01'::date"
	fi

	read -r -d '' QUERY <<-EOF
		SELECT
			pg_size_pretty(sum(total_size)), date_trunc('month', dataset.create_time AT TIME ZONE 'UTC') AS month
		FROM
			dataset
		$where
		GROUP BY
			month
		ORDER BY
			month DESC;
	EOF
}

query_monthly-users(){ ## query monthly-users [year]: Number of active users per month, running jobs
	handle_help "$@" <<-EOF
		Number of unique users each month who ran jobs. NOTE: does not include anonymous users.

		    [galaxy@sn04 galaxy]$ gxadmin query monthly-users 2018
		     unique_users |        month
		    --------------+---------------------
		              811 | 2018-12-01 00:00:00
		              658 | 2018-11-01 00:00:00
		              583 | 2018-10-01 00:00:00
		              444 | 2018-09-01 00:00:00
		              342 | 2018-08-01 00:00:00
		              379 | 2018-07-01 00:00:00
		              370 | 2018-06-01 00:00:00
		              330 | 2018-05-01 00:00:00
		              274 | 2018-04-01 00:00:00
		              186 | 2018-03-01 00:00:00
		              168 | 2018-02-01 00:00:00
		              122 | 2018-01-01 00:00:00
	EOF

	if (( $# > 0 )); then
		where="WHERE date_trunc('year', job.create_time AT TIME ZONE 'UTC') = '$1-01-01'::date"
	fi

	read -r -d '' QUERY <<-EOF
		SELECT
			count(distinct user_id) as unique_users,
			date_trunc('month', job.create_time AT TIME ZONE 'UTC') as month
		FROM job
		$where
		GROUP BY month
		ORDER BY month DESC
	EOF
}

query_monthly-jobs(){ ## query monthly-jobs [year]: Number of jobs run each month
	handle_help "$@" <<-EOF
		Count jobs run each month

		    [galaxy@sn04 galaxy]$ gxadmin query monthly-jobs 2018
		            month        | count
		    ---------------------+--------
		     2018-12-01 00:00:00 |  96941
		     2018-11-01 00:00:00 |  94625
		     2018-10-01 00:00:00 | 156940
		     2018-09-01 00:00:00 | 103331
		     2018-08-01 00:00:00 | 128658
		     2018-07-01 00:00:00 |  90852
		     2018-06-01 00:00:00 | 230470
		     2018-05-01 00:00:00 | 182331
		     2018-04-01 00:00:00 | 109032
		     2018-03-01 00:00:00 | 197125
		     2018-02-01 00:00:00 | 260931
		     2018-01-01 00:00:00 |  25378
	EOF

	if (( $# > 0 )); then
		where="WHERE date_trunc('year', job.create_time AT TIME ZONE 'UTC') = '$1-01-01'::date"
	fi

	read -r -d '' QUERY <<-EOF
		SELECT
			date_trunc('month', job.create_time AT TIME ZONE 'UTC') AS month,
			count(*)
		FROM
			job
		$where
		GROUP BY
			month
		ORDER BY
			month DESC
	EOF

}

query_job-history() { ## query job-history <id>: Job state history for a specific job
	handle_help "$@" <<-EOF
		    $ gxadmin query job-history 4384025
		            time         |  state
		    ---------------------+---------
		     2018-10-05 16:20:13 | ok
		     2018-10-05 16:19:57 | running
		     2018-10-05 16:19:55 | queued
		     2018-10-05 16:19:54 | new
		    (4 rows)
	EOF

	assert_count $# 1 "Missing Job ID"

	read -r -d '' QUERY <<-EOF
			SELECT
				create_time AT TIME ZONE 'UTC' as time,
				state
			FROM job_state_history
			WHERE job_id = $1
	EOF
}

query_job-inputs() { ## query job-inputs <id>: Input datasets to a specific job
	handle_help "$@" <<-EOF
	EOF
	assert_count $# 1 "Missing Job ID"

	read -r -d '' QUERY <<-EOF
			SELECT
				hda.id AS hda_id,
				hda.state AS hda_state,
				hda.deleted AS hda_deleted,
				hda.purged AS hda_purged,
				d.id AS d_id,
				d.state AS d_state,
				d.deleted AS d_deleted,
				d.purged AS d_purged,
				d.object_store_id AS object_store_id
			FROM job j
				JOIN job_to_input_dataset jtid
					ON j.id = jtid.job_id
				JOIN history_dataset_association hda
					ON hda.id = jtid.dataset_id
				JOIN dataset d
					ON hda.dataset_id = d.id
			WHERE j.id = $1
	EOF
}

query_job-outputs() { ## query job-outputs <id>: Output datasets from a specific job
	handle_help "$@" <<-EOF
	EOF

	assert_count $# 1 "Missing Job ID"

	read -r -d '' QUERY <<-EOF
			SELECT
				hda.id AS hda_id,
				hda.state AS hda_state,
				hda.deleted AS hda_deleted,
				hda.purged AS hda_purged,
				d.id AS d_id,
				d.state AS d_state,
				d.deleted AS d_deleted,
				d.purged AS d_purged,
				d.object_store_id AS object_store_id
			FROM job j
				JOIN job_to_output_dataset jtod
					ON j.id = jtod.job_id
				JOIN history_dataset_association hda
					ON hda.id = jtod.dataset_id
				JOIN dataset d
					ON hda.dataset_id = d.id
			WHERE j.id = $1
		"
	EOF
}

query_old-histories(){ ## query old-histories <weeks>: Lists histories that haven't been updated (used) for <weeks>
	handle_help "$@" <<-EOF
		Histories and their users who haven't been updated for a specified number of weeks. Default number of weeks is 15.

		    $gxadmin query old-histories 52
		      id   |        update_time         | user_id |  email  |       name         | published | deleted | purged | hid_counter
		    -------+----------------------------+---------+---------+--------------------+-----------+---------+--------+-------------
		     39903 | 2017-06-13 12:35:07.174749 |     834 | xxx@xxx | Unnamed history    | f         | f       | f      |          23
		      1674 | 2017-06-13 14:08:30.017574 |       9 | xxx@xxx | SAHA project       | f         | f       | f      |          47
		     40088 | 2017-06-15 04:10:48.879122 |     986 | xxx@xxx | Unnamed history    | f         | f       | f      |           3
		     39023 | 2017-06-15 09:33:12.007002 |     849 | xxx@xxx | prac 4 new final   | f         | f       | f      |         297
		     35437 | 2017-06-16 04:41:13.15785  |     731 | xxx@xxx | Unnamed history    | f         | f       | f      |          98
		     40123 | 2017-06-16 13:43:24.948344 |     987 | xxx@xxx | Unnamed history    | f         | f       | f      |          22
		     40050 | 2017-06-19 00:46:29.032462 |     193 | xxx@xxx | Telmatactis        | f         | f       | f      |          74
		     12212 | 2017-06-20 14:41:03.762881 |     169 | xxx@xxx | Unnamed history    | f         | f       | f      |          24
		     39523 | 2017-06-21 01:34:52.226653 |       9 | xxx@xxx | OSCC Cell Lines    | f         | f       | f      |         139
	EOF

	assert_count_ge $# 1 "Missing <weeks>"

	weeks=$1
	email=$(gdpr_safe galaxy_user.email 'email')

	read -r -d '' QUERY <<-EOF
		SELECT
			history.id,
			history.update_time AT TIME ZONE 'UTC' as update_time,
			history.user_id,
			$email,
			history.name,
			history.published,
			history.deleted,
			history.purged,
			history.hid_counter
		FROM
			history,
			galaxy_user
		WHERE
			history.update_time < (now() AT TIME ZONE 'UTC' - '$weeks weeks'::interval) AND
			history.user_id = galaxy_user.id AND
			history.deleted = FALSE AND
			history.published = FALSE
		ORDER BY
			history.update_time desc
	EOF
}

query_errored-jobs(){ ## query errored-jobs <hours>: Lists jobs that errored in the last N hours.
	handle_help "$@" <<-EOF
		Lists details of jobs that have status = 'error' for the specified number of hours. Default = 24 hours

		    $gxadmin query errored-jobs 24
		    TO_DO: Add output of query here!

	EOF

	hours=$1
	email=$(gdpr_safe galaxy_user.email 'email')

	read -r -d '' QUERY <<-EOF
		SELECT
			job.id,
			job.create_time AT TIME ZONE 'UTC' as create_time,
			job.tool_id,
			job.tool_version,
			job.handler,
			job.destination_id,
			$email
		FROM
			job,
			galaxy_user
		WHERE
			job.create_time >= (now() AT TIME ZONE 'UTC' - '$hours hours'::interval) AND
			job.state = 'error' AND
			job.user_id = galaxy_user.id
		ORDER BY
			job.id
	EOF
}

query_server-users() { ## query server-users [date]
	handle_help "$@" <<-EOF
	EOF

	date_filter=""
	if (( $# > 1 )); then
		date_filter="WHERE create_time AT TIME ZONE 'UTC' <= '{date}'::date"
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

query_server-users-cumulative() { ## query server-users-cumulative [date]
	handle_help "$@" <<-EOF
	EOF

	date_filter=""
	if (( $# > 1 )); then
		date_filter="WHERE create_time AT TIME ZONE 'UTC' <= '{date}'::date"
	fi

	fields="count=0"

	read -r -d '' QUERY <<-EOF
		SELECT
			count(*)
		FROM
			galaxy_user
		WHERE
			$date_filter
	EOF
}

query_server-groups() { ## query server-groups
	handle_help "$@" <<-EOF
	EOF

	date_filter=""
	if (( $# > 1 )); then
		date_filter="WHERE create_time AT TIME ZONE 'UTC' <= '{date}'::date"
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
		GROUP BY name
	EOF
}

query_server-datasets() { ## query server-datasets
	handle_help "$@" <<-EOF
	EOF

	date_filter=""
	if (( $# > 1 )); then
		date_filter="WHERE create_time AT TIME ZONE 'UTC' <= '{date}'::date"
	fi

	fields="count=5;size=6"
	tags="state=1;deleted=2;purged=3;object_store_id=4"

	read -r -d '' QUERY <<-EOF
		SELECT
			state, deleted, purged, object_store_id, count(*), coalesce(sum(total_size), 0)
		FROM
			dataset
		GROUP BY
			state, deleted, purged, object_store_id
	EOF
}

query_server-hda() { ## query server-hda [date]
	handle_help "$@" <<-EOF
	EOF

	date_filter=""
	if (( $# > 1 )); then
		date_filter="WHERE create_time AT TIME ZONE 'UTC' <= '{date}'::date"
	fi

	fields="sum=2;avg=3;min=4;max=5"
	tags="extension=0;deleted=1"

	read -r -d '' QUERY <<-EOF
		SELECT
			history_dataset_association.extension,
			history_dataset_association.deleted,
			coalesce(sum(dataset.file_size), 0),
			coalesce(avg(dataset.file_size), 0),
			coalesce(min(dataset.file_size), 0),
			coalesce(max(dataset.file_size), 0),
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

query_server-ts-repos() { ## query server-ts-repos
	handle_help "$@" <<-EOF
	EOF

	date_filter=""
	if (( $# > 1 )); then
		date_filter="WHERE create_time AT TIME ZONE 'UTC' <= '{date}'::date"
	fi

	fields="count=2"
	tags="tool_shed=0;owner=1"

	read -r -d '' QUERY <<-EOF
		SELECT
			tool_shed, owner, count(*)
		FROM
			tool_shed_repository
		GROUP BY
			tool_shed, owner
		ORDER BY count desc
	EOF
}

query_server-histories() { ## query server-histories [date]
	handle_help "$@" <<-EOF
	EOF

	date_filter=""
	if (( $# > 1 )); then
		date_filter="WHERE create_time AT TIME ZONE 'UTC' <= '{date}'::date"
	fi

	fields="count=6"
	tags="deleted=0;purged=1;published=2;importable=3;importing=4;genome_build=5"

	read -r -d '' QUERY <<-EOF
		SELECT
			deleted, purged, published, importable, importing, genome_build, count(*)
		FROM history
		WHERE
			user_id IS NOT NULL ${date_filter}
		GROUP BY
			deleted, purged, published, importable, importing, genome_build
	EOF
}

# TODO: GDPR
query_server-disk-usage() { ## query server-disk-usage
	handle_help "$@" <<-EOF
	EOF

	read -r -d '' QUERY <<-EOF
		SELECT
			history.user_id,
			coalesce(sum(dataset.file_size), 0),
			coalesce(count(dataset.id), 0),
			coalesce(count(history.id), 0)
		FROM
			history, history_dataset_association, dataset
		WHERE
			history.id = history_dataset_association.history_id AND
			history_dataset_association.dataset_id = dataset.id
		GROUP BY
			history.user_id
	EOF
}

query_server-jobs() { ## query server-jobs [date]
	handle_help "$@" <<-EOF
	EOF

	date_filter=""
	if (( $# > 1 )); then
		date_filter="AND create_time AT TIME ZONE 'UTC' <= '{date}'::date"
	fi

	fields="count=3"
	tags="state=0;job_runner_name=1;destination_id=2"

	read -r -d '' QUERY <<-EOF
		SELECT
			state, job_runner_name, destination_id, count(*)
		FROM
			job
		WHERE
			user_id IS NOT NULL ${date_filter}
		GROUP BY
			state, job_runner_name, destination_id
	EOF
}

query_server-jobs-cumulative() { ## query server-jobs-cumulative [date]
	handle_help "$@" <<-EOF
	EOF

	date_filter=""
	if (( $# > 1 )); then
		date_filter="WHERE create_time AT TIME ZONE 'UTC' <= '{date}'::date"
	fi

	fields="count=0"
	tags=""

	read -r -d '' QUERY <<-EOF
		SELECT
			count(*)
		FROM
			job
		${date_filter}
	EOF
}

query_server-workflows() { ## query server-workflows [date]
	handle_help "$@" <<-EOF
	EOF

	date_filter=""
	if (( $# > 1 )); then
		date_filter="WHERE create_time AT TIME ZONE 'UTC' <= '{date}'::date"
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

query_server-workflow-invocations() { ## query server-workflow-invocations [yyyy-mm-dd]
	handle_help "$@" <<-EOF
	EOF

	date_filter=""
	if (( $# > 1 )); then
		date_filter="WHERE create_time AT TIME ZONE 'UTC' <= '{date}'::date"
	fi

	fields="count=2"
	tags="scheduler=0;handler=1"

	read -r -d '' QUERY <<-EOF
		SELECT
			scheduler, handler, count(*)
		FROM
			workflow_invocation
		${date_filter}
		GROUP BY
			scheduler, handler
	EOF
}
