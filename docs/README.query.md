# query

Command | Description
------- | -----------
[`query aq`](#query-aq) | Given a list of IDs from a table (e.g. 'job'), access a specific column from that table
[`query collection-usage`](#query-collection-usage) | Information about how many collections of various types are used
[`query data-origin-distribution`](#query-data-origin-distribution) | data sources (uploaded vs derived)
[`query data-origin-distribution-summary`](#query-data-origin-distribution-summary) | breakdown of data sources (uploaded vs derived)
[`query datasets-created-daily`](#query-datasets-created-daily) | The min/max/average/p95/p99 of total size of datasets created in a single day.
[`query disk-usage`](#query-disk-usage) | Disk usage per object store.
[`query errored-jobs`](#query-errored-jobs) | Lists jobs that errored in the last N hours.
[`query good-for-pulsar`](#query-good-for-pulsar) | Look for jobs EU would like to send to pulsar
[`query group-cpu-seconds`](#query-group-cpu-seconds) | Retrieve an approximation of the CPU time in seconds for group(s)
[`query group-gpu-time`](#query-group-gpu-time) | Retrieve an approximation of the GPU time for users
[`query groups-list`](#query-groups-list) | List all groups known to Galaxy
[`query hdca-datasets`](#query-hdca-datasets) | List of files in a dataset collection
[`query hdca-info`](#query-hdca-info) | Information on a dataset collection
[`query history-connections`](#query-history-connections) | The connections of tools, from output to input, in histories (tool_predictions)
[`query history-contents`](#query-history-contents) | List datasets and/or collections in a history
[`query history-runtime-system-by-tool`](#query-history-runtime-system-by-tool) | Sum of runtimes by all jobs in a history, split by tool
[`query history-runtime-system`](#query-history-runtime-system) | Sum of runtimes by all jobs in a history
[`query history-runtime-wallclock`](#query-history-runtime-wallclock) | Time as elapsed by a clock on the wall
[`query job-history`](#query-job-history) | Job state history for a specific job
[`query job-info`](#query-job-info) | Retrieve information about jobs given some job IDs
[`query job-inputs`](#query-job-inputs) | Input datasets to a specific job
[`query job-outputs`](#query-job-outputs) | Output datasets from a specific job
[`query jobs-max-by-cpu-hours`](#query-jobs-max-by-cpu-hours) | Top 10 jobs by CPU hours consumed (requires CGroups metrics)
[`query jobs-nonterminal`](#query-jobs-nonterminal) | Job info of nonterminal jobs separated by user
[`query jobs-per-user`](#query-jobs-per-user) | Number of jobs run by a specific user
[`query jobs-queued`](#query-jobs-queued) | How many queued jobs have external cluster IDs
[`query jobs-queued-internal-by-handler`](#query-jobs-queued-internal-by-handler) | How many queued jobs do not have external IDs, by handler
[`query jobs-ready-to-run`](#query-jobs-ready-to-run) | Find jobs ready to run (Mostly a performance test)
[`query largest-collection`](#query-largest-collection) | Returns the size of the single largest collection
[`query largest-histories`](#query-largest-histories) | Largest histories in Galaxy
[`query latest-users`](#query-latest-users) | 40 recently registered users
[`query monthly-cpu-stats`](#query-monthly-cpu-stats) | CPU years/hours allocated to tools by month
[`query monthly-cpu-years`](#query-monthly-cpu-years) | CPU years allocated to tools by month
[`query monthly-data`](#query-monthly-data) | Number of active users per month, running jobs
[`query monthly-gpu-years`](#query-monthly-gpu-years) | GPU years allocated to tools by month
[`query monthly-jobs`](#query-monthly-jobs) | Number of jobs run each month
[`query monthly-users-active`](#query-monthly-users-active) | Number of active users per month, running jobs
[`query monthly-users-registered`](#query-monthly-users-registered) | Number of users registered each month
[`query old-histories`](#query-old-histories) | Lists histories that haven't been updated (used) for <weeks>
[`query pg-cache-hit`](#query-pg-cache-hit) | Check postgres in-memory cache hit ratio
[`query pg-index-size`](#query-pg-index-size) | show table and index bloat in your database ordered by most wasteful
[`query pg-index-usage`](#query-pg-index-usage) | calculates your index hit rate (effective databases are at 99% and up)
[`query pg-long-running-queries`](#query-pg-long-running-queries) | show all queries longer than five minutes by descending duration
[`query pg-mandelbrot`](#query-pg-mandelbrot) | show the mandlebrot set
[`query pg-stat-bgwriter`](#query-pg-stat-bgwriter) | Stats about the behaviour of the bgwriter, checkpoints, buffers, etc.
[`query pg-stat-user-tables`](#query-pg-stat-user-tables) | stats about tables (tuples, index scans, vacuums, analyzes)
[`query pg-table-bloat`](#query-pg-table-bloat) | show table and index bloat in your database ordered by most wasteful
[`query pg-table-size`](#query-pg-table-size) | show the size of the tables (excluding indexes), descending by size
[`query pg-unused-indexes`](#query-pg-unused-indexes) | show unused and almost unused indexes
[`query pg-vacuum-stats`](#query-pg-vacuum-stats) | show dead rows and whether an automatic vacuum is expected to be triggered
[`query q`](#query-q) | Passes a raw SQL query directly through to the database
[`query queue`](#query-queue) | Brief overview of currently running jobs grouped by tool (default) or other columns
[`query queue-detail`](#query-queue-detail) | Detailed overview of running and queued jobs
[`query queue-detail-by-handler`](#query-queue-detail-by-handler) | List jobs for a specific handler
[`query queue-overview`](#query-queue-overview) | View used mostly for monitoring
[`query queue-time`](#query-queue-time) | The average/95%/99% a specific tool spends in queue state.
[`query recent-jobs`](#query-recent-jobs) | Jobs run in the past <hours> (in any state)
[`query runtime-per-user`](#query-runtime-per-user) | computation time of user (by email)
[`query tool-available-metrics`](#query-tool-available-metrics) | list all available metrics for a given tool
[`query tool-errors`](#query-tool-errors) | Summarize percent of tool runs in error over the past weeks for all tools that have failed (most popular tools first)
[`query tool-last-used-date`](#query-tool-last-used-date) | When was the most recent invocation of every tool
[`query tool-likely-broken`](#query-tool-likely-broken) | Find tools that have been executed in recent weeks that are (or were due to job running) likely substantially broken
[`query tool-metrics`](#query-tool-metrics) | See values of a specific metric
[`query tool-new-errors`](#query-tool-new-errors) | Summarize percent of tool runs in error over the past weeks for "new tools"
[`query tool-popularity`](#query-tool-popularity) | Most run tools by month (tool_predictions)
[`query tool-usage`](#query-tool-usage) | Counts of tool runs in the past weeks (default = all)
[`query total-jobs`](#query-total-jobs) | Total number of jobs run by galaxy instance
[`query training-list`](#query-training-list) | List known trainings
[`query training-members-remove`](#query-training-members-remove) | Remove a user from a training
[`query training-members`](#query-training-members) | List users in a specific training
[`query training-queue`](#query-training-queue) | Jobs currently being run by people in a given training
[`query ts-repos`](#query-ts-repos) | Counts of toolshed repositories by toolshed and owner.
[`query upload-gb-in-past-hour`](#query-upload-gb-in-past-hour) | Sum in bytes of files uploaded in the past hour
[`query user-cpu-years`](#query-user-cpu-years) | CPU years allocated to tools by user
[`query user-disk-quota`](#query-user-disk-quota) | Retrieves the 50 users with the largest quotas
[`query user-disk-usage`](#query-user-disk-usage) | Retrieve an approximation of the disk usage for users
[`query user-gpu-years`](#query-user-gpu-years) | GPU years allocated to tools by user
[`query user-history-list`](#query-user-history-list) | Shows the ID of the history, it's size and when it was last updated.
[`query user-recent-aggregate-jobs`](#query-user-recent-aggregate-jobs) | Show aggregate information for jobs in past N days for user
[`query users-count`](#query-users-count) | Shows sums of active/external/deleted/purged accounts
[`query users-total`](#query-users-total) | Total number of Galaxy users (incl deleted, purged, inactive)
[`query users-with-oidc`](#query-users-with-oidc) | How many users logged in with OIDC
[`query workers`](#query-workers) | Retrieve a list of Galaxy worker processes
[`query workflow-connections`](#query-workflow-connections) | The connections of tools, from output to input, in the latest (or all) versions of user workflows (tool_predictions)
[`query workflow-invocation-status`](#query-workflow-invocation-status) | Report on how many workflows are in new state by handler
[`query workflow-invocation-totals`](#query-workflow-invocation-totals) | Report on overall workflow counts, to ensure throughput

## query aq

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_aq&type=Code))
query aq -  Given a list of IDs from a table (e.g. 'job'), access a specific column from that table

**SYNOPSIS**

    gxadmin query aq <table> <column> <-|job_id [job_id [...]]>


## query collection-usage

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_collection-usage&type=Code))
query collection-usage -  Information about how many collections of various types are used

**SYNOPSIS**

    gxadmin query collection-usage


## query data-origin-distribution

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_data-origin-distribution&type=Code))
query data-origin-distribution -  data sources (uploaded vs derived)

**SYNOPSIS**

    gxadmin query data-origin-distribution [--human]

**NOTES**

Break down the source of data in the server, uploaded data vs derived (created as output from a tool)

Recommendation is to run with GDPR_MODE so you can safely share this information:

    GDPR_MODE=$(openssl rand -hex 24 2>/dev/null) gxadmin tsvquery data-origin-distribution | gzip > data-origin.tsv.gz

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


## query data-origin-distribution-summary

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_data-origin-distribution-summary&type=Code))
query data-origin-distribution-summary -  breakdown of data sources (uploaded vs derived)

**SYNOPSIS**

    gxadmin query data-origin-distribution-summary [--human]

**NOTES**

Break down the source of data in the server, uploaded data vs derived (created as output from a tool)

This query builds a table with the volume of derivced and uploaded data per user, and then summarizes this:

origin  |   min   | quant_1st | median  |  mean  | quant_3rd | perc_95 | perc_99 |  max  | stddev
------- | ------- | --------- | ------- | ------ | --------- | ------- | ------- | ----- | --------
created | 0 bytes | 17 MB     | 458 MB  | 36 GB  | 11 GB     | 130 GB  | 568 GB  | 11 TB | 257 GB
derived | 0 bytes | 39 MB     | 1751 MB | 200 GB | 28 GB     | 478 GB  | 2699 GB | 90 TB | 2279 GB


## query datasets-created-daily

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_datasets-created-daily&type=Code))
query datasets-created-daily -  The min/max/average/p95/p99 of total size of datasets created in a single day.

**SYNOPSIS**

    gxadmin query datasets-created-daily

**NOTES**

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


## query disk-usage

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_disk-usage&type=Code))
query disk-usage -  Disk usage per object store.

**SYNOPSIS**

    gxadmin query disk-usage [--human]

**NOTES**

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


## query errored-jobs

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_errored-jobs&type=Code))
query errored-jobs -  Lists jobs that errored in the last N hours.

**SYNOPSIS**

    gxadmin query errored-jobs <hours> [--details]

**NOTES**

Lists details of jobs that have status = 'error' for the specified number of hours. Default = 24 hours

    $ gxadmin query errored-jobs 2
     id | create_time | tool_id | tool_version | handler  | destination_id | job_runner_external_id |      email
    ----+-------------+---------+--------------+----------+----------------+------------------------+------------------
      1 |             | upload1 | 1.1.0        | handler2 | slurm_normal   | 42                     | user@example.org
      2 |             | cut1    | 1.1.1        | handler1 | slurm_normal   | 43                     | user@example.org
      3 |             | bwa     | 0.7.17.1     | handler0 | slurm_multi    | 44                     | map@example.org
      4 |             | trinity | 2.9.1        | handler1 | pulsar_bigmem  | 4                      | rna@example.org


## query good-for-pulsar

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_good-for-pulsar&type=Code))
query good-for-pulsar -  Look for jobs EU would like to send to pulsar

**SYNOPSIS**

    gxadmin query good-for-pulsar

**NOTES**

This selects all jobs and finds two things:
- sum of input sizes
- runtime

and then returns a simple /score/ of (input/runtime) and sorts on that
hopefully identifying things with small inputs and long runtimes.


## query group-cpu-seconds

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_group-cpu-seconds&type=Code))
query group-cpu-seconds -  Retrieve an approximation of the CPU time in seconds for group(s)

**SYNOPSIS**

    gxadmin query group-cpu-seconds [group]

**NOTES**

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


## query group-gpu-time

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_group-gpu-time&type=Code))
query group-gpu-time -  Retrieve an approximation of the GPU time for users

**SYNOPSIS**

    gxadmin query group-gpu-time [group]

**NOTES**

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


## query groups-list

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_groups-list&type=Code))
query groups-list -  List all groups known to Galaxy

**SYNOPSIS**

    gxadmin query groups-list


## query hdca-datasets

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_hdca-datasets&type=Code))
query hdca-datasets -  List of files in a dataset collection

**SYNOPSIS**

    gxadmin query hdca-datasets <hdca_id>


## query hdca-info

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_hdca-info&type=Code))
query hdca-info -  Information on a dataset collection

**SYNOPSIS**

    gxadmin query hdca-info <hdca_id>


## query history-connections

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_history-connections&type=Code))
query history-connections -  The connections of tools, from output to input, in histories (tool_predictions)

**SYNOPSIS**

    gxadmin query history-connections

**NOTES**

This is used by the usegalaxy.eu tool prediction workflow, allowing for building models out of tool connections.


## query history-contents

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_history-contents&type=Code))
query history-contents -  List datasets and/or collections in a history

**SYNOPSIS**

    gxadmin query history-contents <history_id> [--dataset|--collection]

**NOTES**

Obtain an overview of tools that a user has run in the past N days


## query history-runtime-system-by-tool

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_history-runtime-system-by-tool&type=Code))
query history-runtime-system-by-tool -  Sum of runtimes by all jobs in a history, split by tool

**SYNOPSIS**

    gxadmin query history-runtime-system-by-tool <history_id>


## query history-runtime-system

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_history-runtime-system&type=Code))
query history-runtime-system -  Sum of runtimes by all jobs in a history

**SYNOPSIS**

    gxadmin query history-runtime-system <history_id>


## query history-runtime-wallclock

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_history-runtime-wallclock&type=Code))
query history-runtime-wallclock -  Time as elapsed by a clock on the wall

**SYNOPSIS**

    gxadmin query history-runtime-wallclock <history_id>


## query job-history

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_job-history&type=Code))
query job-history -  Job state history for a specific job

**SYNOPSIS**

    gxadmin query job-history <id>

**NOTES**

    $ gxadmin query job-history 1
                 time              | state
    -------------------------------+--------
     2018-11-20 17:15:09.297907+00 | error
     2018-11-20 17:15:08.911972+00 | queued
     2018-11-20 17:15:08.243363+00 | new
     2018-11-20 17:15:08.198301+00 | upload
     2018-11-20 17:15:08.19655+00  | new
    (5 rows)


## query job-info

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_job-info&type=Code))
query job-info -  Retrieve information about jobs given some job IDs

**SYNOPSIS**

    gxadmin query job-info <-|job_id [job_id [...]]>

**NOTES**

Retrieves information on a job, like the host it ran on,
how long it ran for and the total memory.

id    | create_time  | update_time |  tool_id     |   hostname   | handler  | runtime_seconds | memtotal
----- | ------------ | ----------- | ------------ | ------------ | -------- | --------------- | --------
1     |              |             | 123f911b5f1  | 123f911b5f1  | handler0 |          20.35  | 20.35 GB
2     |              |             | cb0fabc0002  | cb0fabc0002  | handler1 |          14.93  |  5.96 GB
3     |              |             | 7e9e9b00b89  | 7e9e9b00b89  | handler1 |          14.24  |  3.53 GB
4     |              |             | 42f211e5e87  | 42f211e5e87  | handler4 |          14.06  |  1.79 GB
5     |              |             | 26cdba62c93  | 26cdba62c93  | handler0 |          12.97  |  1.21 GB
6     |              |             | fa87cddfcae  | fa87cddfcae  | handler1 |           7.01  |   987 MB
7     |              |             | 44d2a648aac  | 44d2a648aac  | handler3 |           6.70  |   900 MB
8     |              |             | 66c57b41194  | 66c57b41194  | handler1 |           6.43  |   500 MB
9     |              |             | 6b1467ac118  | 6b1467ac118  | handler0 |           5.45  |   250 MB
10    |              |             | d755361b59a  | d755361b59a  | handler2 |           5.19  |   100 MB


## query job-inputs

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_job-inputs&type=Code))
query job-inputs -  Input datasets to a specific job

**SYNOPSIS**

    gxadmin query job-inputs <id>


## query job-outputs

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_job-outputs&type=Code))
query job-outputs -  Output datasets from a specific job

**SYNOPSIS**

    gxadmin query job-outputs <id>


## query jobs-max-by-cpu-hours

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_jobs-max-by-cpu-hours&type=Code))
query jobs-max-by-cpu-hours -  Top 10 jobs by CPU hours consumed (requires CGroups metrics)

**SYNOPSIS**

    gxadmin query jobs-max-by-cpu-hours


## query jobs-nonterminal

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_jobs-nonterminal&type=Code))
query jobs-nonterminal -  Job info of nonterminal jobs separated by user

**SYNOPSIS**

    gxadmin query jobs-nonterminal [username|id|email]

**NOTES**

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


## query jobs-per-user

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_jobs-per-user&type=Code))
query jobs-per-user -  Number of jobs run by a specific user

**SYNOPSIS**

    gxadmin query jobs-per-user <email>

**NOTES**

    $ gxadmin query jobs-per-user helena
     count | user_id
    -------+---------
       999 |       1
    (1 row)


## query jobs-queued

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_jobs-queued&type=Code))
query jobs-queued -  How many queued jobs have external cluster IDs

**SYNOPSIS**

    gxadmin query jobs-queued

**NOTES**

Shows the distribution of jobs in queued state, whether or not they have received an external ID.


n            | count
------------ | ------
unprocessed  |   118
processed    |    37


## query jobs-queued-internal-by-handler

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_jobs-queued-internal-by-handler&type=Code))
query jobs-queued-internal-by-handler -  How many queued jobs do not have external IDs, by handler

**SYNOPSIS**

    gxadmin query jobs-queued-internal-by-handler

**NOTES**

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


## query jobs-ready-to-run

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_jobs-ready-to-run&type=Code))
query jobs-ready-to-run -  Find jobs ready to run (Mostly a performance test)

**SYNOPSIS**

    gxadmin query jobs-ready-to-run

**NOTES**

Mostly a performance test


## query largest-collection

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_largest-collection&type=Code))
query largest-collection -  Returns the size of the single largest collection

**SYNOPSIS**

    gxadmin query largest-collection


## query largest-histories

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_largest-histories&type=Code))
query largest-histories -  Largest histories in Galaxy

**SYNOPSIS**

    gxadmin query largest-histories [--human]

**NOTES**

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


## query latest-users

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_latest-users&type=Code))
query latest-users -  40 recently registered users

**SYNOPSIS**

    gxadmin query latest-users

**NOTES**

Returns 40 most recently registered users

    $ gxadmin query latest-users
     id |          create_time          | disk_usage | username |     email      |              groups               | active
    ----+-------------------------------+------------+----------+----------------+-----------------------------------+--------
      3 | 2019-03-07 13:06:37.945403+00 |            | beverly  | b@example.com  |                                   | t
      2 | 2019-03-07 13:06:23.369201+00 | 826 bytes  | alice    | a@example.com  |                                   | t
      1 | 2018-11-19 14:54:30.969713+00 | 869 MB     | helena   | hxr@local.host | training-asdf training-hogeschool | t
    (3 rows)


## query monthly-cpu-stats

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_monthly-cpu-stats&type=Code))
query monthly-cpu-stats -  CPU years/hours allocated to tools by month

**SYNOPSIS**

    gxadmin query monthly-cpu-stats [year]

**NOTES**

This uses the galaxy_slots and runtime_seconds metrics in order to
calculate allocated CPU years/hours. This will not be the value of what is
actually consumed by your jobs, you should use cgroups.

    $ gxadmin query monthly-cpu-stats
       month    | cpu_years | cpu_hours
    ------------+-----------+-----------
     2020-05-01 |     53.55 | 469088.02
     2020-04-01 |     59.55 | 521642.60
     2020-03-01 |     57.04 | 499658.86
     2020-02-01 |     53.93 | 472390.31
     2020-01-01 |     56.49 | 494887.37
     ...


## query monthly-cpu-years

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_monthly-cpu-years&type=Code))
query monthly-cpu-years -  CPU years allocated to tools by month

**SYNOPSIS**

    gxadmin query monthly-cpu-years

**NOTES**

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


## query monthly-data

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_monthly-data&type=Code))
query monthly-data -  Number of active users per month, running jobs

**SYNOPSIS**

    gxadmin query monthly-data [year] [--human]

**NOTES**

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


## query monthly-gpu-years

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_monthly-gpu-years&type=Code))
query monthly-gpu-years -  GPU years allocated to tools by month

**SYNOPSIS**

    gxadmin query monthly-gpu-years

**NOTES**

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


## query monthly-jobs

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_monthly-jobs&type=Code))
query monthly-jobs -  Number of jobs run each month

**SYNOPSIS**

    gxadmin query monthly-jobs [year]

**NOTES**

Count jobs run each month

    $ gxadmin query monthly-jobs 2018
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


## query monthly-users-active

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_monthly-users-active&type=Code))
query monthly-users-active -  Number of active users per month, running jobs

**SYNOPSIS**

    gxadmin query monthly-users-active [year]

**NOTES**

Number of unique users each month who ran jobs. **NOTE**: does not include anonymous users.

    $ gxadmin query monthly-users-active 2018
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


## query monthly-users-registered

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_monthly-users-registered&type=Code))
query monthly-users-registered -  Number of users registered each month

**SYNOPSIS**

    gxadmin query monthly-users-registered [year]


## query old-histories

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_old-histories&type=Code))
query old-histories -  Lists histories that haven't been updated (used) for <weeks>

**SYNOPSIS**

    gxadmin query old-histories <weeks>

**NOTES**

Histories and their users who haven't been updated for a specified number of weeks. Default number of weeks is 15.

     query old-histories 52
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


## query pg-cache-hit

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_pg-cache-hit&type=Code))
query pg-cache-hit -  Check postgres in-memory cache hit ratio

**SYNOPSIS**

    gxadmin query pg-cache-hit

**NOTES**

Query from: https://www.citusdata.com/blog/2019/03/29/health-checks-for-your-postgres-database/

Tells you about the cache hit ratio, is Postgres managing to store
commonly requested objects in memory or are they being loaded every
time?

heap_read  | heap_hit |         ratio
----------- ---------- ------------------------
29         |    64445 | 0.99955020628470391165


## query pg-index-size

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_pg-index-size&type=Code))
query pg-index-size -  show table and index bloat in your database ordered by most wasteful

**SYNOPSIS**

    gxadmin query pg-index-size [--human]

**NOTES**

Originally from: https://github.com/heroku/heroku-pg-extras/tree/master/commands


## query pg-index-usage

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_pg-index-usage&type=Code))
query pg-index-usage -  calculates your index hit rate (effective databases are at 99% and up)

**SYNOPSIS**

    gxadmin query pg-index-usage

**NOTES**

Originally from: https://github.com/heroku/heroku-pg-extras/tree/master/commands

-1 means "Insufficient Data", this was changed to a numeric value to be acceptable to InfluxDB


## query pg-long-running-queries

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_pg-long-running-queries&type=Code))
query pg-long-running-queries -  show all queries longer than five minutes by descending duration

