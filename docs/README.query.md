# query

Command | Description
------- | -----------
[`query aq`](#query-aq) | Given a list of IDs from a table (e.g. 'job'), access a specific column from that table
[`query archivable-histories`](#query-archivable-histories) | query archivable-histories [--user-last-active=360] [--history-last-active=360] [--size]
[`query collection-usage`](#query-collection-usage) | Information about how many collections of various types are used
[`query data-origin-distribution`](#query-data-origin-distribution) | data sources (uploaded vs derived)
[`query data-origin-distribution-merged`](#query-data-origin-distribution-merged) | Per-user monthly total data volume (uploaded + derived merged)
[`query data-origin-distribution-summary`](#query-data-origin-distribution-summary) | breakdown of data sources (uploaded vs derived)
[`query dataset-count`](#query-dataset-count) | Count the number of datasets.
[`query datasets-created-daily`](#query-datasets-created-daily) | The min/max/average/p95/p99 of total size of datasets created in a single day.
[`query dataset-usage-and-imports`](#query-dataset-usage-and-imports) | Fetch limited information about which users and histories are using a specific dataset from disk.
[`query destination-queue-run-time`](#query-destination-queue-run-time) | The average/median/95%/99% tool spends in queue/run state grouped by tool and destination.
[`query disk-usage`](#query-disk-usage) | Disk usage per object store.
[`query disk-usage-library`](#query-disk-usage-library) | Retrieve an approximation of the disk usage for a data library
[`query dump-users`](#query-dump-users) | Dump the list of users and their emails
[`query errored-jobs`](#query-errored-jobs) | Lists jobs that errored in the last N hours.
[`query good-for-pulsar`](#query-good-for-pulsar) | Look for jobs EU would like to send to pulsar
[`query group-cpu-seconds`](#query-group-cpu-seconds) | Retrieve an approximation of the CPU time in seconds for group(s)
[`query group-gpu-time`](#query-group-gpu-time) | Retrieve an approximation of the GPU time for users
[`query groups-list`](#query-groups-list) | List all groups known to Galaxy
[`query hdca-datasets`](#query-hdca-datasets) | List of files in a dataset collection
[`query hdca-info`](#query-hdca-info) | Information on a dataset collection
[`query history-connections`](#query-history-connections) | The connections of tools, from output to input, in histories (tool_predictions)
[`query history-contents`](#query-history-contents) | List datasets and/or collections in a history
[`query history-core-hours`](#query-history-core-hours) | Produces the median core hour count for histories matching a name filter
[`query history-count`](#query-history-count) | Count the number of histories.
[`query history-exports`](#query-history-exports) | List history exports ordered by most recent.
[`query history-runtime-system`](#query-history-runtime-system) | Sum of runtimes by all jobs in a history
[`query history-runtime-system-by-tool`](#query-history-runtime-system-by-tool) | Sum of runtimes by all jobs in a history, split by tool
[`query history-runtime-wallclock`](#query-history-runtime-wallclock) | Time as elapsed by a clock on the wall
[`query job-history`](#query-job-history) | Job state history for a specific job
[`query job-info`](#query-job-info) | Retrieve information about jobs given some job IDs
[`query job-inputs`](#query-job-inputs) | Input datasets to a specific job
[`query job-metrics`](#query-job-metrics) | Retrieves input size, runtime, memory for all executed jobs
[`query job-outputs`](#query-job-outputs) | Output datasets from a specific job
[`query jobs-max-by-cpu-days`](#query-jobs-max-by-cpu-days) | Top 10 jobs by CPU days consumed (requires CGroups metrics)
[`query jobs-nonterminal`](#query-jobs-nonterminal) | Job info of nonterminal jobs separated by user
[`query jobs-per-user`](#query-jobs-per-user) | Number of jobs run by a specific user
[`query jobs-queued`](#query-jobs-queued) | How many queued jobs have external cluster IDs
[`query jobs-queued-internal-by-handler`](#query-jobs-queued-internal-by-handler) | How many queued jobs do not have external IDs, by handler
[`query jobs-ready-to-run`](#query-jobs-ready-to-run) | Find jobs ready to run (Mostly a performance test)
[`query job-state`](#query-job-state) | Get current job state given a job ID
[`query job-state-stats`](#query-job-state-stats) | Shows all jobs states within a time interval (default: 30 days) in a table counted by state
[`query jobs`](#query-jobs) | List jobs ordered by most recently updated. = is required.
[`query large-old-histories`](#query-large-old-histories) | Find large, old histories that probably should be deleted.
[`query largest-collection`](#query-largest-collection) | Returns the size of the single largest collection
[`query largest-dataset-users`](#query-largest-dataset-users) | Get largest datasets by users
[`query largest-histories`](#query-largest-histories) | Largest histories in Galaxy
[`query latest-users`](#query-latest-users) | 40 recently registered users
[`query live-tuples`](#query-live-tuples) | Estimate table row counts using the n_live_tup stat
[`query longest-running-jobs-by-destination`](#query-longest-running-jobs-by-destination) | List the longest (currently) running jobs on the Galaxy server by destination
[`query memory-and-cpu-on-same-node`](#query-memory-and-cpu-on-same-node) | Memory and CPU cgroup metrics for jobs that ran on a given host
[`query monthly-cpu-stats`](#query-monthly-cpu-stats) | CPU years/hours allocated to tools by month (+ nb of users)
[`query monthly-cpu-years`](#query-monthly-cpu-years) | CPU years allocated to tools by month
[`query monthly-data`](#query-monthly-data) | Number of active users per month, running jobs
[`query monthly-gpu-years`](#query-monthly-gpu-years) | GPU years allocated to tools by month
[`query monthly-job-runtimes`](#query-monthly-job-runtimes) | Summation of total job run times per user per destination over a period of time
[`query monthly-jobs-by-new-multiday-users`](#query-monthly-jobs-by-new-multiday-users) | Number of jobs run by newly registered users that ran jobs more than a day
[`query monthly-jobs-by-new-users`](#query-monthly-jobs-by-new-users) | Number of jobs run by new users in the given month
[`query monthly-jobs`](#query-monthly-jobs) | Number of jobs run each month
[`query monthly-users-active`](#query-monthly-users-active) | Number of active users per month, running jobs
[`query monthly-users-registered`](#query-monthly-users-registered) | Number of users registered
[`query monthly-workflow-invocations`](#query-monthly-workflow-invocations) | Workflow invocations by month
[`query most-used-tools-by-destination`](#query-most-used-tools-by-destination) | List tools with the highest job count on the Galaxy server by destination
[`query old-histories`](#query-old-histories) | Lists histories that haven't been updated (used) for <weeks>
[`query pg-cache-hit`](#query-pg-cache-hit) | Check postgres in-memory cache hit ratio
[`query pg-column-size`](#query-pg-column-size) | Estimate the size of columns in a table
[`query pg-index-size`](#query-pg-index-size) | show table and index bloat in your database ordered by most wasteful
[`query pg-index-usage`](#query-pg-index-usage) | calculates your index hit rate (effective databases are at 99% and up)
[`query pg-long-running-queries`](#query-pg-long-running-queries) | show all queries longer than five minutes by descending duration
[`query pg-mandelbrot`](#query-pg-mandelbrot) | show the mandlebrot set
[`query pg-rows-per-table`](#query-pg-rows-per-table) | Print rows per table
[`query pg-stat-bgwriter`](#query-pg-stat-bgwriter) | Stats about the behaviour of the bgwriter, checkpoints, buffers, etc.
[`query pg-stat-user-tables`](#query-pg-stat-user-tables) | stats about tables (tuples, index scans, vacuums, analyzes)
[`query pg-table-bloat`](#query-pg-table-bloat) | show table and index bloat in your database ordered by most wasteful
[`query pg-table-size`](#query-pg-table-size) | show the size of the tables (excluding indexes), descending by size
[`query pg-unused-indexes`](#query-pg-unused-indexes) | show unused and almost unused indexes
[`query pg-vacuum-stats`](#query-pg-vacuum-stats) | show dead rows and whether an automatic vacuum is expected to be triggered
[`query potentially-duplicated-datasets`](#query-potentially-duplicated-datasets) | Find duplicated datasets in your database "cheaply" (i.e. by unique(user+file_size))
[`query pulsar-gb-transferred`](#query-pulsar-gb-transferred) | Counts up datasets transferred and output file size produced by jobs running on destinations like pulsar_*
[`query q`](#query-q) | Passes a raw SQL query directly through to the database
[`query queue`](#query-queue) | Brief overview of currently running jobs grouped by tool (default) or other columns
[`query queue-detail`](#query-queue-detail) | Detailed overview of running and queued jobs
[`query queue-detail-by-handler`](#query-queue-detail-by-handler) | List jobs for a specific handler
[`query queue-details-drm`](#query-queue-details-drm) | Detailed overview of running and queued jobs with cores/mem info
[`query queue-overview`](#query-queue-overview) | View used mostly for monitoring
[`query queue-time`](#query-queue-time) | The average/95%/99% a specific tool spends in queue state.
[`query recent-jobs`](#query-recent-jobs) | Jobs run in the past <hours> (in any state)
[`query runtime-per-user`](#query-runtime-per-user) | computation time of user (by email)
[`query tool-available-metrics`](#query-tool-available-metrics) | list all available metrics for a given tool
[`query tool-errors`](#query-tool-errors) | Summarize percent of tool runs in error over the past weeks for all tools that have failed (most popular tools first)
[`query tool-last-used-date`](#query-tool-last-used-date) | When was the most recent invocation of every tool
[`query tool-likely-broken`](#query-tool-likely-broken) | Find tools that have been executed in recent weeks that are (or were due to job running) likely substantially broken
[`query tool-memory-efficiency`](#query-tool-memory-efficiency) | View the efficiency of recent jobs
[`query tool-memory-per-inputs`](#query-tool-memory-per-inputs) | See memory usage and inout size data
[`query tool-metrics`](#query-tool-metrics) | See values of a specific metric
[`query tool-new-errors`](#query-tool-new-errors) | Summarize percent of tool runs in error over the past weeks for "new tools"
[`query tool-popularity`](#query-tool-popularity) | Most run tools by month (tool_predictions)
[`query tools-usage-per-month`](#query-tools-usage-per-month) | By default, startmonth is 1 year ago and end month is current month. tool1, tool2 etc. should correspond to the tool_id with the same format as requested: toolshed.g2.bx.psu.edu/repos/devteam/bowtie2/bowtie2/2.5.0+galaxy0,Cut1 for default, devteam/bowtie2/bowtie2/2.5.0+galaxy0,Cut1 for --short_tool_id, bowtie2/2.5.0+galaxy0,Cut1 for --super_short_tool_id etc...
[`query tools-usage`](#query-tools-usage) | tool1, tool2 etc. should correspond to the tool_id with the same format as requested: toolshed.g2.bx.psu.edu/repos/devteam/bowtie2/bowtie2/2.5.0+galaxy0,Cut1 for default, devteam/bowtie2/bowtie2/2.5.0+galaxy0,Cut1 for --short_tool_id, bowtie2/2.5.0+galaxy0,Cut1 for --super_short_tool_id etc...
[`query tool-usage-over-time`](#query-tool-usage-over-time) | Counts of tool runs by month, filtered by a tool id search
[`query tool-usage`](#query-tool-usage) | Counts of tool runs in the past weeks (default = all)
[`query tool-use-by-group`](#query-tool-use-by-group) | Lists count of tools used by all users in a group
[`query total-jobs`](#query-total-jobs) | Total number of jobs run by Galaxy instance.
[`query tpt-tool-cpu`](#query-tpt-tool-cpu) | Start year is required. Formula returns sum if blank.
[`query tpt-tool-memory`](#query-tpt-tool-memory) | Start year is required. Formula returns sum if blank.
[`query tpt-tool-users`](#query-tpt-tool-users) | Start year is required.
[`query training-list`](#query-training-list) | List known trainings
[`query training-members`](#query-training-members) | List users in a specific training
[`query training-members-remove`](#query-training-members-remove) | Remove a user from a training
[`query training-queue`](#query-training-queue) | Jobs currently being run by people in a given training
[`query ts-repos`](#query-ts-repos) | Counts of toolshed repositories by toolshed and owner.
[`query upload-gb-in-past-hour`](#query-upload-gb-in-past-hour) | Sum in bytes of files uploaded in the past hour
[`query user-cpu-years`](#query-user-cpu-years) | CPU years allocated to tools by user
[`query user-disk-quota`](#query-user-disk-quota) | Retrieves the 50 users with the largest quotas
[`query user-disk-usage`](#query-user-disk-usage) | Retrieve an approximation of the disk usage for users
[`query user-gpu-years`](#query-user-gpu-years) | GPU years allocated to tools by user
[`query user-history-list`](#query-user-history-list) | List a user's (by email/id/username) histories.
[`query user-info`](#query-user-info) | Retrieve information about users given some user identifiers (id, username or email)
[`query user-recent-aggregate-jobs`](#query-user-recent-aggregate-jobs) | Show aggregate information for jobs in past N days for user (by email/id/username)
[`query users-count`](#query-users-count) | Shows sums of active/external/deleted/purged accounts
[`query users-engaged-multiday`](#query-users-engaged-multiday) | Number of users running jobs for more than a day
[`query users-total`](#query-users-total) | Total number of Galaxy users (incl deleted, purged, inactive).
[`query users-with-oidc`](#query-users-with-oidc) | How many users logged in with OIDC
[`query user-tool-usage-over-time`](#query-user-tool-usage-over-time) | Counts distinct users per tool by month for the last 5 years (default = all users)
[`query user-tool-usage`](#query-user-tool-usage) | Counts distinct users per tool for the last 5 years (default = all users)
[`query workers`](#query-workers) | Retrieve a list of Galaxy worker processes
[`query workflow-connections`](#query-workflow-connections) | The connections of tools, from output to input, in the latest (or all) versions of user workflows (tool_predictions)
[`query workflow-count`](#query-workflow-count) | Count the number of workflow.
[`query workflow-invocation-count`](#query-workflow-invocation-count) | Count the total number of workflow invocations.
[`query workflow-invocation-status`](#query-workflow-invocation-status) | Report on how many workflows are in new state by handler
[`query workflow-invocation-totals`](#query-workflow-invocation-totals) | Report on overall workflow counts, to ensure throughput

## query aq

([*source*](https://github.com/galaxyproject/gxadmin/search?q=query_aq&type=Code))
query aq -  Given a list of IDs from a table (e.g. 'job'), access a specific column from that table

**SYNOPSIS**

    gxadmin query aq <table> <column> <-|job_id [job_id [...]]>

