# meta

Command | Description
------- | -----------
[`meta complete-bash`](#meta-complete-bash) | export bash autocompletion
[`meta export-grafana-dashboards`](#meta-export-grafana-dashboards) | Export all dashboards from a Grafana database to CWD and commit them to git.
[`meta gxadmin-as-a-service`](#meta-gxadmin-as-a-service) | A totally ridiculous hack. NOT SAFE :)
[`meta influx-post`](#meta-influx-post) | Post contents of file (in influx line protocol) to influx
[`meta influx-query`](#meta-influx-query) | Query an influx DB
[`meta iquery-grt-export`](#meta-iquery-grt-export) | Export data from a GRT database for sending to influx
[`meta slurp-current`](#meta-slurp-current) | Executes what used to be "Galaxy Slurp"
[`meta slurp-day`](#meta-slurp-day) | Slurps data on a specific date.
[`meta slurp-initial`](#meta-slurp-initial) | Slurps data starting at the first date until the second date.
[`meta slurp-upto`](#meta-slurp-upto) | Slurps data up to a specific date.
[`meta update`](#meta-update) | Update the script
[`meta whatsnew`](#meta-whatsnew) | What's new in this version of gxadmin

## meta complete-bash

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=meta_complete-bash&type=Code))
meta complete-bash -  export bash autocompletion

**SYNOPSIS**

    gxadmin meta complete-bash

**NOTES**

Produces the bash autocompletion for gxadmin

Write the output of this somewhere useful, and source it in your bash profile.

    $ gxadmin meta bash-complete > ~/.cache/gxadmin-autocomplete.sh
$ . ~/.cache/gxadmin-autocomplete.sh
$ gxadmin<TAB>


## meta export-grafana-dashboards

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=meta_export-grafana-dashboards&type=Code))
meta export-grafana-dashboards -  Export all dashboards from a Grafana database to CWD and commit them to git.

**SYNOPSIS**

    gxadmin meta export-grafana-dashboards [grafana_db|/var/lib/grafana/grafana.db]

**NOTES**

Given a grafana database, use sqlite3 to access all of the dashboards within, and then write them out to the current working directly. Next, commit them and update a README.

This script forms the basis of https://github.com/usegalaxy-eu/grafana-dashboards

**WARNING**

!> This script will silently remove all json files from CWD
!> as a first step. Additionally it will commit and push at the end, so it
!> should be run in a directory that has a git repo initialised, where you
!> are not concerned about accidentally pushing to wrong remote.


## meta gxadmin-as-a-service

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=meta_gxadmin-as-a-service&type=Code))
meta gxadmin-as-a-service - )

**SYNOPSIS**

    gxadmin meta gxadmin-as-a-service [port|8080]

**NOTES**

Run gxadmin as a service, specifically the query portion of the API!

    $ curl localhost:8080/ts-repos
    [{"tool_shed":"toolshed.g2.bx.psu.edu","owner":"bgruening","count":1},{"tool_shed":"toolshed.g2.bx.psu.edu","owner":"iuc","count":2}]
    $ curl localhost:8080/latest-users
    [{"id":3,"create_time":"2019-03-07T13:06:37.945403+00:00","disk_usage":null,"username":"beverly","email":"b@example.com","groups":"","active":true},{"id":2,"create_time":"2019-03-07T13:06:23.369201+00:00","disk_usage":"826  bytes","username":"alice","email":"a@example.com","groups":"","active":true},{"id":1,"create_time":"2018-11-19T14:54:30.969713+00:00","disk_usage":"869  MB","username":"helena","email":"hxr@local.host","groups":"training-asdf  training-hogeschool","active":true}]
    $ curl --silent http://localhost:8081/user-history-list/helena | jq '.[0]'
    {
        "ID": 74,
        "Name": "Unnamed  history",
        "Last  Updated": "2020-05-19T14:00:37.066429",
        "Size": "961  kB"
    }

Multiple arguments can be separated by %20 or +

I found https://github.com/izabera/ynaas which contained a very nice, simple bash webservice and so I learnt from that and turned gxadmin into a self-running webservice. jsonquery was already in gxadmin, so it was a short jump to this idea. This is for fun only!! Use at your own risk.

If you're legitimately considering doing this (please, do not), then just use https://github.com/PostgREST/postgrest which is a much safer and more reliable solution.

**WARNING**

!> This is totally ridiculous and no one should ever do this. I thought
!> it was fun, so, I added it. PLEASE DO NOT RUN IN PRODUCTION.


## meta influx-post

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=meta_influx-post&type=Code))
meta influx-post -  Post contents of file (in influx line protocol) to influx

**SYNOPSIS**

    gxadmin meta influx-post <db> <file>

**NOTES**

Post data to InfluxDB. Must be [influx line protocol formatted](https://docs.influxdata.com/influxdb/v1.7/write_protocols/line_protocol_tutorial/)

Posting data from a file:

    $ gxadmin meta influx-post galaxy file.inflx

Posting data from the output of a command

    $ gxadmin meta influx-post galaxy <(echo "weather,location=us-midwest temperature=$RANDOM $(date +%s%N)")

Posting data from the output of a gxadmin command

    $ gxadmin meta influx-post galaxy <(gxadmin meta slurp-current --date)

**WARNING**

!> If you are sending a LOT of data points, consider splitting
!> them. Influx recommends 5-10k lines:
!>
!>     $ split --lines=5000 data.iflx PREFIX
!>     $ for file in PREFIX*; do gxadmin meta influx-post galaxy ; done


## meta influx-query

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=meta_influx-query&type=Code))
meta influx-query -  Query an influx DB

**SYNOPSIS**

    gxadmin meta influx-query <db> "<query>"

**NOTES**

Query an InfluxDB

Query percentage of memory used over last hour.

    $ gxadmin meta influx-query galaxy "select mean(used_percent) from mem where host='X' AND time > now() - 1h group by time(10m)" | \
        jq '.results[0].series[0].values[] | @tsv' -r
    2019-04-26T09:30:00Z    64.83119975586277
    2019-04-26T09:40:00Z    64.58284600472675
    2019-04-26T09:50:00Z    64.62714491344244
    2019-04-26T10:00:00Z    64.62339148181154
    2019-04-26T10:10:00Z    63.95268353798708
    2019-04-26T10:20:00Z    64.66849537282599
    2019-04-26T10:30:00Z    65.06069941790024


## meta iquery-grt-export

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=meta_iquery-grt-export&type=Code))
meta iquery-grt-export -  Export data from a GRT database for sending to influx