**SYNOPSIS**

    gxadmin query pg-long-running-queries

**NOTES**

Originally from: https://github.com/heroku/heroku-pg-extras/tree/master/commands


## query pg-mandelbrot

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_pg-mandelbrot&type=Code))
query pg-mandelbrot -  show the mandlebrot set

**SYNOPSIS**

    gxadmin query pg-mandelbrot

**NOTES**

Copied from: https://github.com/heroku/heroku-pg-extras/tree/master/commands


## query pg-stat-bgwriter

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_pg-stat-bgwriter&type=Code))
query pg-stat-bgwriter -  Stats about the behaviour of the bgwriter, checkpoints, buffers, etc.

**SYNOPSIS**

    gxadmin query pg-stat-bgwriter


## query pg-stat-user-tables

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_pg-stat-user-tables&type=Code))
query pg-stat-user-tables -  stats about tables (tuples, index scans, vacuums, analyzes)

**SYNOPSIS**

    gxadmin query pg-stat-user-tables


## query pg-table-bloat

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_pg-table-bloat&type=Code))
query pg-table-bloat -  show table and index bloat in your database ordered by most wasteful

**SYNOPSIS**

    gxadmin query pg-table-bloat [--human]

**NOTES**

Query from: https://www.citusdata.com/blog/2019/03/29/health-checks-for-your-postgres-database/
Originally from: https://github.com/heroku/heroku-pg-extras/tree/master/commands


