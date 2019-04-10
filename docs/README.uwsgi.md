# uwsgi

Command | Description
------- | -----------
[`uwsgi handler-restart`](#report-user-info) | Restart all handlers
[`uwsgi handler-strace`](#report-user-info) | Strace a handler
[`uwsgi memory`](#report-user-info) | Current system memory usage
[`uwsgi pids`](#report-user-info) | Galaxy process PIDs
[`uwsgi stats_influx`](#report-user-info) | InfluxDB formatted output for the current stats
[`uwsgi stats`](#report-user-info) | uwsgi stats
[`uwsgi status`](#report-user-info) | Current system status
[`uwsgi zerg-scale-down`](#report-user-info) | Remove an extraneous zergling
[`uwsgi zerg-scale-up`](#report-user-info) | Add another zergling to deal with high load
[`uwsgi zerg-strace`](#report-user-info) | Strace a zergling
[`uwsgi zerg-swap`](#report-user-info) | Swap zerglings in order (unintelligent version)

### uwsgi handler-restart

**NAME**

uwsgi handler-restart -  Restart all handlers

**SYNOPSIS**

gxadmin uwsgi handler-restart


### uwsgi handler-strace

**NAME**

uwsgi handler-strace -  Strace a handler

**SYNOPSIS**

gxadmin uwsgi handler-strace [number]


### uwsgi memory

**NAME**

uwsgi memory -  Current system memory usage

**SYNOPSIS**

gxadmin uwsgi memory

**NOTES**

Obtain memory usage of the various Galaxy processes


### uwsgi pids

**NAME**

uwsgi pids -  Galaxy process PIDs

**SYNOPSIS**

gxadmin uwsgi pids

**NOTES**

Obtain memory usage of the various Galaxy processes


### uwsgi stats_influx

**NAME**

uwsgi stats_influx -  InfluxDB formatted output for the current stats

**SYNOPSIS**

gxadmin uwsgi stats_influx <addr>

**NOTES**

Contact a specific uWSGI stats address (requires uwsgi binary on path)
and requests the current stats + formats them for InfluxDB. For some
reason it has trouble with localhost vs IP address, so recommend that
you use IP.

    $ gxadmin uwsgi stats_influx 127.0.0.1:9191
    uwsgi.locks,addr=127.0.0.1:9191,group=user_0 count=0
    uwsgi.locks,addr=127.0.0.1:9191,group=signal count=0
    uwsgi.locks,addr=127.0.0.1:9191,group=filemon count=0
    uwsgi.locks,addr=127.0.0.1:9191,group=timer count=0
    uwsgi.locks,addr=127.0.0.1:9191,group=rbtimer count=0
    uwsgi.locks,addr=127.0.0.1:9191,group=cron count=0
    uwsgi.locks,addr=127.0.0.1:9191,group=thunder count=2006859
    uwsgi.locks,addr=127.0.0.1:9191,group=rpc count=0
    uwsgi.locks,addr=127.0.0.1:9191,group=snmp count=0
    uwsgi.general,addr=127.0.0.1:9191 listen_queue=0,listen_queue_errors=0,load=0,signal_queue=0
    uwsgi.sockets,addr=127.0.0.1:9191,name=127.0.0.1:4001,proto=uwsgi queue=0,max_queue=100,shared=0,can_offload=0
    uwsgi.worker,addr=127.0.0.1:9191,id=1 accepting=1,requests=65312,exceptions=526,harakiri_count=26,signals=0,signal_queue=0,status="idle",rss=0,vsz=0,running_time=17433008661,respawn_count=27,tx=15850829410,avg_rt=71724
    uwsgi.worker,addr=127.0.0.1:9191,id=2 accepting=1,requests=67495,exceptions=472,harakiri_count=51,signals=0,signal_queue=0,status="idle",rss=0,vsz=0,running_time=15467746010,respawn_count=52,tx=15830867066,avg_rt=65380
    uwsgi.worker,addr=127.0.0.1:9191,id=3 accepting=1,requests=67270,exceptions=520,harakiri_count=35,signals=0,signal_queue=0,status="idle",rss=0,vsz=0,running_time=14162158015,respawn_count=36,tx=15799661545,avg_rt=73366
    uwsgi.worker,addr=127.0.0.1:9191,id=4 accepting=1,requests=66434,exceptions=540,harakiri_count=34,signals=0,signal_queue=0,status="idle",rss=0,vsz=0,running_time=15740205807,respawn_count=35,tx=16231969649,avg_rt=75468
    uwsgi.worker,addr=127.0.0.1:9191,id=5 accepting=1,requests=67021,exceptions=534,harakiri_count=38,signals=0,signal_queue=0,status="idle",rss=0,vsz=0,running_time=14573155758,respawn_count=39,tx=16517287963,avg_rt=140855
    uwsgi.worker,addr=127.0.0.1:9191,id=6 accepting=1,requests=66810,exceptions=483,harakiri_count=24,signals=0,signal_queue=0,status="idle",rss=0,vsz=0,running_time=19107513635,respawn_count=25,tx=15945313469,avg_rt=64032
    uwsgi.worker,addr=127.0.0.1:9191,id=7 accepting=1,requests=66544,exceptions=460,harakiri_count=35,signals=0,signal_queue=0,status="idle",rss=0,vsz=0,running_time=14240478391,respawn_count=36,tx=15499531841,avg_rt=114981
    uwsgi.worker,addr=127.0.0.1:9191,id=8 accepting=1,requests=67577,exceptions=517,harakiri_count=35,signals=0,signal_queue=0,status="idle",rss=0,vsz=0,running_time=14767971195,respawn_count=36,tx=15780639229,avg_rt=201275

For multiple zerglings you can run this for each and just 2>/dev/null

    PATH=/opt/galaxy/venv/bin:/sbin:/bin:/usr/sbin:/usr/bin gxadmin uwsgi stats_influx 127.0.0.1:9190 2>/dev/null
    PATH=/opt/galaxy/venv/bin:/sbin:/bin:/usr/sbin:/usr/bin gxadmin uwsgi stats_influx 127.0.0.1:9191 2>/dev/null
    exit 0

And it will fetch only data for responding uwsgis.


### uwsgi stats


### uwsgi status

**NAME**

uwsgi status -  Current system status

**SYNOPSIS**

gxadmin uwsgi status

**NOTES**

Current status of all uwsgi processes


### uwsgi zerg-scale-down

**NAME**

uwsgi zerg-scale-down -  Remove an extraneous zergling

**SYNOPSIS**

gxadmin uwsgi zerg-scale-down


### uwsgi zerg-scale-up

**NAME**

uwsgi zerg-scale-up -  Add another zergling to deal with high load

**SYNOPSIS**

gxadmin uwsgi zerg-scale-up


### uwsgi zerg-strace

**NAME**

uwsgi zerg-strace -  Strace a zergling

**SYNOPSIS**

gxadmin uwsgi zerg-strace [number]


### uwsgi zerg-swap

**NAME**

uwsgi zerg-swap -  Swap zerglings in order (unintelligent version)

**SYNOPSIS**

gxadmin uwsgi zerg-swap

**NOTES**

This is the "dumb" version which loops across the zerglings and restarts them in series

