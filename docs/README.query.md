# query

Command | Description
------- | -----------
`query active-users` | Deprecated, use monthly-users-active
[`query collection-usage`](#query-collection-usage) | Information about how many collections of various types are used
[`query datasets-created-daily`](#query-datasets-created-daily) | The min/max/average/p95/p99 of total size of datasets created in a single day.
[`query disk-usage`](#query-disk-usage) | Disk usage per object store.
[`query errored-jobs`](#query-errored-jobs) | Lists jobs that errored in the last N hours.
[`query groups-list`](#query-groups-list) | List all groups known to Galaxy
[`query hdca-datasets`](#query-hdca-datasets) | (NEW) List of files in a dataset collection
[`query hdca-info`](#query-hdca-info) | (NEW) Information on a dataset collection
[`query history-contents`](#query-history-contents) | (NEW) List datasets and/or collections in a history
[`query job-history`](#query-job-history) | Job state history for a specific job
[`query job-inputs`](#query-job-inputs) | Input datasets to a specific job
[`query job-outputs`](#query-job-outputs) | Output datasets from a specific job
[`query jobs-max-by-cpu-hours`](#query-jobs-max-by-cpu-hours) | Top 10 jobs by CPU hours consumed (requires CGroups metrics)
[`query jobs-nonterminal`](#query-jobs-nonterminal) | Job info of nonterminal jobs separated by user
[`query jobs-per-user`](#query-jobs-per-user) | Number of jobs run by a specific user
[`query largest-collection`](#query-largest-collection) | Returns the size of the single largest collection
[`query largest-histories`](#query-largest-histories) | Largest histories in Galaxy
[`query latest-users`](#query-latest-users) | 40 recently registered users
[`query monthly-cpu-years`](#query-monthly-cpu-years) | CPU years allocated to tools by month
[`query monthly-data`](#query-monthly-data) | Number of active users per month, running jobs
[`query monthly-jobs`](#query-monthly-jobs) | Number of jobs run each month
[`query monthly-users-active`](#query-monthly-users-active) | Number of active users per month, running jobs
`query monthly-users` | Deprecated, use monthly-users-active
[`query monthly-users-registered`](#query-monthly-users-registered) | Number of users registered each month
[`query old-histories`](#query-old-histories) | Lists histories that haven't been updated (used) for <weeks>
[`query queue`](#query-queue) | Brief overview of currently running jobs
[`query queue-detail`](#query-queue-detail) | Detailed overview of running and queued jobs
[`query queue-overview`](#query-queue-overview) | View used mostly for monitoring
[`query queue-time`](#query-queue-time) | The average/95%/99% a specific tool spends in queue state.
[`query recent-jobs`](#query-recent-jobs) | Jobs run in the past <hours> (in any state)
[`query runtime-per-user`](#query-runtime-per-user) | computation time of user (by email)
[`query tool-available-metrics`](#query-tool-available-metrics) | list all available metrics for a given tool
[`query tool-last-used-date`](#query-tool-last-used-date) | When was the most recent invocation of every tool
[`query tool-metrics`](#query-tool-metrics) | See values of a specific metric
[`query tool-popularity`](#query-tool-popularity) | Most run tools by month
[`query tool-usage`](#query-tool-usage) | Counts of tool runs in the past weeks (default = all)
[`query training-list`](#query-training-list) | List known trainings
[`query training-members-remove`](#query-training-members-remove) | Remove a user from a training
[`query training-members`](#query-training-members) | List users in a specific training
[`query training-queue`](#query-training-queue) | Jobs currently being run by people in a given training
[`query ts-repos`](#query-ts-repos) | Counts of toolshed repositories by toolshed and owner.
[`query user-cpu-years`](#query-user-cpu-years) | (NEW) CPU years allocated to tools by user
[`query user-recent-aggregate-jobs`](#query-user-recent-aggregate-jobs) | (NEW) Show aggregate information for jobs in past N days for user
[`query users-count`](#query-users-count) | Shows sums of active/external/deleted/purged accounts
[`query users-total`](#query-users-total) | Total number of Galaxy users (incl deleted, purged, inactive)
[`query workflow-connections`](#query-workflow-connections) | The connections of tools, from output to input, in the latest (or all) versions of user workflows
[`query workflow-invocation-status`](#query-workflow-invocation-status) | Report on how many workflows are in new state by handler

### query collection-usage

**NAME**

query collection-usage -  Information about how many collections of various types are used

**SYNOPSIS**

`gxadmin query collection-usage`


### query datasets-created-daily

**NAME**

query datasets-created-daily -  The min/max/average/p95/p99 of total size of datasets created in a single day.

**SYNOPSIS**

`gxadmin query datasets-created-daily`

**NOTES**

    $ gxadmin query datasets-created-daily
       min   |  avg   | perc_95 | perc_99 |  max
    ---------+--------+---------+---------+-------
     0 bytes | 338 GB | 1355 GB | 2384 GB | 42 TB


### query disk-usage

**NAME**

query disk-usage -  Disk usage per object store.

**SYNOPSIS**

`gxadmin query disk-usage [--nice]`

**NOTES**

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


### query errored-jobs

**NAME**

query errored-jobs -  Lists jobs that errored in the last N hours.

**SYNOPSIS**

`gxadmin query errored-jobs <hours>`

**NOTES**

Lists details of jobs that have status = 'error' for the specified number of hours. Default = 24 hours

     query errored-jobs 24
    TO_DO: Add output of query here!


### query groups-list

**NAME**

query groups-list -  List all groups known to Galaxy

**SYNOPSIS**

`gxadmin query groups-list`


### query hdca-datasets

**NAME**

query hdca-datasets -  (NEW) List of files in a dataset collection

**SYNOPSIS**

`gxadmin query hdca-datasets <hdca_id>`


### query hdca-info

**NAME**

query hdca-info -  (NEW) Information on a dataset collection

**SYNOPSIS**

`gxadmin query hdca-info <hdca_id>`


### query history-contents

**NAME**

query history-contents -  (NEW) List datasets and/or collections in a history

**SYNOPSIS**

`gxadmin query history-contents <history_id> [--dataset|--collection]`

**NOTES**

Obtain an overview of tools that a user has run in the past N days


### query job-history

**NAME**

query job-history -  Job state history for a specific job

**SYNOPSIS**

`gxadmin query job-history <id>`

**NOTES**

    $ gxadmin query job-history 4384025
            time         |  state
    ---------------------+---------
     2018-10-05 16:20:13 | ok
     2018-10-05 16:19:57 | running
     2018-10-05 16:19:55 | queued
     2018-10-05 16:19:54 | new
    (4 rows)


### query job-inputs

**NAME**

query job-inputs -  Input datasets to a specific job

**SYNOPSIS**

`gxadmin query job-inputs <id>`


### query job-outputs

**NAME**

query job-outputs -  Output datasets from a specific job

**SYNOPSIS**

`gxadmin query job-outputs <id>`


### query jobs-max-by-cpu-hours

**NAME**

query jobs-max-by-cpu-hours -  Top 10 jobs by CPU hours consumed (requires CGroups metrics)

**SYNOPSIS**

`gxadmin query jobs-max-by-cpu-hours`


### query jobs-nonterminal

**NAME**

query jobs-nonterminal -  Job info of nonterminal jobs separated by user

**SYNOPSIS**

`gxadmin query jobs-nonterminal [username|id|email]`

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


### query jobs-per-user

**NAME**

query jobs-per-user -  Number of jobs run by a specific user

**SYNOPSIS**

`gxadmin query jobs-per-user <email>`

**NOTES**

    $ gxadmin query jobs-per-user hxr@informatik.uni-freiburg.de
     count
    -------
      1460


### query largest-collection

**NAME**

query largest-collection -  Returns the size of the single largest collection

**SYNOPSIS**

`gxadmin query largest-collection`


### query largest-histories

**NAME**

query largest-histories -  Largest histories in Galaxy

**SYNOPSIS**

`gxadmin query largest-histories`

**NOTES**

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


### query latest-users

**NAME**

query latest-users -  40 recently registered users

**SYNOPSIS**

`gxadmin query latest-users`

**NOTES**

Returns 40 most recently registered users

    $ gxadmin query latest-users
     id |        create_time        | pg_size_pretty |   username    |             email
    ----+---------------------------+----------------+---------------+--------------------------------
      1 | 2018-10-05 11:40:42.90119 |                | helena-rasche | hxr@informatik.uni-freiburg.de


### query monthly-cpu-years

**NAME**

query monthly-cpu-years -  CPU years allocated to tools by month

**SYNOPSIS**

`gxadmin query monthly-cpu-years`

**NOTES**

This uses the galaxy_slots and runtime_seconds metrics in order to
calculate allocated CPU years. This will not be the value of what is
actually consumed by your jobs, you should use cgroups.

    $ gxadmin query monthly-cpu-years
         date_trunc      | cpu_years
    ---------------------+-----------
     2019-04-01 00:00:00 |      2.95
     2019-03-01 00:00:00 |     12.38
     2019-02-01 00:00:00 |     11.47
     2019-01-01 00:00:00 |      8.27
     2018-12-01 00:00:00 |     11.42
     2018-11-01 00:00:00 |     16.99
     2018-10-01 00:00:00 |     12.09
     2018-09-01 00:00:00 |      6.27
     2018-08-01 00:00:00 |      9.06
     2018-07-01 00:00:00 |      6.17
     2018-06-01 00:00:00 |      5.73
     2018-05-01 00:00:00 |      7.36
     2018-04-01 00:00:00 |     10.21
     2018-03-01 00:00:00 |      5.20
     2018-02-01 00:00:00 |      4.53
     2018-01-01 00:00:00 |      4.05
     2017-12-01 00:00:00 |      2.44


### query monthly-data

**NAME**

query monthly-data -  Number of active users per month, running jobs

**SYNOPSIS**

`gxadmin query monthly-data [year]`

**NOTES**

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


### query monthly-jobs

**NAME**

query monthly-jobs -  Number of jobs run each month

**SYNOPSIS**

`gxadmin query monthly-jobs [year]`

**NOTES**

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


### query monthly-users-active

**NAME**

query monthly-users-active -  Number of active users per month, running jobs

**SYNOPSIS**

`gxadmin query monthly-users-active [year]`

**NOTES**

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


### query monthly-users-registered

**NAME**

query monthly-users-registered -  Number of users registered each month

**SYNOPSIS**

`gxadmin query monthly-users-registered [year]`


### query old-histories

**NAME**

query old-histories -  Lists histories that haven't been updated (used) for <weeks>

**SYNOPSIS**

`gxadmin query old-histories <weeks>`

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


### query queue

**NAME**

query queue -  Brief overview of currently running jobs

**SYNOPSIS**

`gxadmin query queue`

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


### query queue-detail

**NAME**

query queue-detail -  Detailed overview of running and queued jobs

**SYNOPSIS**

`gxadmin query queue-detail [--all]`

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


### query queue-overview

**NAME**

query queue-overview -  View used mostly for monitoring

**SYNOPSIS**

`gxadmin query queue-overview [--short-tool-id]`

**NOTES**

Primarily for monitoring of queue. Optimally used with 'iquery' and passed to Telegraf.

    $ gxadmin iquery queue-overview
    queue-overview,tool_id=upload1,tool_version=0.0.1,state=running,handler=main.web.1,destination_id=condor,job_runner_name=condor,user=1 count=1


### query queue-time

**NAME**

query queue-time -  The average/95%/99% a specific tool spends in queue state.

**SYNOPSIS**

`gxadmin query queue-time <tool_id>`

**NOTES**

    $ gxadmin query queue-time toolshed.g2.bx.psu.edu/repos/nilesh/rseqc/rseqc_geneBody_coverage/2.6.4.3
           min       |     perc_95     |     perc_99     |       max
    -----------------+-----------------+-----------------+-----------------
     00:00:15.421457 | 00:00:55.022874 | 00:00:59.974171 | 00:01:01.211995


### query recent-jobs

**NAME**

query recent-jobs -  Jobs run in the past <hours> (in any state)

**SYNOPSIS**

`gxadmin query recent-jobs <hours>`

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


### query runtime-per-user

**NAME**

query runtime-per-user -  computation time of user (by email)

**SYNOPSIS**

`gxadmin query runtime-per-user <email>`

**NOTES**

    $ gxadmin query runtime-per-user hxr@informatik.uni-freiburg.de
       sum
    ----------
     14:07:39


### query tool-available-metrics

**NAME**

query tool-available-metrics -  list all available metrics for a given tool

**SYNOPSIS**

`gxadmin query tool-available-metrics <tool_id>`

**NOTES**

Gives a list of available metrics, which can then be used to query.

    [galaxy@sn04 galaxy]$ gxadmin query tool-available-metrics upload1
                 metric_name
    -------------------------------------
     memory.stat.total_rss
     memory.stat.total_swap
     memory.stat.total_unevictable
     memory.use_hierarchy
     ...


### query tool-last-used-date

**NAME**

query tool-last-used-date -  When was the most recent invocation of every tool

**SYNOPSIS**

`gxadmin query tool-last-used-date`

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

It is not truly every tool, there is no easy way to find the tools which have never been run.


### query tool-metrics

**NAME**

query tool-metrics -  See values of a specific metric

**SYNOPSIS**

`gxadmin query tool-metrics <tool_id> <metric_id> [--like]`

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


### query tool-popularity

**NAME**

query tool-popularity -  Most run tools by month

**SYNOPSIS**

`gxadmin query tool-popularity [months|24]`

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


### query tool-usage

**NAME**

query tool-usage -  Counts of tool runs in the past weeks (default = all)

**SYNOPSIS**

`gxadmin query tool-usage [weeks]`

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


### query training-list

**NAME**

query training-list -  List known trainings

**SYNOPSIS**

`gxadmin query training-list [--all]`

**NOTES**

This module is specific to EU's implementation of Training Infrastructure as a Service. But this specifically just checks for all groups with the name prefix 'training-'

    $ gxadmin query training
           name       |  created
    ------------------+------------
     hts2018          | 2018-09-19


### query training-members-remove

**NAME**

query training-members-remove -  Remove a user from a training

**SYNOPSIS**

`gxadmin query training-members-remove <training> <username> [YESDOIT]`


### query training-members

**NAME**

query training-members -  List users in a specific training

**SYNOPSIS**

`gxadmin query training-members <tr_id>`

**NOTES**

    $ gxadmin query training-members hts2018
          username      |       joined
    --------------------+---------------------
     helena-rasche      | 2018-09-21 21:42:01


### query training-queue

**NAME**

query training-queue -  Jobs currently being run by people in a given training

**SYNOPSIS**

`gxadmin query training-queue <training_id>`

**NOTES**

Finds all jobs by people in that queue (including things they are executing that are not part of a training)

    $ gxadmin query training-queue hts2018
     state  |   id    | extid  | tool_id |   username    |       created
    --------+---------+--------+---------+---------------+---------------------
     queued | 4350274 | 225743 | upload1 |               | 2018-09-26 10:00:00


### query ts-repos

**NAME**

query ts-repos -  Counts of toolshed repositories by toolshed and owner.

**SYNOPSIS**

`gxadmin query ts-repos`


### query user-cpu-years

**NAME**

query user-cpu-years -  (NEW) CPU years allocated to tools by user

**SYNOPSIS**

`gxadmin query user-cpu-years`

**NOTES**

This uses the galaxy_slots and runtime_seconds metrics in order to
calculate allocated CPU years. This will not be the value of what is
actually consumed by your jobs, you should use cgroups.

rank  | user_id |  username   | cpu_years
----- | ------- | ----------- | ----------
    1 |      25 | 123f911b5f1 |     20.35
    2 |    2099 | cb0fabc0002 |     14.93
    3 |    1190 | 7e9e9b00b89 |     14.24
    4 |     365 | 42f211e5e87 |     14.06
    5 |     230 | 26cdba62c93 |     12.97
    6 |     190 | fa87cddfcae |      7.01
    7 |     428 | 44d2a648aac |      6.70
    8 |     748 | 66c57b41194 |      6.43
    9 |    1138 | 6b1467ac118 |      5.45
   10 |       5 | d755361b59a |      5.19


### query user-recent-aggregate-jobs

**NAME**

query user-recent-aggregate-jobs -  (NEW) Show aggregate information for jobs in past N days for user

**SYNOPSIS**

`gxadmin query user-recent-aggregate-jobs <username|id|email> [days|7]`

**NOTES**

Obtain an overview of tools that a user has run in the past N days


### query users-count

**NAME**

query users-count -  Shows sums of active/external/deleted/purged accounts

**SYNOPSIS**

`gxadmin query users-count`

**NOTES**

     active | external | deleted | purged | count
    --------+----------+---------+--------+-------
     f      | f        | f       | f      |   182
     t      | f        | t       | t      |     2
     t      | f        | t       | f      |     6
     t      | f        | f       | f      |  2350
     f      | f        | t       | t      |    36


### query users-total

**NAME**

query users-total -  Total number of Galaxy users (incl deleted, purged, inactive)

**SYNOPSIS**

`gxadmin query users-total`


### query workflow-connections

**NAME**

query workflow-connections -  The connections of tools, from output to input, in the latest (or all) versions of user workflows

**SYNOPSIS**

`gxadmin query workflow-connections [--all]`

**NOTES**

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


### query workflow-invocation-status

**NAME**

query workflow-invocation-status -  Report on how many workflows are in new state by handler

**SYNOPSIS**

`gxadmin query workflow-invocation-status`

**NOTES**

Really only intended to be used in influx queries.