## query pg-table-size

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_pg-table-size&type=Code))
query pg-table-size -  show the size of the tables (excluding indexes), descending by size

**SYNOPSIS**

    gxadmin query pg-table-size [--human]

**NOTES**

Originally from: https://github.com/heroku/heroku-pg-extras/tree/master/commands


## query pg-unused-indexes

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_pg-unused-indexes&type=Code))
query pg-unused-indexes -  show unused and almost unused indexes

**SYNOPSIS**

    gxadmin query pg-unused-indexes [--human]

**NOTES**

Originally from: https://github.com/heroku/heroku-pg-extras/tree/master/commands

From their documentation:

> "Ordered by their size relative to the number of index scans.
> Exclude indexes of very small tables (less than 5 pages),
> where the planner will almost invariably select a sequential scan,
> but may not in the future as the table grows"


## query pg-vacuum-stats

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_pg-vacuum-stats&type=Code))
query pg-vacuum-stats -  show dead rows and whether an automatic vacuum is expected to be triggered

**SYNOPSIS**

    gxadmin query pg-vacuum-stats

**NOTES**

Originally from: https://github.com/heroku/heroku-pg-extras/tree/master/commands


## query q

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_q&type=Code))
query q -  Passes a raw SQL query directly through to the database

**SYNOPSIS**

    gxadmin query q <query>


