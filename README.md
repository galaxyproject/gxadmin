# Galaxy Admin Utility

A small shell script for us galaxy administrators:

- validate your XML files (e.g. before restarting handlers.)
- swaps zerglings (if you use them + supervisord)
- runs common queries against the DB

Mostly it's a good dumping ground for the common queries we all run quite
often. Some useful ones are included. This script strictly expects a postgres
database and we will not support mysql or sqlite3.

## Installation

```
curl https://raw.githubusercontent.com/usegalaxy-eu/gxadmin/master/gxadmin > /usr/bin/gxadmin
chmod +x /usr/bin/gxadmin
```

## Changelog

[Changelog](CHANGELOG.md)

## Authors

- Helena Rasche (@erasche)
- Nate Coraor (@natefoo)

## License

GPLv3

## Query Setup

Queries support being run in normal postgres table, csv, or tsv output as you
need. Just use `gxadmin query`, `gxadmin tsvquery`, or `gxadmin csvquery` as
appropriate.

You should have a `~/.pgpass` with the database connection information, and set
`PGDATABASE`, `PGHOST`, and `PGUSER` in your environment.

Example .pgpass:

```
<pg_host>:5432:*:<pg_user>:<pg_password>
```

Command | Description
------- | -----------
[cleanup](#cleanup) | Cleanup histories/hdas/etc for past N days (default=30)
[handler restart](#handler-restart) | restart handlers
[handler strace](#handler-strace) | Run an strace on a specific handler (to watch it load files.)
[handler tail](#handler-tail) | tail handler logs
[migrate-tool-install-to-sqlite](#migrate-tool-install-to-sqlite) | Converts normal potsgres toolshed repository tables into the SQLite version
[query active-users](#query-active-users) | Count of users who ran jobs in past 1 week (default = 1)
[query collection-usage](#query-collection-usage) | Information about how many collections of various types are used
[query datasets-created-daily](#query-datasets-created-daily) | The min/max/average/p95/p99 of total size of datasets created in a single day.
[query disk-usage](#query-disk-usage) | Disk usage per object store.
[query groups-list](#query-groups-list) | List all groups known to Galaxy
[query job-history](#query-job-history) | Job state history for a specific job
[query job-info](#query-job-info) | Information about a specific job
[query job-inputs](#query-job-inputs) | Input datasets to a specific job
[query job-outputs](#query-job-outputs) | Output datasets from a specific job
[query jobs-per-user](#query-jobs-per-user) | Number of jobs run by a specific user
[query largest-collection](#query-largest-collection) | Returns the size of the single largest collection
[query latest-users](#query-latest-users) | 40 recently registered users
[query queue](#query-queue) | Brief overview of currently running jobs
[query queue-detail](#query-queue-detail) | Detailed overview of running and queued jobs
[query queue-overview](#query-queue-overview) | View used mostly for monitoring
[query queue-time](#query-queue-time) | The average/95%/99% a specific tool spends in queue state.
[query recent-jobs](#query-recent-jobs) | Jobs run in the past <hours> (in any state)
[query runtime-per-user](#query-runtime-per-user) | computation time of user (by email)
[query tool-available-metrics](#query-tool-available-metrics) | list all available metrics for a given tool
[query tool-last-used-date](#query-tool-last-used-date) | When was the most recent invocation of every tool
[query tool-metrics](#query-tool-metrics) | See values of a specific metric
[query tool-usage](#query-tool-usage) | Counts of tool runs
[query training](#query-training) | List known trainings
[query training-memberof](#query-training-memberof) | List trainings that a user is part of
[query training-members](#query-training-members) | List users in a specific training
[query training-queue](#query-training-queue) | Jobs currently being run by people in a given training
[query training-remove-member](#query-training-remove-member) | Remove a user from a training
[query ts-repos](#query-ts-repos) | Counts of toolshed repositories by toolshed and owner.
[query users-count](#query-users-count) | Shows sums of active/external/deleted/purged accounts
[query users-total](#query-users-total) | Total number of Galaxy users (incl deleted, purged, inactive)
[query old-histories](#query-old-histories) | List histories not updated in X weeks
[update](#update) | Update the script
[validate](#validate) | validate config files
[zerg strace](#zerg-strace) | swap zerglings
[zerg swap](#zerg-swap) | swap zerglings
[zerg tail](#zerg-tail) | tail zergling logs


### cleanup

**NAME**

cleanup -  Cleanup histories/hdas/etc for past N days (default=30)

**SYNOPSIS**

gxadmin cleanup [days]

**NOTES**

Cleanup histories/hdas/etc for past N days using the python objects-based method


### handler restart

**NAME**

handler restart -  restart handlers

**SYNOPSIS**

gxadmin handler restart <message>


### handler strace

**NAME**

handler strace -  Run an strace on a specific handler (to watch it load files.)

**SYNOPSIS**

gxadmin handler strace <handler_id>


### handler tail

**NAME**

handler tail -  tail handler logs

**SYNOPSIS**

gxadmin handler tail


### migrate-tool-install-to-sqlite

**NAME**

migrate-tool-install-to-sqlite -  Converts normal potsgres toolshed repository tables into the SQLite version

**SYNOPSIS**

gxadmin migrate-tool-install-to-sqlite

**NOTES**

    $ gxadmin migrate-tool-install-to-sqlite
    Creating new sqlite database: galaxy_install.sqlite
    Migrating tables
      export: tool_shed_repository
      import: tool_shed_repository
      ...
      export: repository_repository_dependency_association
      import: repository_repository_dependency_association
    Complete


### query active-users

**NAME**

query active-users -  Count of users who ran jobs in past 1 week (default = 1)

**SYNOPSIS**

gxadmin query active-users [weeks]

**NOTES**

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


### query collection-usage

**NAME**

query collection-usage -  Information about how many collections of various types are used

**SYNOPSIS**

gxadmin query collection-usage


### query datasets-created-daily

**NAME**

query datasets-created-daily -  The min/max/average/p95/p99 of total size of datasets created in a single day.

**SYNOPSIS**

gxadmin query datasets-created-daily

**NOTES**

    $ gxadmin query datasets-created-daily
       min   |  avg   | perc_95 | perc_99 |  max
    ---------+--------+---------+---------+-------
     0 bytes | 338 GB | 1355 GB | 2384 GB | 42 TB


### query disk-usage

**NAME**

query disk-usage -  Disk usage per object store.

**SYNOPSIS**

gxadmin query disk-usage

**NOTES**

TODO: implement flag for --nice numbers

     object_store_id |      sum
    -----------------+----------------
     files8          | 88109503720067
     files6          | 64083627169725
     files9          | 53690953947700
     files7          | 30657241908566
     files1          | 30633153627407
     files2          | 22117477087642
     files3          | 21571951600351
     files4          | 13969690603365
                     |  6943415154832
     secondary       |   594632335718
    (10 rows)


### query groups-list

**NAME**

query groups-list -  List all groups known to Galaxy

**SYNOPSIS**

gxadmin query groups-list


### query job-history

**NAME**

query job-history -  Job state history for a specific job

**SYNOPSIS**

gxadmin query job-history <id>

**NOTES**

    $ gxadmin query job-history 4384025
            time         |  state
    ---------------------+---------
     2018-10-05 16:20:13 | ok
     2018-10-05 16:19:57 | running
     2018-10-05 16:19:55 | queued
     2018-10-05 16:19:54 | new
    (4 rows)


### query job-info

**NAME**

query job-info -  Information about a specific job

**SYNOPSIS**

gxadmin query job-info <id> [id] ...

**NOTES**

    $ gxadmin query job-info 1
     tool_id | state | username |        create_time         | job_runner_name | job_runner_external_id
    ---------+-------+----------+----------------------------+-----------------+------------------------
     upload1 | ok    | admin    | 2012-12-06 16:34:27.492711 | local:///       | 9347


### query job-inputs

**NAME**

query job-inputs -  Input datasets to a specific job

**SYNOPSIS**

gxadmin query job-inputs <id>


### query job-outputs

**NAME**

query job-outputs -  Output datasets from a specific job

**SYNOPSIS**

gxadmin query job-outputs <id>


### query jobs-per-user

**NAME**

query jobs-per-user -  Number of jobs run by a specific user

**SYNOPSIS**

gxadmin query jobs-per-user <email>

**NOTES**

    $ gxadmin query jobs-per-user hxr@informatik.uni-freiburg.de
     count
    -------
      1460


### query largest-collection

**NAME**

query largest-collection -  Returns the size of the single largest collection

**SYNOPSIS**

gxadmin query largest-collection


### query latest-users

**NAME**

query latest-users -  40 recently registered users

**SYNOPSIS**

gxadmin query latest-users

**NOTES**

Returns 40 most recently registered users

    $ gxadmin query latest-users
     id |        create_time        | pg_size_pretty |   username    |             email
    ----+---------------------------+----------------+---------------+--------------------------------
      1 | 2018-10-05 11:40:42.90119 |                | helena-rasche | hxr@informatik.uni-freiburg.de


### query queue

**NAME**

query queue -  Brief overview of currently running jobs

**SYNOPSIS**

gxadmin query queue

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

gxadmin query queue-detail [--all]

**NOTES**

    $ gxadmin query queue-detail
      state  |   id    |  extid  |                                 tool_id                                   |      username       | time_since_creation
    ---------+---------+---------+---------------------------------------------------------------------------+---------------------+---------------------
     running | 4360629 | 229333  | toolshed.g2.bx.psu.edu/repos/bgruening/infernal/infernal_cmsearch/1.1.2.0 |                     | 5 days 11:00:00
     running | 4362676 | 230237  | toolshed.g2.bx.psu.edu/repos/iuc/mothur_venn/mothur_venn/1.36.1.0         |                     | 4 days 18:00:00
     running | 4364499 | 231055  | toolshed.g2.bx.psu.edu/repos/iuc/mothur_venn/mothur_venn/1.36.1.0         |                     | 4 days 05:00:00
     running | 4366604 | 5183013 | toolshed.g2.bx.psu.edu/repos/iuc/dexseq/dexseq_count/1.24.0.0             |                     | 3 days 20:00:00
     running | 4366605 | 5183016 | toolshed.g2.bx.psu.edu/repos/iuc/dexseq/dexseq_count/1.24.0.0             |                     | 3 days 20:00:00
     queued  | 4350274 | 225743  | toolshed.g2.bx.psu.edu/repos/iuc/unicycler/unicycler/0.4.6.0              |                     | 9 days 05:00:00
     queued  | 4353435 | 227038  | toolshed.g2.bx.psu.edu/repos/iuc/trinity/trinity/2.8.3                    |                     | 8 days 08:00:00
     queued  | 4361914 | 229712  | toolshed.g2.bx.psu.edu/repos/iuc/unicycler/unicycler/0.4.6.0              |                     | 5 days -01:00:00
     queued  | 4361812 | 229696  | toolshed.g2.bx.psu.edu/repos/iuc/unicycler/unicycler/0.4.6.0              |                     | 5 days -01:00:00
     queued  | 4361939 | 229728  | toolshed.g2.bx.psu.edu/repos/nml/spades/spades/1.2                        |                     | 4 days 21:00:00
     queued  | 4361941 | 229731  | toolshed.g2.bx.psu.edu/repos/nml/spades/spades/1.2                        |                     | 4 days 21:00:00


### query queue-overview

**NAME**

query queue-overview -  View used mostly for monitoring

**SYNOPSIS**

gxadmin query queue-overview

**NOTES**

Primarily for monitoring of queue. Optimally used with 'iquery' and passed to Telegraf.

    $ gxadmin iquery queue-overview
    queue-overview,tool_id=test_history_sanitization,tool_version=0.0.1,state=running,handler=main.web.1,destination_id=condor,job_runner_name=condor count=1


### query queue-time

**NAME**

query queue-time -  The average/95%/99% a specific tool spends in queue state.

**SYNOPSIS**

gxadmin query queue-time <tool_id>

**NOTES**

    $ gxadmin query queue-time toolshed.g2.bx.psu.edu/repos/nilesh/rseqc/rseqc_geneBody_coverage/2.6.4.3
           min       |     perc_95     |     perc_99     |       max
    -----------------+-----------------+-----------------+-----------------
     00:00:15.421457 | 00:00:55.022874 | 00:00:59.974171 | 00:01:01.211995


### query recent-jobs

**NAME**

query recent-jobs -  Jobs run in the past <hours> (in any state)

**SYNOPSIS**

gxadmin query recent-jobs <hours>

**NOTES**

Note that your database may have a different TZ than your querying. This is probably a misconfiguration on our end, please let me know how to fix it. Just add your offset to UTC to your query.

    $ gxadmin query recent-jobs 2.1
       id    |     date_trunc      |      tool_id          | state |    username
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

gxadmin query runtime-per-user <email>

**NOTES**

    $ gxadmin query runtime-per-user hxr@informatik.uni-freiburg.de
       sum
    ----------
     14:07:39


### query tool-available-metrics

**NAME**

query tool-available-metrics -  list all available metrics for a given tool

**SYNOPSIS**

gxadmin query tool-available-metrics <tool_id>


### query tool-last-used-date


### query tool-metrics

**NAME**

query tool-metrics -  See values of a specific metric

**SYNOPSIS**

gxadmin query tool-metrics <tool_id> <metric_id> [--like]

**NOTES**

A good way to use this is to fetch the memory usage of a tool and then
do some aggregations. The following requires [data_hacks](https://github.com/bitly/data_hacks)

    $ gxadmin tsvquery tool-metrics %rgrnastar/rna_star% memory.max_usage_in_bytes --like | \
        awk '{print --help / 1024 / 1024 / 1024}' | \
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


### query tool-usage

**NAME**

query tool-usage -  Counts of tool runs

**SYNOPSIS**

gxadmin query tool-usage

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


### query training

**NAME**

query training -  List known trainings

**SYNOPSIS**

gxadmin query training [--all]

**NOTES**

This module is specific to EU's implementation of Training Infrastructure as a Service. But this specifically just checks for all groups with the name prefix

    $ gxadmin query training
           name       |  created
    ------------------+------------
     hts2018          | 2018-09-19


### query training-memberof

**NAME**

query training-memberof -  List trainings that a user is part of

**SYNOPSIS**

gxadmin query training-memberof <username>


### query training-members

**NAME**

query training-members -  List users in a specific training

**SYNOPSIS**

gxadmin query training-members <tr_id>

**NOTES**

    $ gxadmin query training-members hts2018
          username      |       joined
    --------------------+---------------------
     helena-rasche      | 2018-09-21 21:42:01


### query training-queue

**NAME**

query training-queue -  Jobs currently being run by people in a given training

**SYNOPSIS**

gxadmin query training-queue <training_id>

**NOTES**

Finds all jobs by people in that queue (including things they are executing that are not part of a training)

    $ gxadmin query training-queue hts2018
     state  |   id    | extid  | tool_id |   username    |       created
    --------+---------+--------+---------+---------------+---------------------
     queued | 4350274 | 225743 | upload1 |               | 2018-09-26 10:00:00


### query training-remove-member

**NAME**

query training-remove-member -  Remove a user from a training

**SYNOPSIS**

gxadmin query training-remove-member <training> <username> [YESDOIT]


### query ts-repos

**NAME**

query ts-repos -  Counts of toolshed repositories by toolshed and owner.

**SYNOPSIS**

gxadmin query ts-repos


### query users-count

**NAME**

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


### query users-total

**NAME**

query users-total -  Total number of Galaxy users (incl deleted, purged, inactive)

**SYNOPSIS**

gxadmin query users-total

### query old-histories

**NAME**

query old-histories  - Produce a list of histories and their related users that haven't been updated for X weeks.

**SYNOPSIS**

gxadmin query old-histories <weeks>

### update

**NAME**

update -  Update the script

**SYNOPSIS**

gxadmin update


### validate

**NAME**

validate -  validate config files

**SYNOPSIS**

gxadmin validate

**NOTES**

Validate the configuration files
**Warning**:
- This requires you to have `$GALAXY_DIST` set and to have config under `$GALAXY_DIST/config`.
- This only validates that it is well formed XML, and does **not** validate against any schemas.

    $ gxadmin validate
      OK: /usr/local/galaxy/galaxy-dist/data_manager_conf.xml
      ...
      OK: /usr/local/galaxy/galaxy-dist/config/tool_data_table_conf.xml
      OK: /usr/local/galaxy/galaxy-dist/config/tool_sheds_conf.xml
    All XML files validated


### zerg strace

**NAME**

zerg strace -  swap zerglings

**SYNOPSIS**

gxadmin zerg strace [0|1|pool]


### zerg swap

**NAME**

zerg swap -  swap zerglings

**SYNOPSIS**

gxadmin zerg swap <message>


### zerg tail

**NAME**

zerg tail -  tail zergling logs

**SYNOPSIS**

gxadmin zerg tail