**SYNOPSIS**

    gxadmin meta iquery-grt-export

**NOTES**

**WARNING**:

!> GRT database specific query, will not work with a galaxy database!


## meta slurp-current

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=meta_slurp-current&type=Code))
meta slurp-current -  Executes what used to be "Galaxy Slurp"

**SYNOPSIS**

    gxadmin meta slurp-current [--date] [slurp-name [2nd-slurp-name [...]]]

**NOTES**

Obtain influx compatible metrics regarding the current state of the
server. UseGalaxy.EU uses this to display things like "Current user
count" and "Current dataset size/distribution/etc."

It is expected that you are passing this straight to telegraf, there is
no non-influx output supported currently.

Supplying --date will include the current timestamp at the end of the
line, making it compatible for "gxadmin meta influx-post" usage

You can add your own functions which are included in this output, using
the $GXADMIN_SITE_SPECIFIC file. They must start with the prefix
"server_", e.g. "server_mymetric".

    $ gxadmin meta slurp-current
    server-allocated-cpu,job_runner_name=condor cpu_years=102.00
    server-allocated-cpu,job_runner_name=local cpu_years=1346.00
    server-datasets,deleted=f,object_store_id=,state=error,purged=f count=37,size=29895528
    server-datasets,deleted=f,object_store_id=,state=ok,purged=f count=72,size=76739510
    server-datasets,deleted=f,object_store_id=,state=discarded,purged=f count=2,size=0
    server-hda,deleted=f,extension=gff3 max=2682565,sum=2682565,avg=2682565,min=2682565
    server-hda,deleted=t,extension=tabular max=468549,sum=597843,avg=22142,min=2
    server-hda,deleted=f,extension=fastqsanger max=3,sum=3,avg=3,min=3
    server-hda,deleted=f,extension=tabular max=2819293,sum=3270268,avg=155727,min=3
    server-hda,deleted=f,extension=png max=800459,sum=7047695,avg=503407,min=142863
    server-hda,deleted=t,extension=auto max=9571,sum=9571,avg=9571,min=9571
    server-hda,deleted=t,extension=data max=2,sum=2,avg=2,min=2
    server-hda,deleted=t,extension=txt max=5023,sum=5039,avg=2520,min=16
    server-hda,deleted=t,extension=bigwig max=2972569,sum=5857063,avg=1464266,min=0
    server-hda,deleted=t,extension=tar.gz max=209034,sum=1318690,avg=188384,min=91580
    server-hda,deleted=f,extension=vcf_bgzip max=3965889,sum=3965889,avg=3965889,min=3965889
    server-hda,deleted=t,extension=png max=2969711,sum=6584812,avg=1097469,min=183
    server-hda,deleted=f,extension=txt max=9584828,sum=132124407,avg=4556014,min=0
    server-hda,deleted=f,extension=bigwig max=14722,sum=17407,avg=8704,min=2685
    server-hda,deleted=f,extension=tar.gz max=209025,sum=390421,avg=195211,min=181396
    server-histories,importable=f,deleted=f,genome_build=?,published=f,importing=f,purged=f count=14
    server-jobs,state=ok,destination_id=slurm_singularity,job_runner_name=local count=26
    server-jobs,state=error,destination_id=condor_resub,job_runner_name=condor count=1
    server-jobs,state=deleted,destination_id=local,job_runner_name=local count=1
    server-jobs,state=error,destination_id=condor,job_runner_name=condor count=8
    server-jobs,state=ok,destination_id=local,job_runner_name=local count=13
    server-jobs,state=ok,destination_id=condor,job_runner_name=condor count=2
    server-jobs,state=error,destination_id=local,job_runner_name=local count=3
    server-users,active=t,deleted=f,external=f,purged=f count=3
    server-workflows,deleted=f,importable=f,published=f count=3