## query queue

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_queue&type=Code))
query queue -  Brief overview of currently running jobs grouped by tool (default) or other columns

**SYNOPSIS**

    gxadmin query queue [--by (tool|destination|user)]

**NOTES**

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


## query queue-detail

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_queue-detail&type=Code))
query queue-detail -  Detailed overview of running and queued jobs

**SYNOPSIS**

    gxadmin query queue-detail [--all] [--seconds]

**NOTES**

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


## query queue-detail-by-handler

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_queue-detail-by-handler&type=Code))
query queue-detail-by-handler -  List jobs for a specific handler

**SYNOPSIS**

    gxadmin query queue-detail-by-handler <handler_id>

**NOTES**

List the jobs currently being processed by a specific handler


## query queue-overview

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_queue-overview&type=Code))
query queue-overview -  View used mostly for monitoring

**SYNOPSIS**

    gxadmin query queue-overview [--short-tool-id]

**NOTES**

Primarily for monitoring of queue. Optimally used with 'iquery' and passed to Telegraf.

    $ gxadmin iquery queue-overview
    queue-overview,tool_id=upload1,tool_version=0.0.1,state=running,handler=main.web.1,destination_id=condor,job_runner_name=condor,user=1 count=1


## query queue-time

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_queue-time&type=Code))
query queue-time -  The average/95%/99% a specific tool spends in queue state.

