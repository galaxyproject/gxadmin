# shellcheck disable=SC2154
# shellcheck disable=SC2001
# shellcheck disable=SC2034
registered_subcommands="$registered_subcommands query"
_query_short_help="DB Queries"
_query_long_help="
	'query' can be exchanged with 'tsvquery' or 'csvquery' for tab- and comma-separated variants.
	In some cases 'iquery' is supported for InfluxDB compatible output.
	In all cases 'explainquery' will show you the query plan, in case you need to optimise or index data. 'explainjsonquery' is useful with PEV: http://tatiyants.com/pev/
"

query_longest-running-jobs-by-destination() { ## : List the longest (currently) running jobs on the Galaxy server by destination
	handle_help "$@" <<-EOF
		List the longest (currently) running jobs on the Galaxy server by destination

		job_id | tool_id                                                                                  | destination_id         | hours_since_running
		------ | ---------------------------------------------------------------------------------------- | ---------------------- | -------------------
		65213  | toolshed.g2.bx.psu.edu/repos/petr-novak/repeatexplorer2_testing/repeatexplorer2/2.3.12.1 | tpv_pulsar_singularity | 326
		69261  | toolshed.g2.bx.psu.edu/repos/petr-novak/dante/dante/2.6.2                                | tpv_pulsar             | 85
		69435  | toolshed.g2.bx.psu.edu/repos/petr-novak/dante_ltr/dante_ltr_search/4.0.4.1               | tpv_pulsar             | 56

	EOF

	fields="hours_since_running=3"
	tags="job_id=0;tool_id=1;destination_id=2"

	read -r -d '' QUERY <<-EOF
		SELECT
			j.id,
			j.tool_id,
			j.destination_id,
			EXTRACT(EPOCH FROM (NOW() - jsh.running_since)) / 3600 AS hours_since_running
		FROM
			job j JOIN LATERAL (
				SELECT
					MIN(create_time) AS running_since
				FROM
					job_state_history jsh
				WHERE
					jsh.job_id = j.id
					AND jsh.state = 'running'
			) jsh ON true
		WHERE
			j.state = 'running'
		ORDER BY
			hours_since_running DESC
	EOF
}

query_most-used-tools-by-destination() { ## : List tools with the highest job count on the Galaxy server by destination
	handle_help "$@" <<-EOF
		List tools with the highest job count on the Galaxy server by destination

		tool_id                                                                                         | destination_id | job_count
		----------------------------------------------------------------------------------------------- | -------------- | ---------
		toolshed.g2.bx.psu.edu/repos/petr-novak/re_utils/paired_fastq_filtering                         | tpv_pulsar     | 23
		toolshed.g2.bx.psu.edu/repos/petr-novak/re_utils/fasta_affixer                                  | tpv_pulsar     | 14
		toolshed.g2.bx.psu.edu/repos/petr-novak/re_utils/sampler                                        | tpv_pulsar     | 13

	EOF

	fields="job_count=2"
	tags="tool_id=0;destination_id=1"

	read -r -d '' QUERY <<-EOF
		SELECT
			regexp_replace(tool_id, '/[^/]+$', '') AS tool_id_no_version,
			destination_id,
			COUNT(*) AS job_count
		FROM
			job
		WHERE
			create_time >= (NOW() AT TIME ZONE 'UTC' - INTERVAL '1 hour')
			AND tool_id ILIKE 'toolshed%'
			AND destination_id IS NOT NULL
		GROUP BY
			tool_id_no_version,
			destination_id
		ORDER BY
			job_count DESC
	EOF
}

