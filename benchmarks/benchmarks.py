import subprocess


class GxadminSuite:
    def time_query_collection_usage(self):
        query = """
            SELECT
            	dc.collection_type, count(*)
            FROM
            	history_dataset_collection_association AS hdca
            	INNER JOIN dataset_collection AS dc ON
            			hdca.collection_id = dc.id
            GROUP BY
            	dc.collection_type;
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'collection-usage',
        ])
    def time_query_data_origin_distribution(self):
        query = """
            WITH
            	asdf
            		AS (
            			SELECT
            				CASE
            				WHEN job.tool_id = 'upload1' THEN 'created'
            				ELSE 'derived'
            				END
            					AS origin,
            				sum(
            					COALESCE(
            						dataset.total_size,
            						dataset.file_size,
            						0
            					)
            				)
            					AS data,
            				date_trunc('month', dataset.create_time)
            					AS created,
            				COALESCE(job.user_id::STRING, '__UNKNOWN__')
            			FROM
            				job
            				LEFT JOIN job_to_output_dataset ON
            						job.id
            						= job_to_output_dataset.job_id
            				LEFT JOIN history_dataset_association ON
            						job_to_output_dataset.dataset_id
            						= history_dataset_association.id
            				LEFT JOIN dataset ON
            						history_dataset_association.dataset_id
            						= dataset.id
            			GROUP BY
            				origin, job.user_id, created, galaxy_user
            		)
            SELECT
            	origin,
            	round(data, 2 - length(data::STRING)),
            	created,
            	galaxy_user
            FROM
            	asdf
            ORDER BY
            	galaxy_user DESC;
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'data-origin-distribution',
        ])
    def time_query_data_origin_distribution_summary(self):
        query = """
            at or near ")": syntax error: unimplemented: this syntax
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'data-origin-distribution-summary',
        ])
    def time_query_datasets_created_daily(self):
        query = """
            at or near ")": syntax error: unimplemented: this syntax
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'datasets-created-daily',
        ])
    def time_query_disk_usage(self):
        query = """
            SELECT
            	object_store_id,
            	sum(COALESCE(dataset.total_size, dataset.file_size, 0))
            FROM
            	dataset
            WHERE
            	NOT purged
            GROUP BY
            	object_store_id
            ORDER BY
            	sum(COALESCE(dataset.total_size, dataset.file_size, 0))
            		DESC;
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'disk-usage',
        ])
    def time_query_errored_jobs(self):
        query = """
            at or near "as": syntax error: unimplemented: this syntax
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'errored-jobs',
        ])
    def time_query_good_for_pulsar(self):
        query = """
            at or near ")": syntax error: unimplemented: this syntax
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'good-for-pulsar',
        ])
    def time_query_group_cpu_seconds(self):
        query = """
            WITH
            	jobs_info
            		AS (
            			SELECT
            				job.user_id,
            				round(
            					sum(a.metric_value * b.metric_value),
            					2
            				)
            					AS cpu_seconds
            			FROM
            				job_metric_numeric AS a,
            				job_metric_numeric AS b,
            				job
            			WHERE
            				job.id = a.job_id
            				AND job.id = b.job_id
            				AND a.metric_name = 'runtime_seconds'
            				AND b.metric_name = 'galaxy_slots'
            			GROUP BY
            				job.user_id
            		),
            	user_job_info
            		AS (
            			SELECT
            				user_id, sum(cpu_seconds) AS cpu_seconds
            			FROM
            				jobs_info
            			GROUP BY
            				user_id
            		)
            SELECT
            	row_number() OVER (
            		ORDER BY
            			round(sum(user_job_info.cpu_seconds), 0) DESC
            	)
            		AS rank,
            	galaxy_group.id AS group_id,
            	COALESCE(galaxy_group.name::STRING, 'Anonymous'),
            	round(sum(user_job_info.cpu_seconds), 0) AS cpu_seconds
            FROM
            	user_job_info, galaxy_group, user_group_association
            WHERE
            	user_job_info.user_id = user_group_association.user_id
            	AND user_group_association.group_id = galaxy_group.id
            GROUP BY
            	galaxy_group.id, galaxy_group.name
            ORDER BY
            	round(sum(user_job_info.cpu_seconds), 0) DESC
            LIMIT
            	50;
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'group-cpu-seconds',
        ])
    def time_query_group_gpu_time(self):
        query = """
            WITH
            	jobs_info
            		AS (
            			SELECT
            				job.user_id,
            				round(
            					sum(
            						a.metric_value
            						* length(
            								replace(
            									b.metric_value,
            									',',
            									''
            								)
            							)
            					),
            					2
            				)
            					AS gpu_seconds
            			FROM
            				job_metric_numeric AS a,
            				job_metric_text AS b,
            				job
            			WHERE
            				job.id = a.job_id
            				AND job.id = b.job_id
            				AND a.metric_name = 'runtime_seconds'
            				AND b.metric_name = 'CUDA_VISIBLE_DEVICES'
            			GROUP BY
            				job.user_id
            		),
            	user_job_info
            		AS (
            			SELECT
            				user_id, sum(gpu_seconds) AS gpu_seconds
            			FROM
            				jobs_info
            			GROUP BY
            				user_id
            		)
            SELECT
            	row_number() OVER (
            		ORDER BY
            			round(sum(user_job_info.gpu_seconds), 0) DESC
            	)
            		AS rank,
            	galaxy_group.id AS group_id,
            	COALESCE(galaxy_group.name::STRING, 'Anonymous'),
            	round(sum(user_job_info.gpu_seconds), 0) AS gpu_seconds
            FROM
            	user_job_info, galaxy_group, user_group_association
            WHERE
            	user_job_info.user_id = user_group_association.user_id
            	AND user_group_association.group_id = galaxy_group.id
            GROUP BY
            	galaxy_group.id, galaxy_group.name
            ORDER BY
            	round(sum(user_job_info.gpu_seconds), 0) DESC
            LIMIT
            	50;
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'group-gpu-time',
        ])
    def time_query_groups_list(self):
        query = """
            SELECT
            	galaxy_group.name, count(*)
            FROM
            	galaxy_group, user_group_association
            WHERE
            	user_group_association.group_id = galaxy_group.id
            GROUP BY
            	name;
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'groups-list',
        ])
    def time_query_hdca_datasets(self):
        query = """
            at or near "order": syntax error
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'hdca-datasets',
        ])
    def time_query_hdca_info(self):
        query = """
            at or near "EOF": syntax error
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'hdca-info',
        ])
    def time_query_history_connections(self):
        query = """
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
            	LEFT JOIN job_to_output_dataset AS jtod ON
            			j.id = jtod.job_id
            	LEFT JOIN job_to_input_dataset AS jtid ON
            			jtod.dataset_id = jtid.dataset_id
            	LEFT JOIN job AS j2 ON jtid.job_id = j2.id
            WHERE
            	jtid.job_id IS NOT NULL;
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'history-connections',
        ])
    def time_query_history_contents(self):
        query = """
            at or near "EOF": syntax error
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'history-contents',
        ])
    def time_query_history_runtime_system_by_tool(self):
        query = """
            
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'history-runtime-system-by-tool',
        ])
    def time_query_history_runtime_system(self):
        query = """
            
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'history-runtime-system',
        ])
    def time_query_history_runtime_wallclock(self):
        query = """
            
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'history-runtime-wallclock',
        ])
    def time_query_job_history(self):
        query = """
            
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'job-history',
        ])
    def time_query_job_info(self):
        query = """
            
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'job-info',
        ])
    def time_query_job_inputs(self):
        query = """
            
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'job-inputs',
        ])
    def time_query_job_outputs(self):
        query = """
            
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'job-outputs',
        ])
    def time_query_jobs_max_by_cpu_hours(self):
        query = """
            SELECT
            	job.id,
            	job.tool_id,
            	job.create_time,
            	metric_value / 1000000000 / 3600 / 24 AS cpu_days
            FROM
            	job, job_metric_numeric
            WHERE
            	job.id = job_metric_numeric.job_id
            	AND metric_name = 'cpuacct.usage'
            ORDER BY
            	cpu_hours DESC
            LIMIT
            	30;
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'jobs-max-by-cpu-hours',
        ])
    def time_query_jobs_nonterminal(self):
        query = """
            at or near ",": syntax error: unimplemented: this syntax
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'jobs-nonterminal',
        ])
    def time_query_jobs_per_user(self):
        query = """
            
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'jobs-per-user',
        ])
    def time_query_jobs_queued(self):
        query = """
            SELECT
            	CASE
            	WHEN job_runner_external_id IS NOT NULL THEN 'processed'
            	ELSE 'unprocessed'
            	END
            		AS n,
            	count(*)
            FROM
            	job
            WHERE
            	state = 'queued'
            GROUP BY
            	n;
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'jobs-queued',
        ])
    def time_query_jobs_queued_internal_by_handler(self):
        query = """
            SELECT
            	handler, count(handler)
            FROM
            	job
            WHERE
            	state = 'queued' AND job_runner_external_id IS NULL
            GROUP BY
            	handler;
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'jobs-queued-internal-by-handler',
        ])
    def time_query_jobs_ready_to_run(self):
        query = """
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
            	AND job.handler = 'handler0';
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'jobs-ready-to-run',
        ])
    def time_query_largest_collection(self):
        query = """
            WITH
            	temp_table_collection_count
            		AS (
            			SELECT
            				count(*)
            			FROM
            				dataset_collection_element
            			GROUP BY
            				dataset_collection_id
            			ORDER BY
            				count DESC
            		)
            SELECT
            	max(count) AS count
            FROM
            	temp_table_collection_count;
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'largest-collection',
        ])
    def time_query_largest_histories(self):
        query = """
            SELECT
            	sum(COALESCE(dataset.total_size, dataset.file_size, 0))
            		AS total_size,
            	history.id,
            	substring(history.name, 1, 10),
            	COALESCE(galaxy_user.username::STRING, '__UNKNOWN__')
            FROM
            	dataset
            	JOIN history_dataset_association ON
            			dataset.id
            			= history_dataset_association.dataset_id
            	JOIN history ON
            			history_dataset_association.history_id
            			= history.id
            	JOIN galaxy_user ON history.user_id = galaxy_user.id
            GROUP BY
            	history.id,
            	history.name,
            	history.user_id,
            	galaxy_user.username
            ORDER BY
            	sum(COALESCE(dataset.total_size, dataset.file_size, 0))
            		DESC;
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'largest-histories',
        ])
    def time_query_latest_users(self):
        query = """
            at or near "as": syntax error: unimplemented: this syntax
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'latest-users',
        ])
    def time_query_monthly_cpu_stats(self):
        query = """
            at or near ")": syntax error: unimplemented: this syntax
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'monthly-cpu-stats',
        ])
    def time_query_monthly_cpu_years(self):
        query = """
            SELECT
            	date_trunc('month', job.create_time)::DATE AS month,
            	round(
            		sum(
            			a.metric_value * b.metric_value
            			/ 3600
            			/ 24
            			/ 365
            		),
            		2
            	)
            		AS cpu_years
            FROM
            	job_metric_numeric AS a, job_metric_numeric AS b, job
            WHERE
            	b.job_id = a.job_id
            	AND a.job_id = job.id
            	AND a.metric_name = 'runtime_seconds'
            	AND b.metric_name = 'galaxy_slots'
            GROUP BY
            	date_trunc('month', job.create_time)
            ORDER BY
            	date_trunc('month', job.create_time) DESC;
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'monthly-cpu-years',
        ])
    def time_query_monthly_data(self):
        query = """
            at or near ")": syntax error: unimplemented: this syntax
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'monthly-data',
        ])
    def time_query_monthly_gpu_years(self):
        query = """
            SELECT
            	date_trunc('month', job.create_time)::DATE AS month,
            	round(
            		sum(
            			a.metric_value
            			* length(replace(b.metric_value, ',', ''))
            			/ 3600
            			/ 24
            			/ 365
            		),
            		2
            	)
            		AS gpu_years
            FROM
            	job_metric_numeric AS a, job_metric_text AS b, job
            WHERE
            	b.job_id = a.job_id
            	AND a.job_id = job.id
            	AND a.metric_name = 'runtime_seconds'
            	AND b.metric_name = 'CUDA_VISIBLE_DEVICES'
            GROUP BY
            	date_trunc('month', job.create_time)
            ORDER BY
            	date_trunc('month', job.create_time) DESC;
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'monthly-gpu-years',
        ])
    def time_query_monthly_jobs(self):
        query = """
            at or near ")": syntax error: unimplemented: this syntax
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'monthly-jobs',
        ])
    def time_query_monthly_users_active(self):
        query = """
            at or near ")": syntax error: unimplemented: this syntax
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'monthly-users-active',
        ])
    def time_query_monthly_users_registered(self):
        query = """
            SELECT
            	date_trunc('month', galaxy_user.create_time)::DATE
            		AS month,
            	count(*)
            FROM
            	galaxy_user
            GROUP BY
            	month
            ORDER BY
            	month DESC;
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'monthly-users-registered',
        ])
    def time_query_old_histories(self):
        query = """
            
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'old-histories',
        ])
    def time_query_pg_cache_hit(self):
        query = """
            SELECT
            	sum(heap_blks_read) AS heap_read,
            	sum(heap_blks_hit) AS heap_hit,
            	sum(heap_blks_hit)
            	/ (sum(heap_blks_hit) + sum(heap_blks_read))
            		AS ratio
            FROM
            	pg_statio_user_tables;
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'pg-cache-hit',
        ])
    def time_query_pg_index_size(self):
        query = """
            SELECT
            	c.relname AS name,
            	sum(c.relpages::INT8 * 8192)::INT8 AS size
            FROM
            	pg_class AS c
            	LEFT JOIN pg_namespace AS n ON n.oid = c.relnamespace
            WHERE
            	n.nspname NOT IN ('pg_catalog', 'information_schema')
            	AND n.nspname !~ '^pg_toast'
            	AND c.relkind = 'i'
            GROUP BY
            	c.relname
            ORDER BY
            	sum(c.relpages) DESC;
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'pg-index-size',
        ])
    def time_query_pg_index_usage(self):
        query = """
            SELECT
            	relname,
            	CASE COALESCE(idx_scan, 0)
            	WHEN 0 THEN -1
            	ELSE (100 * idx_scan / (seq_scan + idx_scan))
            	END
            		AS percent_of_times_index_used,
            	n_live_tup AS rows_in_table
            FROM
            	pg_stat_user_tables
            ORDER BY
            	n_live_tup DESC;
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'pg-index-usage',
        ])
    def time_query_pg_long_running_queries(self):
        query = """
            SELECT
            	pid,
            	now() - pg_stat_activity.query_start AS duration,
            	query AS query
            FROM
            	pg_stat_activity
            WHERE
            	pg_stat_activity.query != ''::STRING
            	AND state != 'idle'
            	AND now() - pg_stat_activity.query_start
            		> '00:05:00':::INTERVAL
            ORDER BY
            	now() - pg_stat_activity.query_start DESC;
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'pg-long-running-queries',
        ])
    def time_query_pg_mandelbrot(self):
        query = """
            at or near "select": syntax error: unimplemented: this syntax
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'pg-mandelbrot',
        ])
    def time_query_pg_stat_bgwriter(self):
        query = """
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
            	pg_stat_bgwriter;
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'pg-stat-bgwriter',
        ])
    def time_query_pg_stat_user_tables(self):
        query = """
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
            	pg_stat_user_tables;
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'pg-stat-user-tables',
        ])
    def time_query_pg_table_bloat(self):
        query = """
            WITH
            	constants
            		AS (
            			SELECT
            				current_setting('block_size')::DECIMAL
            					AS bs,
            				23 AS hdr,
            				4 AS ma
            		),
            	bloat_info
            		AS (
            			SELECT
            				ma,
            				bs,
            				schemaname,
            				tablename,
            				(
            					datawidth
            					+ hdr + ma
            						- (
            								CASE
            								WHEN hdr % ma = 0 THEN ma
            								ELSE hdr % ma
            								END
            							)
            				)::DECIMAL
            					AS datahdr,
            				maxfracsum
            				* (
            						nullhdr + ma
            						- (
            								CASE
            								WHEN nullhdr % ma = 0
            								THEN ma
            								ELSE nullhdr % ma
            								END
            							)
            					)
            					AS nullhdr2
            			FROM
            				(
            					SELECT
            						schemaname,
            						tablename,
            						hdr,
            						ma,
            						bs,
            						sum((1 - null_frac) * avg_width)
            							AS datawidth,
            						max(null_frac) AS maxfracsum,
            						hdr
            						+ (
            								SELECT
            									1 + count(*) / 8
            								FROM
            									pg_stats AS s2
            								WHERE
            									null_frac != 0
            									AND s2.schemaname
            										= s.schemaname
            									AND s2.tablename
            										= s.tablename
            							)
            							AS nullhdr
            					FROM
            						pg_stats AS s, constants
            					GROUP BY
            						1, 2, 3, 4, 5
            				)
            					AS foo
            		),
            	table_bloat
            		AS (
            			SELECT
            				schemaname,
            				tablename,
            				cc.relpages,
            				bs,
            				ceil(
            					cc.reltuples
            					* (
            							datahdr + ma
            							- (
            									CASE
            									WHEN datahdr % ma = 0
            									THEN ma
            									ELSE datahdr % ma
            									END
            								)
            							+ nullhdr2
            							+ 4
            						)
            					/ (bs - 20::FLOAT8)
            				)
            					AS otta
            			FROM
            				bloat_info
            				JOIN pg_class AS cc ON
            						cc.relname = bloat_info.tablename
            				JOIN pg_namespace AS nn ON
            						cc.relnamespace = nn.oid
            						AND nn.nspname
            							= bloat_info.schemaname
            						AND nn.nspname
            							!= 'information_schema'
            		),
            	index_bloat
            		AS (
            			SELECT
            				schemaname,
            				tablename,
            				bs,
            				COALESCE(c2.relname, '?') AS iname,
            				COALESCE(c2.reltuples, 0) AS ituples,
            				c2.relpages,
            				0 AS ipages,
            				COALESCE(
            					ceil(
            						c2.reltuples * (datahdr - 12)
            						/ (bs - 20::FLOAT8)
            					),
            					0
            				)
            					AS iotta
            			FROM
            				bloat_info
            				JOIN pg_class AS cc ON
            						cc.relname = bloat_info.tablename
            				JOIN pg_namespace AS nn ON
            						cc.relnamespace = nn.oid
            						AND nn.nspname
            							= bloat_info.schemaname
            						AND nn.nspname
            							!= 'information_schema'
            				JOIN pg_index AS i ON indrelid = cc.oid
            				JOIN pg_class AS c2 ON c2.oid = i.indexrelid
            		)
            SELECT
            	type, schemaname, object_name, bloat, raw_waste AS waste
            FROM
            	(
            		SELECT
            			'table' AS type,
            			schemaname,
            			tablename AS object_name,
            			round(
            				CASE
            				WHEN otta = 0 THEN 0.0
            				ELSE table_bloat.relpages / otta::DECIMAL
            				END,
            				1
            			)
            				AS bloat,
            			CASE
            			WHEN relpages < otta THEN '0'
            			ELSE (
            				bs * (table_bloat.relpages - otta)::INT8
            			)::INT8
            			END
            				AS raw_waste
            		FROM
            			table_bloat
            		UNION
            			SELECT
            				'index' AS type,
            				schemaname,
            				tablename || '::' || iname AS object_name,
            				round(
            					CASE
            					WHEN iotta = 0 OR ipages = 0 THEN 0.0
            					ELSE ipages / iotta::DECIMAL
            					END,
            					1
            				)
            					AS bloat,
            				CASE
            				WHEN ipages < iotta THEN '0'
            				ELSE (bs * (ipages - iotta))::INT8
            				END
            					AS raw_waste
            			FROM
            				index_bloat
            	)
            		AS bloat_summary
            ORDER BY
            	raw_waste DESC, bloat DESC;
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'pg-table-bloat',
        ])
    def time_query_pg_table_size(self):
        query = """
            SELECT
            	c.relname AS name,
            	pg_table_size(c.oid) AS size,
            	pg_indexes_size(c.oid) AS index_size
            FROM
            	pg_class AS c
            	LEFT JOIN pg_namespace AS n ON n.oid = c.relnamespace
            WHERE
            	n.nspname NOT IN ('pg_catalog', 'information_schema')
            	AND n.nspname !~ '^pg_toast'
            	AND c.relkind = 'r'
            ORDER BY
            	pg_table_size(c.oid) DESC;
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'pg-table-size',
        ])
    def time_query_pg_unused_indexes(self):
        query = """
            at or near "nulls": syntax error
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'pg-unused-indexes',
        ])
    def time_query_pg_vacuum_stats(self):
        query = """
            WITH
            	table_opts
            		AS (
            			SELECT
            				pg_class.oid,
            				relname,
            				nspname,
            				array_to_string(reloptions, '') AS relopts
            			FROM
            				pg_class
            				INNER JOIN pg_namespace AS ns ON
            						relnamespace = ns.oid
            		),
            	vacuum_settings
            		AS (
            			SELECT
            				oid,
            				relname,
            				nspname,
            				CASE
            				WHEN relopts
            				LIKE '%autovacuum_vacuum_threshold%'
            				THEN substring(
            					relopts,
            					'.*autovacuum_vacuum_threshold=([0-9.]+).*'
            				)::INT8
            				ELSE current_setting(
            					'autovacuum_vacuum_threshold'
            				)::INT8
            				END
            					AS autovacuum_vacuum_threshold,
            				CASE
            				WHEN relopts
            				LIKE '%autovacuum_vacuum_scale_factor%'
            				THEN substring(
            					relopts,
            					'.*autovacuum_vacuum_scale_factor=([0-9.]+).*'
            				)::FLOAT4
            				ELSE current_setting(
            					'autovacuum_vacuum_scale_factor'
            				)::FLOAT4
            				END
            					AS autovacuum_vacuum_scale_factor
            			FROM
            				table_opts
            		)
            SELECT
            	vacuum_settings.nspname AS schema,
            	vacuum_settings.relname AS table,
            	to_char(psut.last_vacuum, 'YYYY-MM-DD HH24:MI')
            		AS last_vacuum,
            	to_char(psut.last_autovacuum, 'YYYY-MM-DD HH24:MI')
            		AS last_autovacuum,
            	to_char(pg_class.reltuples, '9G999G999G999')
            		AS rowcount,
            	to_char(psut.n_dead_tup, '9G999G999G999')
            		AS dead_rowcount,
            	to_char(
            		autovacuum_vacuum_threshold
            		+ autovacuum_vacuum_scale_factor::DECIMAL
            			* pg_class.reltuples,
            		'9G999G999G999'
            	)
            		AS autovacuum_threshold,
            	CASE
            	WHEN autovacuum_vacuum_threshold
            	+ autovacuum_vacuum_scale_factor::DECIMAL
            		* pg_class.reltuples
            	< psut.n_dead_tup
            	THEN 'yes'
            	END
            		AS expect_autovacuum
            FROM
            	pg_stat_user_tables AS psut
            	INNER JOIN pg_class ON psut.relid = pg_class.oid
            	INNER JOIN vacuum_settings ON
            			pg_class.oid = vacuum_settings.oid
            ORDER BY
            	1;
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'pg-vacuum-stats',
        ])
    def time_query_queue(self):
        query = """
            SELECT
            	tool_id, state, count(tool_id) AS tool_count
            FROM
            	job
            WHERE
            	state IN ('queued', 'running')
            GROUP BY
            	tool_id, state
            ORDER BY
            	tool_count DESC;
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'queue',
        ])
    def time_query_queue_detail(self):
        query = """
            at or near "-": syntax error: unimplemented: this syntax
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'queue-detail',
        ])
    def time_query_queue_detail_by_handler(self):
        query = """
            
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'queue-detail-by-handler',
        ])
    def time_query_queue_overview(self):
        query = """
            WITH
            	queue
            		AS (
            			SELECT
            				regexp_replace(
            					tool_id,
            					'/[0-9.a-z+-]+$',
            					''
            				)::STRING
            					AS tool_id,
            				tool_version::STRING,
            				COALESCE(destination_id, 'unknown')::STRING
            					AS destination_id,
            				COALESCE(handler, 'unknown')::STRING
            					AS handler,
            				state::STRING,
            				COALESCE(job_runner_name, 'unknown')::STRING
            					AS job_runner_name,
            				count(*) AS count,
            				user_id::STRING AS user_id
            			FROM
            				job
            			WHERE
            				state = 'running'
            				OR state = 'queued'
            				OR state = 'new'
            			GROUP BY
            				tool_id,
            				tool_version,
            				destination_id,
            				handler,
            				state,
            				job_runner_name,
            				user_id
            		)
            SELECT
            	tool_id,
            	tool_version,
            	destination_id,
            	handler,
            	state,
            	job_runner_name,
            	sum(count),
            	user_id
            FROM
            	queue
            GROUP BY
            	tool_id,
            	tool_version,
            	destination_id,
            	handler,
            	state,
            	job_runner_name,
            	user_id;
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'queue-overview',
        ])
    def time_query_queue_time(self):
        query = """
            
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'queue-time',
        ])
    def time_query_recent_jobs(self):
        query = """
            
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'recent-jobs',
        ])
    def time_query_runtime_per_user(self):
        query = """
            
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'runtime-per-user',
        ])
    def time_query_tool_available_metrics(self):
        query = """
            
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'tool-available-metrics',
        ])
    def time_query_tool_errors(self):
        query = """
            SELECT
            	j.tool_id,
            	count(*) AS tool_runs,
            	sum(
            		CASE
            		WHEN j.state = 'error' THEN 1
            		ELSE 0
            		END
            	)::FLOAT8
            	/ count(*)
            		AS percent_errored,
            	sum(
            		CASE
            		WHEN j.state = 'failed' THEN 1
            		ELSE 0
            		END
            	)::FLOAT8
            	/ count(*)
            		AS percent_failed,
            	sum(CASE WHEN j.state = 'error' THEN 1 ELSE 0 END)
            		AS count_errored,
            	sum(CASE WHEN j.state = 'failed' THEN 1 ELSE 0 END)
            		AS count_failed,
            	j.handler
            FROM
            	job AS j
            WHERE
            	j.create_time > (now() - '4 weeks'::INTERVAL)
            GROUP BY
            	j.tool_id, j.handler
            HAVING
            	sum(
            		CASE
            		WHEN j.state IN ('error', 'failed') THEN 1
            		ELSE 0
            		END
            	)
            	* 100.0
            	/ count(*)
            	> 10.0
            ORDER BY
            	tool_runs DESC;
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'tool-errors',
        ])
    def time_query_tool_last_used_date(self):
        query = """
            at or near ")": syntax error: unimplemented: this syntax
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'tool-last-used-date',
        ])
    def time_query_tool_likely_broken(self):
        query = """
            SELECT
            	j.tool_id,
            	count(*) AS tool_runs,
            	sum(
            		CASE
            		WHEN j.state = 'error' THEN 1
            		ELSE 0
            		END
            	)::FLOAT8
            	/ count(*)
            		AS percent_errored,
            	sum(
            		CASE
            		WHEN j.state = 'failed' THEN 1
            		ELSE 0
            		END
            	)::FLOAT8
            	/ count(*)
            		AS percent_failed,
            	sum(CASE WHEN j.state = 'error' THEN 1 ELSE 0 END)
            		AS count_errored,
            	sum(CASE WHEN j.state = 'failed' THEN 1 ELSE 0 END)
            		AS count_failed,
            	j.handler
            FROM
            	job AS j
            WHERE
            	j.create_time > (now() - '4 weeks'::INTERVAL)
            GROUP BY
            	j.tool_id, j.handler
            HAVING
            	sum(
            		CASE
            		WHEN j.state IN ('error', 'failed') THEN 1
            		ELSE 0
            		END
            	)
            	* 100.0
            	/ count(*)
            	> 95.0
            	AND count(*) > 4
            ORDER BY
            	tool_runs DESC;
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'tool-likely-broken',
        ])
    def time_query_tool_metrics(self):
        query = """
            
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'tool-metrics',
        ])
    def time_query_tool_new_errors(self):
        query = """
            SELECT
            	j.tool_id,
            	count(*) AS tool_runs,
            	sum(
            		CASE
            		WHEN j.state = 'error' THEN 1
            		ELSE 0
            		END
            	)::FLOAT8
            	/ count(*)
            		AS percent_errored,
            	sum(
            		CASE
            		WHEN j.state = 'failed' THEN 1
            		ELSE 0
            		END
            	)::FLOAT8
            	/ count(*)
            		AS percent_failed,
            	sum(CASE WHEN j.state = 'error' THEN 1 ELSE 0 END)
            		AS count_errored,
            	sum(CASE WHEN j.state = 'failed' THEN 1 ELSE 0 END)
            		AS count_failed,
            	j.handler
            FROM
            	job AS j
            WHERE
            	j.tool_id
            	IN (
            			SELECT
            				tool_id
            			FROM
            				job AS j
            			WHERE
            				j.create_time
            				> (now() - '4 weeks'::INTERVAL)
            			GROUP BY
            				j.tool_id
            		)
            GROUP BY
            	j.tool_id, j.handler
            ORDER BY
            	percent_failed_errored DESC;
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'tool-new-errors',
        ])
    def time_query_tool_popularity(self):
        query = """
            at or near ")": syntax error: unimplemented: this syntax
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'tool-popularity',
        ])
    def time_query_tool_usage(self):
        query = """
            SELECT
            	j.tool_id, count(*) AS count
            FROM
            	job AS j
            GROUP BY
            	j.tool_id
            ORDER BY
            	count DESC;
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'tool-usage',
        ])
    def time_query_total_jobs(self):
        query = """
            SELECT
            	state, count(*)
            FROM
            	job
            GROUP BY
            	state
            ORDER BY
            	state;
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'total-jobs',
        ])
    def time_query_training_list(self):
        query = """
            at or near ")": syntax error: unimplemented: this syntax
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'training-list',
        ])
    def time_query_training_members_remove(self):
        query = """
            
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'training-members-remove',
        ])
    def time_query_training_members(self):
        query = """
            
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'training-members',
        ])
    def time_query_training_queue(self):
        query = """
            
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'training-queue',
        ])
    def time_query_ts_repos(self):
        query = """
            SELECT
            	tool_shed, owner, count(*)
            FROM
            	tool_shed_repository
            GROUP BY
            	tool_shed, owner;
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'ts-repos',
        ])
    def time_query_upload_gb_in_past_hour(self):
        query = """
            at or near ">": syntax error: unimplemented: this syntax
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'upload-gb-in-past-hour',
        ])
    def time_query_user_cpu_years(self):
        query = """
            SELECT
            	row_number() OVER (
            		ORDER BY
            			round(
            				sum(
            					a.metric_value * b.metric_value
            					/ 3600
            					/ 24
            					/ 365
            				),
            				2
            			)
            				DESC
            	)
            		AS rank,
            	job.user_id,
            	COALESCE(galaxy_user.username::STRING, 'Anonymous'),
            	round(
            		sum(
            			a.metric_value * b.metric_value
            			/ 3600
            			/ 24
            			/ 365
            		),
            		2
            	)
            		AS cpu_years
            FROM
            	job_metric_numeric AS a,
            	job_metric_numeric AS b,
            	job
            	FULL JOIN galaxy_user ON job.user_id = galaxy_user.id
            WHERE
            	b.job_id = a.job_id
            	AND a.job_id = job.id
            	AND a.metric_name = 'runtime_seconds'
            	AND b.metric_name = 'galaxy_slots'
            GROUP BY
            	job.user_id, galaxy_user.username
            ORDER BY
            	round(
            		sum(
            			a.metric_value * b.metric_value
            			/ 3600
            			/ 24
            			/ 365
            		),
            		2
            	)
            		DESC
            LIMIT
            	50;
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'user-cpu-years',
        ])
    def time_query_user_disk_quota(self):
        query = """
            WITH
            	user_basequota_list
            		AS (
            			SELECT
            				galaxy_user.id AS user_id,
            				basequota.bytes AS quota
            			FROM
            				galaxy_user,
            				quota AS basequota,
            				user_quota_association
            			WHERE
            				galaxy_user.id
            				= user_quota_association.user_id
            				AND basequota.id
            					= user_quota_association.quota_id
            				AND basequota.operation = '='
            				AND NOT basequota.deleted
            			GROUP BY
            				galaxy_user.id, basequota.bytes
            		),
            	user_basequota
            		AS (
            			SELECT
            				user_basequota_list.user_id,
            				max(user_basequota_list.quota) AS quota
            			FROM
            				user_basequota_list
            			GROUP BY
            				user_basequota_list.user_id
            		),
            	user_addquota_list
            		AS (
            			SELECT
            				galaxy_user.id AS user_id,
            				addquota.bytes AS quota
            			FROM
            				galaxy_user,
            				quota AS addquota,
            				user_quota_association
            			WHERE
            				galaxy_user.id
            				= user_quota_association.user_id
            				AND addquota.id
            					= user_quota_association.quota_id
            				AND addquota.operation = '+'
            				AND NOT addquota.deleted
            			GROUP BY
            				galaxy_user.id, addquota.bytes
            		),
            	user_addquota
            		AS (
            			SELECT
            				user_addquota_list.user_id,
            				sum(user_addquota_list.quota) AS quota
            			FROM
            				user_addquota_list
            			GROUP BY
            				user_addquota_list.user_id
            		),
            	user_minquota_list
            		AS (
            			SELECT
            				galaxy_user.id AS user_id,
            				minquota.bytes AS quota
            			FROM
            				galaxy_user,
            				quota AS minquota,
            				user_quota_association
            			WHERE
            				galaxy_user.id
            				= user_quota_association.user_id
            				AND minquota.id
            					= user_quota_association.quota_id
            				AND minquota.operation = '-'
            				AND NOT minquota.deleted
            			GROUP BY
            				galaxy_user.id, minquota.bytes
            		),
            	user_minquota
            		AS (
            			SELECT
            				user_minquota_list.user_id,
            				sum(user_minquota_list.quota) AS quota
            			FROM
            				user_minquota_list
            			GROUP BY
            				user_minquota_list.user_id
            		),
            	group_basequota_list
            		AS (
            			SELECT
            				galaxy_user.id AS user_id,
            				galaxy_group.id AS group_id,
            				basequota.bytes AS quota
            			FROM
            				galaxy_user,
            				galaxy_group,
            				quota AS basequota,
            				group_quota_association,
            				user_group_association
            			WHERE
            				galaxy_user.id
            				= user_group_association.user_id
            				AND galaxy_group.id
            					= user_group_association.group_id
            				AND basequota.id
            					= group_quota_association.quota_id
            				AND galaxy_group.id
            					= group_quota_association.group_id
            				AND basequota.operation = '='
            				AND NOT basequota.deleted
            			GROUP BY
            				galaxy_user.id,
            				galaxy_group.id,
            				basequota.bytes
            		),
            	group_basequota
            		AS (
            			SELECT
            				group_basequota_list.user_id,
            				group_basequota_list.group_id,
            				max(group_basequota_list.quota) AS quota
            			FROM
            				group_basequota_list
            			GROUP BY
            				group_basequota_list.user_id,
            				group_basequota_list.group_id
            		),
            	group_addquota_list
            		AS (
            			SELECT
            				galaxy_user.id AS user_id,
            				addquota.bytes AS quota
            			FROM
            				galaxy_user,
            				galaxy_group,
            				quota AS addquota,
            				group_quota_association,
            				user_group_association
            			WHERE
            				galaxy_user.id
            				= user_group_association.user_id
            				AND galaxy_group.id
            					= user_group_association.group_id
            				AND addquota.id
            					= group_quota_association.quota_id
            				AND galaxy_group.id
            					= group_quota_association.group_id
            				AND addquota.operation = '+'
            				AND NOT addquota.deleted
            			GROUP BY
            				galaxy_user.id, addquota.bytes
            		),
            	group_addquota
            		AS (
            			SELECT
            				group_addquota_list.user_id,
            				sum(group_addquota_list.quota) AS quota
            			FROM
            				group_addquota_list
            			GROUP BY
            				group_addquota_list.user_id
            		),
            	group_minquota_list
            		AS (
            			SELECT
            				galaxy_user.id AS user_id,
            				minquota.bytes AS quota
            			FROM
            				galaxy_user,
            				galaxy_group,
            				quota AS minquota,
            				group_quota_association,
            				user_group_association
            			WHERE
            				galaxy_user.id
            				= user_group_association.user_id
            				AND galaxy_group.id
            					= user_group_association.group_id
            				AND minquota.id
            					= group_quota_association.quota_id
            				AND galaxy_group.id
            					= group_quota_association.group_id
            				AND minquota.operation = '-'
            				AND NOT minquota.deleted
            			GROUP BY
            				galaxy_user.id,
            				galaxy_group.id,
            				galaxy_group.name,
            				minquota.bytes
            		),
            	group_minquota
            		AS (
            			SELECT
            				group_minquota_list.user_id,
            				sum(group_minquota_list.quota) AS quota
            			FROM
            				group_minquota_list
            			GROUP BY
            				group_minquota_list.user_id
            		),
            	all_user_default_quota
            		AS (
            			SELECT
            				galaxy_user.id AS user_id, quota.bytes
            			FROM
            				galaxy_user, quota
            			WHERE
            				quota.id
            				= (
            						SELECT
            							quota_id
            						FROM
            							default_quota_association
            					)
            		),
            	quotas
            		AS (
            			SELECT
            				all_user_default_quota.user_id AS aud_uid,
            				all_user_default_quota.bytes AS aud_quota,
            				user_basequota.user_id AS ubq_uid,
            				user_basequota.quota AS ubq_quota,
            				user_addquota.user_id AS uaq_uid,
            				user_addquota.quota AS uaq_quota,
            				user_minquota.user_id AS umq_uid,
            				user_minquota.quota AS umq_quota,
            				group_basequota.user_id AS gbq_uid,
            				group_basequota.quota AS gbq_quota,
            				group_addquota.user_id AS gaq_uid,
            				group_addquota.quota AS gaq_quota,
            				group_minquota.user_id AS gmq_uid,
            				group_minquota.quota AS gmq_quota
            			FROM
            				all_user_default_quota
            				FULL JOIN user_basequota ON
            						all_user_default_quota.user_id
            						= user_basequota.user_id
            				FULL JOIN user_addquota ON
            						all_user_default_quota.user_id
            						= user_addquota.user_id
            				FULL JOIN user_minquota ON
            						all_user_default_quota.user_id
            						= user_minquota.user_id
            				FULL JOIN group_basequota ON
            						all_user_default_quota.user_id
            						= group_basequota.user_id
            				FULL JOIN group_addquota ON
            						all_user_default_quota.user_id
            						= group_addquota.user_id
            				FULL JOIN group_minquota ON
            						all_user_default_quota.user_id
            						= group_minquota.user_id
            		),
            	computed_quotas
            		AS (
            			SELECT
            				aud_uid AS user_id,
            				COALESCE(
            					greatest(ubq_quota, gbq_quota),
            					aud_quota
            				)
            					AS base_quota,
            				COALESCE(uaq_quota, 0)
            				+ COALESCE(gaq_quota, 0)
            					AS add_quota,
            				COALESCE(umq_quota, 0)
            				+ COALESCE(gmq_quota, 0)
            					AS min_quota
            			FROM
            				quotas
            		)
            SELECT
            	row_number() OVER (
            		ORDER BY
            			(
            				computed_quotas.base_quota
            				+ computed_quotas.add_quota
            				- computed_quotas.min_quota
            			)
            				DESC
            	)
            		AS rank,
            	galaxy_user.id AS user_id,
            	COALESCE(galaxy_user.username::STRING, 'Anonymous'),
            	pg_size_pretty(
            		computed_quotas.base_quota
            		+ computed_quotas.add_quota
            		- computed_quotas.min_quota
            	)
            		AS quota
            FROM
            	computed_quotas, galaxy_user
            WHERE
            	computed_quotas.user_id = galaxy_user.id
            GROUP BY
            	galaxy_user.id,
            	galaxy_user.username,
            	computed_quotas.base_quota,
            	computed_quotas.add_quota,
            	computed_quotas.min_quota
            ORDER BY
            	(
            		computed_quotas.base_quota
            		+ computed_quotas.add_quota
            		- computed_quotas.min_quota
            	)
            		DESC
            LIMIT
            	50;
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'user-disk-quota',
        ])
    def time_query_user_disk_usage(self):
        query = """
            SELECT
            	row_number() OVER (
            		ORDER BY
            			sum(
            				COALESCE(
            					dataset.total_size,
            					dataset.file_size,
            					0
            				)
            			)
            				DESC
            	)
            		AS rank,
            	galaxy_user.id AS "user id",
            	COALESCE(galaxy_user.username::STRING, 'Anonymous'),
            	COALESCE(galaxy_user.email::STRING, 'Anonymous'),
            	sum(COALESCE(dataset.total_size, dataset.file_size, 0))
            		AS "storage usage"
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
            GROUP BY
            	galaxy_user.id
            ORDER BY
            	1
            LIMIT
            	50;
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'user-disk-usage',
        ])
    def time_query_user_gpu_years(self):
        query = """
            SELECT
            	row_number() OVER (
            		ORDER BY
            			round(
            				sum(
            					a.metric_value
            					* length(
            							replace(b.metric_value, ',', '')
            						)
            					/ 3600
            					/ 24
            					/ 365
            				),
            				2
            			)
            				DESC
            	)
            		AS rank,
            	job.user_id,
            	COALESCE(galaxy_user.username::STRING, 'Anonymous'),
            	round(
            		sum(
            			a.metric_value
            			* length(replace(b.metric_value, ',', ''))
            			/ 3600
            			/ 24
            			/ 365
            		),
            		2
            	)
            		AS gpu_years
            FROM
            	job_metric_numeric AS a,
            	job_metric_text AS b,
            	job
            	FULL JOIN galaxy_user ON job.user_id = galaxy_user.id
            WHERE
            	b.job_id = a.job_id
            	AND a.job_id = job.id
            	AND a.metric_name = 'runtime_seconds'
            	AND b.metric_name = 'CUDA_VISIBLE_DEVICES'
            GROUP BY
            	job.user_id, galaxy_user.username
            ORDER BY
            	round(
            		sum(
            			a.metric_value
            			* length(replace(b.metric_value, ',', ''))
            			/ 3600
            			/ 24
            			/ 365
            		),
            		2
            	)
            		DESC
            LIMIT
            	50;
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'user-gpu-years',
        ])
    def time_query_user_history_list(self):
        query = """
            
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'user-history-list',
        ])
    def time_query_user_recent_aggregate_jobs(self):
        query = """
            
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'user-recent-aggregate-jobs',
        ])
    def time_query_users_count(self):
        query = """
            SELECT
            	active, external, deleted, purged, count(*) AS count
            FROM
            	galaxy_user
            GROUP BY
            	active, external, deleted, purged;
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'users-count',
        ])
    def time_query_users_total(self):
        query = """
            SELECT count(*) FROM galaxy_user;
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'users-total',
        ])
    def time_query_users_with_oidc(self):
        query = """
            SELECT
            	provider, count(DISTINCT user_id)
            FROM
            	oidc_user_authnz_tokens
            GROUP BY
            	provider;
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'users-with-oidc',
        ])
    def time_query_workers(self):
        query = """
            SELECT
            	server_name, hostname, pid
            FROM
            	worker_process
            WHERE
            	pid IS NOT NULL;
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'workers',
        ])
    def time_query_workflow_connections(self):
        query = """
            SELECT
            	workflow.id AS wf_id,
            	workflow.update_time::DATE AS wf_updated,
            	ws_in.id AS in_id,
            	ws_in.tool_id AS in_tool,
            	ws_in.tool_version AS in_tool_v,
            	ws_out.id AS out_id,
            	ws_out.tool_id AS out_tool,
            	ws_out.tool_version AS out_tool_v,
            	sw.published AS published,
            	sw.deleted AS deleted,
            	workflow.has_errors AS has_errors
            FROM
            	workflow_step_connection AS wfc
            	LEFT JOIN workflow_step AS ws_in ON
            			ws_in.id = wfc.output_step_id
            	LEFT JOIN workflow_step_input AS wsi ON
            			wfc.input_step_input_id = wsi.id
            	LEFT JOIN workflow_step AS ws_out ON
            			ws_out.id = wsi.workflow_step_id
            	LEFT JOIN workflow_output AS wo ON
            			wsi.workflow_step_id = wfc.output_step_id
            	LEFT JOIN workflow ON ws_in.workflow_id = workflow.id
            	LEFT JOIN stored_workflow AS sw ON
            			sw.latest_workflow_id = workflow.id
            WHERE
            	workflow.id
            	IN (
            			SELECT
            				workflow.id
            			FROM
            				stored_workflow
            				LEFT JOIN workflow ON
            						stored_workflow.latest_workflow_id
            						= workflow.id
            		);
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'workflow-connections',
        ])
    def time_query_workflow_invocation_status(self):
        query = """
            SELECT
            	COALESCE(scheduler, 'none'),
            	COALESCE(handler, 'none'),
            	state,
            	count(*)
            FROM
            	workflow_invocation
            WHERE
            	state IN ('new', 'ready')
            GROUP BY
            	handler, scheduler, state;
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'workflow-invocation-status',
        ])
    def time_query_workflow_invocation_totals(self):
        query = """
            SELECT
            	COALESCE(state, 'unknown'), count(*)
            FROM
            	workflow_invocation
            GROUP BY
            	state;
        """
        query = subprocess.check_output([
            '/home/hxr/arbeit/galaxy/gxadmin/gxadmin',
            'query',
            'workflow-invocation-totals',
        ])