**SYNOPSIS**

    gxadmin query queue-time <tool_id>

**NOTES**

    $ gxadmin query queue-time toolshed.g2.bx.psu.edu/repos/nilesh/rseqc/rseqc_geneBody_coverage/2.6.4.3
           min       |     perc_95     |     perc_99     |       max
    -----------------+-----------------+-----------------+-----------------
     00:00:15.421457 | 00:00:55.022874 | 00:00:59.974171 | 00:01:01.211995


## query recent-jobs

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_recent-jobs&type=Code))
query recent-jobs -  Jobs run in the past <hours> (in any state)

**SYNOPSIS**

    gxadmin query recent-jobs <hours>

**NOTES**

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


## query runtime-per-user

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_runtime-per-user&type=Code))
query runtime-per-user -  computation time of user (by email)

**SYNOPSIS**

    gxadmin query runtime-per-user <email>

**NOTES**

    $ gxadmin query runtime-per-user hxr@informatik.uni-freiburg.de
       sum
    ----------
     14:07:39


## query tool-available-metrics

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_tool-available-metrics&type=Code))
query tool-available-metrics -  list all available metrics for a given tool

**SYNOPSIS**

    gxadmin query tool-available-metrics <tool_id>

**NOTES**

Gives a list of available metrics, which can then be used to query.

    $ gxadmin query tool-available-metrics upload1
                 metric_name
    -------------------------------------
     memory.stat.total_rss
     memory.stat.total_swap
     memory.stat.total_unevictable
     memory.use_hierarchy
     ...


