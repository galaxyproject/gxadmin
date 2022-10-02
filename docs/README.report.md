# report

Command | Description
------- | -----------
[`report assigned-to-handler`](#report-assigned-to-handler) | Report what items are assigned to a handler currently.
[`report data-info`](#report-data-info) | Information about a specific dataset, it can be a UUID or numeric dataset ID or nuemric HDA ID
[`report group-info`](#report-group-info) | Quick overview of a Galaxy group in your system
[`report job-info`](#report-job-info) | Information about a specific job
[`report user-info`](#report-user-info) | Quick overview of a Galaxy user in your system

## report assigned-to-handler

([*source*](https://github.com/galaxyproject/gxadmin/search?q=report_assigned-to-handler&type=Code))
report assigned-to-handler -  Report what items are assigned to a handler currently.

**SYNOPSIS**

    gxadmin report assigned-to-handler <handler>


## report data-info

([*source*](https://github.com/galaxyproject/gxadmin/search?q=report_data-info&type=Code))
report data-info -  Information about a specific dataset, it can be a UUID or numeric dataset ID or nuemric HDA ID

**SYNOPSIS**

    gxadmin report data-info <data_id> [object_store_config_file]

**NOTES**

Report some useful information about a a Galaxy dataset. Mainly useful for debugging.
Takes uuid or dataset id and optionally an object store config file 
gxadmin report data-info 428d0c00-95a5-4c1a-8248-e9e0937f376f object_store_conf.xml
# Galaxy dataset

Property | Value
-------- | -----
ID | 88378397
UUID | 428d0c0095a54c1a8248e9e0937f376f
Created | 2022-05-11 10:36:44.902173
Updated | 2022-05-11 10:36:44.902174
Properties | dataset_state=ok deleted=f purged=f
Object store ID | files12
Size | 7773 MB
Extension | fastqsanger.gz
User id | 5
Tool id | toolshed.g2.bx.psu.edu/repos/bgruening/10x_bamtofastq/10x_bamtofastq/1.4.1
Job state | ok
Disk path | /data/dnb06/galaxy_db/files/4/2/8/dataset_428d0c0095a54c1a8248e9e0937f376f.dat


## report group-info

([*source*](https://github.com/galaxyproject/gxadmin/search?q=report_group-info&type=Code))
report group-info -  Quick overview of a Galaxy group in your system

**SYNOPSIS**

    gxadmin report group-info <group_id|groupname>

**NOTES**

This command lets you quickly find out information about a Galaxy group. The output is formatted as markdown by default.
Consider [mdless](https://github.com/ttscoff/mdless) for easier reading in the terminal!
    $ gxadmin report group-info Backofen
# Galaxy Group 18
      Property | Value
-------------- | -----
            ID | Backofen (id=1)
       Created | 2013-02-25 15:58:10.691672+01
    Properties | deleted=f
    Group size | 8
Number of jobs | 1630
    Disk usage | 304 GB
   Mean Disk usage | 43 GB
Data generated | 6894 GB
     CPU years | 4.07

## Member stats
Username | Email | User ID | Active | Disk Usage | Number of jobs | CPU years
---- | ---- | ---- | ---- | --- | ---- | ---- | ----
bgruening | bgruening@gmail.com | 25 | t | 265 GB | 1421 | 1.14
helena-rasche | hxr@informatik.uni-freiburg.de | 122 | t | 37 GB | 113 | 2.91
videmp | videmp@informatik.uni-freiburg.de | 46 | t | 1383 MB | 96 | 0.02


## report job-info

([*source*](https://github.com/galaxyproject/gxadmin/search?q=report_job-info&type=Code))
report job-info -  Information about a specific job

**SYNOPSIS**

    gxadmin report job-info <id>

**NOTES**

    $ gxadmin report job-info 1
     tool_id | state | username |        create_time         | job_runner_name | job_runner_external_id
    ---------+-------+----------+----------------------------+-----------------+------------------------
     upload1 | ok    | admin    | 2012-12-06 16:34:27.492711 | local:///       | 9347


## report user-info

([*source*](https://github.com/galaxyproject/gxadmin/search?q=report_user-info&type=Code))
report user-info -  Quick overview of a Galaxy user in your system

**SYNOPSIS**

    gxadmin report user-info <user_id|username|email>

**NOTES**

This command lets you quickly find out information about a user. The output is formatted as markdown by default.

Consider [mdless](https://github.com/ttscoff/mdless) for easier reading in the terminal!

    $ gxadmin report user-info helena-rasche
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

