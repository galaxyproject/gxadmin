# uwsgi

Command | Description
------- | -----------
[`uwsgi active-users`](#uwsgi-active-users) | Count active users
[`uwsgi handler-restart`](#uwsgi-handler-restart) | Restart all handlers
[`uwsgi handler-strace`](#uwsgi-handler-strace) | Strace a handler
[`uwsgi lastlog`](#uwsgi-lastlog) | Fetch the number of seconds since the last log message was written
[`uwsgi memory`](#uwsgi-memory) | Current system memory usage
[`uwsgi pids`](#uwsgi-pids) | Galaxy process PIDs
[`uwsgi stats-influx`](#uwsgi-stats-influx) | InfluxDB formatted output for the current stats
[`uwsgi stats`](#uwsgi-stats) | uwsgi stats
[`uwsgi status`](#uwsgi-status) | Current system status
[`uwsgi zerg-scale-up`](#uwsgi-zerg-scale-up) | Add another zergling to deal with high load
[`uwsgi zerg-strace`](#uwsgi-zerg-strace) | Strace a zergling
[`uwsgi zerg-swap`](#uwsgi-zerg-swap) | Swap zerglings in order (unintelligent version)

## uwsgi active-users

([*source*](https://github.com/galaxyproject/gxadmin/search?q=uwsgi_active-users&type=Code))
uwsgi active-users -  Count active users

**SYNOPSIS**

    gxadmin uwsgi active-users

**NOTES**

Count active users and return an influx compatible measurement


## uwsgi handler-restart

([*source*](https://github.com/galaxyproject/gxadmin/search?q=uwsgi_handler-restart&type=Code))
uwsgi handler-restart -  Restart all handlers

**SYNOPSIS**

    gxadmin uwsgi handler-restart


## uwsgi handler-strace

([*source*](https://github.com/galaxyproject/gxadmin/search?q=uwsgi_handler-strace&type=Code))
uwsgi handler-strace -  Strace a handler

**SYNOPSIS**

    gxadmin uwsgi handler-strace [number]


## uwsgi lastlog

([*source*](https://github.com/galaxyproject/gxadmin/search?q=uwsgi_lastlog&type=Code))
uwsgi lastlog -  Fetch the number of seconds since the last log message was written

**SYNOPSIS**

    gxadmin uwsgi lastlog

**NOTES**

Lets you know if any of your workers or handlers have maybe stopped processing jobs.

    $ gxadmin uwsgi lastlog
    journalctl.lastlog,service=galaxy-handler@0 seconds=8
    journalctl.lastlog,service=galaxy-handler@1 seconds=2
    journalctl.lastlog,service=galaxy-handler@2 seconds=186
    journalctl.lastlog,service=galaxy-handler@3 seconds=19
    journalctl.lastlog,service=galaxy-handler@4 seconds=6
    journalctl.lastlog,service=galaxy-handler@5 seconds=80
    journalctl.lastlog,service=galaxy-handler@6 seconds=52
    journalctl.lastlog,service=galaxy-handler@7 seconds=1
    journalctl.lastlog,service=galaxy-handler@8 seconds=79
    journalctl.lastlog,service=galaxy-handler@9 seconds=40
    journalctl.lastlog,service=galaxy-handler@10 seconds=123
    journalctl.lastlog,service=galaxy-handler@11 seconds=13
    journalctl.lastlog,service=galaxy-zergling@0 seconds=0
    journalctl.lastlog,service=galaxy-zergling@1 seconds=0
    journalctl.lastlog,service=galaxy-zergling@2 seconds=2866


## uwsgi memory

([*source*](https://github.com/galaxyproject/gxadmin/search?q=uwsgi_memory&type=Code))
uwsgi memory -  Current system memory usage

**SYNOPSIS**

    gxadmin uwsgi memory

**NOTES**

Obtain memory usage of the various Galaxy processes

Also consider using systemd-cgtop


## uwsgi pids

([*source*](https://github.com/galaxyproject/gxadmin/search?q=uwsgi_pids&type=Code))
uwsgi pids -  Galaxy process PIDs

**SYNOPSIS**

    gxadmin uwsgi pids

**NOTES**

Obtain memory usage of the various Galaxy processes


## uwsgi stats-influx

([*source*](https://github.com/galaxyproject/gxadmin/search?q=uwsgi_stats-influx&type=Code))
uwsgi stats-influx -  InfluxDB formatted output for the current stats

**SYNOPSIS**

    gxadmin uwsgi stats-influx <addr>

**NOTES**

Contact a specific uWSGI stats address (requires uwsgi binary on path)
and requests the current stats + formats them for InfluxDB. For some
reason it has trouble with localhost vs IP address, so recommend that
you use IP.

    $ gxadmin uwsgi stats-influx 127.0.0.1:9191
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

    PATH=/opt/galaxy/venv/bin:/sbin:/bin:/usr/sbin:/usr/bin gxadmin uwsgi stats-influx 127.0.0.1:9190 2>/dev/null
    PATH=/opt/galaxy/venv/bin:/sbin:/bin:/usr/sbin:/usr/bin gxadmin uwsgi stats-influx 127.0.0.1:9191 2>/dev/null
    exit 0

And it will fetch only data for responding uwsgis.


## uwsgi stats

([*source*](https://github.com/galaxyproject/gxadmin/search?q=uwsgi_stats&type=Code))
uwsgi stats -  uwsgi stats

**SYNOPSIS**

    gxadmin uwsgi stats


## uwsgi status

([*source*](https://github.com/galaxyproject/gxadmin/search?q=uwsgi_status&type=Code))
uwsgi status -  Current system status

**SYNOPSIS**

    gxadmin uwsgi status

**NOTES**

Current status of all uwsgi processes


## uwsgi zerg-scale-up

([*source*](https://github.com/galaxyproject/gxadmin/search?q=uwsgi_zerg-scale-up&type=Code))
uwsgi zerg-scale-up -  Add another zergling to deal with high load

**SYNOPSIS**

    gxadmin uwsgi zerg-scale-up


## uwsgi zerg-strace

([*source*](https://github.com/galaxyproject/gxadmin/search?q=uwsgi_zerg-strace&type=Code))
uwsgi zerg-strace -  Strace a zergling

**SYNOPSIS**

    gxadmin uwsgi zerg-strace [number]


## uwsgi zerg-swap

([*source*](https://github.com/galaxyproject/gxadmin/search?q=uwsgi_zerg-swap&type=Code))
uwsgi zerg-swap -  Swap zerglings in order (unintelligent version)

**SYNOPSIS**

    gxadmin uwsgi zerg-swap

**NOTES**

This is the "dumb" version which loops across the zerglings and restarts them in series

