query_latest-users() { ## : 40 recently registered users
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

query_tool-usage() { ## [weeks]: Counts of tool runs in the past weeks (default = all)
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

query_tool-popularity() { ## [months|24]: Most run tools by month (tool_predictions)
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

query_workflow-connections() { ## [--all]: The connections of tools, from output to input, in the latest (or all) versions of user workflows (tool_predictions)
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
			workflow.update_time::DATE as wf_updated,
			ws_in.id as in_id,
			ws_in.tool_id as in_tool,
			ws_in.tool_version as in_tool_v,
			ws_out.id as out_id,
			ws_out.tool_id as out_tool,
			ws_out.tool_version as out_tool_v
		FROM workflow_step_connection wfc
		LEFT JOIN workflow_step ws_out ON ws_out.id = wfc.output_step_id
		LEFT JOIN workflow_step_input wsi ON wfc.input_step_input_id = wsi.id
		LEFT JOIN workflow_step ws_in  ON ws_in.id = wsi.workflow_step_id
		LEFT JOIN workflow on ws_in.workflow_id = workflow.id
		$wf_filter
	EOF
}

query_history-connections() { ## : The connections of tools, from output to input, in histories (tool_predictions)
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

query_datasets-created-daily() { ## : The min/max/average/p95/p99 of total size of datasets created in a single day.
	handle_help "$@" <<-EOF
		    $ gxadmin query datasets-created-daily
		       min   |  avg   | perc_95 | perc_99 |  max
		    ---------+--------+---------+---------+-------
		     0 bytes | 338 GB | 1355 GB | 2384 GB | 42 TB
	EOF

	summary="$(summary_statistics sum)"

	read -r -d '' QUERY <<-EOF
		WITH temp_queue_times AS
		(select
			date_trunc('day', create_time AT TIME ZONE 'UTC'),
			sum(coalesce(total_size, file_size))
		from dataset
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

query_queue-time() { ## <tool_id>: The average/95%/99% a specific tool spends in queue state.
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

query_queue() { ## : Brief overview of currently running jobs
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

query_queue-overview() { ## [--short-tool-id]: View used mostly for monitoring
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

query_queue-details() {
	query_queue-detail $@
}

query_queue-detail() { ## [--all] [--seconds]: Detailed overview of running and queued jobs
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
	nonpretty="("

	for i in "$@"; do
		if [[ $i == "--all" ]]; then
			d=", 'new'"
		fi

		if [[ $i == "--seconds" ]]; then
			nonpretty="EXTRACT(EPOCH FROM "
		fi
	done

	username=$(gdpr_safe galaxy_user.username username "Anonymous User")

	read -r -d '' QUERY <<-EOF
		SELECT
			job.state,
			job.id,
			job.job_runner_external_id as extid,
			job.tool_id,
			$username,
			$nonpretty now() AT TIME ZONE 'UTC' - job.create_time) as time_since_creation,
			job.handler,
			job.job_runner_name,
			job.destination_id
		FROM job
		FULL OUTER JOIN galaxy_user ON job.user_id = galaxy_user.id
		WHERE
			state in ('running', 'queued'$d)
		ORDER BY
			state desc,
			time_since_creation desc
	EOF
}

query_runtime-per-user() { ## <email>: computation time of user (by email)
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

query_jobs-nonterminal() { ## [username|id|email]: Job info of nonterminal jobs separated by user
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

	user_id=$(gdpr_safe job.user_id user_id "anon")

	read -r -d '' QUERY <<-EOF
		SELECT
			job.id, job.tool_id, job.state, job.create_time AT TIME ZONE 'UTC', job.job_runner_name, job.job_runner_external_id, job.handler, $user_id
		FROM
			job
		LEFT OUTER JOIN
			galaxy_user ON job.user_id = galaxy_user.id
		WHERE
			$user_filter AND job.state IN ('new', 'queued', 'running')
		ORDER BY job.id ASC
	EOF
}

query_jobs-per-user() { ## <email>: Number of jobs run by a specific user
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
			)
	EOF
}

query_recent-jobs() { ## <hours>: Jobs run in the past <hours> (in any state)
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

query_training-list() { ## [--all]: List known trainings
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

query_training-members() { ## <tr_id>: List users in a specific training
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
			SELECT DISTINCT ON ($username)
				$username,
				date_trunc('second', user_group_association.create_time AT TIME ZONE 'UTC') as joined
			FROM galaxy_user, user_group_association, galaxy_group
			WHERE galaxy_group.name = 'training-$ww'
				AND galaxy_group.id = user_group_association.group_id
				AND user_group_association.user_id = galaxy_user.id
	EOF
}

query_training-members-remove() { ## <training> <username> [YESDOIT]: Remove a user from a training
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
				AND galaxy_user.username = '$2'
		EOF
	fi
}

query_largest-histories() { ## [--human]: Largest histories in Galaxy
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

	fields="size=0"
    tags="id=1;name=2;username=3"

	total_size="sum(coalesce(dataset.total_size, dataset.file_size, 0)) as total_size"
	if [[ $1 == "--human" ]]; then
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

query_training-queue() { ## <training_id>: Jobs currently being run by people in a given training
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

query_disk-usage() { ## [--human]: Disk usage per object store.
	handle_help "$@" <<-EOF
		Query the different object stores referenced in your Galaxy database

		    $ gxadmin query disk-usage
		     object_store_id |      sum
		    -----------------+----------------
		     files8          | 88109503720067
		     files6          | 64083627169725
		     files9          | 53690953947700
		     files7          | 30657241908566

		Or you can supply the --human flag, but this should not be used with iquery/InfluxDB

		    $ gxadmin query disk-usage --human
		     object_store_id |   sum
		    -----------------+---------
		     files9          | 114 TB
		     files8          | 77 TB
		     files7          | 56 TB
		     files6          | 17 TB
	EOF

	fields="count=1"
	tags="object_store_id=0"

	size="sum(coalesce(dataset.total_size, dataset.file_size, 0))"
	if [[ $1 == "--human" ]]; then
		size="pg_size_pretty(sum(coalesce(dataset.total_size, dataset.file_size, 0))) as sum"
	fi

	read -r -d '' QUERY <<-EOF
			SELECT
				object_store_id, $size
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

query_users-total() { ## : Total number of Galaxy users (incl deleted, purged, inactive)
	handle_help "$@" <<-EOF
	EOF

	fields="count=0"
	tags=""

	read -r -d '' QUERY <<-EOF
			SELECT count(*) FROM galaxy_user
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

query_tool-metrics() { ## <tool_id> <metric_id> [--like]: See values of a specific metric
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

query_tool-available-metrics() { ## <tool_id>: list all available metrics for a given tool
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

query_monthly-cpu-years() { ## : CPU years allocated to tools by month
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


query_monthly-data(){ ## [year] [--human]: Number of active users per month, running jobs
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
	if (( $# > 0 )); then
		for args in "$@"; do
			if [ "$args" = "--human" ]; then
				size="pg_size_pretty(sum(coalesce(dataset.total_size, dataset.file_size, 0)))"
			else
				where="WHERE date_trunc('year', dataset.create_time AT TIME ZONE 'UTC') = '$args-01-01'::date"
			fi
		done
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

query_user-cpu-years() { ## : CPU years allocated to tools by user
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

query_user-disk-usage() { ## [--human]: Retrieve an approximation of the disk usage for users
	handle_help "$@" <<-EOF
		This uses the dataset size and the history association in order to
		calculate total disk usage for a user. This is currently limited
		to the 50 users with the highest storage usage.

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
	EOF

	username=$(gdpr_safe galaxy_user.username user_name 'Anonymous')
	useremail=$(gdpr_safe galaxy_user.email user_email 'Anonymous')


	fields="size=4"
    tags="userid=1;username=2"

	size="sum(coalesce(dataset.total_size, dataset.file_size, 0)) as \"storage usage\""
	if [[ $1 == "--human" ]]; then
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
}

query_user-disk-quota() { ## : Retrieves the 50 users with the largest quotas
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

query_group-cpu-seconds() { ## [group]: Retrieve an approximation of the CPU time in seconds for group(s)
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

	if (( $# > 0 )); then
		where="AND galaxy_group.name = '$1'"
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

query_group-gpu-time() { ## [group]: Retrieve an approximation of the GPU time for users
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

	if (( $# > 0 )); then
		where="AND galaxy_group.name = '$1'"
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

query_monthly-users-registered(){ ## [year]: Number of users registered each month
	handle_help "$@" <<-EOF
	EOF

	if (( $# > 0 )); then
		where="WHERE date_trunc('year', galaxy_user.create_time AT TIME ZONE 'UTC') = '$1-01-01'::date"
	fi

	read -r -d '' QUERY <<-EOF
		SELECT
			date_trunc('month', galaxy_user.create_time)::DATE AS month,
			count(*)
		FROM
			galaxy_user
		$where
		GROUP BY
			month
		ORDER BY
			month DESC
	EOF
}

query_monthly-users-active(){ ## [year]: Number of active users per month, running jobs
	handle_help "$@" <<-EOF
		Number of unique users each month who ran jobs. **NOTE**: does not include anonymous users.

		    [galaxy@sn04 galaxy]$ gxadmin query monthly-users-active 2018
		       month    | active_users
		    ------------+--------------
		     2018-12-01 |          811
		     2018-11-01 |          658
		     2018-10-01 |          583
		     2018-09-01 |          444
		     2018-08-01 |          342
		     2018-07-01 |          379
		     2018-06-01 |          370
		     2018-05-01 |          330
		     2018-04-01 |          274
		     2018-03-01 |          186
		     2018-02-01 |          168
		     2018-01-01 |          122
	EOF

	if (( $# > 0 )); then
		where="WHERE date_trunc('year', job.create_time AT TIME ZONE 'UTC') = '$1-01-01'::date"
	fi

	read -r -d '' QUERY <<-EOF
		SELECT
			date_trunc('month', job.create_time AT TIME ZONE 'UTC')::date as month,
			count(distinct user_id) as active_users
		FROM job
		$where
		GROUP BY month
		ORDER BY month DESC
	EOF
}

query_monthly-jobs(){ ## [year]: Number of jobs run each month
	handle_help "$@" <<-EOF
		Count jobs run each month

		    [galaxy@sn04 galaxy]$ gxadmin query monthly-jobs 2018
		        month   | count
		    ------------+--------
		     2018-12-01 |  96941
		     2018-11-01 |  94625
		     2018-10-01 | 156940
		     2018-09-01 | 103331
		     2018-08-01 | 128658
		     2018-07-01 |  90852
		     2018-06-01 | 230470
		     2018-05-01 | 182331
		     2018-04-01 | 109032
		     2018-03-01 | 197125
		     2018-02-01 | 260931
		     2018-01-01 |  25378
	EOF

	if (( $# > 0 )); then
		where="WHERE date_trunc('year', job.create_time AT TIME ZONE 'UTC') = '$1-01-01'::date"
	fi

	read -r -d '' QUERY <<-EOF
		SELECT
			date_trunc('month', job.create_time AT TIME ZONE 'UTC')::DATE AS month,
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

query_job-history() { ## <id>: Job state history for a specific job
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

query_job-inputs() { ## <id>: Input datasets to a specific job
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

query_job-outputs() { ## <id>: Output datasets from a specific job
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
	EOF
}

query_job-info() { ## <-|job_id [job_id [...]]> : Retrieve information about jobs given some job IDs
	handle_help "$@" <<-EOF
		Retrieves information on a job, like the host it ran on,
		how long it ran for and the total memory.

		id    | create_time  | update_time |  tool_id     |   hostname   | runtime_seconds | memtotal
		----- | ------------ | ----------- | ------------ | ------------ | --------------- | --------
		1     |              |             | 123f911b5f1  | 123f911b5f1  |          20.35  | 20.35 GB
		2     |              |             | cb0fabc0002  | cb0fabc0002  |          14.93  |  5.96 GB
		3     |              |             | 7e9e9b00b89  | 7e9e9b00b89  |          14.24  |  3.53 GB
		4     |              |             | 42f211e5e87  | 42f211e5e87  |          14.06  |  1.79 GB
		5     |              |             | 26cdba62c93  | 26cdba62c93  |          12.97  |  1.21 GB
		6     |              |             | fa87cddfcae  | fa87cddfcae  |           7.01  |   987 MB
		7     |              |             | 44d2a648aac  | 44d2a648aac  |           6.70  |   900 MB
		8     |              |             | 66c57b41194  | 66c57b41194  |           6.43  |   500 MB
		9     |              |             | 6b1467ac118  | 6b1467ac118  |           5.45  |   250 MB
		10    |              |             | d755361b59a  | d755361b59a  |           5.19  |   100 MB
	EOF

	assert_count_ge $# 1 "Missing job IDs"

	if [[ "$1" == "-" ]]; then
		# read jobs from stdin
		job_ids=$(cat | paste -s -d' ')
	else
		# read from $@
		job_ids=$@;
	fi

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
			hostname_query.hostname,
			metric_num_query.runtime_seconds,
			metric_num_query.memtotal
		FROM job
			FULL OUTER JOIN hostname_query ON hostname_query.job_id = job.id
			FULL OUTER JOIN metric_num_query ON metric_num_query.job_id = job.id
		WHERE job.id IN ($job_ids_string)
	EOF
}

query_old-histories(){ ## <weeks>: Lists histories that haven't been updated (used) for <weeks>
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

# TODO(hxr): generic summation by metric? Leave math to consumer?
query_jobs-max-by-cpu-hours() { ## : Top 10 jobs by CPU hours consumed (requires CGroups metrics)
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
		ORDER BY cpu_hours desc
		LIMIT 30
	EOF
}

query_errored-jobs(){ ## <hours>: Lists jobs that errored in the last N hours.
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

query_server-users() {
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

query_server-groups() {
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

query_server-datasets() {
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

query_server-hda() {
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

query_server-ts-repos() {
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

query_server-histories() {
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


query_server-jobs() {
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

query_server-allocated-cpu() {
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

query_server-allocated-gpu() {
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

query_server-workflows() {
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

query_server-workflow-invocations() {
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

query_server-groups-disk-usage() { ## [YYYY-MM-DD] [=, <=, >= operators]: Retrieve an approximation of the disk usage for groups
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

query_server-groups-allocated-cpu() { ## [YYYY-MM-DD] [=, <=, >= operators]: Retrieve an approximation of the CPU allocation for groups
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

query_server-groups-allocated-gpu() { ## [YYYY-MM-DD] [=, <=, >= operators]: Retrieve an approximation of the GPU allocation for groups
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

query_workflow-invocation-status() { ## : Report on how many workflows are in new state by handler
	handle_help "$@" <<-EOF
		Really only intended to be used in influx queries.
	EOF

	fields="count=2"
	tags="scheduler=0;handler=1"

	read -r -d '' QUERY <<-EOF
		SELECT
			scheduler,
			handler,
			count(*)
		FROM
			workflow_invocation
		WHERE state = 'new'
		GROUP BY handler, scheduler
	EOF
}

query_tool-new-errors() { ## [weeks|4]: Summarize percent of tool runs in error over the past weeks for "new tools"
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

	# TODO: Fix this nonsense for proper args
	tool_id="j.tool_id"
	if [[ "$1" = --short-tool-id ]]; then
		tool_id="regexp_replace(j.tool_id, '.*toolshed.*/repos/', '') as tool_id"
		weeks=${2:-4}
	else
		weeks=${1:-4}
	fi

	fields="tool_runs=1;percent_errored=2;percent_failed=3;count_errored=4;count_failed=5"
	tags="tool_id=0;handler=6"


	read -r -d '' QUERY <<-EOF
		SELECT
			j.tool_id,
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
					WHERE j.create_time > (now() - '$weeks weeks'::INTERVAL)
					GROUP BY j.tool_id
				)
		GROUP BY j.tool_id, j.handler
		ORDER BY percent_failed_errored DESC
	EOF
}

query_tool-errors() { ## [--short-tool-id] [weeks|4]: Summarize percent of tool runs in error over the past weeks for all tools that have failed (most popular tools first)
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
	if [[ "$1" = --short-tool-id ]]; then
		tool_id="regexp_replace(j.tool_id, '.*toolshed.*/repos/', '') as tool_id"
		weeks=${2:-4}
	else
		weeks=${1:-4}
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
			j.create_time > (now() - '$weeks weeks'::INTERVAL)
		GROUP BY
			j.tool_id, j.handler
		HAVING
			sum(CASE WHEN j.state IN ('error', 'failed') THEN 1 ELSE 0 END) * 100.0 / count(*) > 10.0
		ORDER BY
			tool_runs DESC
	EOF
}

query_tool-likely-broken() { ## [--short-tool-id] [weeks|4]: Find tools that have been executed in recent weeks that are (or were due to job running) likely substantially broken
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
	if [[ "$1" = --short-tool-id ]]; then
		tool_id="regexp_replace(j.tool_id, '.*toolshed.*/repos/', '') as tool_id"
		weeks=${2:-4}
	else
		weeks=${1:-4}
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
			j.create_time > (now() - '$weeks weeks'::INTERVAL)
		GROUP BY
			j.tool_id, j.handler
		HAVING
			sum(CASE WHEN j.state IN ('error', 'failed') THEN 1 ELSE 0 END) * 100.0 / count(*) > 95.0
			AND count(*) > 4
		ORDER BY
			tool_runs DESC
	EOF
}

query_user-recent-aggregate-jobs() { ## <username|id|email> [days|7]: Show aggregate information for jobs in past N days for user
	handle_help "$@" <<-EOF
		Obtain an overview of tools that a user has run in the past N days
	EOF

	# args
	assert_count_ge $# 1 "Must supply <username|id|email>"
	user_filter="(galaxy_user.email = '$1' or galaxy_user.username = '$1' or galaxy_user.id = CAST(REGEXP_REPLACE(COALESCE('$1','0'), '[^0-9]+', '0', 'g') AS INTEGER))"
	days_filter="${2:-7}"

	read -r -d '' QUERY <<-EOF
		SELECT
			date_trunc('day', create_time), tool_id, state, count(*)
		FROM
			job
		JOIN
			galaxy_user on galaxy_user.id = job.user_id
		WHERE
			$user_filter AND create_time > (now() - '$days_filter days'::INTERVAL)
		GROUP BY
			date_trunc, tool_id, state
		ORDER BY
			date_trunc DESC
	EOF
}

query_user-history-list() { ## <username|id|email> [--size]: Shows the ID of the history, it's size and when it was last updated.
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
	assert_count_ge $# 1 "Must supply <username|id|email>"
	user_filter="(galaxy_user.email = '$1' or galaxy_user.username = '$1' or galaxy_user.id = CAST(REGEXP_REPLACE(COALESCE('$1','0'), '[^0-9]+', '0', 'g') AS INTEGER))"
	order_col="uh.update_time"
	if (( $# > 1 )); then
		if [[ $2 == "--size" ]]; then
			order_col="hs.hist_size"
		fi
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

query_hdca-info() { ## <hdca_id>: Information on a dataset collection
	handle_help "$@" <<-EOF
	EOF

	read -r -d '' QUERY <<-EOF
		SELECT *
		FROM dataset_collection
		WHERE id = $1
	EOF
}

query_hdca-datasets() { ## <hdca_id>: List of files in a dataset collection
	handle_help "$@" <<-EOF
	EOF

	read -r -d '' QUERY <<-EOF
		SELECT element_index, hda_id, ldda_id, child_collection_id, element_identifier
		FROM dataset_collection_element
		WHERE dataset_collection_id = $1
		ORDER by element_index asc
	EOF
}

query_jobs-queued-internal-by-handler() { ## : How many queued jobs do not have external IDs, by handler
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

query_history-runtime-system() { ## <history_id>: Sum of runtimes by all jobs in a history
	handle_help "$@" <<-EOF
	EOF

	assert_count $# 1 "Missing history ID"
}
	read -r -d '' QUERY <<-EOF
		SELECT
			(sum(job_metric_numeric.metric_value)::INT8 || 'seconds')::INTERVAL
		FROM
			job LEFT JOIN job_metric_numeric ON job.id = job_metric_numeric.job_id
		WHERE
			job.history_id = $1 AND metric_name = 'runtime_seconds'
	EOF

query_history-runtime-wallclock() { ## <history_id>: Time as elapsed by a clock on the wall
	handle_help "$@" <<-EOF
	EOF

	assert_count $# 1 "Missing history ID"

	read -r -d '' QUERY <<-EOF
		SELECT
			max(job.update_time) - min(job.create_time)
		FROM
			job
		WHERE
			job.history_id = $1
	EOF
}

query_history-runtime-system-by-tool() { ## <history_id>: Sum of runtimes by all jobs in a history, split by tool
	handle_help "$@" <<-EOF
	EOF

	assert_count $# 1 "Missing history ID"

	read -r -d '' QUERY <<-EOF
		SELECT
			job.tool_id,
			(sum(job_metric_numeric.metric_value)::INT || 'seconds')::INTERVAL
		FROM
			job LEFT JOIN job_metric_numeric ON job.id = job_metric_numeric.job_id
		WHERE
			job.history_id = $1 AND metric_name = 'runtime_seconds'
		GROUP BY
			job.tool_id
		ORDER BY
			"interval" DESC
	EOF
}

query_upload-gb-in-past-hour() { ## [hours|1]: Sum in bytes of files uploaded in the past hour
	handle_help "$@" <<-EOF
		Quick output, mostly useful for graphing, to produce a nice graph of how heavily are people uploading currently.
	EOF

	hours=${1:-1}
	fields="count=0"
	tags="hours=1"

	read -r -d '' QUERY <<-EOF
		SELECT
			coalesce(sum(coalesce(dataset.total_size, coalesce(dataset.file_size, 0))), 0),
			$hours as hours
		FROM
			job
			LEFT JOIN job_to_output_dataset ON job.id = job_to_output_dataset.job_id
			LEFT JOIN history_dataset_association ON
					job_to_output_dataset.dataset_id = history_dataset_association.id
			LEFT JOIN dataset ON history_dataset_association.dataset_id = dataset.id
		WHERE
			job.tool_id = 'upload1'
			AND job.create_time AT TIME ZONE 'UTC' > (now() - '$hours hours'::INTERVAL)
EOF
}

query_queue-detail-by-handler() { ## <handler_id>: List jobs for a specific handler
	handle_help "$@" <<-EOF
		List the jobs currently being processed by a specific handler
	EOF

	assert_count_ge $# 1 "Missing handler ID"

	handler_id=$1

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
			handler = '$handler_id' AND state IN ('new', 'queued', 'running')
	EOF
}


query_pg-cache-hit() { ## : Check postgres in-memory cache hit ratio
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

query_pg-table-bloat() { ## [--human]: show table and index bloat in your database ordered by most wasteful
	handle_help "$@" <<-EOF
		Query from: https://www.citusdata.com/blog/2019/03/29/health-checks-for-your-postgres-database/
		Originally from: https://github.com/heroku/heroku-pg-extras/tree/master/commands
	EOF

	if [[ $1 == "--human" ]]; then
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

query_pg-index-size() { ## [--human]: show table and index bloat in your database ordered by most wasteful
	handle_help "$@" <<-EOF
		Originally from: https://github.com/heroku/heroku-pg-extras/tree/master/commands
	EOF

	if [[ $1 == "--human" ]]; then
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

query_pg-table-size() { ## [--human]: show the size of the tables (excluding indexes), descending by size
	handle_help "$@" <<-EOF
		Originally from: https://github.com/heroku/heroku-pg-extras/tree/master/commands
	EOF

	if [[ $1 == "--human" ]]; then
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

query_pg-unused-indexes() { ## [--human]: show unused and almost unused indexes
	handle_help "$@" <<-EOF
		Originally from: https://github.com/heroku/heroku-pg-extras/tree/master/commands

		From their documentation:

		> "Ordered by their size relative to the number of index scans.
		> Exclude indexes of very small tables (less than 5 pages),
		> where the planner will almost invariably select a sequential scan,
		> but may not in the future as the table grows"
	EOF

	if [[ $1 == "--human" ]]; then
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
	summary="$(summary_statistics data $human)"
	username=$(gdpr_safe job.user_id galaxy_user)

	read -r -d '' QUERY <<-EOF
		WITH asdf AS (
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
		FROM asdf
		ORDER BY galaxy_user desc
	EOF
}

query_data-origin-distribution() { ## [--human]: data sources (uploaded vs derived)
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

	if [[ $1 == "--human" ]]; then
		human=1
	else
		human=0
	fi

	summary="$(summary_statistics data $human)"
	username=$(gdpr_safe job.user_id galaxy_user)

	read -r -d '' QUERY <<-EOF
		WITH asdf AS (
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
		FROM asdf
		ORDER BY galaxy_user desc
	EOF
}

query_data-origin-distribution-summary() { ## [--human]: breakdown of data sources (uploaded vs derived)
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

	if [[ $1 == "--human" ]]; then
		human=1
	else
		human=0
	fi

	summary="$(summary_statistics data $human)"

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
	handle_help "$@" <<-EOF
	EOF

	table=$1; shift
	column=$1; shift

	if [[ "$1" == "-" ]]; then
		# read jobs from stdin
		ids=$(cat | paste -s -d' ')
	else
		# read from $@
		ids=$@;
	fi

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

	QUERY="$1"
}

query_good-for-pulsar() { ## : Look for jobs EU would like to send to pulsar
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
			job.stdout AS job_stdout,
			job.stderr AS job_stderr,
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
