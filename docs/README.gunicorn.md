# gunicorn

Command | Description
------- | -----------
[`gunicorn active-users`](#gunicorn-active-users) | Shows active users in last 10 minutes
[`gunicorn lastlog`](#gunicorn-lastlog) | Fetch the number of seconds since the last log message was written

## gunicorn active-users

([*source*](https://github.com/galaxyproject/gxadmin/search?q=gunicorn_active-users&type=Code))
gunicorn active-users -  Shows active users in last 10 minutes

**SYNOPSIS**

    gxadmin gunicorn active-users

**NOTES**

See unique sorts IP adresses from 'GET /history/current_history_json' from last 10 minutes and prints it in influx line format


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

