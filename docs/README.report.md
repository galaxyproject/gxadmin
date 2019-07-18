# report

Command | Description
------- | -----------
[`report assigned-to-handler`](#report-assigned-to-handler) | Report what items are assigned to a handler currently.
[`report job-info`](#report-job-info) | Information about a specific job
[`report user-info`](#report-user-info) | Quick overview of a Galaxy user in your system

## report assigned-to-handler

report assigned-to-handler -  Report what items are assigned to a handler currently.

**SYNOPSIS**

    gxadmin report assigned-to-handler <handler>


## report job-info

report job-info -  Information about a specific job

**SYNOPSIS**

    gxadmin report job-info <id>

**NOTES**

    $ gxadmin report job-info 1
     tool_id | state | username |        create_time         | job_runner_name | job_runner_external_id
    ---------+-------+----------+----------------------------+-----------------+------------------------
     upload1 | ok    | admin    | 2012-12-06 16:34:27.492711 | local:///       | 9347


## report user-info

report user-info -  Quick overview of a Galaxy user in your system

**SYNOPSIS**

    gxadmin report user-info <user_id|username|email>

**NOTES**

This command lets you quickly find out information about a user. The output is formatted as markdown by default.

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

