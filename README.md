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

## Queries

The query section of the tool supports writing query data out in normal
postgres tables, csv, or tsv as desired by the user:

- [validate](#validate): Validate XML config files
- [migrate-tool-install-to-sqlite](#migrate-tool-install-to-sqlite): Converts normal potsgres toolshed repository tables into the SQLite version
- Queries
    - [latest-users](#latest-users): 40 recently registered users
    - [tool-usage](#tool-usage): Counts of tool runs
    - [job-info](#job-info): Information about a specific job
    - [job-outputs](#job-outputs): Output datasets from a specific job
    - [job-history](#job-history): Job state history for a specific job
    - [queue](#queue): Brief overview of currently running jobs
    - [queue-detail](#queue-detail): Detailed overview of running and queued jobs
    - [recent-jobs](#recent-jobs): Jobs run in the past <hours> (in any state)
    - [jobs-per-user](#jobs-per-user): Number of jobs run by a specific user
    - [runtime-per-user](#runtime-per-user): computation time of user (by email)
    - [training](#training): List known trainings
    - [training-members](#training-members): List users in a specific training
    - [queue-time](#queue-time): The average/95%/99% a specific tool spends in queue state.
    - [datasets-created-daily](#datasets-created-daily): The min/max/average/p95/p99 of total size of datasets created in a single day.


### validate

This requires you to have `$GALAXY_DIST` set and to have config under `$GALAXY_DIST/config`

```
$ gxadmin validate
  OK: /usr/local/galaxy/galaxy-dist/data_manager_conf.xml
  OK: /usr/local/galaxy/galaxy-dist/datatypes_conf.xml
  OK: /usr/local/galaxy/galaxy-dist/integrated_tool_panel.xml
  OK: /usr/local/galaxy/galaxy-dist/shed_data_manager_conf.xml
  OK: /usr/local/galaxy/galaxy-dist/shed_tool_conf.xml
  OK: /usr/local/galaxy/galaxy-dist/config/data_manager_conf.xml
  OK: /usr/local/galaxy/galaxy-dist/config/datatypes_conf.xml
  OK: /usr/local/galaxy/galaxy-dist/config/dependency_resolvers_conf.xml
  OK: /usr/local/galaxy/galaxy-dist/config/external_service_types_conf.xml
  OK: /usr/local/galaxy/galaxy-dist/config/job_conf.xml
  OK: /usr/local/galaxy/galaxy-dist/config/job_metrics_conf.xml
  OK: /usr/local/galaxy/galaxy-dist/config/migrated_tools_conf.xml
  OK: /usr/local/galaxy/galaxy-dist/config/nagios_tool_conf.xml
  OK: /usr/local/galaxy/galaxy-dist/config/object_store_conf.xml
  OK: /usr/local/galaxy/galaxy-dist/config/oidc_backends_config.xml
  OK: /usr/local/galaxy/galaxy-dist/config/oidc_config.xml
  OK: /usr/local/galaxy/galaxy-dist/config/shed_data_manager_conf.xml
  OK: /usr/local/galaxy/galaxy-dist/config/shed_tool_conf.xml
  OK: /usr/local/galaxy/galaxy-dist/config/shed_tool_data_table_conf.xml
  OK: /usr/local/galaxy/galaxy-dist/config/tool_conf.xml
  OK: /usr/local/galaxy/galaxy-dist/config/tool_data_table_conf.xml
  OK: /usr/local/galaxy/galaxy-dist/config/tool_sheds_conf.xml
All XML files validated
```


### latest-users

Returns 40 most recently registered users

```
$ gxadmin query latest-users
 id |        create_time        | pg_size_pretty |   username    |             email
----+---------------------------+----------------+---------------+--------------------------------
  1 | 2018-10-05 11:40:42.90119 |                | helena-rasche | hxr@informatik.uni-freiburg.de
```

### tool-usage

```
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
```

### job-info

```
$ gxadmin query job-info 1
 tool_id | state | username |        create_time         | job_runner_name | job_runner_external_id
---------+-------+----------+----------------------------+-----------------+------------------------
 upload1 | ok    | admin    | 2012-12-06 16:34:27.492711 | local:///       | 9347
```

### job-outputs

```
$ gxadmin query job-outputs 1000
  id  | state | deleted | purged |  id  | state | deleted | purged
------+-------+---------+--------+------+-------+---------+--------
 1403 |       | f       | f      | 3559 | ok    | f       | f
```


### job-history

```
$ gxadmin query job-history 4384025
        time         |  state
---------------------+---------
 2018-10-05 16:20:13 | ok
 2018-10-05 16:19:57 | running
 2018-10-05 16:19:55 | queued
 2018-10-05 16:19:54 | new
(4 rows)
```

### queue

```

$ gxadmin query queue
                                              tool_id                                              |  state  | count
---------------------------------------------------------------------------------------------------+---------+-------
 toolshed.g2.bx.psu.edu/repos/iuc/unicycler/unicycler/0.4.6.0                                      | queued  |     9
 toolshed.g2.bx.psu.edu/repos/iuc/dexseq/dexseq_count/1.24.0.0                                     | running |     7
 toolshed.g2.bx.psu.edu/repos/nml/spades/spades/1.2                                                | queued  |     6
 ebi_sra_main                                                                                      | running |     6
 toolshed.g2.bx.psu.edu/repos/iuc/trinity/trinity/2.8.3                                            | queued  |     5
 toolshed.g2.bx.psu.edu/repos/devteam/bowtie2/bowtie2/2.3.4.2                                      | running |     5
 toolshed.g2.bx.psu.edu/repos/nml/spades/spades/3.11.1+galaxy1                                     | queued  |     4
 toolshed.g2.bx.psu.edu/repos/devteam/fastqc/fastqc/0.69                                           | running |     4
 toolshed.g2.bx.psu.edu/repos/bgruening/nucleosome_prediction/Nucleosome/3.0                       | running |     3
 toolshed.g2.bx.psu.edu/repos/galaxyp/maldi_quant_preprocessing/maldi_quant_preprocessing/1.18.0.0 | queued  |     3
 toolshed.g2.bx.psu.edu/repos/iuc/mothur_venn/mothur_venn/1.36.1.0                                 | running |     2
 toolshed.g2.bx.psu.edu/repos/nml/metaspades/metaspades/3.9.0                                      | running |     2
 upload1                                                                                           | running |     2
```

### queue-detail

```
$ gxadmin query queue-detail
  state  |   id    |  extid  |                                 tool_id                                   |      username       | time_since_creation
---------+---------+---------+---------------------------------------------------------------------------+---------------------+---------------------
 running | 4360629 | 229333  | toolshed.g2.bx.psu.edu/repos/bgruening/infernal/infernal_cmsearch/1.1.2.0 |                     | 5 days 11:00:00
 running | 4362676 | 230237  | toolshed.g2.bx.psu.edu/repos/iuc/mothur_venn/mothur_venn/1.36.1.0         |                     | 4 days 18:00:00
 running | 4364499 | 231055  | toolshed.g2.bx.psu.edu/repos/iuc/mothur_venn/mothur_venn/1.36.1.0         |                     | 4 days 05:00:00
 running | 4366604 | 5183013 | toolshed.g2.bx.psu.edu/repos/iuc/dexseq/dexseq_count/1.24.0.0             |                     | 3 days 20:00:00
 running | 4366605 | 5183016 | toolshed.g2.bx.psu.edu/repos/iuc/dexseq/dexseq_count/1.24.0.0             |                     | 3 days 20:00:00
 running | 4366606 | 5183017 | toolshed.g2.bx.psu.edu/repos/iuc/dexseq/dexseq_count/1.24.0.0             |                     | 3 days 20:00:00
 running | 4366603 | 5183014 | toolshed.g2.bx.psu.edu/repos/iuc/dexseq/dexseq_count/1.24.0.0             |                     | 3 days 20:00:00
 running | 4366601 | 5183010 | toolshed.g2.bx.psu.edu/repos/iuc/dexseq/dexseq_count/1.24.0.0             |                     | 3 days 20:00:00
 running | 4366602 | 5183011 | toolshed.g2.bx.psu.edu/repos/iuc/dexseq/dexseq_count/1.24.0.0             |                     | 3 days 20:00:00
 running | 4369132 | 5183706 | toolshed.g2.bx.psu.edu/repos/devteam/clustalw/clustalw/2.1                |                     | 3 days 05:00:00
 running | 4371602 | 234952  | toolshed.g2.bx.psu.edu/repos/devteam/fastqc/fastqc/0.69                   |                     | 3 days -01:00:00
 queued  | 4325084 | 217919  | toolshed.g2.bx.psu.edu/repos/iuc/trinity/trinity/2.8.3                    |                     | 14 days 02:00:00
 queued  | 4325142 | 217959  | toolshed.g2.bx.psu.edu/repos/iuc/trinity/trinity/2.8.3                    |                     | 14 days 02:00:00
 queued  | 4326844 | 218690  | toolshed.g2.bx.psu.edu/repos/nml/spades/spades/3.11.1                     |                     | 13 days 12:00:00
 queued  | 4344238 | 222573  | toolshed.g2.bx.psu.edu/repos/nml/spades/spades/1.2                        |                     | 10 days 08:00:00
 queued  | 4350274 | 225743  | toolshed.g2.bx.psu.edu/repos/iuc/unicycler/unicycler/0.4.6.0              |                     | 9 days 05:00:00
 queued  | 4353435 | 227038  | toolshed.g2.bx.psu.edu/repos/iuc/trinity/trinity/2.8.3                    |                     | 8 days 08:00:00
 queued  | 4361914 | 229712  | toolshed.g2.bx.psu.edu/repos/iuc/unicycler/unicycler/0.4.6.0              |                     | 5 days -01:00:00
 queued  | 4361812 | 229696  | toolshed.g2.bx.psu.edu/repos/iuc/unicycler/unicycler/0.4.6.0              |                     | 5 days -01:00:00
 queued  | 4361939 | 229728  | toolshed.g2.bx.psu.edu/repos/nml/spades/spades/1.2                        |                     | 4 days 21:00:00
 queued  | 4361941 | 229731  | toolshed.g2.bx.psu.edu/repos/nml/spades/spades/1.2                        |                     | 4 days 21:00:00
```

### recent-jobs

```
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
```

### jobs-per-user

```

$ gxadmin query jobs-per-user hxr@informatik.uni-freiburg.de
 count
-------
  1460
```

### runtime-per-user

```
$ gxadmin query runtime-per-user hxr@informatik.uni-freiburg.de
   sum
----------
 14:07:39
```

### training

This module is specific to EU's implementation of Training Infrastructure as a Service. But this specifically just checks for all groups with the name prefix `training-`

```
$ gxadmin query training
       name       |  created
------------------+------------
 hts2018          | 2018-09-19
```

### training-members

```
$ gxadmin query training-members hts2018
      username      |       joined
--------------------+---------------------
 helena-rasche      | 2018-09-21 21:42:01
```

### training-queue

Finds all jobs by people in that queue (including things they are executing that are not part of a training)

```
$ gxadmin query training-queue hts2018
 state  |   id    | extid  | tool_id |   username    |       created
--------+---------+--------+---------+---------------+---------------------
 queued | 4350274 | 225743 | upload1 |               | 2018-09-26 10:00:00
```

### queue-time

```
$ gxadmin query queue-time toolshed.g2.bx.psu.edu/repos/nilesh/rseqc/rseqc_geneBody_coverage/2.6.4.3
       min       |     perc_95     |     perc_99     |       max
-----------------+-----------------+-----------------+-----------------
 00:00:15.421457 | 00:00:55.022874 | 00:00:59.974171 | 00:01:01.211995
```

### datasets-created-daily

```
$ gxadmin query datasets-created-daily
   min   |  avg   | perc_95 | perc_99 |  max
---------+--------+---------+---------+-------
 0 bytes | 338 GB | 1355 GB | 2384 GB | 42 TB
```

### migrate-tool-install-to-sqlite

```
$ gxadmin migrate-tool-install-to-sqlite
Creating new sqlite database: galaxy_install.sqlite
Migrating tables
  export: tool_shed_repository
  import: tool_shed_repository
  export: migrate_version
  import: migrate_version
  export: tool_version
  import: tool_version
  export: tool_version_association
  import: tool_version_association
  export: migrate_tools
  import: migrate_tools
  export: tool_dependency
  import: tool_dependency
  export: repository_dependency
  import: repository_dependency
  export: repository_repository_dependency_association
  import: repository_repository_dependency_association
Complete
```

## License

GPLv3