query_latest-users() { ## : 40 recently registered users
	meta <<-EOF
		AUTHORS: hexylena
		ADDED: 1
		UPDATED: 1
	EOF
	handle_help "$@" <<-EOF
		Returns 40 most recently registered users

		    $ gxadmin query latest-users
		     id |          create_time          | disk_usage | username |     email      |              groups               | active
		    ----+-------------------------------+------------+----------+----------------+-----------------------------------+--------
		      3 | 2019-03-07 13:06:37.945403+00 |            | beverly  | b@example.com  |                                   | t
		      2 | 2019-03-07 13:06:23.369201+00 | 826 bytes  | alice    | a@example.com  |                                   | t
		      1 | 2018-11-19 14:54:30.969713+00 | 869 MB     | helena   | hxr@local.host | training-fff training-hogeschool | t
		    (3 rows)
	EOF

	username=$(gdpr_safe galaxy_user.username username)
	email=$(gdpr_safe galaxy_user.email email)

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

query_tool-usage() { ##? [weeks]: Counts of tool runs in the past weeks (default = all)
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
	if (( arg_weeks > 0 )); then
		where="WHERE j.create_time > (now() - '${arg_weeks} weeks'::interval)"
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

query_tool-usage-over-time() { ##? [searchterm]: Counts of tool runs by month, filtered by a tool id search
	meta <<-EOF
		ADDED: 19
	EOF
	handle_help "$@" <<-EOF
		    $ gxadmin tool-usage-over-time
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
	if [[ "$arg_searchterm" != "" ]]; then
		where="WHERE tool_id like '%$arg_searchterm%'"
	fi

	read -r -d '' QUERY <<-EOF
		WITH
			cte
				AS (
					SELECT
						date_trunc('month', create_time),
						tool_id
					FROM
						job
					$where
				)
		SELECT
			date_trunc, tool_id, count(*)
		FROM
			cte
		GROUP BY
			date_trunc, tool_id
		ORDER BY
			date_trunc ASC, count DESC
	EOF
}

query_tool-popularity() { ##? [months=24] [--error]: Most run tools by month (tool_predictions)
	handle_help "$@" <<-EOF
		See most popular tools by month. Use --error to include error counts.

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
	if [[ -n $arg_error ]]; then
		fields="${fields}:error_count=3"
		error_count=", count(CASE state WHEN 'error' THEN 1 ELSE NULL END) as error_count"
	fi


	read -r -d '' QUERY <<-EOF
		SELECT
			tool_id,
			date_trunc('month', create_time AT TIME ZONE 'UTC')::date as month,
			count(*) as count $error_count
		FROM job
		WHERE create_time > (now() AT TIME ZONE 'UTC' - '$arg_months months'::interval)
		GROUP BY tool_id, month
		ORDER BY month desc, count desc
	EOF
}

query_workflow-connections() { ##? [--all]: The connections of tools, from output to input, in the latest (or all) versions of user workflows (tool_predictions)
	handle_help "$@" <<-EOF
		This is used by the usegalaxy.eu tool prediction workflow, allowing for building models out of tool connections in workflows.

		    $ gxadmin query workflow-connections
		     wf_id |     wf_updated      | in_id |      in_tool      | in_tool_v | out_id |     out_tool      | out_tool_v | published | deleted | has_errors
		    -------+---------------------+-------+-------------------+-----------+--------+-------------------+----------------------------------------------
		         3 | 2013-02-07 16:48:00 |     5 | Grep1             | 1.0.1     |     12 |                   |            |    f      |    f    |    f
		         3 | 2013-02-07 16:48:00 |     6 | Cut1              | 1.0.1     |      7 | Remove beginning1 | 1.0.0      |    f      |    f    |    f
		         3 | 2013-02-07 16:48:00 |     7 | Remove beginning1 | 1.0.0     |      5 | Grep1             | 1.0.1      |    f      |    f    |    f
		         3 | 2013-02-07 16:48:00 |     8 | addValue          | 1.0.0     |      6 | Cut1              | 1.0.1      |    t      |    f    |    f
		         3 | 2013-02-07 16:48:00 |     9 | Cut1              | 1.0.1     |      7 | Remove beginning1 | 1.0.0      |    f      |    f    |    f
		         3 | 2013-02-07 16:48:00 |    10 | addValue          | 1.0.0     |     11 | Paste1            | 1.0.0      |    t      |    f    |    f
		         3 | 2013-02-07 16:48:00 |    11 | Paste1            | 1.0.0     |      9 | Cut1              | 1.0.1      |    f      |    f    |    f
		         3 | 2013-02-07 16:48:00 |    11 | Paste1            | 1.0.0     |      8 | addValue          | 1.0.0      |    t      |    t    |    f
		         4 | 2013-02-07 16:48:00 |    13 | cat1              | 1.0.0     |     18 | addValue          | 1.0.0      |    t      |    f    |    f
		         4 | 2013-02-07 16:48:00 |    13 | cat1              | 1.0.0     |     20 | Count1            | 1.0.0      |    t      |    t    |    f
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
	if [[ -n "$arg_all" ]]; then
		wf_filter=""
	fi

	read -r -d '' QUERY <<-EOF
		SELECT
			workflow.id as wf_id,
			workflow.update_time::DATE as wf_updated,
			ws_in.id as in_id,
			ws_in.tool_id as in_tool,
			ws_in.tool_version as in_tool_v,
			ws_out.id as out_id,
			ws_out.tool_id as out_tool,
			ws_out.tool_version as out_tool_v,
			sw.published as published,
			sw.deleted as deleted,
			workflow.has_errors as has_errors
		FROM workflow_step_connection wfc
		LEFT JOIN workflow_step ws_in ON ws_in.id = wfc.output_step_id
		LEFT JOIN workflow_step_input wsi ON wfc.input_step_input_id = wsi.id
		LEFT JOIN workflow_step ws_out ON ws_out.id = wsi.workflow_step_id
		LEFT JOIN workflow_output as wo ON wsi.workflow_step_id = wfc.output_step_id
		LEFT JOIN workflow on ws_in.workflow_id = workflow.id
		LEFT JOIN stored_workflow as sw on sw.latest_workflow_id = workflow.id
		$wf_filter
	EOF
}

query_history-connections() { ## : The connections of tools, from output to input, in histories (tool_predictions)
	meta <<-EOF
		ADDED: 15
	EOF
	handle_help "$@" <<-EOF
		This is used by the usegalaxy.eu tool prediction workflow, allowing for building models out of tool connections.
	EOF

	read -r -d '' QUERY <<-EOF
		SELECT
			h.id AS h_id,
			h.update_time::DATE AS h_update,
			jtod.job_id AS in_id,
			j.tool_id AS in_tool,
			j.tool_version AS in_tool_v,
			jtid.job_id AS out_id,
			j2.tool_id AS out_tool,
			j2.tool_version AS out_ver
		FROM
			job AS j
			LEFT JOIN history AS h ON j.history_id = h.id
			LEFT JOIN job_to_output_dataset AS jtod ON j.id = jtod.job_id
			LEFT JOIN job_to_input_dataset AS jtid ON jtod.dataset_id = jtid.dataset_id
			LEFT JOIN job AS j2 ON jtid.job_id = j2.id
		WHERE
			jtid.job_id IS NOT NULL
	EOF
}

query_datasets-created-daily() { ##? [months=all] [--human]: The min/max/average/p95/p99 of total size of datasets created in a single day.
	handle_help "$@" <<-EOF
		    $ gxadmin query datasets-created-daily
		     min | quant_1st | median  |         mean          | quant_3rd |  perc_95  |  perc_99  |    max    |    sum     |    stddev
		    -----+-----------+---------+-----------------------+-----------+-----------+-----------+-----------+------------+---------------
		       2 |    303814 | 6812862 | 39653071.914285714286 |  30215616 | 177509882 | 415786146 | 533643009 | 1387857517 | 96920615.1745
		    (1 row)

		or more readably:

		    $ gxadmin query datasets-created-daily --human
		       min   | quant_1st | median  | mean  | quant_3rd | perc_95 | perc_99 |  max   |   sum   | stddev
		    ---------+-----------+---------+-------+-----------+---------+---------+--------+---------+--------
		     2 bytes | 297 kB    | 6653 kB | 38 MB | 29 MB     | 169 MB  | 397 MB  | 509 MB | 1324 MB | 92 MB
		    (1 row)

		only consider datasets created in the past month:

		    $ gxadmin query datasets-created-daily 1 --human
		       min   | quant_1st | median  |  mean   | quant_3rd | perc_95 | perc_99 |  max  |  sum   | stddev
		    ---------+-----------+---------+---------+-----------+---------+---------+-------+--------+---------
		     1974 GB | 7651 GB   | 9705 GB | 9089 GB | 11 TB     | 13 TB   | 13 TB   | 13 TB | 284 TB | 2727 GB
	EOF

	if [[ -n $arg_human ]]; then
		summary="$(summary_statistics sum 1)"
	else
		summary="$(summary_statistics sum)"
	fi

	if [[ -z $arg_months || $arg_months == 'all' ]]; then
		since=
	else
		since="WHERE create_time > (now() AT TIME ZONE 'UTC' - '$arg_months months'::interval)"
	fi

	read -r -d '' QUERY <<-EOF
		WITH temp_queue_times AS
		(select
			date_trunc('day', create_time AT TIME ZONE 'UTC'),
			sum(coalesce(total_size, file_size))
		from dataset
		$since
		group by date_trunc
		order by date_trunc desc)
		select
			$summary
		from temp_queue_times
	EOF
}

query_largest-collection() { ## : Returns the size of the single largest collection
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

query_queue-time() { ##? <tool_id>: The average/95%/99% a specific tool spends in queue state.
	handle_help "$@" <<-EOF
		    $ gxadmin query queue-time toolshed.g2.bx.psu.edu/repos/nilesh/rseqc/rseqc_geneBody_coverage/2.6.4.3
		           min       |     perc_95     |     perc_99     |       max
		    -----------------+-----------------+-----------------+-----------------
		     00:00:15.421457 | 00:00:55.022874 | 00:00:59.974171 | 00:01:01.211995
	EOF

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
			a.job_id in (select id from job where tool_id like '%${arg_tool_id}%' and state = 'ok' and create_time > (now() AT TIME ZONE 'UTC' - '3 months'::interval))
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

query_destination-queue-run-time() { ##? [--older-than=30] [--seconds]: The average/median/95%/99% tool spends in queue/run state grouped by tool and destination.
	meta <<-EOF
		AUTHORS: pauldg
		ADDED: 22
	EOF

	handle_help "$@" <<-EOF
			Lists queue and run time statistics grouped by use tool and destination within a time window (# of days).
			Requires <older-than> a given number of days

		    $ gxadmin query destination-queue-run-time --older-than='90'
			destination_id |     tool_id     | count |       avg       |       min       |  median_queue   |  perc_95_queue  |  perc_99_queue  |       max       |       avg       |       min
			|   median_run    |   perc_95_run   |   perc_99_run   |       max
			----------------+-----------------+-------+-----------------+-----------------+-----------------+-----------------+-----------------+-----------------+-----------------+--------------
			---+-----------------+-----------------+-----------------+-----------------
			condor_tpv     | Show beginning1 |     4 | 00:00:42.190985 | 00:00:41.921395 | 00:00:42.197197 | 00:00:42.419296 | 00:00:42.44238  | 00:00:42.448151 | 00:00:15.742914 | 00:00:12.2020
			32 | 00:00:14.23126  | 00:00:21.398603 | 00:00:22.125406 | 00:00:22.307107
			pulsar_be_tpv  | Show beginning1        |    30 | 00:00:03.752367 | 00:00:00.828691 | 00:00:01.227039 | 00:00:15.833112 | 00:00:19.567223 | 00:00:20.822238 | 00:00:12.835613 | 00:00:07.3436
			93 | 00:00:08.121174 | 00:00:39.547216 | 00:00:47.76481  | 00:00:48.391205
							| __DATA_FETCH__  |     5 | 00:00:01.0595   | 00:00:00.557755 | 00:00:00.974273 | 00:00:01.63247  | 00:00:01.722836 | 00:00:01.745428 | 00:00:17.421127 | 00:00:00.4875
			62 | 00:00:10.301916 | 00:00:37.743373 | 00:00:39.621173 | 00:00:40.090623
	EOF

	fields="count=2"
	tags="destination_id=0;tool_id=1"

	nonpretty=""
	nonprettyend=""

	if [[ -n "$arg_seconds" ]]; then
			  fields="$fields;avg_queue=3;min_queue=4;median_queue=5;perc_95_queue=6;perc_99_queue=7;max_queue=8;avg_run=9;min_run=10;median_run=11;perc_95_run=12;perc_99_run=13;max_run=14"
			  nonpretty="EXTRACT(EPOCH FROM "
			  nonprettyend=") :: bigint"
	fi

	read -r -d '' QUERY <<-EOF
		WITH
			temp_queue_run_times
				AS (
					SELECT
						j.destination_id,
						j.tool_id,
						j.id,
						$nonpretty (min(a.create_time) - min(b.create_time))$nonprettyend
							AS queue_time,
						$nonpretty (min(c.create_time) - min(a.create_time))$nonprettyend
							AS run_time
					FROM
						job AS j
						JOIN job_state_history AS a ON
								(j.id = a.job_id)
						INNER JOIN job_state_history AS b ON
								(a.job_id = b.job_id)
						LEFT JOIN job_state_history AS c ON
								(a.job_id = c.job_id)
					WHERE
						j.create_time
						> (
								timezone('UTC', now())
								- '${arg_older_than} days'::INTERVAL
							)
						AND a.state = 'running'
						AND b.state = 'queued'
						AND c.state = 'ok'
					GROUP BY
						j.id
					ORDER BY
						queue_time DESC
				)
		SELECT
			destination_id,
			tool_id,
			count(id),
			avg(queue_time),
			min(queue_time),
			percentile_cont(0.50) WITHIN GROUP (ORDER BY queue_time) as median_queue,
			percentile_cont(0.95) WITHIN GROUP (ORDER BY queue_time) as perc_95_queue,
			percentile_cont(0.99) WITHIN GROUP (ORDER BY queue_time) as perc_99_queue,
			max(queue_time),
			avg(run_time),
			min(run_time),
			percentile_cont(0.50) WITHIN GROUP (ORDER BY run_time) as median_run,
			percentile_cont(0.95) WITHIN GROUP (ORDER BY run_time) as perc_95_run,
			percentile_cont(0.99) WITHIN GROUP (ORDER BY run_time) as perc_99_run,
			max(run_time)
		FROM
			temp_queue_run_times
		GROUP BY
			destination_id, tool_id
	EOF
}

query_queue() { ## [--by (tool|destination|user)]: Brief overview of currently running jobs grouped by tool (default) or other columns
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

		    $ gxadmin query queue --by destination

		     destination_id |  state  | job_count
		    ----------------+---------+-----------
		     normal         | running |       128
		     multicore      | running |        64
		     multicore      | queued  |        16

		    $ gxadmin iquery queue --by destination
		    queue-summary-by-destination,state=running,destination_id=normal count=128
		    queue-summary-by-destination,state=running,destination_id=multicore count=64
		    queue-summary-by-destination,state=queued,destination_id=multicore count=16
	EOF

	fields="count=2"
	tags="tool_id=0;state=1"
	column="tool_id"
	title="tool"

	if [[ "$1" == "--by" ]]; then
		if [[ "$2" == "user" ]]; then
			tags="user_id=0;state=1"
			column="user_id"
			column_query="CASE WHEN user_id IS NOT null THEN user_id ELSE -1 END AS user_id"
			title="user"
			query_name="queue_by_user"
		elif [[ "$2" == "destination" ]]; then
			tags="destination_id=0;state=1"
			column="destination_id"
			title="destination"
			query_name="queue_by_destination"
		elif [[ "$2" == "tool" ]]; then
			query_name="queue_by_tool"
			# nothing else needed
		else
			error "Unknown attribute"
			exit 1
		fi
	fi

	if [[ -z "${column_query:-}" ]]; then
		column_query="$column"
	fi

	read -r -d '' QUERY <<-EOF
		SELECT
			${column_query}, state, count(${column}) as ${title}_count
		FROM
			job
		WHERE
			state in ('queued', 'running')
		GROUP BY
			${column}, state
		ORDER BY
			${title}_count desc
	EOF
}

query_queue-overview() { ##? [--short-tool-id]: View used mostly for monitoring
	handle_help "$@" <<-EOF
		Primarily for monitoring of queue. Optimally used with 'iquery' and passed to Telegraf.

		    $ gxadmin iquery queue-overview
		    queue-overview,tool_id=upload1,tool_version=0.0.1,state=running,handler=main.web.1,destination_id=condor,job_runner_name=condor,user=1 count=1

	EOF

	# Use full tool id by default
	tool_id="tool_id"
	if [[ -n "$arg_short_tool_id" ]]; then
		tool_id="regexp_replace(tool_id, '.*toolshed.*/repos/', '')"
	fi

	# Include by default
	if [[ -z "$GDPR_MODE" ]]; then
		user_id='user_id'
	else
		user_id="'0'"
	fi

	fields="count=6"
	tags="tool_id=0;tool_version=1;destination_id=2;handler=3;state=4;job_runner_name=5;user_id=7"

	read -r -d '' QUERY <<-EOF
		WITH queue AS (
			SELECT
				regexp_replace($tool_id, '/[0-9.a-z+-]+$', '')::TEXT AS tool_id,
				tool_version::TEXT,
				COALESCE(destination_id, 'unknown')::TEXT AS destination_id,
				COALESCE(handler, 'unknown')::TEXT AS handler,
				state::TEXT,
				COALESCE(job_runner_name, 'unknown')::TEXT AS job_runner_name,
				count(*) AS count,
				$user_id::TEXT AS user_id
			FROM
				job
			WHERE
				state = 'running' OR state = 'queued' OR state = 'new'
			GROUP BY
				tool_id, tool_version, destination_id, handler, state, job_runner_name, user_id
		)
		SELECT
			tool_id, tool_version, destination_id, handler, state, job_runner_name, sum(count), user_id
		FROM
			queue
		GROUP BY
			tool_id, tool_version, destination_id, handler, state, job_runner_name, user_id

	EOF
}

query_queue-detail() { ##? [--all] [--seconds] [--since-update]: Detailed overview of running and queued jobs
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

	fields="id=1;extid=2;count=9"
	tags="state=0;tool_id=3;username=4;handler=6;job_runner_name=7;destination_id=8"

	d=""
	nonpretty="("
	time_column="job.create_time"
	time_column_name="time_since_creation"

	if [[ -n "$arg_all" ]]; then
		d=", 'new'"
	fi
	if [[ -n "$arg_seconds" ]]; then
		fields="$fields;time_since_creation=5"
		nonpretty="EXTRACT(EPOCH FROM "
	fi
	if [[ -n "$arg_since_update" ]]; then
		time_column="job.update_time"
		time_column_name="time_since_update"
	fi

	username=$(gdpr_safe galaxy_user.username username "Anonymous User")

	read -r -d '' QUERY <<-EOF
		SELECT
			job.state,
			job.id,
			job.job_runner_external_id as extid,
			job.tool_id,
			$username,
			$nonpretty now() AT TIME ZONE 'UTC' - $time_column) as $time_column_name,
			job.handler,
			job.job_runner_name,
			COALESCE(job.destination_id, 'none') as destination_id,
			1 as count
		FROM job
		FULL OUTER JOIN galaxy_user ON job.user_id = galaxy_user.id
		WHERE
			state in ('running', 'queued'$d)
		ORDER BY
			state desc,
			$time_column_name desc
	EOF
}

query_runtime-per-user() { ##? <email>: computation time of user (by email)
	handle_help "$@" <<-EOF
		    $ gxadmin query runtime-per-user hxr@informatik.uni-freiburg.de
		       sum
		    ----------
		     14:07:39
	EOF

	read -r -d '' QUERY <<-EOF
			SELECT sum((metric_value || ' second')::interval)
			FROM job_metric_numeric
			WHERE job_id in (
				SELECT id
				FROM job
				WHERE user_id in (
					SELECT id
					FROM galaxy_user
					where email = '$arg_email'
				)
			) AND metric_name = 'runtime_seconds'
	EOF
}

query_jobs-nonterminal() { ## [--states=new,queued,running] [--update-time] [--older-than=<interval>] [--show-user=id|email|username] [username|id|email]: Job info of nonterminal jobs separated by user
	handle_help "$@" <<-EOF
		You can request the user information by username, id, and user email

		    $ gxadmin query jobs-nonterminal helena-Rasche
		       id    |       tool_id       |  state  |        create_time         | runner | ext_id |     handler     | user
		    ---------+---------------------+---------+----------------------------+--------+--------+-----------------+------
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
		       id    |        tool_id      |  state  |        create_time         | runner | ext_id |     handler     | user
		    ---------+---------------------+---------+----------------------------+--------+--------+-----------------+------
		     4760549 | featurecounts/1.6.3 | running | 2019-01-18 14:05:14.871711 | condor | 197549 | handler_main_7  |  599
		     4760552 | featurecounts/1.6.3 | running | 2019-01-18 14:05:16.205867 | condor | 197552 | handler_main_7  |  599
		     4760554 | featurecounts/1.6.3 | running | 2019-01-18 14:05:17.170157 | condor | 197580 | handler_main_8  |  599
		     4760557 | featurecounts/1.6.3 | running | 2019-01-18 14:05:18.25044  | condor | 197545 | handler_main_10 |  599
		     4760573 | featurecounts/1.6.3 | running | 2019-01-18 14:05:47.20392  | condor | 197553 | handler_main_2  |  599
		     4760588 | featurecounts/1.6.3 | new     | 2019-01-18 14:11:03.766558 |        |        | handler_main_9  |   11
		     4760589 | featurecounts/1.6.3 | new     | 2019-01-18 14:11:05.895232 |        |        | handler_main_1  |   11
		     4760590 | featurecounts/1.6.3 | new     | 2019-01-18 14:11:07.328533 |        |        | handler_main_2  |   11

		You can display user emails or usernames rather than user ID using the --show-user option:

		    $ gxadmin query jobs-nonterminal --show-user=username
		       id   |       tool_id        |  state  |     create_time     | runner | ext_id |  handler  |   user
		    --------+----------------------+---------+---------------------+--------+--------+-----------+----------
		     897234 | hisat2/2.1.0+galaxy7 | running | 2021-05-25 04:13:19 | slurm  | 987443 | handler_1 | zaphod
		     897798 | hisat2/2.1.0+galaxy7 | queued  | 2021-05-25 08:20:12 | slurm  | 988014 | handler_0 | ford
		     899127 | hisat2/2.1.0+galaxy7 | new     | 2021-05-25 09:43:44 | slurm  | 990129 | handler_2 | trillian

		By default jobs in the states 'new', 'queued', and 'running' are considered non-terminal, but this can
		be controlled by passing a comma-separated list to the '--states=' parameter. In addition, by default,
		all non-terminal jobs are displayed, but you can limit this to only jobs created or updated before a
		certain time with '--older-than='. This option takes a value in the PostgreSQL date/time interval
		format, see documentation: https://www.postgresql.org/docs/current/functions-datetime.html

		Be sure to quote intervals containing spaces. Finally, by default, the column returned (and filtered
		with in the case of '--older-than=') is 'job.create_time', but this can be changed to 'job.update_time'
		with '--update-time'. So to return all queued and running jobs that have not been updated in the past 2
		days:

		    $ gxadmin query jobs-nonterminal --states=queued,running --older-than='2 days' --update-time | head -5
		       id   |       tool_id        |  state  |     update_time     |    runner    | ext_id |      handler     | user
		    --------+----------------------+---------+---------------------+--------------+--------+------------------+------
		     335897 | trinity/2.9.1        | queued  | 2021-03-10 10:44:09 | bridges      | 335897 | main_w3_handler2 |  599
		     338554 | repeatmasker/4.0.9   | running | 2021-03-09 10:41:30 | jetstream_iu | 338554 | main_w4_handler2 |   11
		     338699 | hisat2/2.1.0+galaxy7 | queued  | 2021-03-10 05:36:26 | jetstream_iu | 338699 | main_w3_handler2 |   42
	EOF

	states='new,queued,running'
	interval=
	user_filter='true'
	time_column='create_time'
	user_column='job.user_id'

	if (( $# > 0 )); then
		for args in "$@"; do
			if [[ "$args" = '--update-time' ]]; then
				time_column='update_time'
			elif [[ "$args" = '--show-user=email' ]]; then
				user_column='galaxy_user.email'
			elif [[ "$args" = '--show-user=username' ]]; then
				user_column='galaxy_user.username'
			elif [[ "${args:0:9}" = '--states=' ]]; then
				states="${args:9}"
			elif [[ "${args:0:13}" = '--older-than=' ]]; then
				interval="${args:13}"
			elif [[ "${args:0:2}" != '==' ]]; then
				user_filter=$(get_user_filter "$1")
			fi
		done
	fi

	states="'$(echo "$states" | sed "s/,/', '/g")'"

	if [[ -n "$interval" ]]; then
		interval="AND job.$time_column < NOW() - interval '$interval'"
	fi

	user=$(gdpr_safe "$user_column" user "anon")

	read -r -d '' QUERY <<-EOF
		SELECT
			job.id, job.tool_id, job.state, job.$time_column AT TIME ZONE 'UTC' AS $time_column, job.job_runner_name, job.job_runner_external_id, job.handler, $user
		FROM
			job
		LEFT OUTER JOIN
			galaxy_user ON job.user_id = galaxy_user.id
		WHERE
			$user_filter AND job.state IN ($states) $interval
		ORDER BY job.id ASC
	EOF
}

query_jobs-per-user() { ##? <user>: Number of jobs run by a specific user
	handle_help "$@" <<-EOF
		    $ gxadmin query jobs-per-user helena
		     count | user_id
		    -------+---------
		       999 |       1
		    (1 row)
	EOF

	user_filter=$(get_user_filter "$arg_user")

	read -r -d '' QUERY <<-EOF
			SELECT count(*), user_id
			FROM job
			WHERE user_id in (
				SELECT id
				FROM galaxy_user
				WHERE $user_filter
			)
			GROUP BY user_id
	EOF
}

query_recent-jobs() { ##? <hours>: Jobs run in the past <hours> (in any state)
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

	username=$(gdpr_safe galaxy_user.username username)

	read -r -d '' QUERY <<-EOF
		SELECT
			job.id,
			job.create_time AT TIME ZONE 'UTC' as create_time,
			job.tool_id,
			job.state, $username
		FROM job, galaxy_user
		WHERE job.create_time > (now() AT TIME ZONE 'UTC' - '$arg_hours hours'::interval) AND job.user_id = galaxy_user.id
		ORDER BY id desc
	EOF
}

query_job-state-stats() { ##? [--older-than=<interval>]: Shows all jobs states within a time interval (default: 30 days) in a table counted by state
	meta <<-EOF
		ADDED: 19
		UPDATED: 22
	EOF
	handle_help "$@" <<-EOFhelp
		Shows all job states within a time interval (default: 30 days) in a table counted by state

		Example:
		$ gxadmin query job-state-stats
		    date    |  new  | running | queued | upload |  ok   | error | paused | stopped | deleted
		------------+-------+---------+--------+--------+-------+-------+--------+---------+---------
		2022-04-26 |   921 |     564 |    799 |      0 |   581 |    21 |      1 |       0 |       2
		2022-04-25 |  1412 |    1230 |   1642 |      0 |  1132 |   122 |     14 |       0 |      15
		2022-04-24 |   356 |     282 |    380 |      0 |   271 |    16 |      0 |       0 |      10
		2022-04-23 |   254 |     229 |    276 |      0 |   203 |    29 |      0 |       0 |       4
		...
		-26 days

		The '--older-than=' option takes a value in the PostgreSQL date/time interval
		format, see documentation: https://www.postgresql.org/docs/current/functions-datetime.html
		Be sure to quote intervals containing spaces:

		$ gxadmin query job-state-stats --older-than='2 days'
		    date    |  new  | running | queued | upload |  ok   | error | paused | stopped | deleted
		------------+-------+---------+--------+--------+-------+-------+--------+---------+---------
		2022-04-26 |   921 |     564 |    799 |      0 |   581 |    21 |      1 |       0 |       2
		2022-04-25 |  1412 |    1230 |   1642 |      0 |  1132 |   122 |     14 |       0 |      15

EOFhelp

	fields="new=1;running=2;queued=3;upload=4;ok=5;error=6;paused=7;stopped=8;deleted=9"
	tags="date=0"

	interval="AND job.create_time > (timezone('UTC', now()) - '30 days'::INTERVAL)"
	if [[ -n "$arg_older_than" ]]; then
		interval="AND job.create_time > (timezone('UTC', now()) - '$arg_older_than'::INTERVAL)"
	fi


	read -r -d '' QUERY <<-EOF
		SELECT
			date_trunc ('day', job.create_time)::date as date,
			count (job_state_history.state) filter (where job_state_history.state = 'new') as new,
			count (job_state_history.state) filter (where job_state_history.state = 'running') as running,
			count (job_state_history.state) filter (where job_state_history.state = 'queued') as queued,
			count (job_state_history.state) filter (where job_state_history.state = 'upload') as upload,
			count (job_state_history.state) filter (where job_state_history.state = 'ok') as ok,
			count (job_state_history.state) filter (where job_state_history.state = 'error') as error,
			count (job_state_history.state) filter (where job_state_history.state = 'paused') as paused,
			count (job_state_history.state) filter (where job_state_history.state = 'stopped') as stopped,
			count (job_state_history.state) filter (where job_state_history.state = 'deleted') as deleted
		FROM
			job,
			job_state_history
		WHERE
			job_state_history.job_id = job.id
			$interval
		GROUP BY
			date
		ORDER BY
			date DESC
EOF
}

query_monthly-job-runtimes() { ##? [--year=<YYYY>] [--month=<MM>] [--sub_dest=<N>]: Summation of total job run times per user per destination over a period of time
	meta <<-EOF
		ADDED: 19
	EOF
	handle_help "$@" <<-EOF
		This query computes the total run time for all jobs per user per destination over
		an optionally specified time period.  If no time period is specified, all years
		and months will be displayed.  The total job run time is returned in seconds, minutes
		and hours.

		The destination id can be restricted to the first N letters in the id string by using
		the --sub_dest flag.  This allows grouping on values like "slurm" and "front" instead
		of "slurm_multi", "slurm_normal", "frontera_small", "frontera_large", etc., which
		clutters the output.

		A time period can be defined using 3 options:

		--year XXXX --month XX - the specified month of the specified year

		$ gxadmin local query-monthly-job-runtimes --year 2022 --month 05 --sub_dest 5
		   month    | total_jobs | destination_id | runtime_secomnds | runtime_minutes | runtime_hours |   user_email
		------------+------------+----------------+------------------+-----------------+---------------+-----------------
		 2022-05-01 |      20323 | front          |           502031 |         8367.18 |        139.45 |
		 2022-05-01 |       3013 | slurm          |            99135 |         1652.25 |         27.54 |

		--year XXXX - all months of the specified year

		$ gxadmin local query-monthly-job-runtimes --year 2021 --sub_dest 5
		   month    | total_jobs | destination_id | runtime_secomnds | runtime_minutes | runtime_hours |   user_email
		------------+------------+----------------+------------------+-----------------+---------------+-----------------
		 2021-12-01 |        155 | slurm          |            27981 |          466.35 |          7.77 |
		 2021-12-01 |        417 | slurm          |            47063 |          784.38 |         13.07 |
		 2021-11-01 |        113 | slurm          |             3032 |           50.53 |          0.84 |
		 2021-11-01 |          2 | slurm          |              142 |            2.37 |          0.04 |

		--month XX - the specified month of the current year

		$ gxadmin local query-monthly-job-runtimes --month 04 --sub_dest 5
		   month    | total_jobs | destination_id | runtime_secomnds | runtime_minutes | runtime_hours |   user_email
		------------+------------+----------------+------------------+-----------------+---------------+-----------------
		 2022-04-01 |         94 | front          |           333029 |         5550.48 |         92.51 |
		 2022-04-01 |        146 | slurm          |           278408 |         4640.13 |         77.34 |
	EOF

	dest="job.destination_id as destination_id,"
	group_by="GROUP BY user_email, month, destination_id"

	if [[ -n "$arg_sub_dest" ]]; then
		dest="substr(job.destination_id, 1, $arg_sub_dest) as destination_id,"
		group_by="GROUP BY user_email, month, substr(destination_id, 1, $arg_sub_dest)"
	fi

	if [[ -n "$arg_year" ]]  && [[ -n "$arg_month" ]]; then
		filter_by_time_period="AND date_trunc('month', job.create_time AT TIME ZONE 'UTC') = '${arg_year}-${arg_month}-01'::date"
		year=$(date +'%Y')
	elif [[ -n "$arg_year" ]]; then
		filter_by_time_period="AND date_trunc('year', job.create_time AT TIME ZONE 'UTC') = '${arg_year}-01-01'::date"
	elif [[ -n "$arg_month" ]]; then
		year=$(date +'%Y')
		filter_by_time_period="AND date_trunc('month', job.create_time AT TIME ZONE 'UTC') = '$year-${arg_month}-01'::date"
	fi

	read -r -d '' QUERY <<-EOF
		SELECT
			date_trunc('month', job.create_time  AT TIME ZONE 'UTC')::date as month,
			count(job.id) as total_jobs,
			$dest
			round(sum(job_metric_numeric.metric_value), 0) as runtime_secomnds,
			round(sum(job_metric_numeric.metric_value / 60), 2) as runtime_minutes,
			round(sum(job_metric_numeric.metric_value / 3600), 2) as runtime_hours,
			galaxy_user.email as user_email
		FROM
			job,
			job_metric_numeric,
			galaxy_user
		WHERE
			job.id = job_metric_numeric.job_id
			AND job.user_id = galaxy_user.id
			$filter_by_time_period
			AND job_metric_numeric.metric_name = 'runtime_seconds'
		$group_by
		ORDER BY month DESC
	EOF
}

query_training-list() { ##? [--all]: List known trainings
	meta <<-EOF
		ADDED: 12
	EOF
	handle_help "$@" <<-EOF
		This module is specific to EU's implementation of Training Infrastructure as a Service. But this specifically just checks for all groups with the name prefix 'training-'

		    $ gxadmin query training-list
		        name    |  created
		    ------------+------------
		     hogeschool | 2020-01-22
		     ffff       | 2019-08-28
		    (2 rows)

	EOF

	d1=""
	d2="AND deleted = false"
	if [[ -n "$arg_all" ]]; then
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

query_training-members() { ##? <tr_id>: List users in a specific training
	meta <<-EOF
		ADDED: 12
	EOF
	handle_help "$@" <<-EOF
		    $ gxadmin query training-members hts2018
		          username      |       joined
		    --------------------+---------------------
		     helena-Rasche      | 2018-09-21 21:42:01
	EOF

	# Remove training- if they used it.
	ww=$(echo "$arg_tr_id" | sed 's/^training-//g')
	username=$(gdpr_safe galaxy_user.username username)

	read -r -d '' QUERY <<-EOF
			SELECT DISTINCT ON ($username)
				$username,
				date_trunc('second', user_group_association.create_time AT TIME ZONE 'UTC') as joined
			FROM galaxy_user, user_group_association, galaxy_group
			WHERE galaxy_group.name = 'training-$ww'
				AND galaxy_group.id = user_group_association.group_id
				AND user_group_association.user_id = galaxy_user.id
	EOF
}

query_training-members-remove() { ##? <training> <username> [--yesdoit]: Remove a user from a training
	meta <<-EOF
		ADDED: 12
	EOF
	handle_help "$@" <<-EOF
	EOF
	# TODO: Move to mutate

	# Remove training- if they used it.
	ww=$(echo "$arg_training" | sed 's/^training-//g')

	if [[ -n $arg_yesdoit ]]; then
		results="$(query_tsv "$qstr")"
		uga_id=$(echo "$results" | awk -F'\t' '{print $1}')
		if (( uga_id > -1 )); then
			qstr="delete from user_group_association where id = $uga_id"
		fi
		echo "$qstr"
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
				AND galaxy_user.username = '$arg_username'
		EOF
	fi
}

query_largest-histories() { ##? [--human]: Largest histories in Galaxy
	meta <<-EOF
		ADDED: 12
	EOF
	handle_help "$@" <<-EOF
		Finds all histories and print by decreasing size

		    $ gxadmin query largest-histories
		     total_size | id | substring  | username
		    ------------+----+------------+----------
		       17215831 |  6 | Unnamed hi | helena
		          45433 |  8 | Unnamed hi | helena
		          42846 |  9 | Unnamed hi | helena
		           1508 | 10 | Circos     | helena
		            365 |  2 | Tag Testin | helena
		            158 | 44 | test       | helena
		             16 | 45 | Unnamed hi | alice

		Or you can supply the --human flag, but this should not be used with iquery/InfluxDB

		    $ gxadmin query largest-histories --human
		     total_size | id | substring  | userna
		    ------------+----+------------+-------
		     16 MB      |  6 | Unnamed hi | helena
		     44 kB      |  8 | Unnamed hi | helena
		     42 kB      |  9 | Unnamed hi | helena
		     1508 bytes | 10 | Circos     | helena
		     365 bytes  |  2 | Tag Testin | helena
		     158 bytes  | 44 | test       | helena
		     16 bytes   | 45 | Unnamed hi | alice
	EOF

	username=$(gdpr_safe galaxy_user.username username)

	fields="size=0"
	tags="id=1;name=2;username=3"

	total_size="sum(coalesce(dataset.total_size, dataset.file_size, 0)) as total_size"
	if [[ -n "$arg_human" ]]; then
		total_size="pg_size_pretty(sum(coalesce(dataset.total_size, dataset.file_size, 0))) as total_size"
	fi

	read -r -d '' QUERY <<-EOF
		SELECT
			$total_size,
			history.id,
			substring(history.name, 1, 10),
			$username
		FROM
			dataset
			JOIN history_dataset_association on dataset.id = history_dataset_association.dataset_id
			JOIN history on history_dataset_association.history_id = history.id
			JOIN galaxy_user on history.user_id = galaxy_user.id
		GROUP BY history.id, history.name, history.user_id, galaxy_user.username
		ORDER BY sum(coalesce(dataset.total_size, dataset.file_size, 0)) DESC
	EOF
}

query_training-queue() { ##? <training_id>: Jobs currently being run by people in a given training
	meta <<-EOF
		ADDED: 12
	EOF
	handle_help "$@" <<-EOF
		Finds all jobs by people in that queue (including things they are executing that are not part of a training)

		    $ gxadmin query training-queue hts2018
		     state  |   id    | extid  | tool_id |   username    |       created
		    --------+---------+--------+---------+---------------+---------------------
		     queued | 4350274 | 225743 | upload1 |               | 2018-09-26 10:00:00
	EOF

	# Remove training- if they used it.
	ww=$(echo "$arg_training_id" | sed 's/^training-//g')

	username=$(gdpr_safe galaxy_user.username username)

	read -r -d '' QUERY <<-EOF
			SELECT
				job.state,
				job.id,
				job.job_runner_external_id AS extid,
				job.tool_id,
				$username,
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

query_disk-usage() { ##? [--human]: Disk usage per object store.
	handle_help "$@" <<-EOF
		Query the different object stores referenced in your Galaxy database

		    $ gxadmin query disk-usage
		     object_store_id |    sum
		    -----------------+------------
		                     | 1387857517
		    (1 row)

		Or you can supply the --human flag, but this should not be used with iquery/InfluxDB

		    $ gxadmin query disk-usage --human
		     object_store_id |    sum
		    -----------------+------------
		                     | 1324 MB
		    (1 row)
	EOF

	fields="count=1"
	tags="object_store_id=0"

	size="sum(coalesce(dataset.total_size, dataset.file_size, 0))"
	if [[ -n "$arg_human" ]]; then
		size="pg_size_pretty(sum(coalesce(dataset.total_size, dataset.file_size, 0))) as sum"
	fi

	read -r -d '' QUERY <<-EOF
			SELECT
				CASE WHEN object_store_id IS NOT null THEN object_store_id ELSE '_null_' END AS object_store_id,
				$size
			FROM dataset
			WHERE NOT purged
			GROUP BY object_store_id
			ORDER BY sum(coalesce(dataset.total_size, dataset.file_size, 0)) DESC
	EOF
}

query_users-count() { ## : Shows sums of active/external/deleted/purged accounts
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

query_tool-last-used-date() { ## : When was the most recent invocation of every tool
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

		!> It is not truly every tool, there is no easy way to find the tools which have never been run.
	EOF

	read -r -d '' QUERY <<-EOF
		select max(date_trunc('month', create_time AT TIME ZONE 'UTC')), tool_id from job group by tool_id order by max desc
	EOF
}

query_tool-use-by-group() { ##? <year_month> <group>: Lists count of tools used by all users in a group
	meta <<-EOF
		ADDED: 19
		UPDATED: 22
		AUTHORS: gavindi
	EOF
	handle_help "$@" <<-EOFhelp
		Lists tools use count by users in group.
		Requires <year-month> (2022-03) and <group>

		Example:
		$ gxadmin query tool-use-by-group 2022-02 NameOfGroup
		tool_id                                             |             username             | count
		----------------------------------------------------+----------------------------------+-------
		CONVERTER_gz_to_uncompressed                        | user_1                           |     1
		Convert characters1                                 | user_2                           |     1
		Cut1                                                | user_2                           |     1
		Cut1                                                | user_3                           |     1

EOFhelp
	username=$(gdpr_safe galaxy_user.username username "Anonymous User")
	read -r -d '' QUERY <<-EOF
		SELECT
			job.tool_id, $username, count(job.tool_id)
		FROM
			job, galaxy_user, galaxy_group, user_group_association
		WHERE
			job.user_id = galaxy_user.id
		AND
			user_group_association.group_id = galaxy_group.id
		AND
			user_group_association.user_id = galaxy_user.id
		AND
			date_trunc('month', job.create_time) = '$arg_year_month-01'
		AND
			galaxy_group.name = '$arg_group'
		GROUP BY
			job.tool_id, galaxy_user.username
EOF
}

query_users-total() { ##? [date] : Total number of Galaxy users (incl deleted, purged, inactive).
	handle_help "$@" <<-EOF
		Count total number of registered users. Providing optional date (as YYYY-MM-DD) counts up to that date.

			$ gxadmin query users-total 2024-06-01
 			 count
			--------
			 351400
			(1 row)
	EOF

	fields="count=0"
	tags=""
	where=""

	if [[ -n $arg_date ]]; then
		where="WHERE create_time < '$arg_date'"
	fi

	read -r -d '' QUERY <<-EOF
			SELECT count(*) FROM galaxy_user
			$where
	EOF
}

query_groups-list() { ## : List all groups known to Galaxy
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

query_collection-usage() { ## : Information about how many collections of various types are used
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
			dc.collection_type
	EOF
}

query_ts-repos() { ## : Counts of toolshed repositories by toolshed and owner.
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

query_tool-metrics() { ##? <tool_id> <metric_id> [last=-1] [--like] [--ok] [--summary]: See values of a specific metric
	handle_help "$@" <<-EOF
		A good way to use this is to fetch the memory usage of a tool and then
		do some aggregations. The following requires [data_hacks](https://github.com/bitly/data_hacks)

		    $ gxadmin tsvquery tool-metrics %rgrnastar/rna_star% memory.max_usage_in_bytes --like | \\
		        awk '{print \$1 / 1024 / 1024 / 1024}' | \\
		        | gxadmin filter histogram
		    (   0.104,   12.614) n=23228 **************
		    [  12.614,   25.124) n=15873 *********
		    [  25.124,   37.634) n=80849 **************************************************
		    [  37.634,   50.144) n=45171 ***************************
		    [  50.144,   62.654) n=37672 ***********************
		    [  62.654,   75.163) n=20549 ************
		    [  75.163,   87.673) n=7726  ****
		    [  87.673,  100.183) n=7390  ****
		    [ 100.183,  112.693) n=4309  **
		    [ 112.693,  125.203) n=1686  *
		    [ 125.203,  137.713) n=975
		    [ 137.713,  150.223) n=970
		    [ 150.223,  162.733) n=746


		Multiple metrics can be specified by separating them with a comma.

		The optional 'last' argument can be used to limit the number of most recent jobs that will be checked.
		The default is all jobs. Note that this can return zero results if your most recent jobs have not
		returned metric data for your selected metric.

		Use the --ok option to only include jobs that finished successfully.

		Use the --summary option to output summary statistics instead of the values themselves.
	EOF

	limit_clause=
	metric_clause=
	summary='*'

	tool_subquery="SELECT id FROM job WHERE tool_id = '$arg_tool_id'"
	if [[ -n "$arg_like" ]]; then
		tool_subquery="SELECT id FROM job WHERE tool_id like '$arg_tool_id'"
	fi
	if [[ -n "$arg_ok" ]]; then
		tool_subquery="$tool_subquery AND state = 'ok'"
	fi
	if [[ "$arg_last" -gt 0 ]]; then
		limit_clause="ORDER BY id DESC LIMIT $arg_last"
	fi
	if [[ -n "$arg_summary" ]]; then
		summary="$(summary_statistics metric_value 0)"
	fi

	if [[ "$arg_metric_id" =~ ',' ]]; then
		metric_clause="metric_name IN ('$(echo "$arg_metric_id" | sed "s/,/','/g")')"
	else
		metric_clause="metric_name = '$arg_metric_id'"
	fi

	read -r -d '' QUERY <<-EOF
		WITH runtime_data AS (
			SELECT
				metric_value
			FROM job_metric_numeric
			WHERE
				$metric_clause
				and
				job_id in (
					$tool_subquery
				)
			$limit_clause
		)

		SELECT
			$summary
		FROM runtime_data
	EOF
}

query_tool-available-metrics() { ##? <tool_id>: list all available metrics for a given tool
	handle_help "$@" <<-EOF
		Gives a list of available metrics, which can then be used to query.

		    $ gxadmin query tool-available-metrics upload1
		                 metric_name
		    -------------------------------------
		     memory.stat.total_rss
		     memory.stat.total_swap
		     memory.stat.total_unevictable
		     memory.use_hierarchy
		     ...
	EOF

	read -r -d '' QUERY <<-EOF
		SELECT
			distinct metric_name
		FROM job_metric_numeric
		WHERE job_id in (
			SELECT id FROM job WHERE tool_id = '$arg_tool_id'
		)
		ORDER BY metric_name asc
	EOF
}

query_tool-memory-per-inputs() { ##? <tool_id> [--like]: See memory usage and inout size data
	meta <<-EOF
		ADDED: 19
	EOF
	handle_help "$@" <<-EOF
		Display details about tool input counts and sizes along with memory usage and the relation between them,
		to aid in determining appropriate memory allocations for tools.

		    $ gxadmin query tool-memory-per-inputs %/unicycler/% --like
		        id    |                           tool_id                            | input_count | total_input_size_mb | mean_input_size_mb | median_input_size_mb | memory_used_mb | memory_used_per_input_mb | memory_mean_input_ratio | memory_median_input_ratio
		    ----------+--------------------------------------------------------------+-------------+---------------------+--------------------+----------------------+----------------+--------------------------+-------------------------+---------------------------
		     34663027 | toolshed.g2.bx.psu.edu/repos/iuc/unicycler/unicycler/0.4.8.0 |           2 |                 245 |                122 |                  122 |           4645 |                       19 |                      38 |                        38
		     34657045 | toolshed.g2.bx.psu.edu/repos/iuc/unicycler/unicycler/0.4.8.0 |           2 |                  51 |                 25 |                   25 |           1739 |                       34 |                      68 |                        68
		     34655863 | toolshed.g2.bx.psu.edu/repos/iuc/unicycler/unicycler/0.4.8.0 |           2 |                1829 |                915 |                  915 |          20635 |                       11 |                      23 |                        23
		     34650581 | toolshed.g2.bx.psu.edu/repos/iuc/unicycler/unicycler/0.4.8.0 |           3 |                 235 |                 78 |                  112 |          30550 |                      130 |                     391 |                       274
		     34629187 | toolshed.g2.bx.psu.edu/repos/iuc/unicycler/unicycler/0.4.8.0 |           2 |                2411 |               1206 |                 1206 |          50018 |                       21 |                      41 |                        41

		A good way to use this is to fetch the data and then do some aggregations. The following requires
		[data_hacks](https://github.com/bitly/data_hacks):

		    $ gxadmin tsvquery tool-memory-per-inputs %/unicycler/% --like | \\
		        awk '{print \$10}' | histogram.py --percentage --max=256
		    # NumSamples = 870; Min = 4.00; Max = 256.00
		    # 29 values outside of min/max
		    # Mean = 67.804598; Variance = 15461.789404; SD = 124.345444; Median 37.000000
		    # each ∎ represents a count of 4
		        4.0000 -    29.2000 [   368]: ∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎ (42.30%)
		       29.2000 -    54.4000 [   226]: ∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎ (25.98%)
		       54.4000 -    79.6000 [   133]: ∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎ (15.29%)
		       79.6000 -   104.8000 [    45]: ∎∎∎∎∎∎∎∎∎∎∎ (5.17%)
		      104.8000 -   130.0000 [    28]: ∎∎∎∎∎∎∎ (3.22%)
		      130.0000 -   155.2000 [    12]: ∎∎∎ (1.38%)
		      155.2000 -   180.4000 [     9]: ∎∎ (1.03%)
		      180.4000 -   205.6000 [     6]: ∎ (0.69%)
		      205.6000 -   230.8000 [    10]: ∎∎ (1.15%)
		      230.8000 -   256.0000 [     4]: ∎ (0.46%)
	EOF

	tool_clause="j.tool_id = '$arg_tool_id'"
	if [[ -n "$arg_like" ]]; then
		tool_clause="j.tool_id like '$arg_tool_id'"
	fi

	read -r -d '' QUERY <<-EOF
		WITH job_cte AS (
			SELECT
				j.id,
				j.tool_id
			FROM
				job j
			WHERE
				$tool_clause
				AND
					j.state = 'ok'
		),
		mem_cte AS (
			SELECT
				j.id,
				jmn.metric_value AS memory_used
			FROM
				job_cte j
			JOIN
				job_metric_numeric jmn ON j.id = jmn.job_id
			WHERE
				jmn.plugin = 'cgroup'
				AND
					jmn.metric_name = 'memory.memsw.max_usage_in_bytes'
		),
		data_cte AS (
			SELECT
				j.id,
				count(jtid.id) AS input_count,
				sum(d.total_size) AS total_input_size,
				avg(d.total_size) AS mean_input_size,
				percentile_cont(0.5) WITHIN GROUP (ORDER BY d.total_size) AS median_input_size
			FROM
				job_cte j
			JOIN
				job_to_input_dataset jtid ON j.id = jtid.job_id
			JOIN
				history_dataset_association hda ON jtid.dataset_id = hda.id
			JOIN
				dataset d ON hda.dataset_id = d.id
			GROUP BY
				j.id
		)
		SELECT
			j.*,
			d.input_count,
			(d.total_input_size/1024/1024)::bigint AS total_input_size_mb,
			(d.mean_input_size/1024/1024)::bigint AS mean_input_size_mb,
			(d.median_input_size/1024/1024)::bigint AS median_input_size_mb,
			(m.memory_used/1024/1024)::bigint AS memory_used_mb,
			(m.memory_used/NULLIF(d.total_input_size,0))::bigint AS memory_used_per_input_mb,
			(m.memory_used/NULLIF(d.mean_input_size,0))::bigint AS memory_mean_input_ratio,
			(m.memory_used/NULLIF(d.median_input_size,0))::bigint AS memory_median_input_ratio
		FROM
			job_cte j
		JOIN
			mem_cte m on j.id = m.id
		JOIN
			data_cte d on j.id = d.id
		ORDER BY
			j.id DESC
	EOF
}

query_monthly-cpu-stats() { ##? [--nb-users] [--filter-email=<domain>] [year]: CPU years/hours allocated to tools by month (+ nb of users)
	meta <<-EOF
		ADDED: 17
		UPDATED: 22
		AUTHORS: gmauro, lldelisle
	EOF
	handle_help "$@" <<-EOF
		This uses the galaxy_slots and runtime_seconds metrics in order to
		calculate allocated CPU years/hours. This will not be the value of what is
		actually consumed by your jobs, you should use cgroups. It can also display the number of users that ran jobs. You can also filter for email domain.

		    $ gxadmin query monthly-cpu-stats --nb-users --filter-email epfl.ch 2022
			   month    | cpu_years | cpu_hours | nb_users
			------------+-----------+-----------+----------
			 2022-12-01 |      0.44 |   3894.59 |        4
			 2022-11-01 |      0.06 |    558.50 |        6
			 2022-10-01 |      0.10 |    903.05 |        5
			 2022-09-01 |      0.14 |   1198.12 |        5
			 2022-08-01 |      0.19 |   1650.16 |        6
			 2022-07-01 |      0.13 |   1142.43 |        5
			 2022-06-01 |      0.01 |     65.51 |        3
			 2022-05-01 |      0.01 |     50.95 |        2
			 2022-04-01 |      0.02 |    216.83 |        4
			 2022-03-01 |      0.09 |    802.63 |        7
			 2022-02-01 |      0.20 |   1764.14 |        6
			 2022-01-01 |      0.01 |     71.66 |        8
			(12 rows)

		     ...
	EOF

	if [[ -n $arg_year ]]; then
	    filter_by_year="AND date_trunc('year', job.create_time AT TIME ZONE 'UTC') = '$arg_year-01-01'::date"
	fi
	if [[ -n $arg_nb_users ]]; then
	    nb_users=", COUNT (DISTINCT job.user_id) as nb_users"
	fi
	if [[ -n $arg_filter_email ]]; then
		filter_email_from=", galaxy_user"
	    filter_email="AND job.user_id = galaxy_user.id AND galaxy_user.email LIKE '%${arg_filter_email}'"
	fi
	read -r -d '' QUERY <<-EOF
		SELECT
			date_trunc('month', job.create_time  AT TIME ZONE 'UTC')::date as month,
			round(sum((a.metric_value * b.metric_value) / 3600 / 24 / 365 ), 2) as cpu_years,
			round(sum((a.metric_value * b.metric_value) / 3600 ), 2) as cpu_hours
			$nb_users
		FROM
			job_metric_numeric a,
			job_metric_numeric b,
			job
			$filter_email_from
		WHERE
			b.job_id = a.job_id
			AND a.job_id = job.id
			AND a.metric_name = 'runtime_seconds'
			AND b.metric_name = 'galaxy_slots'
			$filter_by_year
			$filter_email
		GROUP BY month
		ORDER BY month DESC
	EOF
}

query_monthly-cpu-years() { ## : CPU years allocated to tools by month
	meta <<-EOF
		ADDED: 12
	EOF
	handle_help "$@" <<-EOF
		This uses the galaxy_slots and runtime_seconds metrics in order to
		calculate allocated CPU years. This will not be the value of what is
		actually consumed by your jobs, you should use cgroups.

		    $ gxadmin query monthly-cpu-years
		        month   | cpu_years
		    ------------+-----------
		     2019-04-01 |      2.95
		     2019-03-01 |     12.38
		     2019-02-01 |     11.47
		     2019-01-01 |      8.27
		     2018-12-01 |     11.42
		     2018-11-01 |     16.99
		     2018-10-01 |     12.09
		     2018-09-01 |      6.27
		     2018-08-01 |      9.06
		     2018-07-01 |      6.17
		     2018-06-01 |      5.73
		     2018-05-01 |      7.36
		     2018-04-01 |     10.21
		     2018-03-01 |      5.20
		     2018-02-01 |      4.53
		     2018-01-01 |      4.05
		     2017-12-01 |      2.44
	EOF

	read -r -d '' QUERY <<-EOF
		SELECT
			date_trunc('month', job.create_time)::date as month,
			round(sum((a.metric_value * b.metric_value) / 3600 / 24 / 365), 2) as cpu_years
		FROM
			job_metric_numeric a,
			job_metric_numeric b,
			job
		WHERE
			b.job_id = a.job_id
			AND a.job_id = job.id
			AND a.metric_name = 'runtime_seconds'
			AND b.metric_name = 'galaxy_slots'
		GROUP BY date_trunc('month', job.create_time)
		ORDER BY date_trunc('month', job.create_time) DESC
	EOF
}


query_monthly-data(){ ##? [year] [--human]: Number of active users per month, running jobs
	handle_help "$@" <<-EOF
		Find out how much data was ingested or created by Galaxy during the past months.

		    $ gxadmin query monthly-data 2018
		        month   | pg_size_pretty
		    ------------+----------------
		     2018-12-01 | 62 TB
		     2018-11-01 | 50 TB
		     2018-10-01 | 59 TB
		     2018-09-01 | 32 TB
		     2018-08-01 | 26 TB
		     2018-07-01 | 42 TB
		     2018-06-01 | 34 TB
		     2018-05-01 | 33 TB
		     2018-04-01 | 27 TB
		     2018-03-01 | 32 TB
		     2018-02-01 | 18 TB
		     2018-01-01 | 16 TB
	EOF
	size="sum(coalesce(dataset.total_size, dataset.file_size, 0))"

	if [[ -n $arg_human ]]; then
		size="pg_size_pretty(sum(coalesce(dataset.total_size, dataset.file_size, 0)))"
	fi

	if [[ -n $arg_year ]]; then
		where="WHERE date_trunc('year', dataset.create_time AT TIME ZONE 'UTC') = '$arg_year-01-01'::date"
	fi

	read -r -d '' QUERY <<-EOF
		SELECT
			date_trunc('month', dataset.create_time AT TIME ZONE 'UTC')::date AS month,
			$size
		FROM
			dataset
		$where
		GROUP BY
			month
		ORDER BY
			month DESC
	EOF
}

query_monthly-gpu-years() { ## : GPU years allocated to tools by month
	meta <<-EOF
		ADDED: 14
	EOF
	handle_help "$@" <<-EOF
		This uses the CUDA_VISIBLE_DEVICES and runtime_seconds metrics in order to
		calculate allocated GPU years. This will not be the value of what is
		actually consumed by your jobs, you should use cgroups. Only works if the
		environment variable 'CUDA_VISIBLE_DEVICES' is recorded as job metric by Galaxy.
		Requires Nvidia GPUs.

		    $ gxadmin query monthly-gpu-years
		        month   | gpu_years
		    ------------+-----------
		     2019-04-01 |      2.95
		     2019-03-01 |     12.38
		     2019-02-01 |     11.47
		     2019-01-01 |      8.27
		     2018-12-01 |     11.42
		     2018-11-01 |     16.99
		     2018-10-01 |     12.09
		     2018-09-01 |      6.27
		     2018-08-01 |      9.06
		     2018-07-01 |      6.17
		     2018-06-01 |      5.73
		     2018-05-01 |      7.36
		     2018-04-01 |     10.21
		     2018-03-01 |      5.20
		     2018-02-01 |      4.53
		     2018-01-01 |      4.05
		     2017-12-01 |      2.44
	EOF

	read -r -d '' QUERY <<-EOF
		SELECT
			date_trunc('month', job.create_time)::date as month,
			round(sum((a.metric_value * length(replace(b.metric_value, ',', ''))) / 3600 / 24 / 365), 2) as gpu_years
		FROM
			job_metric_numeric a,
			job_metric_text b,
			job
		WHERE
			b.job_id = a.job_id
			AND a.job_id = job.id
			AND a.metric_name = 'runtime_seconds'
			AND b.metric_name = 'CUDA_VISIBLE_DEVICES'
		GROUP BY date_trunc('month', job.create_time)
		ORDER BY date_trunc('month', job.create_time) DESC
	EOF
}

query_monthly-workflow-invocations() { ## : Workflow invocations by month
	meta <<-EOF
		ADDED: 19
	EOF
	handle_help "$@" <<-EOF
		Find out how many workflows has been invocated by Galaxy during the past months.

		    $ gxadmin query monthly-workflow-invocations
		       month    | count
		    ------------+-------
		     2022-05-01 |  4183
		     2022-04-01 |  5043
		     2022-03-01 |  4851
		     2022-02-01 | 29587
	EOF

		read -r -d '' QUERY <<-EOF
		SELECT
			date_trunc('month', workflow_invocation.create_time)::date as month,
			count(*)
		FROM
			workflow_invocation
		GROUP BY date_trunc('month', workflow_invocation.create_time)
		ORDER BY date_trunc('month', workflow_invocation.create_time) DESC
	EOF
}

query_workflow-invocation-count() { ##? [date] : Count the total number of workflow invocations.
	meta <<-EOF
		ADDED: 23
	EOF
	handle_help "$@" <<-EOF
		Count total number of workflow invocations. Providing optional date (as YYYY-MM-DD) counts
		number of invocations up to that date.

			$ gxadmin query workflow-invocation-count
			 num_workflow_invocations
			--------------------------
							   758473
			(1 row)
	EOF

	where=""
	if [[ -n $arg_date ]]; then
		where="WHERE create_time < '$arg_date'"
	fi

	read -r -d '' QUERY <<-EOF
		SELECT
			count(*) as num_workflow_invocations
		FROM
			workflow_invocation
		$where
	EOF
}

query_workflow-count() { ##? [date] : Count the number of workflow.
	meta <<-EOF
		ADDED: 23
	EOF
	handle_help "$@" <<-EOF
		Count total number of workflows. Providing optional date (as YYYY-MM-DD) counts
		number of workflows created up to that date.

			$ gxadmin query workflow-count
			 num_workflows
			---------------
					403101
			(1 row)
	EOF

	where=""
	if [[ -n $arg_date ]]; then
		where="WHERE create_time < '$arg_date'"
	fi

	read -r -d '' QUERY <<-EOF
		SELECT
			count(distinct(uuid)) as num_workflows
		FROM
			workflow
		$where
	EOF
}

query_user-cpu-years() { ## : CPU years allocated to tools by user
	meta <<-EOF
		ADDED: 12
	EOF
	handle_help "$@" <<-EOF
		This uses the galaxy_slots and runtime_seconds metrics in order to
		calculate allocated CPU years. This will not be the value of what is
		actually consumed by your jobs, you should use cgroups.

		rank  | user_id |  username   | cpu_years
		----- | ------- | ----------- | ----------
		1     |         | 123f911b5f1 |     20.35
		2     |         | cb0fabc0002 |     14.93
		3     |         | 7e9e9b00b89 |     14.24
		4     |         | 42f211e5e87 |     14.06
		5     |         | 26cdba62c93 |     12.97
		6     |         | fa87cddfcae |      7.01
		7     |         | 44d2a648aac |      6.70
		8     |         | 66c57b41194 |      6.43
		9     |         | 6b1467ac118 |      5.45
		10    |         | d755361b59a |      5.19

	EOF

	username=$(gdpr_safe galaxy_user.username username 'Anonymous')

	read -r -d '' QUERY <<-EOF
		SELECT
			row_number() OVER (ORDER BY round(sum((a.metric_value * b.metric_value) / 3600 / 24 / 365), 2) DESC) as rank,
			job.user_id,
			$username,
			round(sum((a.metric_value * b.metric_value) / 3600 / 24 / 365), 2) as cpu_years
		FROM
			job_metric_numeric a,
			job_metric_numeric b,
			job
			FULL OUTER JOIN galaxy_user ON job.user_id = galaxy_user.id
		WHERE
			b.job_id = a.job_id
			AND a.job_id = job.id
			AND a.metric_name = 'runtime_seconds'
			AND b.metric_name = 'galaxy_slots'
		GROUP BY job.user_id, galaxy_user.username
		ORDER BY round(sum((a.metric_value * b.metric_value) / 3600 / 24 / 365), 2) DESC
		LIMIT 50
	EOF
}

query_user-gpu-years() { ## : GPU years allocated to tools by user
	handle_help "$@" <<-EOF
		This uses the CUDA_VISIBLE_DEVICES and runtime_seconds metrics in order to
		calculate allocated GPU years. This will not be the value of what is
		actually consumed by your jobs, you should use cgroups. Only works if the
		environment variable 'CUDA_VISIBLE_DEVICES' is recorded as job metric by Galaxy.
		Requires Nvidia GPUs.

		rank  | user_id |  username   | gpu_years
		----- | ------- | ----------- | ----------
		1     |         | 123f911b5f1 |     20.35
		2     |         | cb0fabc0002 |     14.93
		3     |         | 7e9e9b00b89 |     14.24
		4     |         | 42f211e5e87 |     14.06
		5     |         | 26cdba62c93 |     12.97
		6     |         | fa87cddfcae |      7.01
		7     |         | 44d2a648aac |      6.70
		8     |         | 66c57b41194 |      6.43
		9     |         | 6b1467ac118 |      5.45
		10    |         | d755361b59a |      5.19

	EOF

	username=$(gdpr_safe galaxy_user.username username 'Anonymous')

	read -r -d '' QUERY <<-EOF
		SELECT
			row_number() OVER (ORDER BY round(sum((a.metric_value * length(replace(b.metric_value, ',', ''))) / 3600 / 24 / 365), 2) DESC) as rank,
			job.user_id,
			$username,
			round(sum((a.metric_value * length(replace(b.metric_value, ',', ''))) / 3600 / 24 / 365), 2) as gpu_years
		FROM
			job_metric_numeric a,
			job_metric_text b,
			job
			FULL OUTER JOIN galaxy_user ON job.user_id = galaxy_user.id
		WHERE
			b.job_id = a.job_id
			AND a.job_id = job.id
			AND a.metric_name = 'runtime_seconds'
			AND b.metric_name = 'CUDA_VISIBLE_DEVICES'
		GROUP BY job.user_id, galaxy_user.username
		ORDER BY round(sum((a.metric_value * length(replace(b.metric_value, ',', ''))) / 3600 / 24 / 365), 2) DESC
		LIMIT 50
	EOF
}

query_user-disk-usage() { ##? [--human] [--use-precalc]: Retrieve an approximation of the disk usage for users
	meta <<-EOF
		ADDED: 13
	EOF
	handle_help "$@" <<-EOF
		This uses the dataset size and the history association in order to
		calculate total disk usage for a user. This is currently limited
		to the 50 users with the highest storage usage.
		By default it prints the storage usage in bytes but you can use --human:

		rank  | user id  |  username   |  email      | storage usage
		----- | -------- | ----------- | ----------- | -------------
		1     |  5       | 123f911b5f1 | 123@911.5f1 |      20.35 TB
		2     |  6       | cb0fabc0002 | cb0@abc.002 |      14.93 TB
		3     |  9       | 7e9e9b00b89 | 7e9@9b0.b89 |      14.24 TB
		4     |  11      | 42f211e5e87 | 42f@11e.e87 |      14.06 GB
		5     |  2       | 26cdba62c93 | 26c@ba6.c93 |      12.97 GB
		6     |  1005    | fa87cddfcae | fa8@cdd.cae |       7.01 GB
		7     |  2009    | 44d2a648aac | 44d@a64.aac |       6.70 GB
		8     |  432     | 66c57b41194 | 66c@7b4.194 |       6.43 GB
		9     |  58945   | 6b1467ac118 | 6b1@67a.118 |       5.45 MB
		10    |  10      | d755361b59a | d75@361.59a |       5.19 KB

		A flag, --use-precalc, is provided which reads the disk_usage column of the galaxy_user table, using the values precisely as displayed to users in Galaxy.
	EOF

	username=$(gdpr_safe galaxy_user.username user_name 'Anonymous')
	useremail=$(gdpr_safe galaxy_user.email user_email 'Anonymous')


	fields="size=4"
	tags="userid=1;username=2"

	if [[ -n $arg_use_precalc ]]; then
		size="disk_usage as \"storage usage\""
		if [[ -n $arg_human ]]; then
			size="pg_size_pretty(disk_usage) as \"storage usage\""
		fi

		read -r -d '' QUERY <<-EOF
			SELECT
				row_number() OVER (ORDER BY galaxy_user.disk_usage DESC) as rank,
				galaxy_user.id as "user id",
				$username,
				$useremail,
				$size
			FROM
				galaxy_user
			GROUP BY galaxy_user.id
			ORDER BY 1
			LIMIT 50
		EOF
	else
		size="sum(coalesce(dataset.total_size, dataset.file_size, 0)) as \"storage usage\""
		if [[ -n $arg_human ]]; then
			size="pg_size_pretty(sum(coalesce(dataset.total_size, dataset.file_size, 0))) as \"storage usage\""
		fi

		read -r -d '' QUERY <<-EOF
			SELECT
				row_number() OVER (ORDER BY sum(coalesce(dataset.total_size, dataset.file_size, 0)) DESC) as rank,
				galaxy_user.id as "user id",
				$username,
				$useremail,
				$size
			FROM
				dataset,
				galaxy_user,
				history_dataset_association,
				history
			WHERE
				NOT dataset.purged
				AND dataset.id = history_dataset_association.dataset_id
				AND history_dataset_association.history_id = history.id
				AND history.user_id = galaxy_user.id
			GROUP BY galaxy_user.id
			ORDER BY 1
			LIMIT 50
		EOF
	fi
}

query_user-disk-quota() { ## : Retrieves the 50 users with the largest quotas
	meta <<-EOF
		ADDED: 14
	EOF
	handle_help "$@" <<-EOF
		This calculates the total assigned disk quota to users.
		It only displays the top 50 quotas.

		rank  | user_id  |  username    |    quota
		----- | -------- | ------------ | ------------
		1     |          | 123f911b5f1  |       20.35
		2     |          | cb0fabc0002  |       14.93
		3     |          | 7e9e9b00b89  |       14.24
		4     |          | 42f211e5e87  |       14.06
		5     |          | 26cdba62c93  |       12.97
		6     |          | fa87cddfcae  |        7.01
		7     |          | 44d2a648aac  |        6.70
		8     |          | 66c57b41194  |        6.43
		9     |          | 6b1467ac118  |        5.45
		10    |          | d755361b59a  |        5.19
	EOF

	username=$(gdpr_safe galaxy_user.username username 'Anonymous')

	read -r -d '' QUERY <<-EOF
		WITH user_basequota_list AS (
			SELECT galaxy_user.id as "user_id",
				basequota.bytes as "quota"
			FROM galaxy_user,
				quota basequota,
				user_quota_association
			WHERE galaxy_user.id = user_quota_association.user_id
				AND basequota.id = user_quota_association.quota_id
				AND basequota.operation = '='
				AND NOT basequota.deleted
			GROUP BY galaxy_user.id, basequota.bytes
		),
		user_basequota AS (
			SELECT user_basequota_list.user_id,
				MAX(user_basequota_list.quota) as "quota"
			FROM user_basequota_list
			GROUP BY user_basequota_list.user_id
		),
		user_addquota_list AS (
			SELECT galaxy_user.id as "user_id",
				addquota.bytes as "quota"
			FROM galaxy_user,
				quota addquota,
				user_quota_association
			WHERE galaxy_user.id = user_quota_association.user_id
				AND addquota.id = user_quota_association.quota_id
				AND addquota.operation = '+'
				AND NOT addquota.deleted
			GROUP BY galaxy_user.id, addquota.bytes
		),
		user_addquota AS (
			SELECT user_addquota_list.user_id,
				sum(user_addquota_list.quota) AS "quota"
			FROM user_addquota_list
			GROUP BY user_addquota_list.user_id
		),
		user_minquota_list AS (
			SELECT galaxy_user.id as "user_id",
				minquota.bytes as "quota"
			FROM galaxy_user,
				quota minquota,
				user_quota_association
			WHERE galaxy_user.id = user_quota_association.user_id
				AND minquota.id = user_quota_association.quota_id
				AND minquota.operation = '-'
				AND NOT minquota.deleted
			GROUP BY galaxy_user.id, minquota.bytes
		),
		user_minquota AS (
			SELECT user_minquota_list.user_id,
				sum(user_minquota_list.quota) AS "quota"
			FROM user_minquota_list
			GROUP BY user_minquota_list.user_id
		),
		group_basequota_list AS (
			SELECT galaxy_user.id as "user_id",
				galaxy_group.id as "group_id",
				basequota.bytes as "quota"
			FROM galaxy_user,
				galaxy_group,
				quota basequota,
				group_quota_association,
				user_group_association
			WHERE galaxy_user.id = user_group_association.user_id
				AND galaxy_group.id = user_group_association.group_id
				AND basequota.id = group_quota_association.quota_id
				AND galaxy_group.id = group_quota_association.group_id
				AND basequota.operation = '='
				AND NOT basequota.deleted
			GROUP BY galaxy_user.id, galaxy_group.id, basequota.bytes
		),
		group_basequota AS (
			SELECT group_basequota_list.user_id,
				group_basequota_list.group_id,
				MAX(group_basequota_list.quota) as "quota"
			FROM group_basequota_list
			GROUP BY group_basequota_list.user_id, group_basequota_list.group_id
		),
		group_addquota_list AS (
			SELECT galaxy_user.id as "user_id",
				addquota.bytes as "quota"
			FROM galaxy_user,
				galaxy_group,
				quota addquota,
				group_quota_association,
				user_group_association
			WHERE galaxy_user.id = user_group_association.user_id
				AND galaxy_group.id = user_group_association.group_id
				AND addquota.id = group_quota_association.quota_id
				AND galaxy_group.id = group_quota_association.group_id
				AND addquota.operation = '+'
				AND NOT addquota.deleted
			GROUP BY galaxy_user.id, addquota.bytes
		),
		group_addquota AS (
			SELECT group_addquota_list.user_id,
				sum(group_addquota_list.quota) AS "quota"
			FROM group_addquota_list
			GROUP BY group_addquota_list.user_id
		),
		group_minquota_list AS (
			SELECT galaxy_user.id as "user_id",
				minquota.bytes as "quota"
			FROM galaxy_user,
				galaxy_group,
				quota minquota,
				group_quota_association,
				user_group_association
			WHERE galaxy_user.id = user_group_association.user_id
				AND galaxy_group.id = user_group_association.group_id
				AND minquota.id = group_quota_association.quota_id
				AND galaxy_group.id = group_quota_association.group_id
				AND minquota.operation = '-'
				AND NOT minquota.deleted
			GROUP BY galaxy_user.id, galaxy_group.id, galaxy_group.name, minquota.bytes
		),
		group_minquota AS (
			SELECT group_minquota_list.user_id,
				sum(group_minquota_list.quota) AS "quota"
			FROM group_minquota_list
			GROUP BY group_minquota_list.user_id
		),
		all_user_default_quota AS (
			SELECT galaxy_user.id as "user_id",
				quota.bytes
			FROM galaxy_user,
				quota
			WHERE quota.id = (SELECT quota_id FROM default_quota_association)
		),
		quotas AS (
			SELECT all_user_default_quota.user_id as "aud_uid",
				all_user_default_quota.bytes as "aud_quota",
				user_basequota.user_id as "ubq_uid",
				user_basequota.quota as "ubq_quota",
				user_addquota.user_id as "uaq_uid",
				user_addquota.quota as "uaq_quota",
				user_minquota.user_id as "umq_uid",
				user_minquota.quota as "umq_quota",
				group_basequota.user_id as "gbq_uid",
				group_basequota.quota as "gbq_quota",
				group_addquota.user_id as "gaq_uid",
				group_addquota.quota as "gaq_quota",
				group_minquota.user_id as "gmq_uid",
				group_minquota.quota as "gmq_quota"
			FROM all_user_default_quota
			FULL OUTER JOIN user_basequota ON all_user_default_quota.user_id = user_basequota.user_id
			FULL OUTER JOIN user_addquota ON all_user_default_quota.user_id = user_addquota.user_id
			FULL OUTER JOIN user_minquota ON all_user_default_quota.user_id = user_minquota.user_id
			FULL OUTER JOIN group_basequota ON all_user_default_quota.user_id = group_basequota.user_id
			FULL OUTER JOIN group_addquota ON all_user_default_quota.user_id = group_addquota.user_id
			FULL OUTER JOIN group_minquota ON all_user_default_quota.user_id = group_minquota.user_id
		),
		computed_quotas AS (
			SELECT aud_uid as "user_id",
				COALESCE(GREATEST(ubq_quota, gbq_quota), aud_quota) as "base_quota",
				(COALESCE(uaq_quota, 0) + COALESCE(gaq_quota, 0)) as "add_quota",
				(COALESCE(umq_quota, 0) + COALESCE(gmq_quota, 0)) as "min_quota"
			FROM quotas
		)

		SELECT row_number() OVER (ORDER BY (computed_quotas.base_quota + computed_quotas.add_quota - computed_quotas.min_quota) DESC) as rank,
			galaxy_user.id as "user_id",
			$username,
			pg_size_pretty(computed_quotas.base_quota + computed_quotas.add_quota - computed_quotas.min_quota) as "quota"
		FROM computed_quotas,
			galaxy_user
		WHERE computed_quotas.user_id = galaxy_user.id
		GROUP BY galaxy_user.id, galaxy_user.username, computed_quotas.base_quota, computed_quotas.add_quota, computed_quotas.min_quota
		ORDER BY (computed_quotas.base_quota + computed_quotas.add_quota - computed_quotas.min_quota) DESC
		LIMIT 50
	EOF
}

query_disk-usage-library() { ##? [--library_name=<NAME>] [--by_folder] [--human]: Retrieve an approximation of the disk usage for a data library
	meta <<-EOF
		ADDED: 19
	EOF
	handle_help "$@" <<-EOF
		This uses the dataset size and the library dataset association in order to
		calculate total disk usage for a data library.  By default it prints the
		usage in bytes...

		$ gxadmin local query-disk-usage-library --library_name 'My Library'
		 library_name  | library size
		---------------+-------------
		 My Library    | 25298225177

		...but the --human flag displays readable formats:

		$ gxadmin local query-disk-usage-library --library_name 'My Library' --human
		 library_name  | library size
		---------------+--------------
		 My Library    | 24 GB

		A --by_folder flag is also available for displaying disk usage for each folder.

		a$ gxadmin local query-disk-usage-library --library_name 'My Library' --by_folder
		       folder_name       | folder size
		-------------------------+-------------
		 Contamination Filtering | 10798630750
		 Metagenomes             | 12026310232
		 Metatranscriptomes      |  2473284195

		And, of course, the --human flag can be used here as well.

		$ gxadmin local query-disk-usage-library --library_name 'My Library' --by_folder --human
		       folder_name       | folder size
		-------------------------+-------------
		 Contamination Filtering | 10 GB
		 Metagenomes             | 11 GB
		 Metatranscriptomes      | 2359 MB
	EOF

	where="WHERE
		library.name = '$2'
		AND library_folder.id IN (SELECT id FROM library_tree)
		AND library_folder.id = library_dataset.folder_id
		AND library_dataset.library_dataset_dataset_association_id = library_dataset_dataset_association.id
		AND library_dataset_dataset_association.dataset_id = dataset.id
		AND NOT dataset.purged"

	from="FROM
		(SELECT
			library.name as library_name,
			library_folder.name as folder_name,
			sum(coalesce(dataset.total_size, dataset.file_size, 0)) as folder_size
		FROM
			library,
			library_folder,
			library_dataset_dataset_association,
			library_dataset,
			dataset
		$where
		GROUP BY library_name, folder_name) lib"

	group_by="GROUP BY library_name"

	if [[ -n $3 ]]
	then
		if [[ $3 == '--by_folder' ]]
		then
			if [[ -n $4 && $4 == '--human' ]]
			then
				folder_size="pg_size_pretty(sum(coalesce(dataset.total_size, dataset.file_size, 0))) as \"folder size\""
			else
				folder_size="sum(coalesce(dataset.total_size, dataset.file_size, 0)) as \"folder size\""
			fi
			select="SELECT library_folder.name as folder_name, $folder_size"
			from="FROM library, library_folder, library_dataset_dataset_association, library_dataset, dataset"
			group_by="GROUP BY folder_name"
		elif [[ $3 == '--human' ]]
		then
			select="SELECT lib.library_name as library_name, pg_size_pretty(sum(folder_size)) as \"library size\""
			where=""
		fi
	else
		select="SELECT lib.library_name as library_name, sum(folder_size) as \"library size\""
		where=""
	fi

	read -r -d '' QUERY <<-EOF
		WITH RECURSIVE library_tree AS (
			SELECT id,
			    name,
			    parent_id,
			    0 AS folder_level
			FROM library_folder
			WHERE parent_id IS NULL
			AND name = '$2'
		UNION ALL
			SELECT child.id,
				child.name,
				child.parent_id,
			folder_level+1 AS folder_level
			FROM library_folder child
			JOIN library_tree lt
				ON lt.id = child.parent_id
		)

		$select
		$from
		$where
		$group_by
	EOF
}

query_group-cpu-seconds() { ##? [group]: Retrieve an approximation of the CPU time in seconds for group(s)
	meta <<-EOF
		ADDED: 13
	EOF
	handle_help "$@" <<-EOF
		This uses the galaxy_slots and runtime_seconds metrics in order to
		calculate allocated CPU time in seconds. This will not be the value of
		what is actually consumed by jobs of the group, you should use cgroups instead.

		rank  | group_id |  group_name  | cpu_seconds
		----- | -------- | ------------ | ------------
		1     |          | 123f911b5f1  |       20.35
		2     |          | cb0fabc0002  |       14.93
		3     |          | 7e9e9b00b89  |       14.24
		4     |          | 42f211e5e87  |       14.06
		5     |          | 26cdba62c93  |       12.97
		6     |          | fa87cddfcae  |        7.01
		7     |          | 44d2a648aac  |        6.70
		8     |          | 66c57b41194  |        6.43
		9     |          | 6b1467ac118  |        5.45
		10    |          | d755361b59a  |        5.19
	EOF

	where=""
	if [[ -n $arg_group ]]; then
		where="AND galaxy_group.name = '$arg_group'"
	fi

	groupname=$(gdpr_safe galaxy_group.name group_name 'Anonymous')

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
			GROUP BY job.user_id
		), user_job_info AS (
			SELECT user_id,
				sum(cpu_seconds) AS cpu_seconds
			FROM jobs_info
			GROUP BY user_id
		)

		SELECT row_number() OVER (ORDER BY round(sum(user_job_info.cpu_seconds), 0) DESC) as rank,
			galaxy_group.id as group_id,
			$groupname,
			round(sum(user_job_info.cpu_seconds), 0) as cpu_seconds
		FROM user_job_info,
			galaxy_group,
			user_group_association
		WHERE user_job_info.user_id = user_group_association.user_id
			AND user_group_association.group_id = galaxy_group.id
			$where
		GROUP BY galaxy_group.id, galaxy_group.name
		ORDER BY round(sum(user_job_info.cpu_seconds), 0) DESC
		LIMIT 50
	EOF
}

query_group-gpu-time() { ##? [group]: Retrieve an approximation of the GPU time for users
	meta <<-EOF
		ADDED: 14
	EOF
	handle_help "$@" <<-EOF
		This uses the galaxy_slots and runtime_seconds metrics in order to
		calculate allocated GPU time. This will not be the value of what is
		actually consumed by jobs of the group, you should use cgroups instead.
		Only works if the  environment variable 'CUDA_VISIBLE_DEVICES' is
		recorded as job metric by Galaxy. Requires Nvidia GPUs.

		rank  | group_id |  group_name | gpu_seconds
		----- | -------- | ----------- | -----------
		1     |          | 123f911b5f1 |      20.35
		2     |          | cb0fabc0002 |      14.93
		3     |          | 7e9e9b00b89 |      14.24
		4     |          | 42f211e5e87 |      14.06
		5     |          | 26cdba62c93 |      12.97
		6     |          | fa87cddfcae |       7.01
		7     |          | 44d2a648aac |       6.70
		8     |          | 66c57b41194 |       6.43
		9     |          | 6b1467ac118 |       5.45
		10    |          | d755361b59a |       5.19
	EOF

	where=""
	if [[ -n $arg_group ]]; then
		where="AND galaxy_group.name = '$arg_group'"
	fi

	groupname=$(gdpr_safe galaxy_group.name group_name 'Anonymous')

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
			GROUP BY job.user_id
		), user_job_info AS (
			SELECT user_id,
				sum(gpu_seconds) AS gpu_seconds
			FROM jobs_info
			GROUP BY user_id
		)
		SELECT row_number() OVER (ORDER BY round(sum(user_job_info.gpu_seconds), 0) DESC) as rank,
			galaxy_group.id as group_id,
			$groupname,
			round(sum(user_job_info.gpu_seconds), 0) as gpu_seconds
		FROM user_job_info,
			galaxy_group,
			user_group_association
		WHERE user_job_info.user_id = user_group_association.user_id
			AND user_group_association.group_id = galaxy_group.id
			$where
		GROUP BY galaxy_group.id, galaxy_group.name
		ORDER BY round(sum(user_job_info.gpu_seconds), 0) DESC
		LIMIT 50
	EOF
}

query_monthly-users-registered(){ ##? [--year=<YYYY>] [--month=<MM>] [--by_group]: Number of users registered
	handle_help "$@" <<-EOF
		Number of users that registered each month. **NOTE**: Does not include anonymous users or users in no group.
		Parameters:
		--by_group: Will separate out registrations by galaxy user group as well
		--year=<YYYY>: Will return monthly user registrations for the given year
		--month=<MM>: Will return number of user registrations for the given month. If --year is not supplied, will return for each year.

		$ gxadmin query monthly-users-registered --year=2024
		  month  | num_registered_users
		---------+----------------------
		 2024-03 |                 4109
		 2024-02 |                 4709
		 2024-01 |                 3711

		$ gxadmin query monthly-users-registered --year=2024 --by_group
		   month  |    group_name    | num_registered_users
		 ---------+------------------+----------------------
		  2024-02 | Group_1          |                    1
		  2024-02 | Group_2          |                   18
		  2024-02 | Group_3          |                    1
		  2024-01 | Group_4          |                    6
	EOF

	where="WHERE true"
	if [[ -n "$arg_year" ]] ; then
		where="$where AND date_trunc('year', galaxy_user.create_time AT TIME ZONE 'UTC') = '$arg_year-01-01'::date"
	fi;
	if [[ -n "$arg_month" ]]; then
		where="$where AND DATE_TRUNC('month', galaxy_user.create_time) = DATE_TRUNC('month', CAST(CONCAT(EXTRACT(YEAR FROM galaxy_user.create_time), '-$arg_month-01') AS DATE))"
	fi;
	if [[ -n "$arg_by_group" ]]; then
		where="$where AND galaxy_user.id = user_group_association.user_id AND galaxy_group.id = user_group_association.group_id"
		select="galaxy_group.name AS group_name,"
		from="galaxy_group, user_group_association,"
		group=", galaxy_group.name"
	fi

	read -r -d '' QUERY <<-EOF
		SELECT
			TO_CHAR(date_trunc('month', galaxy_user.create_time)::DATE, 'YYYY-MM') AS month,
			$select
			count(*) AS num_registered_users
		FROM
			$from
			galaxy_user
		$where
		GROUP BY
			month
			$group
		ORDER BY
			month DESC
	EOF
}

query_monthly-users-active(){ ##? [--year=<YYYY>] [--month=<MM>] [--by_group]: Number of active users per month, running jobs
	meta <<-EOF
		ADDED: 12
	EOF
	handle_help "$@" <<-EOF
		Number of unique users each month who ran jobs. **NOTE**: does not include anonymous users.
		Parameters:
		--by_group: Separate out active users by galaxy user group
		--year=<YYYY>: Will return monthly active user count for the given year
		--month=<MM>: Will return number of active users for the given month. If --year is not supplied, will return for each year.

		    $ gxadmin query monthly-users-active --year=2024
	  		  month  | active_users
			---------+--------------
			 2024-02 |         1580
			 2024-01 |         6812
	EOF

	where="WHERE true"
	if [[ -n "$arg_year" ]] ; then
		where="$where AND date_trunc('year', job.create_time AT TIME ZONE 'UTC') = '$arg_year-01-01'::date"
	fi;
	if [[ -n "$arg_month" ]]; then
		where="$where AND DATE_TRUNC('month', job.create_time) = DATE_TRUNC('month', CAST(CONCAT(EXTRACT(YEAR FROM job.create_time), '-$arg_month-01') AS DATE))"
	fi;
	if [[ -n "$arg_by_group" ]]; then
		where="$where AND job.user_id = user_group_association.user_id AND galaxy_group.id = user_group_association.group_id"
		select="galaxy_group.name AS group_name,"
		from="galaxy_group, user_group_association,"
		group=", galaxy_group.name"
	fi

	read -r -d '' QUERY <<-EOF
		SELECT
			TO_CHAR(date_trunc('month', job.create_time)::date, 'YYYY-MM') AS month,
			$select
			count(distinct job.user_id) as active_users
		FROM
			$from
			job
		$where
		GROUP BY
			month
			$group
		ORDER BY
			month DESC
	EOF
}

query_users-engaged-multiday() { ##? [month] [--new_only]: Number of users running jobs for more than a day
	meta <<-EOF
		ADDED: 22
	EOF
	handle_help "$@" <<-EOF
		Number of unique users in a given month who ran jobs for more than a day.
		Parameters:
		month: Month to count jobs for, provided as YYYY-MM. If month is not provided, defaults to current month.
		--new_only: Only count users who registered in the same month

		    $ gxadmin query users-engaged-multiday 2024-02
	  		  month  | users_engaged_more_than_day
			---------+-----------------------------
			 2024-02 |                         454
	EOF

	if [ $# -eq 0 ] || [ -z "$arg_month" ]; then
		arg_month=$(date +%Y-%m)
	fi

	job_table="job"
	if [[ -n $arg_new_only ]]; then
		new_users_jobs="
			WITH new_users_jobs AS (
				SELECT
					j.create_time,
					j.user_id
				FROM
					job j
				JOIN
					galaxy_user u ON j.user_id = u.id
				WHERE
					DATE_TRUNC('month', j.create_time) = DATE_TRUNC('month', CAST('$arg_month-01' AS DATE))
					AND DATE_TRUNC('month', u.create_time) = DATE_TRUNC('month', CAST('$arg_month-01' AS DATE))
			)"
		job_table="new_users_jobs"
	fi

	read -r -d '' QUERY <<-EOF
		$new_users_jobs

		SELECT
			TO_CHAR(CAST('$arg_month-01' AS DATE), 'YYYY-MM') AS month,
			count(DISTINCT user_id) AS users_engaged_more_than_day
		FROM
			(
				SELECT
					user_id,
					count(DISTINCT date_group) AS date_group_count
				FROM
					(
						SELECT
							user_id,
							to_char(create_time, 'YYYY-MM-DD') AS date_group
						FROM
							$job_table
						WHERE
							DATE_TRUNC('month', create_time) = DATE_TRUNC('month', CAST('$arg_month-01' AS DATE))
						GROUP BY
							user_id,
							date_group
						HAVING
							COUNT(user_id) > 1
					) AS user_date_groups
				GROUP BY
					user_id
				HAVING
					count(*) > 1
			) AS users_that_ran_jobs_more_than_1_day
	EOF
}

query_monthly-jobs(){ ##? [--year=<YYYY>] [--month=<MM>] [--by_group] [--by_state] [--state=<state>]: Number of jobs run each month
	handle_help "$@" <<-EOF
		Count jobs run each month or specified month
		Parameters:
		--by_group: Will separate out job counts for each month by galaxy user group
		--by_state: Will separate out job counts for each month by job state
		--state=<state>: Only count jobs in the given state
		--year=<YYYY>: Will return monthly job count for the given year
		--month=<MM>: Will return monthly job count for the given month. If --year is not supplied, will return for each year.

		$ gxadmin query monthly-jobs --year=2024
		  month  | count
		---------+--------
		 2024-02 |  71238
		 2024-01 | 589359
	EOF

	state=""
	group_by=""

	where="WHERE true"
	if [[ -n "$arg_year" ]] ; then
		where="$where AND date_trunc('year', job.create_time AT TIME ZONE 'UTC') = '$arg_year-01-01'::date"
	fi;
	if [[ -n "$arg_month" ]]; then
		where="$where AND DATE_TRUNC('month', job.create_time) = DATE_TRUNC('month', CAST(CONCAT(EXTRACT(YEAR FROM job.create_time), '-$arg_month-01') AS DATE))"
	fi;
	if [[ -n "$arg_by_group" ]]; then
		where="$where AND job.user_id = user_group_association.user_id AND galaxy_group.id = user_group_association.group_id"
		select="galaxy_group.name AS group_name,"
		from="galaxy_group, user_group_association,"
		group=", galaxy_group.name"
	fi
	if [[ -n "$arg_by_state" ]]; then
		state=", state"
		group_by=", state"
	elif [[ -n $arg_state ]]; then
		state=", state"
		where="$where AND state = '$arg_state'"
	fi

	read -r -d '' QUERY <<-EOF
		SELECT
			TO_CHAR(date_trunc('month', job.create_time)::DATE, 'YYYY-MM') AS month,
			$select
			count(*) AS num_jobs
			$state
		FROM
			$from
			job
		$where
		GROUP BY
			month
			$state
			$group
		ORDER BY
			month DESC
	EOF
}

query_monthly-jobs-by-new-users() { ##? [month] [--no_state] [--state=<state>]: Number of jobs run by new users in the given month
	meta <<-EOF
		ADDED: 22
	EOF
	handle_help "$@" <<-EOF
		Count jobs run by users that registered in the given month
		month: Month to count jobs for, provided as YYYY-MM. If month is not provided, defaults to current month.
		--no_state: Do not break down jobs by state
		--state=<state>: Only count jobs in the given state

		    $ gxadmin query jobs-by-new-users 2024-02
		      state   | jobs_by_new_users
			----------+-------------------
			 deleted  |               340
			 deleting |                 2
			 error    |              1092
			 new      |                41
			 ok       |              4688
			 paused   |                87
			 stopped  |                 1
	EOF

	state="state,"
	group_by_order_by="GROUP BY month, state ORDER BY month, state"

	if [[ -z "$arg_month" ]]; then
		arg_month=$(date +%Y-%m)
	fi

	if [[ -n $arg_no_state ]]; then
		state=""
		group_by_order_by="GROUP BY month ORDER BY month"
	elif [[ -n $arg_state ]]; then
		where_state="AND state = '$arg_state'"
	fi

	read -r -d '' QUERY <<-EOF
		SELECT
			TO_CHAR(date_trunc('month', j.create_time)::DATE, 'YYYY-MM') AS month,
			$state
			COUNT(j.id) AS jobs_by_new_users
		FROM
			job j
		JOIN
			galaxy_user u ON j.user_id = u.id
		WHERE
			DATE_TRUNC('month', j.create_time) = DATE_TRUNC('month', CAST('$arg_month-01' AS DATE))
			AND DATE_TRUNC('month', u.create_time) = DATE_TRUNC('month', CAST('$arg_month-01' AS DATE))
			$where_state
		$group_by_order_by
	EOF
}

query_monthly-jobs-by-new-multiday-users() { ##? [month]: Number of jobs run by newly registered users that ran jobs more than a day
	meta <<-EOF
		ADDED: 22
	EOF
	handle_help "$@" <<-EOF
		Number of jobs run by newly registered users that ran jobs more than a day
		Parameters:
		month: Month to count jobs for, provided as YYYY-MM. If month is not provided, defaults to current month.

		    $ gxadmin query monthly-jobs-by-new-multiday-users 2024-02
			  month  | num_jobs_by_new_users_engaged_more_than_day
			---------+---------------------------------------------
			 2024-02 |                                        2771
	EOF

	if [[ -z "$arg_month" ]]; then
		arg_month=$(date +%Y-%m)
	fi

	read -r -d '' QUERY <<-EOF
		WITH new_users_jobs AS (
			SELECT
				j.id AS job_id,
				j.create_time,
				j.user_id
			FROM
				job j
			JOIN
				galaxy_user u ON j.user_id = u.id
			WHERE
				DATE_TRUNC('month', j.create_time) = DATE_TRUNC('month', CAST('$arg_month-01' AS DATE))
				AND DATE_TRUNC('month', u.create_time) = DATE_TRUNC('month', CAST('$arg_month-01' AS DATE))
		), new_users_engaged_more_than_day AS (
			SELECT
				user_id
			FROM
				(
					SELECT
						user_id,
						count(DISTINCT date_group) AS date_group_count
					FROM
						(
							SELECT
								user_id,
								to_char(create_time, 'YYYY-MM-DD') AS date_group
							FROM
								new_users_jobs
							WHERE
								DATE_TRUNC('month', create_time) = DATE_TRUNC('month', CAST('$arg_month-01' AS DATE))
							GROUP BY
								user_id,
								date_group
							HAVING
								COUNT(user_id) > 1
						) AS user_date_groups
					GROUP BY
						user_id
					HAVING
						count(*) > 1
				) AS users_that_ran_jobs_more_than_1_day
			)
		SELECT
			TO_CHAR(CAST('$arg_month-01' AS DATE), 'YYYY-MM') AS month,
			COUNT(DISTINCT(j1.job_id)) as num_jobs_by_new_users_engaged_more_than_day
		FROM
			new_users_jobs j1
		JOIN new_users_engaged_more_than_day AS j2 ON j1.user_id = j2.user_id
	EOF
}

query_total-jobs(){ ##? [date] [--no_state]: Total number of jobs run by Galaxy instance.
	meta <<-EOF
		ADDED: 17
	EOF
	handle_help "$@" <<-EOF
		Count total number of jobs. Providing optional date (as YYYY-MM-DD) counts jobs up to that date.
		Adding '--no_state' does not break jobs down by job state.

		    $ gxadmin query total-jobs
		      state  | num_jobs
		    ---------+---------
		     deleted |    21
		     error   |   197
		     ok      |   798
		    (3 rows)
	EOF

	state="state,"
	group_by_order_by="GROUP BY state ORDER BY state"
	if [[ -n $arg_no_state ]]; then
		state=""
		group_by_order_by=""
	fi

	if [[ -n $arg_date ]]; then
		where="WHERE create_time < '$arg_date'"
	fi

	fields="count=1"
	tags="state=0"

	read -r -d '' QUERY <<-EOF
		SELECT
			$state
			count(*) AS num_jobs
		FROM
			job
		$where
		$group_by_order_by
	EOF

}

query_job-state() { ##? <job_id>: Get current job state given a job ID
	meta <<-EOF
		ADDED: 19
	EOF
	handle_help "$@" <<-EOF
		    $ gxadmin query job-state 1
		     state
		    --------
		     error
		    (1 row)
	EOF

	read -r -d '' QUERY <<-EOF
			SELECT
				state
			FROM job
			WHERE id = $arg_id
	EOF
}

query_job-history() { ##? <id>: Job state history for a specific job
	handle_help "$@" <<-EOF
		    $ gxadmin query job-history 1
		                 time              | state
		    -------------------------------+--------
		     2018-11-20 17:15:09.297907+00 | error
		     2018-11-20 17:15:08.911972+00 | queued
		     2018-11-20 17:15:08.243363+00 | new
		     2018-11-20 17:15:08.198301+00 | upload
		     2018-11-20 17:15:08.19655+00  | new
		    (5 rows)
	EOF

	read -r -d '' QUERY <<-EOF
			SELECT
				create_time AT TIME ZONE 'UTC' as time,
				state
			FROM job_state_history
			WHERE job_id = $arg_id
   			ORDER BY create_time ASC
	EOF
}

query_job-inputs() { ##? <id>: Input datasets to a specific job
	handle_help "$@" <<-EOF
	EOF

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
			WHERE j.id = $arg_id
	EOF
}

query_job-outputs() { ##? <id>: Output datasets from a specific job
	handle_help "$@" <<-EOF
	EOF

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
			WHERE j.id = $arg_id
	EOF
}

query_job-info() { ## <-|job_id [job_id [...]]> : Retrieve information about jobs given some job IDs
	handle_help "$@" <<-EOF
		Retrieves information on a job, like the host it ran on,
		how long it ran for and the total memory.

		id    | create_time  | update_time |  tool_id     | state |   hostname   | handler  | runtime_seconds | memtotal
		----- | ------------ | ----------- | ------------ | ----- | ------------ | -------- | --------------- | --------
		1     |              |             | 123f911b5f1  | ok    | 123f911b5f1  | handler0 |          20.35  | 20.35 GB
		2     |              |             | cb0fabc0002  | ok    | cb0fabc0002  | handler1 |          14.93  |  5.96 GB
		3     |              |             | 7e9e9b00b89  | ok    | 7e9e9b00b89  | handler1 |          14.24  |  3.53 GB
		4     |              |             | 42f211e5e87  | ok    | 42f211e5e87  | handler4 |          14.06  |  1.79 GB
		5     |              |             | 26cdba62c93  | error | 26cdba62c93  | handler0 |          12.97  |  1.21 GB
		6     |              |             | fa87cddfcae  | ok    | fa87cddfcae  | handler1 |           7.01  |   987 MB
		7     |              |             | 44d2a648aac  | ok    | 44d2a648aac  | handler3 |           6.70  |   900 MB
		8     |              |             | 66c57b41194  | ok    | 66c57b41194  | handler1 |           6.43  |   500 MB
		9     |              |             | 6b1467ac118  | ok    | 6b1467ac118  | handler0 |           5.45  |   250 MB
		10    |              |             | d755361b59a  | ok    | d755361b59a  | handler2 |           5.19  |   100 MB
	EOF

	assert_count_ge $# 1 "Missing job IDs"

	if [[ "$1" == "-" ]]; then
		# read jobs from stdin
		job_ids=$(cat | paste -s -d' ')
	else
		# read from $@
		job_ids=$*;
	fi

	# shellcheck disable=SC2068
	job_ids_string=$(join_by ',' ${job_ids[@]})

	read -r -d '' QUERY <<-EOF
		WITH hostname_query AS (
			SELECT job_id,
				metric_value as hostname
			FROM job_metric_text
			WHERE job_id IN ($job_ids_string)
				AND metric_name='HOSTNAME'
		),
		metric_num_query AS (
			SELECT job_id,
				SUM(CASE WHEN metric_name='runtime_seconds' THEN metric_value END) runtime_seconds,
				pg_size_pretty(SUM(CASE WHEN metric_name='memtotal' THEN metric_value END)) memtotal
			FROM job_metric_numeric
			WHERE job_id IN ($job_ids_string)
				AND metric_name IN ('runtime_seconds', 'memtotal')
			GROUP BY job_id
		)

		SELECT job.id,
			job.create_time,
			job.update_time,
			job.tool_id,
			job.state,
			job.handler,
			hostname_query.hostname,
			metric_num_query.runtime_seconds,
			metric_num_query.memtotal
		FROM job
			FULL OUTER JOIN hostname_query ON hostname_query.job_id = job.id
			FULL OUTER JOIN metric_num_query ON metric_num_query.job_id = job.id
		WHERE job.id IN ($job_ids_string)
	EOF
}

query_old-histories(){ ##? <weeks>: Lists histories that haven't been updated (used) for <weeks>
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
			history.update_time < (now() AT TIME ZONE 'UTC' - '$arg_weeks weeks'::interval) AND
			history.user_id = galaxy_user.id AND
			history.deleted = FALSE AND
			history.published = FALSE
		ORDER BY
			history.update_time desc
	EOF
}

# TODO(hxr): generic summation by metric? Leave math to consumer?
query_jobs-max-by-cpu-days() { ## : Top 10 jobs by CPU days consumed (requires CGroups metrics)
	meta <<-EOF
		ADDED: 12
	EOF
	handle_help "$@" <<-EOF
	EOF

	read -r -d '' QUERY <<-EOF
		SELECT
			job.id,
			job.tool_id,
			job.create_time,
			metric_value/1000000000/3600/24 as cpu_days
		FROM job, job_metric_numeric
		WHERE
			job.id = job_metric_numeric.job_id
			AND metric_name = 'cpuacct.usage'
		ORDER BY cpu_days desc
		LIMIT 30
	EOF
}

query_errored-jobs(){ ##? <hours> [--details]: Lists jobs that errored in the last N hours.
	handle_help "$@" <<-EOF
		Lists details of jobs that have status = 'error' for the specified number of hours. Default = 24 hours

		    $ gxadmin query errored-jobs 2
		     id | create_time | tool_id | tool_version | handler  | destination_id | job_runner_external_id |      email
		    ----+-------------+---------+--------------+----------+----------------+------------------------+------------------
		      1 |             | upload1 | 1.1.0        | handler2 | slurm_normal   | 42                     | user@example.org
		      2 |             | cut1    | 1.1.1        | handler1 | slurm_normal   | 43                     | user@example.org
		      3 |             | bwa     | 0.7.17.1     | handler0 | slurm_multi    | 44                     | map@example.org
		      4 |             | trinity | 2.9.1        | handler1 | pulsar_bigmem  | 4                      | rna@example.org


	EOF

	email=$(gdpr_safe galaxy_user.email 'email')

	details=
	if [[ -n "$arg_details" ]]; then
		details="job.job_stderr,"
	fi

	read -r -d '' QUERY <<-EOF
		SELECT
			job.id,
			job.create_time AT TIME ZONE 'UTC' as create_time,
			job.tool_id,
			job.tool_version,
			job.handler,
			job.destination_id,
			job.job_runner_external_id,
			$details
			$email
		FROM
			job,
			galaxy_user
		WHERE
			job.create_time >= (now() AT TIME ZONE 'UTC' - '$arg_hours hours'::interval) AND
			job.state = 'error' AND
			job.user_id = galaxy_user.id
		ORDER BY
			job.id
	EOF
}


query_workflow-invocation-status() { ## : Report on how many workflows are in new state by handler
	meta <<-EOF
		ADDED: 12
	EOF
	handle_help "$@" <<-EOF
		Really only intended to be used in influx queries.
	EOF

	fields="count=3"
	tags="scheduler=0;handler=1;state=2"

	read -r -d '' QUERY <<-EOF
		SELECT
			COALESCE(scheduler, 'none'),
			COALESCE(handler, 'none'),
			state,
			count(*)
		FROM
			workflow_invocation
		WHERE state in ('new', 'ready')
		GROUP BY handler, scheduler, state
	EOF
}


query_workflow-invocation-totals() { ## : Report on overall workflow counts, to ensure throughput
	meta <<-EOF
		ADDED: 17
	EOF
	handle_help "$@" <<-EOF
		Really only intended to be used in influx queries.
	EOF

	fields="count=1"
	tags="state=0"

	read -r -d '' QUERY <<-EOF
		SELECT
			COALESCE(state, 'unknown'), count(*)
		FROM
			workflow_invocation
		GROUP BY state
	EOF
}

query_tool-new-errors() { ##? [weeks=4] [--short-tool-id]: Summarize percent of tool runs in error over the past weeks for "new tools"
	meta <<-EOF
		ADDED: 12
	EOF
	handle_help "$@" <<-EOF
		See jobs-in-error summary for recent tools (tools whose first execution is in recent weeks).

		    $ gxadmin query tool-errors --short-tool-id 1
		        tool_id                        | tool_runs |  percent_errored  | percent_failed | count_errored | count_failed |     handler
		    -----------------------------------+-----------+-------------------+----------------+---------------+--------------+-----------------
		     rnateam/graphclust_align_cluster/ |        55 | 0.145454545454545 |              0 |             8 |            0 | handler_main_10
		     iuc/rgrnastar/rna_star/2.6.0b-2   |        46 | 0.347826086956522 |              0 |            16 |            0 | handler_main_3
		     iuc/rgrnastar/rna_star/2.6.0b-2   |        43 | 0.186046511627907 |              0 |             8 |            0 | handler_main_0
		     iuc/rgrnastar/rna_star/2.6.0b-2   |        41 | 0.390243902439024 |              0 |            16 |            0 | handler_main_4
		     iuc/rgrnastar/rna_star/2.6.0b-2   |        40 |             0.325 |              0 |            13 |            0 | handler_main_6
		     Filter1                           |        40 |             0.125 |              0 |             5 |            0 | handler_main_0
		     devteam/bowtie2/bowtie2/2.3.4.3   |        40 |             0.125 |              0 |             5 |            0 | handler_main_7
		     iuc/rgrnastar/rna_star/2.6.0b-2   |        40 |               0.3 |              0 |            12 |            0 | handler_main_2
	EOF

	tool_id="j.tool_id"
	if [[ -n $arg_short_tool_id ]]; then
		tool_id="regexp_replace(j.tool_id, '.*toolshed.*/repos/', '') as tool_id"
	fi

	fields="tool_runs=1;percent_errored=2;percent_failed=3;count_errored=4;count_failed=5"
	tags="tool_id=0;handler=6"

	read -r -d '' QUERY <<-EOF
		SELECT
			$tool_id,
			count(*) AS tool_runs,
			sum(CASE WHEN j.state = 'error'  THEN 1 ELSE 0 END)::float / count(*) AS percent_errored,
			sum(CASE WHEN j.state = 'failed' THEN 1 ELSE 0 END)::float / count(*) AS percent_failed,
			sum(CASE WHEN j.state = 'error'  THEN 1 ELSE 0 END) AS count_errored,
			sum(CASE WHEN j.state = 'failed' THEN 1 ELSE 0 END) AS count_failed,
			j.handler
		FROM job AS j
		WHERE
			j.tool_id
			IN (
					SELECT tool_id
					FROM job AS j
					WHERE j.create_time > (now() - '$arg_weeks weeks'::INTERVAL)
					GROUP BY j.tool_id
				)
		GROUP BY j.tool_id, j.handler
		ORDER BY percent_failed_errored DESC
	EOF
}

query_tool-errors() { ##? [--short-tool-id] [weeks=4]: Summarize percent of tool runs in error over the past weeks for all tools that have failed (most popular tools first)
	meta <<-EOF
		ADDED: 12
	EOF
	handle_help "$@" <<-EOF
		See jobs-in-error summary for recently executed tools that have failed at least 10% of the time.

		    $ gxadmin query tool-errors --short-tool-id 1
		        tool_id                        | tool_runs |  percent_errored  | percent_failed | count_errored | count_failed |     handler
		    -----------------------------------+-----------+-------------------+----------------+---------------+--------------+-----------------
		     rnateam/graphclust_align_cluster/ |        55 | 0.145454545454545 |              0 |             8 |            0 | handler_main_10
		     iuc/rgrnastar/rna_star/2.6.0b-2   |        46 | 0.347826086956522 |              0 |            16 |            0 | handler_main_3
		     iuc/rgrnastar/rna_star/2.6.0b-2   |        43 | 0.186046511627907 |              0 |             8 |            0 | handler_main_0
		     iuc/rgrnastar/rna_star/2.6.0b-2   |        41 | 0.390243902439024 |              0 |            16 |            0 | handler_main_4
		     iuc/rgrnastar/rna_star/2.6.0b-2   |        40 |             0.325 |              0 |            13 |            0 | handler_main_6
		     Filter1                           |        40 |             0.125 |              0 |             5 |            0 | handler_main_0
		     devteam/bowtie2/bowtie2/2.3.4.3   |        40 |             0.125 |              0 |             5 |            0 | handler_main_7
		     iuc/rgrnastar/rna_star/2.6.0b-2   |        40 |               0.3 |              0 |            12 |            0 | handler_main_2
	EOF

	# TODO: Fix this nonsense for proper args
	tool_id="j.tool_id"
	if [[ -n $arg_short_tool_id ]]; then
		tool_id="regexp_replace(j.tool_id, '.*toolshed.*/repos/', '') as tool_id"
	fi

	fields="tool_runs=1;percent_errored=2;percent_failed=3;count_errored=4;count_failed=5"
	tags="tool_id=0;handler=6"

	read -r -d '' QUERY <<-EOF
		SELECT
			$tool_id,
			count(*) AS tool_runs,
			sum(CASE WHEN j.state = 'error'  THEN 1 ELSE 0 END)::float / count(*) AS percent_errored,
			sum(CASE WHEN j.state = 'failed' THEN 1 ELSE 0 END)::float / count(*) AS percent_failed,
			sum(CASE WHEN j.state = 'error'  THEN 1 ELSE 0 END) AS count_errored,
			sum(CASE WHEN j.state = 'failed' THEN 1 ELSE 0 END) AS count_failed,
			j.handler
		FROM
			job AS j
		WHERE
			j.create_time > (now() - '$arg_weeks weeks'::INTERVAL)
		GROUP BY
			j.tool_id, j.handler
		HAVING
			sum(CASE WHEN j.state IN ('error', 'failed') THEN 1 ELSE 0 END) * 100.0 / count(*) > 10.0
		ORDER BY
			tool_runs DESC
	EOF
}

query_tool-likely-broken() { ##? [--short-tool-id] [weeks=4]: Find tools that have been executed in recent weeks that are (or were due to job running) likely substantially broken
	handle_help "$@" <<-EOF
		This runs an identical query to tool-errors, except filtering for tools
		which were run more than 4 times, and have a failure rate over 95%.

		                             tool_id                       | tool_runs | percent_errored | percent_failed | count_errored | count_failed |     handler
		    -------------------------------------------------------+-----------+-----------------+----------------+---------------+--------------+-----------------
		     simon-gladman/velvetoptimiser/velvetoptimiser/2.2.6   |        14 |               1 |              0 |            14 |            0 | handler_main_7
		     bgruening/hicexplorer_hicplottads/hicexplorer_hicplott|         9 |               1 |              0 |             9 |            0 | handler_main_0
		     bgruening/text_processing/tp_replace_in_column/1.1.3  |         8 |               1 |              0 |             8 |            0 | handler_main_3
		     bgruening/text_processing/tp_awk_tool/1.1.1           |         7 |               1 |              0 |             7 |            0 | handler_main_5
		     rnateam/dorina/dorina_search/1.0.0                    |         7 |               1 |              0 |             7 |            0 | handler_main_2
		     bgruening/text_processing/tp_replace_in_column/1.1.3  |         6 |               1 |              0 |             6 |            0 | handler_main_9
		     rnateam/dorina/dorina_search/1.0.0                    |         6 |               1 |              0 |             6 |            0 | handler_main_11
		     rnateam/dorina/dorina_search/1.0.0                    |         6 |               1 |              0 |             6 |            0 | handler_main_8
	EOF

	# TODO: Fix this nonsense for proper args
	tool_id="j.tool_id"
	if [[ -n $arg_short_tool_id ]]; then
		tool_id="regexp_replace(j.tool_id, '.*toolshed.*/repos/', '') as tool_id"
	fi

	fields="tool_runs=1;percent_errored=2;percent_failed=3;count_errored=4;count_failed=5"
	tags="tool_id=0;handler=6"

	read -r -d '' QUERY <<-EOF
		SELECT
			$tool_id,
			count(*) AS tool_runs,
			sum(CASE WHEN j.state = 'error'  THEN 1 ELSE 0 END)::float / count(*) AS percent_errored,
			sum(CASE WHEN j.state = 'failed' THEN 1 ELSE 0 END)::float / count(*) AS percent_failed,
			sum(CASE WHEN j.state = 'error'  THEN 1 ELSE 0 END) AS count_errored,
			sum(CASE WHEN j.state = 'failed' THEN 1 ELSE 0 END) AS count_failed,
			j.handler
		FROM
			job AS j
		WHERE
			j.create_time > (now() - '$arg_weeks weeks'::INTERVAL)
		GROUP BY
			j.tool_id, j.handler
		HAVING
			sum(CASE WHEN j.state IN ('error', 'failed') THEN 1 ELSE 0 END) * 100.0 / count(*) > 95.0
			AND count(*) > 4
		ORDER BY
			tool_runs DESC
	EOF
}

query_user-recent-aggregate-jobs() { ##? <user> [days=7]: Show aggregate information for jobs in past N days for user (by email/id/username)
	meta <<-EOF
		ADDED: 12
	EOF
	handle_help "$@" <<-EOF
		Obtain an overview of tools that a user has run in the past N days
	EOF

	# args
	user_filter=$(get_user_filter "$arg_user")

	read -r -d '' QUERY <<-EOF
		SELECT
			date_trunc('day', create_time), tool_id, state, count(*)
		FROM
			job
		JOIN
			galaxy_user on galaxy_user.id = job.user_id
		WHERE
			$user_filter AND create_time > (now() - '$arg_days days'::INTERVAL)
		GROUP BY
			date_trunc, tool_id, state
		ORDER BY
			date_trunc DESC
	EOF
}

query_user-history-list() { ##? <user> [--size]: List a user's (by email/id/username) histories.
	meta <<-EOF
		ADDED: 14
	EOF
	handle_help "$@" <<-EOF
		Obtain an overview of histories of a user. By default orders the histories by date.
		When using '--size' it overrides the order to size.

		$ gxadmin query user-history-list <username|id|email>
		  ID   |                 Name                 |        Last Updated        |   Size
		-------+--------------------------------------+----------------------------+-----------
			52 | Unnamed history                      | 2019-08-08 15:15:32.284678 | 293 MB
		 30906 | Unnamed history                      | 2019-07-23 16:25:36.084019 | 13 kB
	EOF

	# args
	user_filter=$(get_user_filter "$arg_user")
	order_col="uh.update_time"
	if [[ -n "$arg_size" ]]; then
		order_col="hs.hist_size"
	fi

	read -r -d '' QUERY <<-EOF
		WITH user_histories AS (
			SELECT id,
				name,
				update_time
			FROM history
			WHERE user_id IN (
				SELECT id
				FROM galaxy_user
				WHERE $user_filter
			) AND NOT purged
		), history_sizes AS (
			SELECT history_id,
				sum(coalesce(dataset.total_size, dataset.file_size, 0)) as "hist_size"
			FROM history_dataset_association,
				dataset
			WHERE history_id IN (
				SELECT id
				FROM user_histories
			) AND history_dataset_association.dataset_id = dataset.id
			GROUP BY history_id
		)
		SELECT uh.id as "ID",
			uh.name as "Name",
			uh.update_time as "Last Updated",
			pg_size_pretty(hs.hist_size) as "Size"
		FROM user_histories uh,
			history_sizes hs
		WHERE uh.id = hs.history_id
		ORDER BY $order_col DESC
	EOF
}

query_history-contents() { ## <history_id> [--dataset|--collection]: List datasets and/or collections in a history
	meta <<-EOF
		ADDED: 12
	EOF
	handle_help "$@" <<-EOF
		Obtain an overview of tools that a user has run in the past N days
	EOF
	local dsq clq q

	dsq="select dataset_id, name, hid, visible, deleted, copied_from_history_dataset_association_id as copied_from from history_dataset_association where history_id = $1"
	clq="select collection_id, name, hid, visible, deleted, copied_from_history_dataset_collection_association_id as copied_from from history_dataset_collection_association where history_id = $1;"

	if [[ $2 == "--dataset" ]] || [[ $2 == "--datasets" ]]; then
			q="$dsq"
	elif [[ $2 == "--collection" ]] || [[ $2 == "--collections" ]]; then
			q="$clq"
	else
			q="$dsq;$clq"
	fi

	read -r -d '' QUERY <<-EOF
			$q
	EOF
}

query_hdca-info() { ##? <hdca_id>: Information on a dataset collection
	meta <<-EOF
		ADDED: 12
	EOF
	handle_help "$@" <<-EOF
	EOF

	read -r -d '' QUERY <<-EOF
		SELECT *
		FROM dataset_collection
		WHERE id = $arg_hdca_id
	EOF
}

query_hdca-datasets() { ##? <hdca_id>: List of files in a dataset collection
	meta <<-EOF
		ADDED: 12
	EOF
	handle_help "$@" <<-EOF
	EOF

	read -r -d '' QUERY <<-EOF
		SELECT element_index, hda_id, ldda_id, child_collection_id, element_identifier
		FROM dataset_collection_element
		WHERE dataset_collection_id = $arg_hdca_id
		ORDER by element_index asc
	EOF
}

query_jobs-queued-internal-by-handler() { ## : How many queued jobs do not have external IDs, by handler
	meta <<-EOF
		ADDED: 13
	EOF
	handle_help "$@" <<-EOF
		Identify which handlers have a backlog of jobs which should be
		receiving external cluster IDs but have not yet.

		handler          | count
		---------------- + ------
		handler_main_0   |    14
		handler_main_1   |     4
		handler_main_10  |    13
		handler_main_2   |    11
		handler_main_3   |    14
		handler_main_4   |    12
		handler_main_5   |     9
		handler_main_6   |     7
		handler_main_7   |    13
		handler_main_8   |     9
		handler_main_9   |    14
	EOF

	fields="count=1"
	tags="handler=0"

	read -r -d '' QUERY <<-EOF
		SELECT
			handler,
			count(handler)
		FROM
			job
		WHERE
			state = 'queued'
			AND job_runner_external_id IS null
		GROUP BY
			handler
	EOF
}



query_jobs-queued() { ## : How many queued jobs have external cluster IDs
	meta <<-EOF
		ADDED: 13
	EOF
	handle_help "$@" <<-EOF
		Shows the distribution of jobs in queued state, whether or not they have received an external ID.


		n            | count
		------------ | ------
		unprocessed  |   118
		processed    |    37
	EOF

	fields="count=1"
	tags="group=0"

	read -r -d '' QUERY <<-EOF
		SELECT
			CASE WHEN job_runner_external_id IS NOT null THEN 'processed' ELSE 'unprocessed' END as n,
			count(*)
		FROM
			job
		WHERE
			state = 'queued'
		GROUP BY n
	EOF
}

query_users-with-oidc() { ## : How many users logged in with OIDC
	meta <<-EOF
		ADDED: 13
	EOF
	handle_help "$@" <<-EOF
		provider | count
		-------- | ------
		elixir   |     5
	EOF

	fields="count=1"
	tags="provider=0"

	read -r -d '' QUERY <<-EOF
		SELECT provider, count(distinct user_id) FROM oidc_user_authnz_tokens GROUP BY provider
	EOF
}

query_history-runtime-system() { ##? <history_id>: Sum of runtimes by all jobs in a history
	meta <<-EOF
		ADDED: 13
	EOF
	handle_help "$@" <<-EOF
	EOF

	read -r -d '' QUERY <<-EOF
		SELECT
			(sum(job_metric_numeric.metric_value)::INT8 || 'seconds')::INTERVAL
		FROM
			job LEFT JOIN job_metric_numeric ON job.id = job_metric_numeric.job_id
		WHERE
			job.history_id = $arg_history_id AND metric_name = 'runtime_seconds'
	EOF
}

query_history-runtime-wallclock() { ##? <history_id>: Time as elapsed by a clock on the wall
	meta <<-EOF
		ADDED: 13
	EOF
	handle_help "$@" <<-EOF
	EOF

	read -r -d '' QUERY <<-EOF
		SELECT
			max(job.update_time) - min(job.create_time)
		FROM
			job
		WHERE
			job.history_id = $arg_history_id
	EOF
}

query_history-runtime-system-by-tool() { ##? <history_id>: Sum of runtimes by all jobs in a history, split by tool
	meta <<-EOF
		ADDED: 13
	EOF
	handle_help "$@" <<-EOF
	EOF

	read -r -d '' QUERY <<-EOF
		SELECT
			job.tool_id,
			(sum(job_metric_numeric.metric_value)::INT || 'seconds')::INTERVAL
		FROM
			job LEFT JOIN job_metric_numeric ON job.id = job_metric_numeric.job_id
		WHERE
			job.history_id = $arg_history_id AND metric_name = 'runtime_seconds'
		GROUP BY
			job.tool_id
		ORDER BY
			"interval" DESC
	EOF
}

query_history-count() { ##? [date] : Count the number of histories.
	meta <<-EOF
		ADDED: 23
	EOF
	handle_help "$@" <<-EOF
		Count total number of histories. Providing optional date (as YYYY-MM-DD) counts
		number of histories created up to that date.

			$ gxadmin query history-count
			num_histories
			---------------
				9065181
			(1 row)
	EOF

	where=""
	if [[ -n $arg_date ]]; then
		where="WHERE create_time < '$arg_date'"
	fi

	read -r -d '' QUERY <<-EOF
		SELECT
			count(*) as num_histories
		FROM
			history
		$where
	EOF
}

query_upload-gb-in-past-hour() { ##? [hours=1]: Sum in bytes of files uploaded in the past hour
	meta <<-EOF
		ADDED: 13
	EOF
	handle_help "$@" <<-EOF
		Quick output, mostly useful for graphing, to produce a nice graph of how heavily are people uploading currently.
	EOF

	fields="count=0"
	tags="hours=1"

	read -r -d '' QUERY <<-EOF
		SELECT
			coalesce(sum(coalesce(dataset.total_size, coalesce(dataset.file_size, 0))), 0),
			$arg_hours as hours
		FROM
			job
			LEFT JOIN job_to_output_dataset ON job.id = job_to_output_dataset.job_id
			LEFT JOIN history_dataset_association ON
					job_to_output_dataset.dataset_id = history_dataset_association.id
			LEFT JOIN dataset ON history_dataset_association.dataset_id = dataset.id
		WHERE
			job.tool_id in ('__DATA_FETCH__', 'upload1')
			AND job.create_time AT TIME ZONE 'UTC' > (now() - '$arg_hours hours'::INTERVAL)
	EOF
}

query_queue-detail-by-handler() { ##? <handler_id>: List jobs for a specific handler
	meta <<-EOF
		ADDED: 14
	EOF
	handle_help "$@" <<-EOF
		List the jobs currently being processed by a specific handler
	EOF

	read -r -d '' QUERY <<-EOF
		SELECT
			id,
			create_time,
			state,
			regexp_replace(tool_id, '.*toolshed.*/repos/', ''),
			job_runner_name,
			job_runner_external_id,
			destination_id
		FROM
			job
		WHERE
			handler = '$arg_handler_id' AND state IN ('new', 'queued', 'running')
	EOF
}

query_pg-column-size() { ##? <table>: Estimate the size of columns in a table
	meta <<-EOF
		ADDED: 19
	EOF
	handle_help "$@" <<-EOF
	EOF

	results="$(query_tsv "SELECT column_name FROM information_schema.columns WHERE table_name   = '$arg_table'")"

	declare -a select
	declare -a cols

	for c in $results; do
		cols+=("$c")
		select+=("pg_size_pretty(sum(pg_column_size($c))) as size_$c")
	done

	strcol="${cols[*]}"
	strsel="${select[*]}"
	csvcol="${strcol//${IFS:0:1}/,}"
	csvsel="${strsel//${IFS:0:1}/,}"
	csvsel="$(echo "$csvsel" | sed 's/,as,/ AS /g')"

	read -r -d '' QUERY <<-EOF
		WITH
			x AS (
				SELECT
				$csvcol
				FROM $arg_table
				ORDER BY id DESC
				LIMIT 100000
			)
		SELECT
			$csvsel
		FROM
			x
	EOF

}


query_pg-cache-hit() { ## : Check postgres in-memory cache hit ratio
	meta <<-EOF
		ADDED: 14
	EOF
	handle_help "$@" <<-EOF
		Query from: https://www.citusdata.com/blog/2019/03/29/health-checks-for-your-postgres-database/

		Tells you about the cache hit ratio, is Postgres managing to store
		commonly requested objects in memory or are they being loaded every
		time?

		heap_read  | heap_hit |         ratio
		----------- ---------- ------------------------
		29         |    64445 | 0.99955020628470391165
	EOF

	fields="read=0;hit=1;ratio=2"
	tags=""

	read -r -d '' QUERY <<-EOF
		SELECT
			sum(heap_blks_read) as heap_read,
			sum(heap_blks_hit)  as heap_hit,
			sum(heap_blks_hit) / (sum(heap_blks_hit) + sum(heap_blks_read)) as ratio
		FROM
			pg_statio_user_tables
	EOF

}

query_pg-table-bloat() { ##? [--human]: show table and index bloat in your database ordered by most wasteful
	meta <<-EOF
		ADDED: 14
	EOF
	handle_help "$@" <<-EOF
		Query from: https://www.citusdata.com/blog/2019/03/29/health-checks-for-your-postgres-database/
		Originally from: https://github.com/heroku/heroku-pg-extras/tree/master/commands
	EOF

	if [[ -n "$arg_human" ]]; then
		waste_query="pg_size_pretty(raw_waste)"
	else
		waste_query="raw_waste"
	fi

	fields="bloat=3;ratio=4"
	tags="type=0;schema=1;object=2"

	read -r -d '' QUERY <<-EOF
		WITH constants AS (
			SELECT current_setting('block_size')::numeric AS bs, 23 AS hdr, 4 AS ma
		), bloat_info AS (
			SELECT
				ma,bs,schemaname,tablename,
				(datawidth+(hdr+ma-(case when hdr%ma=0 THEN ma ELSE hdr%ma END)))::numeric AS datahdr,
				(maxfracsum*(nullhdr+ma-(case when nullhdr%ma=0 THEN ma ELSE nullhdr%ma END))) AS nullhdr2
			FROM (
				SELECT
					schemaname, tablename, hdr, ma, bs,
					SUM((1-null_frac)*avg_width) AS datawidth,
					MAX(null_frac) AS maxfracsum,
					hdr+(
						SELECT 1+count(*)/8
						FROM pg_stats s2
						WHERE null_frac<>0 AND s2.schemaname = s.schemaname AND s2.tablename = s.tablename
					) AS nullhdr
				FROM pg_stats s, constants
				GROUP BY 1,2,3,4,5
			) AS foo
		), table_bloat AS (
			SELECT
				schemaname, tablename, cc.relpages, bs,
				CEIL((cc.reltuples*((datahdr+ma-
					(CASE WHEN datahdr%ma=0 THEN ma ELSE datahdr%ma END))+nullhdr2+4))/(bs-20::float)) AS otta
			FROM bloat_info
			JOIN pg_class cc ON cc.relname = bloat_info.tablename
			JOIN pg_namespace nn ON cc.relnamespace = nn.oid AND nn.nspname = bloat_info.schemaname AND nn.nspname <> 'information_schema'
		), index_bloat AS (
			SELECT
				schemaname, tablename, bs,
				coalesce(c2.relname,'?') AS iname, COALESCE(c2.reltuples,0) AS ituples, c2.relpages,0 AS ipages,
				COALESCE(CEIL((c2.reltuples*(datahdr-12))/(bs-20::float)),0) AS iotta -- very rough approximation, assumes all cols
			FROM bloat_info
			JOIN pg_class cc ON cc.relname = bloat_info.tablename
			JOIN pg_namespace nn ON cc.relnamespace = nn.oid AND nn.nspname = bloat_info.schemaname AND nn.nspname <> 'information_schema'
			JOIN pg_index i ON indrelid = cc.oid
			JOIN pg_class c2 ON c2.oid = i.indexrelid
		)
		SELECT
			type, schemaname, object_name, bloat, $waste_query as waste
		FROM
		(SELECT
			'table' as type,
			schemaname,
			tablename as object_name,
			ROUND(CASE WHEN otta=0 THEN 0.0 ELSE table_bloat.relpages/otta::numeric END,1) AS bloat,
			CASE WHEN relpages < otta THEN '0' ELSE (bs*(table_bloat.relpages-otta)::bigint)::bigint END AS raw_waste
		FROM
			table_bloat
				UNION
		SELECT
			'index' as type,
			schemaname,
			tablename || '::' || iname as object_name,
			ROUND(CASE WHEN iotta=0 OR ipages=0 THEN 0.0 ELSE ipages/iotta::numeric END,1) AS bloat,
			CASE WHEN ipages < iotta THEN '0' ELSE (bs*(ipages-iotta))::bigint END AS raw_waste
		FROM
			index_bloat) bloat_summary
		ORDER BY raw_waste DESC, bloat DESC
	EOF
}

query_pg-mandelbrot() { ## : show the mandlebrot set
	meta <<-EOF
		ADDED: 14
	EOF
	handle_help "$@" <<-EOF
		Copied from: https://github.com/heroku/heroku-pg-extras/tree/master/commands
	EOF

	read -r -d '' QUERY <<-EOF
		WITH RECURSIVE Z(IX, IY, CX, CY, X, Y, I) AS (
				SELECT IX, IY, X::float, Y::float, X::float, Y::float, 0
				FROM (select -2.2 + 0.031 * i, i from generate_series(0,101) as i) as xgen(x,ix),
					 (select -1.5 + 0.031 * i, i from generate_series(0,101) as i) as ygen(y,iy)
				UNION ALL
				SELECT IX, IY, CX, CY, X * X - Y * Y + CX AS X, Y * X * 2 + CY, I + 1
				FROM Z
				WHERE X * X + Y * Y < 16::float
				AND I < 100
		)
		SELECT array_to_string(array_agg(SUBSTRING(' .,,,-----++++%%%%@@@@#### ', LEAST(GREATEST(I,1),27), 1)),'')
		FROM (
			SELECT IX, IY, MAX(I) AS I
			FROM Z
			GROUP BY IY, IX
			ORDER BY IY, IX
		 ) AS ZT
		GROUP BY IY
		ORDER BY IY
	EOF
}

query_pg-index-usage() { ## : calculates your index hit rate (effective databases are at 99% and up)
	meta <<-EOF
		ADDED: 14
	EOF
	handle_help "$@" <<-EOF
		Originally from: https://github.com/heroku/heroku-pg-extras/tree/master/commands

		-1 means "Insufficient Data", this was changed to a numeric value to be acceptable to InfluxDB
	EOF

	fields="index_usage=1;rows=2"
	tags="relname=0"

	read -r -d '' QUERY <<-EOF
		SELECT relname,
			CASE COALESCE(idx_scan, 0)
				WHEN 0 THEN -1
				ELSE (100 * idx_scan / (seq_scan + idx_scan))
			END percent_of_times_index_used,
			n_live_tup rows_in_table
		 FROM
			pg_stat_user_tables
		ORDER BY
			n_live_tup DESC
	EOF
}

query_pg-index-size() { ##? [--human]: show table and index bloat in your database ordered by most wasteful
	meta <<-EOF
		ADDED: 14
	EOF
	handle_help "$@" <<-EOF
		Originally from: https://github.com/heroku/heroku-pg-extras/tree/master/commands
	EOF

	if [[ -n "$arg_human" ]]; then
		human_size="pg_size_pretty(sum(c.relpages::bigint*8192)::bigint)"
	else
		human_size="sum(c.relpages::bigint*8192)::bigint"
	fi

	fields="size=1"
	tags="relname=0"

	read -r -d '' QUERY <<-EOF
		SELECT
			c.relname AS name,
			$human_size AS size
		FROM pg_class c
		LEFT JOIN pg_namespace n ON (n.oid = c.relnamespace)
		WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
		AND n.nspname !~ '^pg_toast'
		AND c.relkind='i'
		GROUP BY c.relname
		ORDER BY sum(c.relpages) DESC
	EOF
}

query_pg-long-running-queries() { ## : show all queries longer than five minutes by descending duration
	meta <<-EOF
		ADDED: 14
	EOF
	handle_help "$@" <<-EOF
		Originally from: https://github.com/heroku/heroku-pg-extras/tree/master/commands
	EOF

	read -r -d '' QUERY <<-EOF
		SELECT
			pid,
			now() - pg_stat_activity.query_start AS duration,
			query AS query
		FROM
			pg_stat_activity
		WHERE
			pg_stat_activity.query <> ''::text
			AND state <> 'idle'
			AND now() - pg_stat_activity.query_start > interval '5 minutes'
		ORDER BY
			now() - pg_stat_activity.query_start DESC
	EOF

}

query_pg-table-size() { ##? [--human]: show the size of the tables (excluding indexes), descending by size
	meta <<-EOF
		ADDED: 14
	EOF
	handle_help "$@" <<-EOF
		Originally from: https://github.com/heroku/heroku-pg-extras/tree/master/commands
	EOF

	if [[ -n "$arg_human" ]]; then
		# TODO: there has got to be a less ugly way to do this
		human_size="pg_size_pretty("
		human_after=")"
	else
		human_size=""
		human_after=""
	fi

	fields="table_size=1;index_size=2"
	tags="relname=0"

	read -r -d '' QUERY <<-EOF
		SELECT
			c.relname AS name,
			${human_size}pg_table_size(c.oid)${human_after} AS size,
			${human_size}pg_indexes_size(c.oid)${human_after} AS index_size
		FROM pg_class c
		LEFT JOIN pg_namespace n ON (n.oid = c.relnamespace)
		WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
		AND n.nspname !~ '^pg_toast'
		AND c.relkind='r'
		ORDER BY pg_table_size(c.oid) DESC
	EOF
}

query_pg-unused-indexes() { ##? [--human]: show unused and almost unused indexes
	meta <<-EOF
		ADDED: 14
	EOF
	handle_help "$@" <<-EOF
		Originally from: https://github.com/heroku/heroku-pg-extras/tree/master/commands

		From their documentation:

		> "Ordered by their size relative to the number of index scans.
		> Exclude indexes of very small tables (less than 5 pages),
		> where the planner will almost invariably select a sequential scan,
		> but may not in the future as the table grows"
	EOF

	if [[ -n "$arg_human" ]]; then
		# TODO: there has got to be a less ugly way to do this
		human_size="pg_size_pretty("
		human_after=")"
	else
		human_size=""
		human_after=""
	fi

	fields="index_size=2;index_scans=3"
	tags="table=0;index=1"

	read -r -d '' QUERY <<-EOF
		SELECT
			schemaname || '.' || relname AS table,
			indexrelname AS index,
			${human_size}pg_relation_size(i.indexrelid)${human_after} AS index_size,
			COALESCE(idx_scan, 0) as index_scans
		FROM pg_stat_user_indexes ui
		JOIN pg_index i ON ui.indexrelid = i.indexrelid
		WHERE NOT indisunique AND idx_scan < 50 AND pg_relation_size(relid) > 5 * 8192
		ORDER BY
			pg_relation_size(i.indexrelid) / nullif(idx_scan, 0) DESC NULLS FIRST,
			pg_relation_size(i.indexrelid) DESC
	EOF
}

query_pg-vacuum-stats() { ## : show dead rows and whether an automatic vacuum is expected to be triggered
	meta <<-EOF
		ADDED: 14
	EOF
	handle_help "$@" <<-EOF
		Originally from: https://github.com/heroku/heroku-pg-extras/tree/master/commands
	EOF

	read -r -d '' QUERY <<-EOF
		WITH table_opts AS (
			SELECT
				pg_class.oid, relname, nspname, array_to_string(reloptions, '') AS relopts
			FROM
				 pg_class INNER JOIN pg_namespace ns ON relnamespace = ns.oid
		), vacuum_settings AS (
			SELECT
				oid, relname, nspname,
				CASE
					WHEN relopts LIKE '%autovacuum_vacuum_threshold%'
						THEN substring(relopts, '.*autovacuum_vacuum_threshold=([0-9.]+).*')::integer
						ELSE current_setting('autovacuum_vacuum_threshold')::integer
					END AS autovacuum_vacuum_threshold,
				CASE
					WHEN relopts LIKE '%autovacuum_vacuum_scale_factor%'
						THEN substring(relopts, '.*autovacuum_vacuum_scale_factor=([0-9.]+).*')::real
						ELSE current_setting('autovacuum_vacuum_scale_factor')::real
					END AS autovacuum_vacuum_scale_factor
			FROM
				table_opts
		)
		SELECT
			vacuum_settings.nspname AS schema,
			vacuum_settings.relname AS table,
			to_char(psut.last_vacuum, 'YYYY-MM-DD HH24:MI') AS last_vacuum,
			to_char(psut.last_autovacuum, 'YYYY-MM-DD HH24:MI') AS last_autovacuum,
			to_char(pg_class.reltuples, '9G999G999G999') AS rowcount,
			to_char(psut.n_dead_tup, '9G999G999G999') AS dead_rowcount,
			to_char(autovacuum_vacuum_threshold
					 + (autovacuum_vacuum_scale_factor::numeric * pg_class.reltuples), '9G999G999G999') AS autovacuum_threshold,
			CASE
				WHEN autovacuum_vacuum_threshold + (autovacuum_vacuum_scale_factor::numeric * pg_class.reltuples) < psut.n_dead_tup
				THEN 'yes'
			END AS expect_autovacuum
		FROM
			pg_stat_user_tables psut INNER JOIN pg_class ON psut.relid = pg_class.oid
				INNER JOIN vacuum_settings ON pg_class.oid = vacuum_settings.oid
		ORDER BY 1
	EOF
}

query_pg-stat-bgwriter() { ## : Stats about the behaviour of the bgwriter, checkpoints, buffers, etc.
	meta <<-EOF
		ADDED: 14
	EOF
	handle_help "$@" <<-EOF
	EOF

	fields="checkpoints_timed=0;checkpoints_req=1;checkpoint_write_time=2;checkpoint_sync_time=3;buffers_checkpoint=4;buffers_clean=5;maxwritten_clean=6;buffers_backend=7;buffers_backend_fsync=8;buffers_alloc=9"

	read -r -d '' QUERY <<-EOF
		SELECT
			checkpoints_timed,
			checkpoints_req,
			checkpoint_write_time,
			checkpoint_sync_time,
			buffers_checkpoint,
			buffers_clean,
			maxwritten_clean,
			buffers_backend,
			buffers_backend_fsync,
			buffers_alloc
		FROM
			pg_stat_bgwriter
	EOF
}


query_pg-stat-user-tables() { ## : stats about tables (tuples, index scans, vacuums, analyzes)
	meta <<-EOF
		ADDED: 14
	EOF
	handle_help "$@" <<-EOF
	EOF

	tags="schemaname=0;relname=1"
	fields="seq_scan=2;seq_tup_read=3;idx_scan=4;idx_tup_fetch=5;n_tup_ins=6;n_tup_upd=7;n_tup_del=8;n_tup_hot_upd=9;n_live_tup=10;n_dead_tup=11;vacuum_count=12;autovacuum_count=13;analyze_count=14;autoanalyze_count=15"

	read -r -d '' QUERY <<-EOF
		SELECT
			schemaname,
			relname,
			seq_scan,
			seq_tup_read,
			COALESCE(idx_scan, 0),
			COALESCE(idx_tup_fetch, 0),
			n_tup_ins,
			n_tup_upd,
			n_tup_del,
			n_tup_hot_upd,
			n_live_tup,
			n_dead_tup,
			vacuum_count,
			autovacuum_count,
			analyze_count,
			autoanalyze_count
		FROM
			pg_stat_user_tables
	EOF
}

query_data-origin-distribution-merged() {
	summary="$(summary_statistics data "$human")"
	username=$(gdpr_safe job.user_id galaxy_user)

	read -r -d '' QUERY <<-EOF
		WITH origins AS (
			SELECT
				'total' as origin,
				sum(coalesce(dataset.total_size, dataset.file_size, 0)) AS data,
				date_trunc('month', dataset.create_time) as created,
				$username
			FROM job
			LEFT JOIN job_to_output_dataset ON job.id = job_to_output_dataset.job_id
			LEFT JOIN history_dataset_association ON job_to_output_dataset.dataset_id = history_dataset_association.id
			LEFT JOIN dataset ON history_dataset_association.dataset_id = dataset.id
			GROUP BY
				origin, job.user_id, created, galaxy_user
		)
		SELECT
			origin,
			round(data, 2 - length(data::text)),
			created,
			galaxy_user
		FROM origins
		ORDER BY galaxy_user desc
	EOF
}

query_data-origin-distribution() { ## : data sources (uploaded vs derived)
	meta <<-EOF
		ADDED: 14
	EOF
	handle_help "$@" <<-EOF
		Break down the source of data in the server, uploaded data vs derived (created as output from a tool)

		Recommendation is to run with GDPR_MODE so you can safely share this information:

		    GDPR_MODE=\$(openssl rand -hex 24 2>/dev/null) gxadmin tsvquery data-origin-distribution | gzip > data-origin.tsv.gz

		Output looks like:

		    derived 130000000000    2019-07-01 00:00:00     fff4f423d06
		    derived 61000000000     2019-08-01 00:00:00     fff4f423d06
		    created 340000000       2019-08-01 00:00:00     fff4f423d06
		    created 19000000000     2019-07-01 00:00:00     fff4f423d06
		    derived 180000000000    2019-04-01 00:00:00     ffd28c0cf8c
		    created 21000000000     2019-04-01 00:00:00     ffd28c0cf8c
		    derived 1700000000      2019-06-01 00:00:00     ffd28c0cf8c
		    derived 120000000       2019-06-01 00:00:00     ffcb567a837
		    created 62000000        2019-05-01 00:00:00     ffcb567a837
		    created 52000000        2019-06-01 00:00:00     ffcb567a837
		    derived 34000000        2019-07-01 00:00:00     ffcb567a837

	EOF

	username=$(gdpr_safe job.user_id galaxy_user)
	echo "$username"

	read -r -d '' QUERY <<-EOF
		WITH data_status AS (
			SELECT
				case when job.tool_id = 'upload1' then 'created' else 'derived' end AS origin,
				sum(coalesce(dataset.total_size, dataset.file_size, 0)) AS data,
				date_trunc('month', dataset.create_time) as created,
				$username
			FROM job
			LEFT JOIN job_to_output_dataset ON job.id = job_to_output_dataset.job_id
			LEFT JOIN history_dataset_association ON job_to_output_dataset.dataset_id = history_dataset_association.id
			LEFT JOIN dataset ON history_dataset_association.dataset_id = dataset.id
			GROUP BY
				origin, job.user_id, created, galaxy_user
		)
		SELECT
			origin,
			round(data, 2 - length(data::text)),
			created,
			galaxy_user
		FROM data_status
		ORDER BY galaxy_user, created desc
	EOF
}

query_data-origin-distribution-summary() { ##? [--human]: breakdown of data sources (uploaded vs derived)
	meta <<-EOF
		ADDED: 14
	EOF
	handle_help "$@" <<-EOF
		Break down the source of data in the server, uploaded data vs derived (created as output from a tool)

		This query builds a table with the volume of derivced and uploaded data per user, and then summarizes this:

		origin  |   min   | quant_1st | median  |  mean  | quant_3rd | perc_95 | perc_99 |  max  | stddev
		------- | ------- | --------- | ------- | ------ | --------- | ------- | ------- | ----- | --------
		created | 0 bytes | 17 MB     | 458 MB  | 36 GB  | 11 GB     | 130 GB  | 568 GB  | 11 TB | 257 GB
		derived | 0 bytes | 39 MB     | 1751 MB | 200 GB | 28 GB     | 478 GB  | 2699 GB | 90 TB | 2279 GB
	EOF

	tags="dataorigin=0"
	fields="min=1;q1=2;median=3;mean=4;q3=5;p95=6;p99=7;max=8;sum=9;stddev=10"

	summary="$(summary_statistics data "$arg_human")"

	read -r -d '' QUERY <<-EOF
		WITH user_job_data AS (
			SELECT
				case when job.tool_id = 'upload1' then 'created' else 'derived' end AS origin,
				sum(coalesce(dataset.total_size, dataset.file_size, 0)) AS data,
				job.user_id
			FROM job
			LEFT JOIN job_to_output_dataset ON job.id = job_to_output_dataset.job_id
			LEFT JOIN history_dataset_association ON job_to_output_dataset.dataset_id = history_dataset_association.id
			LEFT JOIN dataset ON history_dataset_association.dataset_id = dataset.id
			GROUP BY
				origin, job.user_id
		)

		SELECT
			origin,
			$summary
		FROM user_job_data
		GROUP BY origin
	EOF
}

query_aq() { ## <table> <column> <-|job_id [job_id [...]]>: Given a list of IDs from a table (e.g. 'job'), access a specific column from that table
	meta <<-EOF
		ADDED: 15
	EOF
	handle_help "$@" <<-EOF
	EOF

	table=$1; shift
	column=$1; shift

	if [[ "$1" == "-" ]]; then
		# read jobs from stdin
		ids=$(cat | paste -s -d' ')
	else
		# read from $@
		ids=$*;
	fi

	# shellcheck disable=SC2068
	ids_string=$(join_by ',' ${ids[@]})

	read -r -d '' QUERY <<-EOF
		SELECT
			$column
		FROM $table
		WHERE id in ($ids_string)
	EOF
}

query_q() { ## <query>: Passes a raw SQL query directly through to the database
	handle_help "$@" <<-EOF
	EOF

	QUERY="$*"
}

query_good-for-pulsar() { ## : Look for jobs EU would like to send to pulsar
	meta <<-EOF
		ADDED: 15
	EOF
	handle_help "$@" <<-EOF
		This selects all jobs and finds two things:
		- sum of input sizes
		- runtime

		and then returns a simple /score/ of (input/runtime) and sorts on that
		hopefully identifying things with small inputs and long runtimes.
	EOF

	read -r -d '' QUERY <<-EOF
		WITH job_data AS (
			SELECT
				regexp_replace(j.tool_id, '.*toolshed.*/repos/', '') as tool_id,
				SUM(d.total_size) AS size,
				MIN(jmn.metric_value) AS runtime,
				SUM(d.total_size) / min(jmn.metric_value) AS score
			FROM job j
			LEFT JOIN job_to_input_dataset jtid ON j.id = jtid.job_id
			LEFT JOIN history_dataset_association hda ON jtid.dataset_id = hda.id
			LEFT JOIN dataset d ON hda.dataset_id = d.id
			LEFT JOIN job_metric_numeric jmn ON j.id = jmn.job_id
			WHERE jmn.metric_name = 'runtime_seconds'
				AND d.total_size IS NOT NULL
			GROUP BY j.id
		)

		SELECT
			tool_id,
			percentile_cont(0.50) WITHIN GROUP (ORDER BY score) ::bigint AS median_score,
			percentile_cont(0.50) WITHIN GROUP (ORDER BY runtime) ::bigint AS median_runtime,
			pg_size_pretty(percentile_cont(0.50) WITHIN GROUP (ORDER BY size) ::bigint) AS median_size,
			count(*)
		FROM job_data
		GROUP BY tool_id
		ORDER BY median_score ASC
	EOF
}

query_jobs-ready-to-run() { ## : Find jobs ready to run (Mostly a performance test)
	meta <<-EOF
		ADDED: 16
	EOF
	handle_help "$@" <<-EOF
		Mostly a performance test
	EOF

	read -r -d '' QUERY <<-EOF
		SELECT
			EXISTS(
				SELECT
					history_dataset_association.id,
					history_dataset_association.history_id,
					history_dataset_association.dataset_id,
					history_dataset_association.create_time,
					history_dataset_association.update_time,
					history_dataset_association.state,
					history_dataset_association.copied_from_history_dataset_association_id,
					history_dataset_association.copied_from_library_dataset_dataset_association_id,
					history_dataset_association.name,
					history_dataset_association.info,
					history_dataset_association.blurb,
					history_dataset_association.peek,
					history_dataset_association.tool_version,
					history_dataset_association.extension,
					history_dataset_association.metadata,
					history_dataset_association.parent_id,
					history_dataset_association.designation,
					history_dataset_association.deleted,
					history_dataset_association.visible,
					history_dataset_association.extended_metadata_id,
					history_dataset_association.version,
					history_dataset_association.hid,
					history_dataset_association.purged,
					history_dataset_association.hidden_beneath_collection_instance_id
				FROM
					history_dataset_association,
					job_to_output_dataset
				WHERE
					job.id = job_to_output_dataset.job_id
					AND history_dataset_association.id
						= job_to_output_dataset.dataset_id
					AND history_dataset_association.deleted = true
			)
				AS anon_1,
			EXISTS(
				SELECT
					history_dataset_collection_association.id
				FROM
					history_dataset_collection_association,
					job_to_output_dataset_collection
				WHERE
					job.id = job_to_output_dataset_collection.job_id
					AND history_dataset_collection_association.id
						= job_to_output_dataset_collection.dataset_collection_id
					AND history_dataset_collection_association.deleted
						= true
			)
				AS anon_2,
			job.id AS job_id,
			job.create_time AS job_create_time,
			job.update_time AS job_update_time,
			job.history_id AS job_history_id,
			job.library_folder_id AS job_library_folder_id,
			job.tool_id AS job_tool_id,
			job.tool_version AS job_tool_version,
			job.state AS job_state,
			job.info AS job_info,
			job.copied_from_job_id AS job_copied_from_job_id,
			job.command_line AS job_command_line,
			job.dependencies AS job_dependencies,
			job.param_filename AS job_param_filename,
			job.runner_name AS job_runner_name_1,
			job.job_stdout AS job_stdout,
			job.job_stderr AS job_stderr,
			job.exit_code AS job_exit_code,
			job.traceback AS job_traceback,
			job.session_id AS job_session_id,
			job.user_id AS job_user_id,
			job.job_runner_name AS job_job_runner_name,
			job.job_runner_external_id
				AS job_job_runner_external_id,
			job.destination_id AS job_destination_id,
			job.destination_params AS job_destination_params,
			job.object_store_id AS job_object_store_id,
			job.imported AS job_imported,
			job.params AS job_params,
			job.handler AS job_handler
		FROM
			job
		WHERE
			job.state = 'new'
			AND job.handler IS NULL
			AND job.handler = 'handler0'
	EOF
}

query_workers() { ## : Retrieve a list of Galaxy worker processes
	meta <<-EOF
		ADDED: 17
	EOF
	handle_help "$@" <<-EOF
		This retrieves a list of Galaxy worker processes.
		This functionality is only available on Galaxy
		20.01 or later.

		server_name         | hostname | pid
		------------------- | -------- | ---
		main.web.1          | server1  | 123
		main.job-handlers.1 | server2  | 456

	EOF

	read -r -d '' QUERY <<-EOF
		SELECT
			server_name,
			hostname,
			pid
		FROM
			worker_process
		WHERE
			pid IS NOT NULL
	EOF
}

query_pg-rows-per-table() { ## : Print rows per table
	meta <<-EOF
		ADDED: 17
	EOF
	handle_help "$@" <<-EOF
		This retrieves a list of tables in the database and their size
	EOF

	read -r -d '' QUERY <<-EOF
		SELECT
		    n.nspname AS table_schema,
		    c.relname AS table_name,
		    c.reltuples AS rows
		FROM
		    pg_class AS c
		    JOIN pg_namespace AS n ON
		            n.oid = c.relnamespace
		WHERE
		    c.relkind = 'r'
		    AND n.nspname
		        NOT IN (
		                'information_schema',
		                'pg_catalog'
		            )
		ORDER BY
		    c.reltuples DESC
	EOF
}

query_dump-users() { ##? [--apikey] [--email] : Dump the list of users and their emails
	meta <<-EOF
		ADDED: 19
	EOF
	handle_help "$@" <<-EOF
		This retrieves a list of all users
	EOF

	if [[ -n "$arg_email"  ]]; then
		email=",$(gdpr_safe email email)"
	else
		email=""
	fi

	if [[ -n "$arg_apikey"  ]]; then
		apikey="apikey"
		apikeyjoin="left join api_keys "
	else
		email=""
	fi

	read -r -d '' QUERY <<-EOF
		SELECT
			username
			$email
		FROM
			galaxy_user
		ORDER BY
		    id desc
	EOF
}

query_job-metrics() { ## : Retrieves input size, runtime, memory for all executed jobs
	meta <<-EOF
		ADDED: 19
	EOF
	handle_help "$@" <<-EOF
		Dump runtime stats for ALL jobs:

		    $ gxadmin query job-metrics
		    job_id  |               tool_id                |  state  | total_filesize | num_files | runtime_seconds |   slots   | memory_bytes |        create_time
		    --------+--------------------------------------+---------+----------------+-----------+-----------------+-----------+--------------+----------------------------
		    19      | require_format                       | ok      |           5098 |         1 |       4.0000000 | 1.0000000 |              | 2018-12-04 17:17:02.148239
		    48      | __SET_METADATA__                     | ok      |                |         0 |       4.0000000 | 1.0000000 |              | 2019-02-05 22:46:33.848141
		    49      | upload1                              | ok      |                |           |       6.0000000 | 1.0000000 |              | 2019-02-05 22:58:41.610146
		    50      | upload1                              | ok      |                |           |       5.0000000 | 1.0000000 |              | 2019-02-07 21:30:11.645826
		    51      | upload1                              | ok      |                |           |       5.0000000 | 1.0000000 |              | 2019-02-07 21:30:12.18259
		    52      | upload1                              | ok      |                |           |       7.0000000 | 1.0000000 |              | 2019-02-07 21:31:15.304868
		    54      | upload1                              | ok      |                |           |       5.0000000 | 1.0000000 |              | 2019-02-07 21:31:16.116164
		    53      | upload1                              | ok      |                |           |       7.0000000 | 1.0000000 |              | 2019-02-07 21:31:15.665948
			...
		    989     | circos                               | error   |         671523 |        12 |      14.0000000 | 1.0000000 |              | 2020-04-30 10:13:33.872872
		    990     | circos                               | error   |         671523 |        12 |      10.0000000 | 1.0000000 |              | 2020-04-30 10:19:36.72646
		    991     | circos                               | error   |         671523 |        12 |      10.0000000 | 1.0000000 |              | 2020-04-30 10:21:00.460471
		    992     | circos                               | ok      |         671523 |        12 |      21.0000000 | 1.0000000 |              | 2020-04-30 10:31:35.366913
		    993     | circos                               | error   |         588747 |         6 |       8.0000000 | 1.0000000 |              | 2020-04-30 11:12:17.340591
		    994     | circos                               | error   |         588747 |         6 |       9.0000000 | 1.0000000 |              | 2020-04-30 11:15:27.076502
		    995     | circos                               | error   |         588747 |         6 |      42.0000000 | 1.0000000 |              | 2020-04-30 11:16:41.19449
		    996     | circos                               | ok      |         588747 |         6 |      48.0000000 | 1.0000000 |              | 2020-04-30 11:21:51.49684
		    997     | circos                               | ok      |         588747 |         6 |      46.0000000 | 1.0000000 |              | 2020-04-30 11:23:52.455536

		**WARNING**

		!> This can be very slow for large databases and there is no tool filtering; every job + dataset table record are scanned.
	EOF

	read -r -d '' QUERY <<-EOF
		WITH dataset_filesizes AS (
			SELECT
				job_to_input_dataset.job_id, sum(file_size) AS total_filesize,
				count(file_size) AS num_files FROM dataset
			LEFT JOIN job_to_input_dataset ON dataset.id = job_to_input_dataset.dataset_id
			GROUP BY job_to_input_dataset.job_id
		)

		SELECT
			job.id AS job_id,
			job.tool_id,
			job.state,
			dataset_filesizes.total_filesize,
			dataset_filesizes.num_files,
			jmn1.metric_value AS runtime_seconds,
			jmn2.metric_value AS slots,
			jmn3.metric_value AS memory_bytes,
			job.create_time AS create_time
		FROM job
		LEFT JOIN dataset_filesizes ON job.id = dataset_filesizes.job_id
		LEFT JOIN (SELECT * FROM job_metric_numeric WHERE job_metric_numeric.metric_name = 'runtime_seconds') jmn1 ON jmn1.job_id = job.id
		LEFT JOIN (SELECT * FROM job_metric_numeric WHERE job_metric_numeric.metric_name = 'galaxy_slots') jmn2 ON jmn2.job_id = job.id
		LEFT JOIN (SELECT * FROM job_metric_numeric WHERE job_metric_numeric.metric_name = 'memory.memsw.max_usage_in_bytes') jmn3 ON jmn3.job_id = job.id
	EOF
}

query_history-core-hours()  { ##? [history-name-ilike]: Produces the median core hour count for histories matching a name filter
	meta <<-EOF
		ADDED: 19
	EOF
	handle_help "$@" <<-EOF
	EOF

	read -r -d '' QUERY <<-EOF
		WITH
			toolavg
				AS (
					SELECT
						tool_id, history_id, round(sum(a.metric_value * b.metric_value / 3600), 2) AS cpu_hours
					FROM
						job_metric_numeric AS a, job_metric_numeric AS b, job
					WHERE
						b.job_id = a.job_id
						AND a.job_id = job.id
						AND a.metric_name = 'runtime_seconds'
						AND b.metric_name = 'galaxy_slots'
						AND history_id in (select id from history where name ilike '%$arg_history_name_ilike%')
					GROUP BY
						tool_id, history_id
				),
			toolmedian
				AS (
					SELECT
						toolavg.tool_id, percentile_cont(0.5) WITHIN GROUP (ORDER BY cpu_hours)
					FROM
						toolavg
					GROUP BY
						toolavg.tool_id
				)
		SELECT
			sum(toolmedian.percentile_cont)
		FROM
			toolmedian
	EOF
}

query_pulsar-gb-transferred()  { ##? [--bymonth] [--byrunner] [--human]: Counts up datasets transferred and output file size produced by jobs running on destinations like pulsar_*
	meta <<-EOF
		ADDED: 19
	EOF
	handle_help "$@" <<-EOF
	EOF

	orderby=""
	declare -a ordering

	if [[ -n "$arg_bymonth" ]]; then
		orderby="ORDER BY sent.month ASC"
		ordering+=("sent.month")
	fi

	if [[ -n "$arg_byrunner" ]]; then
		if [[ -z "$arg_bymonth" ]]; then
			orderby="ORDER BY sent.runner ASC"
		fi
		ordering+=("sent.runner")
	fi

	if [[ -n "$arg_human" ]]; then
		pg_size_pretty_a="pg_size_pretty("
		pg_size_pretty_b=")"
	fi

	groupby=""
	data_string="${ordering[*]}"
	csvcols="${data_string//${IFS:0:1}/,}"
	if (( ${#ordering[@]} > 0 )); then
		groupby="GROUP BY $csvcols"
		csvcols="$csvcols,"
	fi

	read -r -d '' QUERY <<-EOF
		WITH
			sent
				AS (
					SELECT
						job.id AS job,
						date_trunc('month', job.create_time)::DATE AS month,
						job.job_runner_name AS runner,
						ds_in.total_size AS size
					FROM
						job
						LEFT JOIN job_to_input_dataset AS jtid ON job.id = jtid.job_id
						LEFT JOIN history_dataset_association AS hda_in ON jtid.dataset_id = hda_in.id
						LEFT JOIN dataset AS ds_in ON hda_in.dataset_id = ds_in.id
					WHERE
						job_runner_name LIKE 'pulsar%'
					ORDER BY
						job.id DESC
				),
			recv
				AS (
					SELECT
						job.id AS job,
						date_trunc('month', job.create_time)::DATE AS month,
						job.job_runner_name AS runner,
						ds_out.total_size AS size
					FROM
						job
						LEFT JOIN job_to_output_dataset AS jtid ON job.id = jtid.job_id
						LEFT JOIN history_dataset_association AS hda_out ON jtid.dataset_id = hda_out.id
						LEFT JOIN dataset AS ds_out ON hda_out.dataset_id = ds_out.id
					WHERE
						job_runner_name LIKE 'pulsar%'
					ORDER BY
						job.id DESC
				)
		SELECT
			$csvcols ${pg_size_pretty_a}sum(sent.size)${pg_size_pretty_b} AS sent, ${pg_size_pretty_a}sum(recv.size)${pg_size_pretty_b} AS recv, count(sent.size) as sent_count, count(recv.size) as recv_count
		FROM
			sent FULL JOIN recv ON sent.job = recv.job
		$groupby
		$orderby
	EOF
}

query_largest-dataset-users() { ##? [--human] [--deleted] [--purged] [--format-uuid]: Get largest datasets by users
	meta <<-EOF
		ADDED: 19
	EOF
	handle_help "$@" <<-EOF
		Optionally includes deleted and purged datasets

		    $ gxadmin query largest-dataset-users --human
		                   uuid               | job_id | file_size | total_size |  username  | id  |      history_name       |                     hda_name
		    ----------------------------------+--------+-----------+------------+------------+-----+-------------------------+---------------------------------------------------
		     a18fed2a9d4d4f66b301b48c4c6ed720 |   6995 | 220 GB    | 220 GB     | alice      | 269 | B1MG_Case5_IC           | EGA Download Client: EGAF00005572869
		     a18fed2a9d4d4f66b301b48c4c6ed720 |   6995 | 220 GB    | 220 GB     | beth       | 280 | imported: B1MG_Case5_IC | EGA Download Client: EGAF00005572869
		     a18fed2a9d4d4f66b301b48c4c6ed720 |   6995 | 220 GB    | 220 GB     | beth       | 284 | HTSGET                  | Case 5 Child BAM (EGAF00005572869)

		here you can see another user has imported this single large dataset multiple times.

	EOF

	username=$(gdpr_safe galaxy_user.username username)

	if [[ -n "$arg_human" ]]; then
		sizes="pg_size_pretty(dataset.file_size) as file_size, pg_size_pretty(dataset.total_size) as total_size"
	else
		sizes="dataset.file_size as file_size, dataset.total_size as total_size"
	fi

	if [[ -n "$arg_deleted" ]]; then
		deleted=""
	else
		deleted="AND dataset.deleted = false"
	fi

	if [[ -n "$arg_purged" ]]; then
		purged=""
	else
		purged="AND dataset.purged = false"
	fi

	if [[ -n "$arg_format_uuid" ]]; then
		uuid="REGEXP_REPLACE(dataset.uuid, '(........)(....)(....)(....)(............)', '\1-\2-\3-\4-\5')"
	else
		uuid="dataset.uuid"
	fi

	read -r -d '' QUERY <<-EOF
		WITH
			top_datasets AS (
				SELECT id
				FROM dataset
				WHERE total_size IS NOT NULL
					$deleted
					$purged
				ORDER BY total_size
				DESC LIMIT 30
			)
		SELECT
			$uuid,
			job_id as job_id,
			$sizes,
			$username,
			history.id,
			history.name as history_name,
			history_dataset_association.name as hda_name
		FROM
			top_datasets
			LEFT JOIN dataset ON top_datasets.id = dataset.id
			LEFT JOIN history_dataset_association ON history_dataset_association.dataset_id = top_datasets.id
			LEFT JOIN history ON history_dataset_association.history_id = history.id
			LEFT JOIN job ON dataset.job_id = job.id
			LEFT JOIN galaxy_user ON history.user_id = galaxy_user.id
	EOF
}

query_dataset-usage-and-imports() { ##? <dataset_uuid>: Fetch limited information about which users and histories are using a specific dataset from disk.
	meta <<-EOF
		ADDED: 19
	EOF
	handle_help "$@" <<-EOF
		This has built in support for "cleaning up" paths like /data/galaxy/.../dataset_<uuid>.dat into just the properly formatted UUID. It will also strip - characters from the uuid if present.
		    $ gxadmin query dataset-usage-and-imports /data/galaxy/b/8/4/dataset_b8482e38-0e6f-4871-92ee-a699458f18a5.dat
		      id  | job_id | history_id | user_id | username |              name              |  name
		    ------+--------+------------+---------+----------+--------------------------------+---------
		     3338 |        |         93 |       6 | alice    | transient vector vs normal M14 | sources
		    (1 row)

	EOF

	cleaned_dataset_uuid=$(echo "$arg_dataset_uuid" | sed 's/.*dataset_//g;s/\.dat$//g;s/-//g')

	read -r -d '' QUERY <<-EOF
		SELECT
			dataset.id, job_id, history_id, history.user_id,
			galaxy_user.username, history.name,
			history_dataset_association.name
		FROM
			dataset
			LEFT JOIN history_dataset_association ON dataset.id = history_dataset_association.dataset_id
			LEFT JOIN history ON history_dataset_association.history_id = history.id
			LEFT JOIN galaxy_user ON history.user_id = galaxy_user.id
		WHERE
			uuid = '$cleaned_dataset_uuid'
	EOF
}

query_dataset-count() { ##? [date] : Count the number of datasets.
	meta <<-EOF
		ADDED: 23
	EOF
	handle_help "$@" <<-EOF
		Count total number of datasets. Providing optional date (as YYYY-MM-DD) counts
		number of datasets created up to that date.

			$ gxadmin query dataset-count
			 num_datasets
			---------------
				 107615974
			(1 row)
	EOF

	where=""
	if [[ -n $arg_date ]]; then
		where="WHERE create_time < '$arg_date'"
	fi

	read -r -d '' QUERY <<-EOF
		SELECT
			count(*) as num_datasets
		FROM
			dataset
		$where
	EOF
}

query_queue-details-drm() { ##? [--all] [--seconds] [--since-update]: Detailed overview of running and queued jobs with cores/mem info
	meta <<-EOF
		ADDED: 20
	EOF
	handle_help "$@" <<-EOF
		This is a copy of gxadmin query queue-detail with job destination info (cores/mem/partition) added and runner_id, count removed

		    $ gxadmin query queue-details-drm
		           state  |  id  | extid |								  tool_id								  | username | time_since_creation |		 handler		 | cores | mem  | partition | destination_id
		    ---------+------+-------+-----------------------------------------------------------+----------+---------------------+---------------------+-------+------+-----------+-----------------
		     running | 4385 | 4011  | upload1																	| cat		| 00:01:01.518932	  | main.job-handlers.2 | 2	  | 6144 |			  | slurm
		     queued  | 4387 | 4012  | toolshed.g2.bx.psu.edu/repos/devteam/bwa/bwa_mem/0.7.17.2 | cat		| 00:00:24.377336	  | main.job-handlers.2 | 1	  | 3072 |			  | slurm
		     queued  | 4388 | 4388  | toolshed.g2.bx.psu.edu/repos/devteam/bwa/bwa_mem/0.7.17.2 | cat		| 00:00:13.254505	  | main.job-handlers.1 | 1	  | 3072 |			  | pulsar-nci-test
		     queued  | 4389 | 4013  | toolshed.g2.bx.psu.edu/repos/devteam/bwa/bwa_mem/0.7.17.2 | cat		| 00:00:01.834048	  | main.job-handlers.2 | 1	  | 3072 |			  | slurm
	EOF

	fields="count=9"
	tags="state=0;id=1;extid=2;tool_id=3;username=4;handler=6;job_runner_name=7;destination_id=8"

	d=""
	nonpretty="("
	time_column="job.create_time"
	time_column_name="time_since_creation"

	if [[ -n "$arg_all" ]]; then
			  d=", 'new'"
	fi
	if [[ -n "$arg_seconds" ]]; then
			  fields="$fields;time_since_creation=5"
			  nonpretty="EXTRACT(EPOCH FROM "
	fi
	if [[ -n "$arg_since_update" ]]; then
			  time_column="job.update_time"
			  time_column_name="time_since_update"
	fi

	username=$(gdpr_safe galaxy_user.username username "Anonymous User")

	read -r -d '' QUERY <<-EOF
		WITH
			job_data
				AS (
					SELECT
						job.state as jobstate,
						job.id as jobid,
						job.job_runner_external_id as extid,
						job.tool_id as toolid,
						$username,
						$nonpretty now() AT TIME ZONE 'UTC' - $time_column) as $time_column_name,
						job.handler as handler,
						(REGEXP_MATCHES(encode(job.destination_params, 'escape'), 'ntasks=(\d+)'))[1] as cpu_slurm,
						(REGEXP_MATCHES(encode(job.destination_params, 'escape'), '\"request_cpus\":\s+\"(\d+)\"'))[1] as cpu_condor,
						(REGEXP_MATCHES(encode(job.destination_params, 'escape'), 'mem=(\d+)'))[1] as mem_slurm,
						(REGEXP_MATCHES(encode(job.destination_params, 'escape'), '\"request_memory\":\s+\"([0-9.]+)G\"'))[1] as mem_condor,
						(REGEXP_MATCHES(encode(job.destination_params, 'escape'), 'partition=(\w+)'))[1] as partition_slurm,
						(REGEXP_MATCHES(encode(job.destination_params, 'escape'), '\"requirements\":\s+\".*\", '))[1] as partition_condor,
						COALESCE(job.destination_id, 'none') as destination_id
					FROM job
						FULL OUTER JOIN galaxy_user ON job.user_id = galaxy_user.id
					WHERE
						state in ('running', 'queued'$d)
					ORDER BY
						state desc,
						$time_column_name desc
				)
		SELECT
			jobstate,
			jobid,
			extid,
			toolid,
			username,
			$time_column_name,
			handler,
			COALESCE(mem_slurm, mem_condor) as mem,
			COALESCE(cpu_slurm, cpu_condor) as cpu,
			COALESCE(partition_slurm, partition_condor) as partition
		FROM
			job_data
	EOF
}

query_jobs() { ##? [--tool=] [--destination=] [--limit=50] [--states=<comma,sep,list>] [--user=] [--terminal] [--nonterminal]: List jobs ordered by most recently updated. = is required.
	handle_help "$@" <<-EOF
		Displays a list of jobs ordered from most recently updated, which can be filtered by states, destination_id,
		tool_id or user. By default up to 50 rows are returned which can be adjusted with the --limit or -l flag.

		    $ gxadmin query jobs --destination=pulsar-nci-test
		      id   |     create_time     |     update_time     | user_id |  state  |                                           tool_id                                           |  handler  |         destination         | external_id
		    -------+---------------------+---------------------+---------+---------+---------------------------------------------------------------------------------------------+-----------+-----------------------------+-------------
		     14701 | 2022-10-31 00:54:43 | 2022-10-31 00:55:02 |      16 | ok      | toolshed.g2.bx.psu.edu/repos/devteam/bwa/bwa_mem/0.7.17.2                                   | handler_0 | pulsar-nci-test             | 14701
		     14700 | 2022-10-31 00:53:45 | 2022-10-31 00:54:04 |      16 | ok      | toolshed.g2.bx.psu.edu/repos/devteam/fastqc/fastqc/0.71                                     | handler_0 | pulsar-nci-test             | 14700
		     14588 | 2022-10-19 10:45:42 | 2022-10-19 10:46:01 |      16 | ok      | toolshed.g2.bx.psu.edu/repos/devteam/bwa/bwa_mem/0.7.17.2                                   | handler_2 | pulsar-nci-test             | 14588
		     14584 | 2022-10-19 10:45:12 | 2022-10-19 10:45:31 |      16 | ok      | toolshed.g2.bx.psu.edu/repos/devteam/bwa/bwa_mem/0.7.17.2                                   | handler_2 | pulsar-nci-test             | 14584
		     14580 | 2022-10-19 10:44:43 | 2022-10-19 10:45:02 |      16 | ok      | toolshed.g2.bx.psu.edu/repos/devteam/bwa/bwa_mem/0.7.17.2                                   | handler_2 | pulsar-nci-test             | 14580

		    $ gxadmin query jobs --destination=pulsar-nci-test --tool=bionano
		      id   |     create_time     |     update_time     | user_id | state |                                        tool_id                                         |       handler       |         destination         | external_id
		    -------+---------------------+---------------------+---------+-------+----------------------------------------------------------------------------------------+---------------------+-----------------------------+-------------
		     14085 | 2022-09-08 07:44:48 | 2022-09-08 08:21:58 |       3 | ok    | toolshed.g2.bx.psu.edu/repos/bgruening/bionano_scaffold/bionano_scaffold/3.6.1+galaxy3 | handler_2           | pulsar-nci-test             | 14085
		     14080 | 2022-09-08 07:00:14 | 2022-09-08 07:44:31 |       3 | ok    | toolshed.g2.bx.psu.edu/repos/bgruening/bionano_scaffold/bionano_scaffold/3.6.1+galaxy3 | handler_0           | pulsar-nci-test             | 14080
		     14076 | 2022-09-08 06:15:37 | 2022-09-08 06:59:59 |       3 | error | toolshed.g2.bx.psu.edu/repos/bgruening/bionano_scaffold/bionano_scaffold/3.6.1+galaxy3 | handler_2           | pulsar-nci-test             | 14076
		     14071 | 2022-09-08 05:38:25 | 2022-09-08 06:15:22 |       3 | error | toolshed.g2.bx.psu.edu/repos/bgruening/bionano_scaffold/bionano_scaffold/3.6.1+galaxy3 | handler_1           | pulsar-nci-test             | 14071
	EOF

	tool_id_substr="${arg_tool}"
	destination_id_substr="${arg_destination}"
	states="${arg_states}"

	if [[ -n "$arg_user" ]]; then
		user_filter=" AND $(get_user_filter "$arg_user")"
	fi
	if [[ -n "$arg_terminal" ]]; then
		states="ok,deleted,error"
	fi
	if [[ -n "$arg_nonterminal" ]]; then
		states="new,queued,running"
	fi

	state_filter=
	if [[ "$states" ]]; then
		states="'$(echo "$states" | sed "s/,/', '/g")'"
		state_filter="AND job.state IN (${states})"
	fi

	destination_filter=
	if [[ -n "$destination_id_substr" ]]; then
		destination_filter="AND job.destination_id ~ '${destination_id_substr}'";
	fi

	read -r -d '' QUERY <<-EOF
			SELECT
				job.id as job_id,
				job.create_time::timestamp(0) as create_time,
				job.update_time::timestamp(0) as update_time,
				job.user_id as user_id,
				job.state as state,
				job.tool_id as tool_id,
				job.handler as handler,
				job.destination_id as destination,
				job.job_runner_external_id as external_id
			FROM job
			LEFT OUTER JOIN
				galaxy_user ON job.user_id = galaxy_user.id
			WHERE job.tool_id ~ '$tool_id_substr' ${destination_filter} ${state_filter} $user_filter
			ORDER BY job.update_time desc
			LIMIT $arg_limit
	EOF
}

query_large-old-histories() { ##? [--older-than=30] [--limit=30] [--larger-than=1073741824]: Find large, old histories that probably should be deleted.
	meta <<-EOF
		ADDED: 21
		AUTHORS: hexylena
	EOF
	handle_help "$@" <<-EOF
		Find large, easily deletable histories. This makes a nice list to give
		your colleagues and say "do you really need that?"
	EOF

	read -r -d '' QUERY <<-EOF
		WITH
			cte
				AS (
					SELECT
						sum(COALESCE(dataset.total_size, dataset.file_size, 0)) AS total_size,
						date_trunc('day', now() - history.update_time) AS untouched_in,
						history.id AS history_id,
						history.name AS history_name,
						COALESCE(galaxy_user.username::text, '__UNKNOWN__') AS username
					FROM
						dataset
						JOIN history_dataset_association ON dataset.id = history_dataset_association.dataset_id
						JOIN history ON history_dataset_association.history_id = history.id
						JOIN galaxy_user ON history.user_id = galaxy_user.id
					WHERE
						history.deleted = false AND total_size > ${arg_larger_than} AND (now() - history.update_time) > '${arg_older_than} days'::INTERVAL
					GROUP BY
						history.id, history.name, history.user_id, galaxy_user.username
				)
		SELECT
			history_id, history_name, username, pg_size_pretty(total_size) AS size, untouched_in
		FROM
			cte
		ORDER BY
			total_size DESC
		LIMIT ${arg_limit}
	EOF
}

query_potentially-duplicated-datasets() { ##? [--show-names] [--show-uuids] [--limit=50] [--min-considered-size=100000000]: Find duplicated datasets in your database "cheaply" (i.e. by unique(user+file_size))
	meta <<-EOF
		ADDED: 21
		AUTHORS: hexylena
	EOF
	handle_help "$@" <<-EOF
		Sometimes your colleagues will re-upload the same file over and over
		and over again.

		This will help you find the duplicated datasets. It works best for
		larger files where the number of bytes is more likely to be a "unique"
		identifier.

		The minimum considered size is a first-pass filter to only find large
		(and thus more likely to be unique based solely on byte count) files.
		Lowering this will likely increase your false positives.
	EOF

	show_names=""
	if [[ -n "$arg_show_names" ]]; then
		show_names=",unique_dupe_names"
	fi

	show_uuids=""
	if [[ -n "$arg_show_uuids" ]]; then
		show_uuids=",unique_dupe_uuids"
	fi

	read -r -d '' QUERY <<-EOF
		WITH
			cte
				AS (
					SELECT
						array_agg(ds.uuid) AS dupe_uuids,
						array_agg(hda.name) AS dupe_names,
						ds.file_size AS size,
						job.user_id AS user_id,
						count(*) AS count
					FROM
						dataset AS ds LEFT JOIN job ON ds.job_id = job.id LEFT JOIN history_dataset_association AS hda ON hda.dataset_id = ds.id
					WHERE
						ds.file_size > $arg_min_considered_size AND ds.deleted = false
					GROUP BY
						ds.file_size, ds.total_size, job.user_id
					ORDER BY
						count DESC
				),
			cte2
				AS (
					SELECT
						ARRAY (SELECT DISTINCT * FROM ROWS FROM (unnest(dupe_uuids))) AS unique_dupe_uuids,
						ARRAY (SELECT DISTINCT * FROM ROWS FROM (unnest(dupe_names))) AS unique_dupe_names,
						array_length(ARRAY (SELECT DISTINCT * FROM ROWS FROM (unnest(dupe_uuids))), 1) AS true_dupes,
						size,
						user_id,
						count
					FROM
						cte
					WHERE
						array_length(ARRAY (SELECT DISTINCT * FROM ROWS FROM (unnest(dupe_uuids))), 1) > 1
				)
		SELECT
			size AS bytes,
			pg_size_pretty(size) AS size,
			user_id,
			true_dupes AS identical_copies,
			pg_size_pretty((true_dupes - 1) * size) AS wasted_space
			$show_names
			$show_uuids
		FROM
			cte2
		WHERE
			count > 1
		ORDER BY
			((true_dupes - 1) * size) DESC
		LIMIT $arg_limit
	EOF
}

query_potentially-duplicated-reclaimable-space() { ##?
	meta <<-EOF
		ADDED: 21
		AUTHORS: hexylena
	EOF
	handle_help "$@" <<-EOF
		Sometimes your colleagues will re-upload the same file over and over
		and over again.

		This will help you find the total potential reclaimable space, if you de-duplicate.
	EOF

	read -r -d '' QUERY <<-EOF
		WITH
			cte
				AS (
					SELECT
						array_agg(ds.uuid) AS dupe_uuids, array_agg(hda.name) AS dupe_names, ds.file_size AS size, job.user_id AS user_id, count(*) AS count
					FROM
						dataset AS ds LEFT JOIN job ON ds.job_id = job.id LEFT JOIN history_dataset_association AS hda ON hda.dataset_id = ds.id
					WHERE
						ds.file_size > 100000000 AND ds.deleted = false
					GROUP BY
						ds.file_size, ds.total_size, job.user_id
					ORDER BY
						count DESC
				),
			cte2
				AS (
					SELECT
						ARRAY (SELECT DISTINCT * FROM ROWS FROM (unnest(dupe_uuids))) AS unique_dupe_uuids,
						array_length(ARRAY (SELECT DISTINCT * FROM ROWS FROM (unnest(dupe_uuids))), 1) AS true_dupes,
						size,
						user_id,
						count
					FROM
						cte
					WHERE
						array_length(ARRAY (SELECT DISTINCT * FROM ROWS FROM (unnest(dupe_uuids))), 1) > 1
				)
		SELECT
				pg_size_pretty(sum((true_dupes - 1) * size)) as potentially_reclaimable_space
		FROM
			cte2
		WHERE
			true_dupes > 1
	EOF
}

query_tpt-tool-cpu() { ##? [--startyear=<YYYY>] [--endyear=<YYYY>] [--formula=avg]: Start year is required. Formula returns sum if blank.
	meta <<-EOF
		AUTHORS: hujambo-dunia
		ADDED: 20
	EOF
	handle_help "$@" <<-EOF
		Tool Performance Tracking: CPU by Month-Year.

		    $ gxadmin tpt-tool-cpu
		              tool_id          |   month    | seconds | destination_id
		    ---------------------------+------------+--------------------------
		     circos                    | 2019-02-01 | 2329342 | multicore
		     upload1                   | 2019-02-01 | 1243878 | multicore
		     require_format            | 2019-02-01 |  933630 | multicore
		     circos_gc_skew            | 2019-02-01 |  752233 | multicore
		     circos_wiggle_to_scatter  | 2019-02-01 |  337924 | normal
		     test_history_sanitization | 2019-02-01 |  246521 | normal
		     circos_interval_to_tile   | 2019-02-01 |  109382 | normal
		     __SET_METADATA__          | 2019-02-01 |   82791 | normal
		    (8 rows)
	EOF

	filter_by_time_period=""
	if [[ -n $arg_startyear ]]; then
		filter_by_time_period="date_trunc('year', job.create_time AT TIME ZONE 'UTC') >= '$arg_startyear-01-01'::date"
	fi
	if [[ -n $arg_endyear ]]; then
		arg_endyear=$((arg_endyear + 1))
		filter_by_time_period=$filter_by_time_period "AND date_trunc('year', job.create_time AT TIME ZONE 'UTC') < '$arg_endyear-01-01'::date"
	fi

	if [[ "$arg_formula" == "avg" ]]; then
		sql_formula="AVG"
	else
		sql_formula="SUM"
	fi

	read -r -d '' QUERY <<-EOF
		WITH cpu_usage AS (
			SELECT
				DISTINCT job_id,
				destination_id,
				metric_value / 1000000000 AS cpu_usage_seconds
			FROM
				job_metric_numeric
			WHERE
				metric_name = 'cpuacct.usage'
		)
		SELECT
			job.tool_id,
			date_trunc('month', job.create_time) AS month,
			cpu_usage.destination_id,
			ROUND($sql_formula(cpu_usage.cpu_usage_seconds), 0) AS seconds
		FROM
			job
			JOIN cpu_usage ON job.id = cpu_usage.job_id
		WHERE
			$filter_by_time_period
		GROUP BY
			month,
			job.tool_id
		ORDER BY
			month ASC,
			seconds DESC
	EOF
}

query_tpt-tool-users() { ##? [--startyear=<YYYY>] [--endyear=<YYYY>]: Start year is required.
	meta <<-EOF
		AUTHORS: hujambo-dunia
		ADDED: 20
	EOF
	handle_help "$@" <<-EOF
		Tool Performance Tracking: Users by Month-Year.

		    $ gxadmin tpt-tool-users
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

	filter_by_time_period=""
	if [[ -n $arg_startyear ]]; then
		filter_by_time_period="date_trunc('year', job.create_time AT TIME ZONE 'UTC') >= '$arg_startyear-01-01'::date"
	fi
	if [[ -n $arg_endyear ]]; then
		arg_endyear=$((arg_endyear + 1))
		filter_by_time_period=$filter_by_time_period "AND date_trunc('year', job.create_time AT TIME ZONE 'UTC') < '$arg_endyear-01-01'::date"
	fi

	read -r -d '' QUERY <<-EOF
		SELECT
			tool_id,
			date_trunc('month', job.create_time AT TIME ZONE 'UTC') AS month,
			COUNT(DISTINCT galaxy_user.username) AS count
		FROM
			job
		FULL OUTER JOIN galaxy_user ON job.user_id = galaxy_user.id
		WHERE
			$filter_by_time_period
		GROUP BY
			month,
			tool_id
		ORDER BY
			month ASC,
			count DESC
	EOF
}

query_tpt-tool-memory() { ##? [--startyear=<YYYY>] [--endyear=<YYYY>] [--formula=avg]: Start year is required. Formula returns sum if blank.
	meta <<-EOF
		AUTHORS: hujambo-dunia
		ADDED: 20
	EOF
	handle_help "$@" <<-EOF
		Tool Performance Tracking: Memory by Month-Year.

		    $ gxadmin tpt-tool-users
		              tool_id          |   month    | consumed_gigabytes
		    ---------------------------+------------+-------------------
		     circos                    | 2019-02-01 |              24234
		     upload1                   | 2019-02-01 |              12435
		     require_format            | 2019-02-01 |               9535
		     circos_gc_skew            | 2019-02-01 |               7163
		     circos_wiggle_to_scatter  | 2019-02-01 |               3053
		     test_history_sanitization | 2019-02-01 |               2390
		     circos_interval_to_tile   | 2019-02-01 |               1315
		     __SET_METADATA__          | 2019-02-01 |               1623
		    (8 rows)
	EOF

	filter_by_time_period=""
	if [[ -n $arg_startyear ]]; then
		filter_by_time_period="date_trunc('year', job.create_time AT TIME ZONE 'UTC') >= '$arg_startyear-01-01'::date"
	fi
	if [[ -n $arg_endyear ]]; then
		arg_endyear=$((arg_endyear + 1))
		filter_by_time_period=$filter_by_time_period "AND date_trunc('year', job.create_time AT TIME ZONE 'UTC') < '$arg_endyear-01-01'::date"
	fi

	if [[ "$arg_formula" == "avg" ]]; then
		sql_formula="AVG"
	else
		sql_formula="SUM"
	fi

	read -r -d '' QUERY <<-EOF
		WITH consumed_mem AS (
			SELECT
				DISTINCT job_id,
				metric_value
			FROM
				job_metric_numeric
			WHERE
				metric_name = 'memory.memsw.max_usage_in_bytes'
		)
		SELECT
			tool_id,
			date_trunc('month', job.create_time AT TIME ZONE 'UTC') AS month,
			ROUND($sql_formula(metric_value) * 0.000000001, 0) AS consumed_gigabytes
		FROM
			job
			JOIN consumed_mem ON job.id = consumed_mem.job_id
		WHERE
			$filter_by_time_period
		GROUP BY
			month,
			tool_id
		ORDER BY
			month ASC,
			consumed_gigabytes DESC
	EOF
}

query_tools-usage-per-month() { ##? [--startmonth=<YYYY>-<MM>] [--endmonth=<YYYY>-<MM>] [--tools=<tool1,tool2,...>] [--short_tool_id] [--super_short_tool_id] [--no_version]: By default, startmonth is 1 year ago and end month is current month. tool1, tool2 etc. should correspond to the tool_id with the same format as requested: toolshed.g2.bx.psu.edu/repos/devteam/bowtie2/bowtie2/2.5.0+galaxy0,Cut1 for default, devteam/bowtie2/bowtie2/2.5.0+galaxy0,Cut1 for --short_tool_id, bowtie2/2.5.0+galaxy0,Cut1 for --super_short_tool_id etc...
	meta <<-EOF
		AUTHORS: lldelisle
		ADDED: 22
		EDITED: 23
	EOF
	handle_help "$@" <<-EOF
		Tools Usage Tracking: cpu-hours and nb_users by Month-Year.

		    $ gxadmin query tools-usage-per-month --super_short_tool_id --no_version --tools bowtie2,Cut1 --startmonth=2023-03 --endmonth 2023-08
			   month    | cpu_hours | tool_id | nb_users
			------------+-----------+---------+----------
			 2023-08-01 |    796.15 | bowtie2 |        2
			 2023-07-01 |     20.04 | bowtie2 |        1
			 2023-07-01 |      0.00 | Cut1    |        1
			 2023-06-01 |    271.16 | bowtie2 |        3
			 2023-06-01 |      0.07 | Cut1    |        4
			 2023-05-01 |    732.74 | bowtie2 |        3
			 2023-05-01 |      0.01 | Cut1    |        2
			 2023-04-01 |    426.32 | bowtie2 |        2
			 2023-04-01 |      0.05 | Cut1    |        4
			 2023-03-01 |    944.02 | bowtie2 |        2
			 2023-03-01 |      0.01 | Cut1    |        2
			(11 rows)
	EOF

	filter_by_time_period=""
	if [[ -n $arg_startmonth ]]; then
		filter_by_time_period="date_trunc('month', job.create_time AT TIME ZONE 'UTC') >= '$arg_startmonth-01'::date"
	else
		filter_by_time_period="job.create_time > NOW() - interval '1 year'"
	fi
	if [[ -n $arg_endmonth ]]; then
		filter_by_time_period="$filter_by_time_period AND date_trunc('month', job.create_time AT TIME ZONE 'UTC') <= '$arg_endmonth-01'::date"
	fi
	tool_id="job.tool_id"
	if [[ -n $arg_short_tool_id ]]; then
		tool_id="regexp_replace(job.tool_id, '.*toolshed.*/repos/', '')"
	fi
	if [[ -n $arg_super_short_tool_id ]]; then
		tool_id="regexp_replace(job.tool_id, '.*toolshed.*/repos/[^/]*/[^/]*/', '')"
	fi

	if [[ -n $arg_no_version ]]; then
		tool_id="regexp_replace(${tool_id}::TEXT, '/[0-9.a-z+-]+$', '')"
	fi
	filter_tool=""
	if [[ -n $arg_tools ]]; then
		tool_list=$(echo "$arg_tools" | sed -e "s/^/('/" -e "s/,/', '/g" -e "s/$/')/")
		filter_tool="AND $tool_id in $tool_list"
	fi

	read -r -d '' QUERY <<-EOF
		SELECT
			date_trunc('month', job.create_time  AT TIME ZONE 'UTC')::date as month,
			round(sum((a.metric_value * b.metric_value) / 3600 ), 2) as cpu_hours,
			$tool_id as tool_id,
			COUNT (DISTINCT job.user_id) as nb_users
		FROM
			job_metric_numeric a,
			job_metric_numeric b,
			job
		WHERE
			b.job_id = a.job_id
			AND a.job_id = job.id
			AND a.metric_name = 'runtime_seconds'
			AND b.metric_name = 'galaxy_slots'
			AND $filter_by_time_period $filter_tool
		GROUP BY
			month, $tool_id
		ORDER BY
			month DESC
	EOF
}

query_archivable-histories() { ##? [--user-last-active=360] [--history-last-active=360] [--size]
	meta <<-EOF
		AUTHORS: natefoo
		ADDED: 22
	EOF
	handle_help "$@" <<-EOF
		Get a list of archivable histories based on user and history age.

		    $ gxadmin query archivable-histories
		    ...

		The --size option can be used to show the size of the histories returned, but can significantly slow the
		query.

		One useful way to use this function is like so:

		    $ gxadmin tsvquery archivable-histories --size | \\
		        awk -F'\\t' '{print \$1; sum+=\$NF;} END {print "Total: " sum/1024^3 " GB" > "/dev/stderr";}' | \\
			GALAXY_CONFIG_FILE=/gx/config/galaxy.yml xargs /gx/venv/bin/python3 | \\
			  /gx/galaxy/scripts/secret_decoder_ring.py encode

		This outputs the total size to archive to stderr while encoding all history IDs on stdout for
		consumption by API-based archival tools.
	EOF

	extra_selects=
	extra_joins=
	extra_conds=
	if [[ -n $arg_size ]]; then
		extra_selects=',
			sum(dataset.total_size) AS size
		'
		extra_joins='
			JOIN dataset on history_dataset_association.dataset_id = dataset.id'
		extra_conds='AND NOT dataset.deleted
			AND NOT dataset.purged'
	fi

	email=$(gdpr_safe galaxy_user.email email)

	read -r -d '' QUERY <<-EOF
		SELECT
			history.id,
			$email,
			date(galaxy_user.update_time) user_age,
			date(history.update_time) history_age
			$extra_selects
		FROM
			history
			JOIN galaxy_user ON history.user_id = galaxy_user.id
			JOIN history_dataset_association on history.id = history_dataset_association.history_id
			$extra_joins
		WHERE
			NOT history.published
			AND NOT history.deleted
			AND NOT history.purged
			AND NOT history_dataset_association.deleted
			AND NOT history_dataset_association.purged
			AND history.update_time < now() - interval '$arg_history_last_active days'
			AND galaxy_user.update_time < now() - interval '$arg_user_last_active days'
			$extra_conds
		GROUP BY
			history.id, galaxy_user.id
		ORDER BY
			user_age ASC,
			galaxy_user.email ASC,
			history_age ASC
	EOF
}

query_tools-usage() { ##? [year] [--tools=<tool1,tool2,...>] [--short_tool_id] [--super_short_tool_id] [--no_version]: tool1, tool2 etc. should correspond to the tool_id with the same format as requested: toolshed.g2.bx.psu.edu/repos/devteam/bowtie2/bowtie2/2.5.0+galaxy0,Cut1 for default, devteam/bowtie2/bowtie2/2.5.0+galaxy0,Cut1 for --short_tool_id, bowtie2/2.5.0+galaxy0,Cut1 for --super_short_tool_id etc...
	meta <<-EOF
		AUTHORS: lldelisle
		ADDED: 23
	EOF
	handle_help "$@" <<-EOF
		Tools Usage Tracking: cpu-hours, cpu-years and nb_users for specific tools (optionally in a given year).

		    $ gxadmin query tools-usage --super_short_tool_id --no_version --tools bowtie2,Cut1 2023
			 cpu_hours | cpu_years | tool_id | nb_users
			-----------+-----------+---------+----------
			   4631.91 |      0.53 | bowtie2 |        7
			      0.24 |      0.00 | Cut1    |        6
			(2 rows)
	EOF
	if [[ -n $arg_year ]]; then
	    filter_by_year="AND date_trunc('year', job.create_time AT TIME ZONE 'UTC') = '$arg_year-01-01'::date"
	fi
	tool_id="job.tool_id"
	if [[ -n $arg_short_tool_id ]]; then
		tool_id="regexp_replace(job.tool_id, '.*toolshed.*/repos/', '')"
	fi
	if [[ -n $arg_super_short_tool_id ]]; then
		tool_id="regexp_replace(job.tool_id, '.*toolshed.*/repos/[^/]*/[^/]*/', '')"
	fi

	if [[ -n $arg_no_version ]]; then
		tool_id="regexp_replace(${tool_id}::TEXT, '/[0-9.a-z+-]+$', '')"
	fi
	filter_tool=""
	if [[ -n $arg_tools ]]; then
		tool_list=$(echo "$arg_tools" | sed -e "s/^/('/" -e "s/,/', '/g" -e "s/$/')/")
		filter_tool="AND $tool_id in $tool_list"
	fi

	read -r -d '' QUERY <<-EOF
		SELECT
			round(sum((a.metric_value * b.metric_value) / 3600 ), 2) as cpu_hours,
			round(sum((a.metric_value * b.metric_value) / 3600 / 24 / 365 ), 2) as cpu_years,
			$tool_id as tool_id,
			COUNT (DISTINCT job.user_id) as nb_users
		FROM
			job_metric_numeric a,
			job_metric_numeric b,
			job
		WHERE
			b.job_id = a.job_id
			AND a.job_id = job.id
			AND a.metric_name = 'runtime_seconds'
			AND b.metric_name = 'galaxy_slots'
			$filter_tool
			$filter_by_year
		GROUP BY
			$tool_id
	EOF
}

query_tool-memory-efficiency() { ##? [--newer-than=2592000] [--min-job-count=5] [--min-runtime=300] [--min-mem=8]: View the efficiency of recent jobs
	meta <<-EOF
		AUTHORS: natefoo
		ADDED: 23
	EOF
	handle_help "$@" <<-EOF
		This is mainly useful for determining which long-running tools with large memory allocations have been
		granted too large of an allocation. It requires that your jobs run in isolated Linux cgroups (as is
		commonly configured for Slurm) that accurately report memory usage in memory.peak (cgroupsv2) or
		memory.memsw.max_usage_in_bytes (cgroupsv1) and you have enabled the Galaxy cgroups job metrics plugin.

		    $ gxadmin query tool-memory-efficiency
		           tool_id       | run_count | total_runtime_hrs | avg_mem_used_gb | avg_mem_allocated_gb | avg_mem_percent
		    ---------------------+-----------+-------------------+-----------------+----------------------+-----------------
		     samtools_sort/2.0.5 |       232 |             48.65 |           10.00 |                10.00 |          100.00
		     featurecounts/2.0.3 |       657 |            123.18 |            7.77 |                 8.00 |           97.07
		     kraken2/2.1.1       |       156 |             74.76 |           78.03 |                84.82 |           91.55
		     bwa_mem2/2.2.1      |       635 |            399.82 |           53.24 |                57.82 |           90.01
		     rna_star/2.7.10b    |        20 |             59.47 |           51.34 |                58.00 |           88.51
		     trim_galore/0.6.7   |      1217 |            358.12 |           10.74 |                18.50 |           58.03
		     fastqc/0.74         |        97 |             15.52 |            6.65 |                27.46 |           24.31
		     metaspades/3.15.3   |         6 |              4.56 |            7.46 |                28.00 |           26.65
		     raxml/8.2.12        |       406 |            133.41 |            0.44 |                59.20 |            0.75

		By default, only jobs from the last 30 days, tools that were allocated 8 GB of memory or more and run
		more than 5 times, and jobs that ran for at least 5 minutes are included, since old jobs and fast and
		infrequent tools can add noise to the results.

		You can change the age of jobs returned by specifying '--newer-than='. This option takes a value in the
		PostgreSQL date/time interval format, see documentation:
		https://www.postgresql.org/docs/current/functions-datetime.html

		Be sure to quote intervals containing spaces.

		The minimum job cutoff per tool can be specified with '--min-job-count', minimum runtime (in seconds)
		with '--min-runtime', and minimum memory (in GB) with '--min-mem'.
	EOF

	fields="run_count=1;total_runtime_hrs=2;avg_mem_used_gb=3;avg_mem_allocated_gb=4;avg_mem_percent=5"
	tags="tool_id=0"

	read -r -d '' QUERY <<-EOF
		WITH job_metrics AS (
			SELECT
			j.id,
			j.tool_id,
			(SELECT metric_value FROM job_metric_numeric WHERE job_id = j.id AND metric_name = 'galaxy_memory_mb' LIMIT 1) * POW(1024, 2) AS mem_allocated,
			(SELECT metric_value FROM job_metric_numeric WHERE job_id = j.id AND metric_name IN ('memory.peak', 'memory.memsw.max_usage_in_bytes') LIMIT 1) AS mem_used,
			(SELECT metric_value FROM job_metric_numeric WHERE job_id = j.id AND metric_name = 'runtime_seconds' LIMIT 1) AS runtime,
			(SELECT metric_value FROM job_metric_numeric WHERE job_id = j.id AND metric_name IN ('memory.peak', 'memory.memsw.max_usage_in_bytes') LIMIT 1)
			  / NULLIF((SELECT metric_value FROM job_metric_numeric WHERE job_id = j.id AND metric_name = 'galaxy_memory_mb' LIMIT 1) * POW(1024, 2), 0) AS mem_ratio
		    FROM
			job j
		    WHERE
			j.update_time > timezone('UTC', now()) - '$arg_newer_than'::INTERVAL
			AND j.state = 'ok'
		)
		SELECT
		    tool_id,
		    COUNT(*) AS run_count,
		    ROUND((SUM(runtime) / POW(60, 2))::numeric, 2) AS total_runtime_hrs,
		    ROUND((AVG(mem_used) / POW(1024, 3))::numeric, 2) AS avg_mem_used_gb,
		    ROUND((AVG(mem_allocated) / POW(1024, 3))::numeric, 2) AS avg_mem_allocated_gb,
		    ROUND((AVG(mem_ratio) * 100)::numeric, 2) AS avg_mem_percent
		FROM
		    job_metrics
		WHERE
		    mem_allocated >= ($arg_min_mem * POW(1024, 3))
		    AND mem_used IS NOT NULL
		    AND runtime > $arg_min_runtime
		GROUP BY
		    tool_id
		HAVING
		    COUNT(tool_id) > $arg_min_job_count
		ORDER BY
		    avg_mem_percent DESC
	EOF
}