## query tool-errors

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_tool-errors&type=Code))
query tool-errors -  Summarize percent of tool runs in error over the past weeks for all tools that have failed (most popular tools first)

**SYNOPSIS**

    gxadmin query tool-errors [--short-tool-id] [weeks|4]

**NOTES**

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


## query tool-last-used-date

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_tool-last-used-date&type=Code))
query tool-last-used-date -  When was the most recent invocation of every tool

**SYNOPSIS**

    gxadmin query tool-last-used-date

**NOTES**

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


## query tool-likely-broken

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_tool-likely-broken&type=Code))
query tool-likely-broken -  Find tools that have been executed in recent weeks that are (or were due to job running) likely substantially broken

**SYNOPSIS**

    gxadmin query tool-likely-broken [--short-tool-id] [weeks|4]

**NOTES**

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


## query tool-metrics

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_tool-metrics&type=Code))
query tool-metrics -  See values of a specific metric

**SYNOPSIS**

    gxadmin query tool-metrics <tool_id> <metric_id> [--like]

**NOTES**

A good way to use this is to fetch the memory usage of a tool and then
do some aggregations. The following requires [data_hacks](https://github.com/bitly/data_hacks)

    $ gxadmin tsvquery tool-metrics %rgrnastar/rna_star% memory.max_usage_in_bytes --like | \
        awk '{print $1 / 1024 / 1024 / 1024}' | \
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


## query tool-new-errors

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_tool-new-errors&type=Code))
query tool-new-errors -  Summarize percent of tool runs in error over the past weeks for "new tools"

