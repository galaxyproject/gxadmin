import subprocess


class GxadminSuite:
    def time_query_collection_usage(self):
        query = """
            SELECT
            dc.collection_type, count(*)
            FROM
            history_dataset_collection_association as hdca
            INNER JOIN
            dataset_collection as dc
            ON hdca.collection_id = dc.id
            GROUP BY
            dc.collection_type
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'collection-usage',
        ])
    def time_query_data_origin_distribution(self):
        query = """
            WITH asdf AS (
            SELECT
            case when job.tool_id = 'upload1' then 'created' else 'derived' end AS origin,
            sum(coalesce(dataset.total_size, dataset.file_size, 0)) AS data,
            date_trunc('month', dataset.create_time) as created,
            COALESCE(job.user_id::text, '__UNKNOWN__')
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
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'data-origin-distribution',
        ])
    def time_query_data_origin_distribution_summary(self):
        query = """
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
            min(data) AS min,
            percentile_cont(0.25) WITHIN GROUP (ORDER BY data) ::bigint AS quant_1st,
            percentile_cont(0.50) WITHIN GROUP (ORDER BY data) ::bigint AS median,
            avg(data) AS mean,
            percentile_cont(0.75) WITHIN GROUP (ORDER BY data) ::bigint AS quant_3rd,
            percentile_cont(0.95) WITHIN GROUP (ORDER BY data) ::bigint AS perc_95,
            percentile_cont(0.99) WITHIN GROUP (ORDER BY data) ::bigint AS perc_99,
            max(data) AS max,
            sum(data) AS sum,
            stddev(data) AS stddev
            FROM user_job_data
            GROUP BY origin
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'data-origin-distribution-summary',
        ])
    def time_query_datasets_created_daily(self):
        query = """
            WITH temp_queue_times AS
            (select
            date_trunc('day', create_time AT TIME ZONE 'UTC'),
            sum(coalesce(total_size, file_size))
            from dataset
            group by date_trunc
            order by date_trunc desc)
            select
            min(sum) AS min,
            percentile_cont(0.25) WITHIN GROUP (ORDER BY sum) ::bigint AS quant_1st,
            percentile_cont(0.50) WITHIN GROUP (ORDER BY sum) ::bigint AS median,
            avg(sum) AS mean,
            percentile_cont(0.75) WITHIN GROUP (ORDER BY sum) ::bigint AS quant_3rd,
            percentile_cont(0.95) WITHIN GROUP (ORDER BY sum) ::bigint AS perc_95,
            percentile_cont(0.99) WITHIN GROUP (ORDER BY sum) ::bigint AS perc_99,
            max(sum) AS max,
            sum(sum) AS sum,
            stddev(sum) AS stddev
            from temp_queue_times
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'datasets-created-daily',
        ])
    def time_query_disk_usage(self):
        query = """
            SELECT
            object_store_id, sum(coalesce(dataset.total_size, dataset.file_size, 0))
            FROM dataset
            WHERE NOT purged
            GROUP BY object_store_id
            ORDER BY sum(coalesce(dataset.total_size, dataset.file_size, 0)) DESC
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'disk-usage',
        ])
    def time_query_errored_jobs(self):
        query = """
            SELECT
            job.id,
            job.create_time AT TIME ZONE 'UTC' as create_time,
            job.tool_id,
            job.tool_version,
            job.handler,
            job.destination_id,
            job.job_runner_external_id,
            
            COALESCE(galaxy_user.email::text, '__UNKNOWN__') AS email
            FROM
            job,
            galaxy_user
            WHERE
            job.create_time >= (now() AT TIME ZONE 'UTC' - ' hours'::interval) AND
            job.state = 'error' AND
            job.user_id = galaxy_user.id
            ORDER BY
            job.id
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'errored-jobs',
        ])
    def time_query_good_for_pulsar(self):
        query = """
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
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'good-for-pulsar',
        ])
    def time_query_group_cpu_seconds(self):
        query = """
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
            COALESCE(galaxy_group.name::text, 'Anonymous'),
            round(sum(user_job_info.cpu_seconds), 0) as cpu_seconds
            FROM user_job_info,
            galaxy_group,
            user_group_association
            WHERE user_job_info.user_id = user_group_association.user_id
            AND user_group_association.group_id = galaxy_group.id
            
            GROUP BY galaxy_group.id, galaxy_group.name
            ORDER BY round(sum(user_job_info.cpu_seconds), 0) DESC
            LIMIT 50
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'group-cpu-seconds',
        ])
    def time_query_group_gpu_time(self):
        query = """
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
            COALESCE(galaxy_group.name::text, 'Anonymous'),
            round(sum(user_job_info.gpu_seconds), 0) as gpu_seconds
            FROM user_job_info,
            galaxy_group,
            user_group_association
            WHERE user_job_info.user_id = user_group_association.user_id
            AND user_group_association.group_id = galaxy_group.id
            
            GROUP BY galaxy_group.id, galaxy_group.name
            ORDER BY round(sum(user_job_info.gpu_seconds), 0) DESC
            LIMIT 50
        """
        query = subprocess.check_output([
            './gxadmin',
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
            GROUP BY name
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'groups-list',
        ])
    def time_query_hdca_datasets(self):
        query = """
            SELECT element_index, hda_id, ldda_id, child_collection_id, element_identifier
            FROM dataset_collection_element
            WHERE dataset_collection_id = 
            ORDER by element_index asc
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'hdca-datasets',
        ])
    def time_query_hdca_info(self):
        query = """
            SELECT *
            FROM dataset_collection
            WHERE id =
        """
        query = subprocess.check_output([
            './gxadmin',
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
            LEFT JOIN job_to_output_dataset AS jtod ON j.id = jtod.job_id
            LEFT JOIN job_to_input_dataset AS jtid ON jtod.dataset_id = jtid.dataset_id
            LEFT JOIN job AS j2 ON jtid.job_id = j2.id
            WHERE
            jtid.job_id IS NOT NULL
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'history-connections',
        ])
    def time_query_history_contents(self):
        query = """
            select dataset_id, name, hid, visible, deleted, copied_from_history_dataset_association_id as copied_from from history_dataset_association where history_id = ;select collection_id, name, hid, visible, deleted, copied_from_history_dataset_collection_association_id as copied_from from history_dataset_collection_association where history_id = ;
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'history-contents',
        ])
    def time_query_history_runtime_system_by_tool(self):
        query = """
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'history-runtime-system-by-tool',
        ])
    def time_query_history_runtime_system(self):
        query = """
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'history-runtime-system',
        ])
    def time_query_history_runtime_wallclock(self):
        query = """
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'history-runtime-wallclock',
        ])
    def time_query_job_history(self):
        query = """
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'job-history',
        ])
    def time_query_job_info(self):
        query = """
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'job-info',
        ])
    def time_query_job_inputs(self):
        query = """
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'job-inputs',
        ])
    def time_query_job_outputs(self):
        query = """
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'job-outputs',
        ])
    def time_query_jobs_max_by_cpu_hours(self):
        query = """
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
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'jobs-max-by-cpu-hours',
        ])
    def time_query_jobs_nonterminal(self):
        query = """
            SELECT
            job.id, job.tool_id, job.state, job.create_time AT TIME ZONE 'UTC', job.job_runner_name, job.job_runner_external_id, job.handler, COALESCE(job.user_id::text, 'anon')
            FROM
            job
            LEFT OUTER JOIN
            galaxy_user ON job.user_id = galaxy_user.id
            WHERE
            true AND job.state IN ('new', 'queued', 'running')
            ORDER BY job.id ASC
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'jobs-nonterminal',
        ])
    def time_query_jobs_per_user(self):
        query = """
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'jobs-per-user',
        ])
    def time_query_jobs_queued(self):
        query = """
            SELECT
            CASE WHEN job_runner_external_id IS NOT null THEN 'processed' ELSE 'unprocessed' END as n,
            count(*)
            FROM
            job
            WHERE
            state = 'queued'
            GROUP BY n
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'jobs-queued',
        ])
    def time_query_jobs_queued_internal_by_handler(self):
        query = """
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
        """
        query = subprocess.check_output([
            './gxadmin',
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
            AND job.handler = 'handler0'
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'jobs-ready-to-run',
        ])
    def time_query_largest_collection(self):
        query = """
            WITH temp_table_collection_count AS (
            SELECT count(*)
            FROM dataset_collection_element
            GROUP BY dataset_collection_id
            ORDER BY count desc
            )
            select max(count) as count from temp_table_collection_count
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'largest-collection',
        ])
    def time_query_largest_histories(self):
        query = """
            SELECT
            sum(coalesce(dataset.total_size, dataset.file_size, 0)) as total_size,
            history.id,
            substring(history.name, 1, 10),
            COALESCE(galaxy_user.username::text, '__UNKNOWN__')
            FROM
            dataset
            JOIN history_dataset_association on dataset.id = history_dataset_association.dataset_id
            JOIN history on history_dataset_association.history_id = history.id
            JOIN galaxy_user on history.user_id = galaxy_user.id
            GROUP BY history.id, history.name, history.user_id, galaxy_user.username
            ORDER BY sum(coalesce(dataset.total_size, dataset.file_size, 0)) DESC
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'largest-histories',
        ])
    def time_query_latest_users(self):
        query = """
            SELECT
            id,
            create_time AT TIME ZONE 'UTC' as create_time,
            pg_size_pretty(disk_usage) as disk_usage,
            COALESCE(username::text, '__UNKNOWN__') as username,
            COALESCE(email::text, '__UNKNOWN__') as email,
            array_to_string(ARRAY(
            select galaxy_group.name from galaxy_group where id in (
            select group_id from user_group_association where user_group_association.user_id = galaxy_user.id
            )
            ), ' ') as groups,
            active
            FROM galaxy_user
            ORDER BY create_time desc
            LIMIT 40
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'latest-users',
        ])
    def time_query_monthly_cpu_stats(self):
        query = """
            SELECT
            date_trunc('month', job.create_time  AT TIME ZONE 'UTC')::date as month,
            round(sum((a.metric_value * b.metric_value) / 3600 / 24 / 365 ), 2) as cpu_years,
            round(sum((a.metric_value * b.metric_value) / 3600 ), 2) as cpu_hours
            FROM
            job_metric_numeric a,
            job_metric_numeric b,
            job
            WHERE
            b.job_id = a.job_id
            AND a.job_id = job.id
            AND a.metric_name = 'runtime_seconds'
            AND b.metric_name = 'galaxy_slots'
            
            GROUP BY month
            ORDER BY month DESC
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'monthly-cpu-stats',
        ])
    def time_query_monthly_cpu_years(self):
        query = """
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
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'monthly-cpu-years',
        ])
    def time_query_monthly_data(self):
        query = """
            SELECT
            date_trunc('month', dataset.create_time AT TIME ZONE 'UTC')::date AS month,
            sum(coalesce(dataset.total_size, dataset.file_size, 0))
            FROM
            dataset
            
            GROUP BY
            month
            ORDER BY
            month DESC
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'monthly-data',
        ])
    def time_query_monthly_gpu_years(self):
        query = """
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
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'monthly-gpu-years',
        ])
    def time_query_monthly_jobs(self):
        query = """
            SELECT
            date_trunc('month', job.create_time AT TIME ZONE 'UTC')::DATE AS month,
            count(*)
            FROM
            job
            
            GROUP BY
            month
            ORDER BY
            month DESC
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'monthly-jobs',
        ])
    def time_query_monthly_users_active(self):
        query = """
            SELECT
            date_trunc('month', job.create_time AT TIME ZONE 'UTC')::date as month,
            count(distinct user_id) as active_users
            FROM job
            
            GROUP BY month
            ORDER BY month DESC
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'monthly-users-active',
        ])
    def time_query_monthly_users_registered(self):
        query = """
            SELECT
            date_trunc('month', galaxy_user.create_time)::DATE AS month,
            count(*)
            FROM
            galaxy_user
            
            GROUP BY
            month
            ORDER BY
            month DESC
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'monthly-users-registered',
        ])
    def time_query_old_histories(self):
        query = """
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'old-histories',
        ])
    def time_query_pg_cache_hit(self):
        query = """
            SELECT
            sum(heap_blks_read) as heap_read,
            sum(heap_blks_hit)  as heap_hit,
            sum(heap_blks_hit) / (sum(heap_blks_hit) + sum(heap_blks_read)) as ratio
            FROM
            pg_statio_user_tables
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'pg-cache-hit',
        ])
    def time_query_pg_index_size(self):
        query = """
            SELECT
            c.relname AS name,
            sum(c.relpages::bigint*8192)::bigint AS size
            FROM pg_class c
            LEFT JOIN pg_namespace n ON (n.oid = c.relnamespace)
            WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
            AND n.nspname !~ '^pg_toast'
            AND c.relkind='i'
            GROUP BY c.relname
            ORDER BY sum(c.relpages) DESC
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'pg-index-size',
        ])
    def time_query_pg_index_usage(self):
        query = """
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
        """
        query = subprocess.check_output([
            './gxadmin',
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
            pg_stat_activity.query <> ''::text
            AND state <> 'idle'
            AND now() - pg_stat_activity.query_start > interval '5 minutes'
            ORDER BY
            now() - pg_stat_activity.query_start DESC
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'pg-long-running-queries',
        ])
    def time_query_pg_mandelbrot(self):
        query = """
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
        """
        query = subprocess.check_output([
            './gxadmin',
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
            pg_stat_bgwriter
        """
        query = subprocess.check_output([
            './gxadmin',
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
            pg_stat_user_tables
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'pg-stat-user-tables',
        ])
    def time_query_pg_table_bloat(self):
        query = """
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
            type, schemaname, object_name, bloat, raw_waste as waste
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
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'pg-table-bloat',
        ])
    def time_query_pg_table_size(self):
        query = """
            SELECT
            c.relname AS name,
            pg_table_size(c.oid) AS size,
            pg_indexes_size(c.oid) AS index_size
            FROM pg_class c
            LEFT JOIN pg_namespace n ON (n.oid = c.relnamespace)
            WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
            AND n.nspname !~ '^pg_toast'
            AND c.relkind='r'
            ORDER BY pg_table_size(c.oid) DESC
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'pg-table-size',
        ])
    def time_query_pg_unused_indexes(self):
        query = """
            SELECT
            schemaname || '.' || relname AS table,
            indexrelname AS index,
            pg_relation_size(i.indexrelid) AS index_size,
            COALESCE(idx_scan, 0) as index_scans
            FROM pg_stat_user_indexes ui
            JOIN pg_index i ON ui.indexrelid = i.indexrelid
            WHERE NOT indisunique AND idx_scan < 50 AND pg_relation_size(relid) > 5 * 8192
            ORDER BY
            pg_relation_size(i.indexrelid) / nullif(idx_scan, 0) DESC NULLS FIRST,
            pg_relation_size(i.indexrelid) DESC
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'pg-unused-indexes',
        ])
    def time_query_pg_vacuum_stats(self):
        query = """
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
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'pg-vacuum-stats',
        ])
    def time_query_queue(self):
        query = """
            SELECT
            tool_id, state, count(tool_id) as tool_count
            FROM
            job
            WHERE
            state in ('queued', 'running')
            GROUP BY
            tool_id, state
            ORDER BY
            tool_count desc
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'queue',
        ])
    def time_query_queue_detail(self):
        query = """
            SELECT
            job.state,
            job.id,
            job.job_runner_external_id as extid,
            job.tool_id,
            COALESCE(galaxy_user.username::text, 'Anonymous User'),
            ( now() AT TIME ZONE 'UTC' - job.create_time) as time_since_creation,
            job.handler,
            job.job_runner_name,
            job.destination_id
            FROM job
            FULL OUTER JOIN galaxy_user ON job.user_id = galaxy_user.id
            WHERE
            state in ('running', 'queued')
            ORDER BY
            state desc,
            time_since_creation desc
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'queue-detail',
        ])
    def time_query_queue_detail_by_handler(self):
        query = """
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'queue-detail-by-handler',
        ])
    def time_query_queue_overview(self):
        query = """
            WITH queue AS (
            SELECT
            regexp_replace(tool_id, '/[0-9.a-z+-]+$', '')::TEXT AS tool_id,
            tool_version::TEXT,
            COALESCE(destination_id, 'unknown')::TEXT AS destination_id,
            COALESCE(handler, 'unknown')::TEXT AS handler,
            state::TEXT,
            COALESCE(job_runner_name, 'unknown')::TEXT AS job_runner_name,
            count(*) AS count,
            user_id::TEXT AS user_id
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
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'queue-overview',
        ])
    def time_query_queue_time(self):
        query = """
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'queue-time',
        ])
    def time_query_recent_jobs(self):
        query = """
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'recent-jobs',
        ])
    def time_query_runtime_per_user(self):
        query = """
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'runtime-per-user',
        ])
    def time_query_tool_available_metrics(self):
        query = """
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'tool-available-metrics',
        ])
    def time_query_tool_errors(self):
        query = """
            SELECT
            j.tool_id,
            count(*) AS tool_runs,
            sum(CASE WHEN j.state = 'error'  THEN 1 ELSE 0 END)::float / count(*) AS percent_errored,
            sum(CASE WHEN j.state = 'failed' THEN 1 ELSE 0 END)::float / count(*) AS percent_failed,
            sum(CASE WHEN j.state = 'error'  THEN 1 ELSE 0 END) AS count_errored,
            sum(CASE WHEN j.state = 'failed' THEN 1 ELSE 0 END) AS count_failed,
            j.handler
            FROM
            job AS j
            WHERE
            j.create_time > (now() - '4 weeks'::INTERVAL)
            GROUP BY
            j.tool_id, j.handler
            HAVING
            sum(CASE WHEN j.state IN ('error', 'failed') THEN 1 ELSE 0 END) * 100.0 / count(*) > 10.0
            ORDER BY
            tool_runs DESC
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'tool-errors',
        ])
    def time_query_tool_last_used_date(self):
        query = """
            select max(date_trunc('month', create_time AT TIME ZONE 'UTC')), tool_id from job group by tool_id order by max desc
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'tool-last-used-date',
        ])
    def time_query_tool_likely_broken(self):
        query = """
            SELECT
            j.tool_id,
            count(*) AS tool_runs,
            sum(CASE WHEN j.state = 'error'  THEN 1 ELSE 0 END)::float / count(*) AS percent_errored,
            sum(CASE WHEN j.state = 'failed' THEN 1 ELSE 0 END)::float / count(*) AS percent_failed,
            sum(CASE WHEN j.state = 'error'  THEN 1 ELSE 0 END) AS count_errored,
            sum(CASE WHEN j.state = 'failed' THEN 1 ELSE 0 END) AS count_failed,
            j.handler
            FROM
            job AS j
            WHERE
            j.create_time > (now() - '4 weeks'::INTERVAL)
            GROUP BY
            j.tool_id, j.handler
            HAVING
            sum(CASE WHEN j.state IN ('error', 'failed') THEN 1 ELSE 0 END) * 100.0 / count(*) > 95.0
            AND count(*) > 4
            ORDER BY
            tool_runs DESC
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'tool-likely-broken',
        ])
    def time_query_tool_metrics(self):
        query = """
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'tool-metrics',
        ])
    def time_query_tool_new_errors(self):
        query = """
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
            WHERE j.create_time > (now() - '4 weeks'::INTERVAL)
            GROUP BY j.tool_id
            )
            GROUP BY j.tool_id, j.handler
            ORDER BY percent_failed_errored DESC
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'tool-new-errors',
        ])
    def time_query_tool_popularity(self):
        query = """
            SELECT
            tool_id,
            date_trunc('month', create_time AT TIME ZONE 'UTC')::date as month,
            count(*)
            FROM job
            WHERE create_time > (now() AT TIME ZONE 'UTC' - '24 months'::interval)
            GROUP BY tool_id, month
            ORDER BY month desc, count desc
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'tool-popularity',
        ])
    def time_query_tool_usage(self):
        query = """
            SELECT
            j.tool_id, count(*) AS count
            FROM job j
            
            GROUP BY j.tool_id
            ORDER BY count DESC
        """
        query = subprocess.check_output([
            './gxadmin',
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
            state
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'total-jobs',
        ])
    def time_query_training_list(self):
        query = """
            SELECT
            substring(name from 10) as name,
            date_trunc('day', create_time AT TIME ZONE 'UTC')::date as created
            
            FROM galaxy_group
            WHERE name like 'training-%' AND deleted = false
            ORDER BY create_time DESC
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'training-list',
        ])
    def time_query_training_members_remove(self):
        query = """
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'training-members-remove',
        ])
    def time_query_training_members(self):
        query = """
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'training-members',
        ])
    def time_query_training_queue(self):
        query = """
        """
        query = subprocess.check_output([
            './gxadmin',
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
            tool_shed, owner
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'ts-repos',
        ])
    def time_query_upload_gb_in_past_hour(self):
        query = """
            SELECT
            coalesce(sum(coalesce(dataset.total_size, coalesce(dataset.file_size, 0))), 0),
            1 as hours
            FROM
            job
            LEFT JOIN job_to_output_dataset ON job.id = job_to_output_dataset.job_id
            LEFT JOIN history_dataset_association ON
            job_to_output_dataset.dataset_id = history_dataset_association.id
            LEFT JOIN dataset ON history_dataset_association.dataset_id = dataset.id
            WHERE
            job.tool_id = 'upload1'
            AND job.create_time AT TIME ZONE 'UTC' > (now() - '1 hours'::INTERVAL)
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'upload-gb-in-past-hour',
        ])
    def time_query_user_cpu_years(self):
        query = """
            SELECT
            row_number() OVER (ORDER BY round(sum((a.metric_value * b.metric_value) / 3600 / 24 / 365), 2) DESC) as rank,
            job.user_id,
            COALESCE(galaxy_user.username::text, 'Anonymous'),
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
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'user-cpu-years',
        ])
    def time_query_user_disk_quota(self):
        query = """
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
            COALESCE(galaxy_user.username::text, 'Anonymous'),
            pg_size_pretty(computed_quotas.base_quota + computed_quotas.add_quota - computed_quotas.min_quota) as "quota"
            FROM computed_quotas,
            galaxy_user
            WHERE computed_quotas.user_id = galaxy_user.id
            GROUP BY galaxy_user.id, galaxy_user.username, computed_quotas.base_quota, computed_quotas.add_quota, computed_quotas.min_quota
            ORDER BY (computed_quotas.base_quota + computed_quotas.add_quota - computed_quotas.min_quota) DESC
            LIMIT 50
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'user-disk-quota',
        ])
    def time_query_user_disk_usage(self):
        query = """
            SELECT
            row_number() OVER (ORDER BY sum(coalesce(dataset.total_size, dataset.file_size, 0)) DESC) as rank,
            galaxy_user.id as "user id",
            COALESCE(galaxy_user.username::text, 'Anonymous'),
            COALESCE(galaxy_user.email::text, 'Anonymous'),
            sum(coalesce(dataset.total_size, dataset.file_size, 0)) as "storage usage"
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
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'user-disk-usage',
        ])
    def time_query_user_gpu_years(self):
        query = """
            SELECT
            row_number() OVER (ORDER BY round(sum((a.metric_value * length(replace(b.metric_value, ',', ''))) / 3600 / 24 / 365), 2) DESC) as rank,
            job.user_id,
            COALESCE(galaxy_user.username::text, 'Anonymous'),
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
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'user-gpu-years',
        ])
    def time_query_user_history_list(self):
        query = """
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'user-history-list',
        ])
    def time_query_user_recent_aggregate_jobs(self):
        query = """
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'user-recent-aggregate-jobs',
        ])
    def time_query_users_count(self):
        query = """
            SELECT
            active, external, deleted, purged, count(*) as count
            FROM
            galaxy_user
            GROUP BY
            active, external, deleted, purged
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'users-count',
        ])
    def time_query_users_total(self):
        query = """
            SELECT count(*) FROM galaxy_user
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'users-total',
        ])
    def time_query_users_with_oidc(self):
        query = """
            SELECT provider, count(distinct user_id) FROM oidc_user_authnz_tokens GROUP BY provider
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'users-with-oidc',
        ])
    def time_query_workers(self):
        query = """
            SELECT
            server_name,
            hostname,
            pid
            FROM
            worker_process
            WHERE
            pid IS NOT NULL
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'workers',
        ])
    def time_query_workflow_connections(self):
        query = """
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
            WHERE
            workflow.id in (
            SELECT
             workflow.id
            FROM
             stored_workflow
            LEFT JOIN
             workflow on stored_workflow.latest_workflow_id = workflow.id
            )
        """
        query = subprocess.check_output([
            './gxadmin',
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
            WHERE state in ('new', 'ready')
            GROUP BY handler, scheduler, state
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'workflow-invocation-status',
        ])
    def time_query_workflow_invocation_totals(self):
        query = """
            SELECT
            COALESCE(state, 'unknown'), count(*)
            FROM
            workflow_invocation
            GROUP BY state
        """
        query = subprocess.check_output([
            './gxadmin',
            'query',
            'workflow-invocation-totals',
        ])
