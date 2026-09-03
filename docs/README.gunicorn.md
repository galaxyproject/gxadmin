# gunicorn

Command | Description
------- | -----------
[`gunicorn active-users`](#gunicorn-active-users) | Shows active users in last 10 minutes
[`gunicorn handler-restart`](#gunicorn-handler-restart) | Restart gunicorn handlers in two batches to avoid downtime
[`gunicorn lastlog`](#gunicorn-lastlog) | Fetch the number of seconds since the last log message was written

## gunicorn active-users

([*source*](https://github.com/galaxyproject/gxadmin/search?q=gunicorn_active-users&type=Code))
gunicorn active-users -  Shows active users in last 10 minutes

**SYNOPSIS**

    gxadmin gunicorn active-users

**NOTES**

See unique sorts IP adresses from 'GET /history/current_history_json' from last 10 minutes and prints it in influx line format


## gunicorn handler-restart

([*source*](https://github.com/galaxyproject/gxadmin/search?q=gunicorn_handler-restart&type=Code))
gunicorn handler-restart -  Restart gunicorn handlers in two batches to avoid downtime

**SYNOPSIS**

    gxadmin gunicorn handler-restart

**NOTES**

Restarts all running `galaxy-gunicorn@*.service` systemd units in two
roughly-equal batches, so that half of the workers remain available
while the other half restarts.

The function:

  - enumerates running `galaxy-gunicorn` units
  - splits them into two batches
  - waits until the first batch is serving HTTP 200s on `GET`
  - restarts the second batch and waits for it to come back online
  - then restarts the first batch

If fewer than two gunicorn handlers are running it refuses to run, since
rolling restarts are not possible without downtime.

**WARNING**

!> This operates on systemd services on the current host and restarts
!> production gunicorn workers. Run it during a maintenance window or
!> when low traffic is expected.

    $ gxadmin gunicorn handler-restart
    Found handlers: galaxy-gunicorn@0.service galaxy-gunicorn@1.service  and galaxy-gunicorn@2.service galaxy-gunicorn@3.service


## gunicorn lastlog

([*source*](https://github.com/galaxyproject/gxadmin/search?q=gunicorn_lastlog&type=Code))
gunicorn lastlog -  Fetch the number of seconds since the last log message was written

**SYNOPSIS**

    gxadmin gunicorn lastlog

**NOTES**

Lets you know if any of your workers or handlers have maybe stopped processing jobs.

$ gxadmin gunicorn lastlog
journalctl.lastlog,service=galaxy-gunicorn@0 seconds=0
journalctl.lastlog,service=galaxy-gunicorn@1 seconds=0
journalctl.lastlog,service=galaxy-gunicorn@2 seconds=2866