**SYNOPSIS**

    gxadmin query tool-new-errors [weeks|4]

**NOTES**

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


## query tool-popularity

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_tool-popularity&type=Code))
query tool-popularity -  Most run tools by month (tool_predictions)

**SYNOPSIS**

    gxadmin query tool-popularity [months|24]

**NOTES**

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


## query tool-usage

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_tool-usage&type=Code))
query tool-usage -  Counts of tool runs in the past weeks (default = all)

**SYNOPSIS**

    gxadmin query tool-usage [weeks]

**NOTES**

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


## query total-jobs

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_total-jobs&type=Code))
query total-jobs -  Total number of jobs run by galaxy instance

**SYNOPSIS**

    gxadmin query total-jobs [year]

**NOTES**

Count total number of jobs

    $ gxadmin query total-jobs
      state  | count
    ---------+-------
     deleted |    21
     error   |   197
     ok      |   798
    (3 rows)


## query training-list

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_training-list&type=Code))
query training-list -  List known trainings

**SYNOPSIS**

    gxadmin query training-list [--all]

**NOTES**

This module is specific to EU's implementation of Training Infrastructure as a Service. But this specifically just checks for all groups with the name prefix 'training-'

    $ gxadmin query training-list
        name    |  created
    ------------+------------
     hogeschool | 2020-01-22
     asdf       | 2019-08-28
    (2 rows)


## query training-members-remove

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_training-members-remove&type=Code))
query training-members-remove -  Remove a user from a training

**SYNOPSIS**

    gxadmin query training-members-remove <training> <username> [YESDOIT]


## query training-members

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_training-members&type=Code))
query training-members -  List users in a specific training

**SYNOPSIS**

    gxadmin query training-members <tr_id>

**NOTES**

    $ gxadmin query training-members hts2018
          username      |       joined
    --------------------+---------------------
     helena-rasche      | 2018-09-21 21:42:01


## query training-queue

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_training-queue&type=Code))
query training-queue -  Jobs currently being run by people in a given training

**SYNOPSIS**

    gxadmin query training-queue <training_id>

**NOTES**