## meta slurp-day

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=meta_slurp-day&type=Code))
meta slurp-day -  Slurps data on a specific date.

**SYNOPSIS**

    gxadmin meta slurp-day <yyyy-mm-dd> [slurp-name [2nd-slurp-name [...]]]

**NOTES**

Obtain influx compatible metrics regarding the state of the
server on a specific date. UseGalaxy.EU uses this to display things
like charts of "how many users were registered as of date X". You can
backfill data from your server by running a for loop like:

    #!/bin/bash
    for i in range {1..365}; do
        gxadmin meta slurp-day $(date -d " days ago" "+%Y-%m-%d") | <get into influx somehow>
    done

It is expected that you are passing this straight to telegraf, there is
no non-influx output supported currently.

This calls all of the same functions as 'gxadmin meta slurp-current',
but with date filters for the entries' creation times.

You can add your own functions which are included in this output, using
the $GXADMIN_SITE_SPECIFIC file. They must start with the prefix
"server_", e.g. "server_mymetric". They should include a date filter as
well, or the metrics reported here will be less useful.

    $ gxadmin meta slurp-day 2019-01-01
    server-allocated-cpu.daily,job_runner_name=condor cpu_years=102.00
    server-datasets.daily,deleted=f,object_store_id=,state=error,purged=f count=37,size=29895528
    server-datasets.daily,deleted=f,object_store_id=,state=ok,purged=f count=72,size=76739510
    server-datasets.daily,deleted=f,object_store_id=,state=discarded,purged=f count=2,size=0
    server-hda.daily,deleted=t,extension=data max=2,sum=2,avg=2,min=2
    server-hda.daily,deleted=t,extension=txt max=5023,sum=5039,avg=2520,min=16
    server-hda.daily,deleted=f,extension=fastqsanger max=3,sum=3,avg=3,min=3
    server-hda.daily,deleted=f,extension=tabular max=3,sum=51,avg=3,min=3
    server-hda.daily,deleted=t,extension=tabular max=468549,sum=552788,avg=21261,min=2
    server-histories.daily,importable=f,deleted=f,genome_build=?,published=f,importing=f,purged=f count=5
    server-jobs.daily,state=error,destination_id=condor,job_runner_name=condor count=8
    server-jobs.daily,state=error,destination_id=condor_resub,job_runner_name=condor count=1
    server-jobs.daily,state=error,destination_id=condor_a,job_runner_name=condor count=11
    server-jobs.daily,state=ok,destination_id=condor,job_runner_name=condor count=2
    server-jobs.daily,state=ok,destination_id=condor_a,job_runner_name=condor count=23
    server-users.daily,active=t,deleted=f,external=f,purged=f count=1
    server-workflows.daily,deleted=f,importable=f,published=f count=1


## meta slurp-initial

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=meta_slurp-initial&type=Code))
meta slurp-initial -  Slurps data starting at the first date until the second date.

**SYNOPSIS**

    gxadmin meta slurp-initial <yyyy-mm-dd> <yyyy-mm-dd> [slurp-name [2nd-slurp-name [...]]]

**NOTES**

Obtains influx compatible metrics between dates and posts this to Influx.
This function calls 'gxadmin meta slurp-upto' and 'gxadmin meta slurp-day'.

It requires a start and end date. Allows to run specific slurp queries.


## meta slurp-upto

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=meta_slurp-upto&type=Code))
meta slurp-upto -  Slurps data up to a specific date.

**SYNOPSIS**

    gxadmin meta slurp-upto <yyyy-mm-dd> [slurp-name [2nd-slurp-name [...]]]

**NOTES**

Obtain influx compatible metrics regarding the summed state of the
server up to a specific date. UseGalaxy.EU uses this to display things
like charts of "how many users were registered as of date X".

This calls all of the same functions as 'gxadmin meta slurp-current',
but with date filters for the entries' creation times.


## meta update

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=meta_update&type=Code))
meta update -  Update the script

**SYNOPSIS**

    gxadmin meta update


## meta whatsnew

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=meta_whatsnew&type=Code))
meta whatsnew -  What's new in this version of gxadmin

**SYNOPSIS**

    gxadmin meta whatsnew

**NOTES**

Informs users of what's new in the changelog since their version