Finds all jobs by people in that queue (including things they are executing that are not part of a training)

    $ gxadmin query training-queue hts2018
     state  |   id    | extid  | tool_id |   username    |       created
    --------+---------+--------+---------+---------------+---------------------
     queued | 4350274 | 225743 | upload1 |               | 2018-09-26 10:00:00


## query ts-repos

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_ts-repos&type=Code))
query ts-repos -  Counts of toolshed repositories by toolshed and owner.

**SYNOPSIS**

    gxadmin query ts-repos


## query upload-gb-in-past-hour

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_upload-gb-in-past-hour&type=Code))
query upload-gb-in-past-hour -  Sum in bytes of files uploaded in the past hour

**SYNOPSIS**

    gxadmin query upload-gb-in-past-hour [hours|1]

**NOTES**

Quick output, mostly useful for graphing, to produce a nice graph of how heavily are people uploading currently.


## query user-cpu-years

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_user-cpu-years&type=Code))
query user-cpu-years -  CPU years allocated to tools by user

**SYNOPSIS**

    gxadmin query user-cpu-years

**NOTES**

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


## query user-disk-quota

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_user-disk-quota&type=Code))
query user-disk-quota -  Retrieves the 50 users with the largest quotas

**SYNOPSIS**

    gxadmin query user-disk-quota

**NOTES**

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


## query user-disk-usage

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_user-disk-usage&type=Code))
query user-disk-usage -  Retrieve an approximation of the disk usage for users

**SYNOPSIS**

    gxadmin query user-disk-usage [--human]

**NOTES**

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


## query user-gpu-years

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_user-gpu-years&type=Code))
query user-gpu-years -  GPU years allocated to tools by user

**SYNOPSIS**

    gxadmin query user-gpu-years

**NOTES**

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


## query user-history-list

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_user-history-list&type=Code))
query user-history-list -  Shows the ID of the history, it's size and when it was last updated.

**SYNOPSIS**

    gxadmin query user-history-list <username|id|email> [--size]

**NOTES**

Obtain an overview of histories of a user. By default orders the histories by date.
When using '--size' it overrides the order to size.

$ gxadmin query user-history-list <username|id|email>
  ID   |                 Name                 |        Last Updated        |   Size
-------+--------------------------------------+----------------------------+-----------
52 | Unnamed history                      | 2019-08-08 15:15:32.284678 | 293 MB
 30906 | Unnamed history                      | 2019-07-23 16:25:36.084019 | 13 kB


## query user-recent-aggregate-jobs

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_user-recent-aggregate-jobs&type=Code))
query user-recent-aggregate-jobs -  Show aggregate information for jobs in past N days for user

**SYNOPSIS**

    gxadmin query user-recent-aggregate-jobs <username|id|email> [days|7]

**NOTES**

Obtain an overview of tools that a user has run in the past N days


## query users-count

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_users-count&type=Code))
query users-count -  Shows sums of active/external/deleted/purged accounts

**SYNOPSIS**

    gxadmin query users-count

**NOTES**

     active | external | deleted | purged | count
    --------+----------+---------+--------+-------
     f      | f        | f       | f      |   182
     t      | f        | t       | t      |     2
     t      | f        | t       | f      |     6
     t      | f        | f       | f      |  2350
     f      | f        | t       | t      |    36


## query users-total

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_users-total&type=Code))
query users-total -  Total number of Galaxy users (incl deleted, purged, inactive)

**SYNOPSIS**

    gxadmin query users-total


## query users-with-oidc

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_users-with-oidc&type=Code))
query users-with-oidc -  How many users logged in with OIDC

**SYNOPSIS**

    gxadmin query users-with-oidc

**NOTES**

provider | count
-------- | ------
elixir   |     5


## query workers

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_workers&type=Code))
query workers -  Retrieve a list of Galaxy worker processes

**SYNOPSIS**

    gxadmin query workers

**NOTES**

This retrieves a list of Galaxy worker processes.
This functionality is only available on Galaxy
20.01 or later.

server_name         | hostname | pid
------------------- | -------- | ---
main.web.1          | server1  | 123
main.job-handlers.1 | server2  | 456


## query workflow-connections

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_workflow-connections&type=Code))
query workflow-connections -  The connections of tools, from output to input, in the latest (or all) versions of user workflows (tool_predictions)

**SYNOPSIS**

    gxadmin query workflow-connections [--all]

**NOTES**

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


## query workflow-invocation-status

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_workflow-invocation-status&type=Code))
query workflow-invocation-status -  Report on how many workflows are in new state by handler

**SYNOPSIS**

    gxadmin query workflow-invocation-status

**NOTES**

Really only intended to be used in influx queries.


## query workflow-invocation-totals

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=query_workflow-invocation-totals&type=Code))
query workflow-invocation-totals -  Report on overall workflow counts, to ensure throughput

**SYNOPSIS**

    gxadmin query workflow-invocation-totals

**NOTES**

Really only intended to be used in influx queries.

