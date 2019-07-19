# Galaxy Admin Utility [![Build Status](https://travis-ci.org/usegalaxy-eu/gxadmin.svg?branch=master)](https://travis-ci.org/usegalaxy-eu/gxadmin)

A command line tool for [Galaxy](https://github.com/galaxyproject/galaxy)
administrators to run common queries against our Postgres databases. It additionally
includes some code for managing zerglings under systemd, and other utilities.

Mostly gxadmin acts as a repository for the common queries we all run regularly
but fail to share with each other. We even include some [unlisted
queries](./parts/27-unlisted.sh) which may be useful as examples, but are not generically useful.

It comes with around 40 commonly useful queries included, but you can easily
add more to your installation with local functions. gxadmin attempts to be a
very readable bash script and avoids using fancy new bash features.

This script strictly expects a postgres database and has no plans to support
mysql or sqlite3.

## Installation

```
curl https://raw.githubusercontent.com/usegalaxy-eu/gxadmin/master/gxadmin > /usr/bin/gxadmin
chmod +x /usr/bin/gxadmin
```

## Contributing

Please make PRs to the `dev` branch. The master branch will only contain releases.

## Changelog

[Changelog](CHANGELOG.md)

## Contributors

- Helena Rasche ([@erasche](https://github.com/erasche))
- Nate Coraor ([@natefoo](https://github.com/natefoo))
- Simon Gladman ([@slugger70](https://github.com/slugger70))
- Anthony Bretaudeau ([@abretaud](https://github.com/abretaud))
- John Chilten ([@jmchilton](https://github.com/jmchilton))
- Manuel Messner (mm@skellet.io)

## License

GPLv3

## Configuration

`gxadmin` does not have much configuration, mostly env vars and functions will complain if you don't have them set properly.

### Postgres

Queries support being run in normal postgres table, csv, or tsv output as you
need. Just use `gxadmin query`, `gxadmin tsvquery`, or `gxadmin csvquery` as
appropriate.

You should have a `~/.pgpass` with the database connection information, and set
`PGDATABASE`, `PGHOST`, and `PGUSER` in your environment.

Example .pgpass:

```
<pg_host>:5432:*:<pg_user>:<pg_password>
```

### GDPR

You may want to set `GDPR_MODE=1`. Please determine your own legal responsibilities, the authors take no responsibility for anything you may have done wrong.

### Local Functions

If you want to add some site-specific functions, you can do this in `~/.config/gxadmin-local.sh` (location can be overridden by setting `$GXADMIN_SITE_SPECIFIC`)

You should write a bash script which looks like. **ALL functions must be prefixed with `local_`**

```bash
local_cats() { ## : Makes cat noises
	handle_help "$@" <<-EOF
		Here is some documentation on this function
	EOF

	echo "Meow"
}
```

This can then be called with `gxadmin` like:

```console
$ gxadmin local cats --help
gxadmin local functions usage:

    cats   Cute kitties

help / -h / --help : this message. Invoke '--help' on any subcommand for help specific to that subcommand
$ gxadmin local cats
Meow
$
```

If you prefix the function name with `query-`, e.g. `local_query-cats`, then it will be run as a database query. CSV/TSV/Influx queries are not currently supported.

## Commands

### config

Command | Description
------- | -----------
[`config dump`](docs/README.config.md#config-dump) | Dump Galaxy configuration as JSON
[`config validate`](docs/README.config.md#config-validate) | validate config files

### filter

Command | Description
------- | -----------
[`filter digest-color`](docs/README.filter.md#filter-digest-color) | Color an input stream based on the contents (e.g. hostname)
[`filter hexdecode`](docs/README.filter.md#filter-hexdecode) | Decodes any hex blobs from postgres outputs
[`filter identicon`](docs/README.filter.md#filter-identicon) | Convert an input data stream into an identicon (e.g. with hostname)
[`filter pg2md`](docs/README.filter.md#filter-pg2md) | Convert postgres table format outputs to something that can be pasted as markdown

### galaxy

Command | Description
------- | -----------
[`galaxy amqp-test`](docs/README.galaxy.md#galaxy-amqp-test) | Test a given AMQP URL for connectivity
[`galaxy cleanup`](docs/README.galaxy.md#galaxy-cleanup) | Cleanup histories/hdas/etc for past N days (default=30)
[`galaxy cleanup-jwd`](docs/README.galaxy.md#galaxy-cleanup-jwd) | (NEW) Cleanup job working directories
[`galaxy migrate-tool-install-from-sqlite`](docs/README.galaxy.md#galaxy-migrate-tool-install-from-sqlite) | Converts SQLite version into normal potsgres toolshed repository tables
[`galaxy migrate-tool-install-to-sqlite`](docs/README.galaxy.md#galaxy-migrate-tool-install-to-sqlite) | Converts normal potsgres toolshed repository tables into the SQLite version

### meta

Command | Description
------- | -----------
[`meta export-grafana-dashboards`](docs/README.meta.md#meta-export-grafana-dashboards) | Export all dashboards from a Grafana database to CWD and commit them to git.
[`meta influx-post`](docs/README.meta.md#meta-influx-post) | Post contents of file (in influx line protocol) to influx
[`meta influx-query`](docs/README.meta.md#meta-influx-query) | Query an influx DB
[`meta iquery-grt-export`](docs/README.meta.md#meta-iquery-grt-export) | Export data from a GRT database for sending to influx
[`meta slurp-current`](docs/README.meta.md#meta-slurp-current) | Executes what used to be "Galaxy Slurp"
[`meta slurp-day`](docs/README.meta.md#meta-slurp-day) | Slurps data on a specific date.
[`meta slurp-upto`](docs/README.meta.md#meta-slurp-upto) | Slurps data up to a specific date.
[`meta update`](docs/README.meta.md#meta-update) | Update the script
[`meta whatsnew`](docs/README.meta.md#meta-whatsnew) | What's new in this version of gxadmin

### mutate

Command | Description
------- | -----------
[`mutate approve-user`](docs/README.mutate.md#mutate-approve-user) | Approve a user in the database
[`mutate assign-unassigned-workflows`](docs/README.mutate.md#mutate-assign-unassigned-workflows) | Randomly assigns unassigned workflows to handlers. Workaround for galaxyproject/galaxy#8209
[`mutate delete-group-role`](docs/README.mutate.md#mutate-delete-group-role) | Remove the group, role, and any user-group + user-role associations
[`mutate fail-history`](docs/README.mutate.md#mutate-fail-history) | Mark all jobs within a history to state error
[`mutate fail-job`](docs/README.mutate.md#mutate-fail-job) | Sets a job state to error
[`mutate fail-terminal-datasets`](docs/README.mutate.md#mutate-fail-terminal-datasets) | Causes the output datasets of jobs which were manually failed, to be marked as failed
[`mutate oidc-role-find-affected`](docs/README.mutate.md#mutate-oidc-role-find-affected) | Find users affected by galaxyproject/galaxy#8244
[`mutate oidc-role-fix`](docs/README.mutate.md#mutate-oidc-role-fix) | Fix permissions for users logged in via OIDC. Workaround for galaxyproject/galaxy#8244

### query

Command | Description
------- | -----------
`query active-users` | Deprecated, use monthly-users-active
[`query collection-usage`](docs/README.query.md#query-collection-usage) | Information about how many collections of various types are used
[`query datasets-created-daily`](docs/README.query.md#query-datasets-created-daily) | The min/max/average/p95/p99 of total size of datasets created in a single day.
[`query disk-usage`](docs/README.query.md#query-disk-usage) | Disk usage per object store.
[`query errored-jobs`](docs/README.query.md#query-errored-jobs) | Lists jobs that errored in the last N hours.
[`query group-cpu-seconds`](docs/README.query.md#query-group-cpu-seconds) | Retrieve an approximation of the CPU time in seconds for group(s)
[`query groups-list`](docs/README.query.md#query-groups-list) | List all groups known to Galaxy
[`query hdca-datasets`](docs/README.query.md#query-hdca-datasets) | List of files in a dataset collection
[`query hdca-info`](docs/README.query.md#query-hdca-info) | Information on a dataset collection
[`query history-contents`](docs/README.query.md#query-history-contents) | List datasets and/or collections in a history
[`query history-runtime-system-by-tool`](docs/README.query.md#query-history-runtime-system-by-tool) | Sum of runtimes by all jobs in a history, split by tool
[`query history-runtime-system`](docs/README.query.md#query-history-runtime-system) | Sum of runtimes by all jobs in a history
[`query history-runtime-wallclock`](docs/README.query.md#query-history-runtime-wallclock) | Time as elapsed by a clock on the wall
[`query job-history`](docs/README.query.md#query-job-history) | Job state history for a specific job
[`query job-inputs`](docs/README.query.md#query-job-inputs) | Input datasets to a specific job
[`query job-outputs`](docs/README.query.md#query-job-outputs) | Output datasets from a specific job
[`query jobs-max-by-cpu-hours`](docs/README.query.md#query-jobs-max-by-cpu-hours) | Top 10 jobs by CPU hours consumed (requires CGroups metrics)
[`query jobs-nonterminal`](docs/README.query.md#query-jobs-nonterminal) | Job info of nonterminal jobs separated by user
[`query jobs-per-user`](docs/README.query.md#query-jobs-per-user) | Number of jobs run by a specific user
[`query jobs-queued`](docs/README.query.md#query-jobs-queued) | How many queued jobs have external cluster IDs
[`query jobs-queued-internal-by-handler`](docs/README.query.md#query-jobs-queued-internal-by-handler) | How many queued jobs do not have external IDs, by handler
[`query largest-collection`](docs/README.query.md#query-largest-collection) | Returns the size of the single largest collection
[`query largest-histories`](docs/README.query.md#query-largest-histories) | Largest histories in Galaxy
[`query latest-users`](docs/README.query.md#query-latest-users) | 40 recently registered users
[`query monthly-cpu-years`](docs/README.query.md#query-monthly-cpu-years) | CPU years allocated to tools by month
[`query monthly-data`](docs/README.query.md#query-monthly-data) | Number of active users per month, running jobs
[`query monthly-jobs`](docs/README.query.md#query-monthly-jobs) | Number of jobs run each month
[`query monthly-users-active`](docs/README.query.md#query-monthly-users-active) | Number of active users per month, running jobs
`query monthly-users` | Deprecated, use monthly-users-active
[`query monthly-users-registered`](docs/README.query.md#query-monthly-users-registered) | Number of users registered each month
[`query old-histories`](docs/README.query.md#query-old-histories) | Lists histories that haven't been updated (used) for <weeks>
[`query queue`](docs/README.query.md#query-queue) | Brief overview of currently running jobs
[`query queue-detail`](docs/README.query.md#query-queue-detail) | Detailed overview of running and queued jobs
[`query queue-overview`](docs/README.query.md#query-queue-overview) | View used mostly for monitoring
[`query queue-time`](docs/README.query.md#query-queue-time) | The average/95%/99% a specific tool spends in queue state.
[`query recent-jobs`](docs/README.query.md#query-recent-jobs) | Jobs run in the past <hours> (in any state)
[`query runtime-per-user`](docs/README.query.md#query-runtime-per-user) | computation time of user (by email)
[`query server-groups-allocated-cpu`](docs/README.query.md#query-server-groups-allocated-cpu) | Retrieve an approximation of the CPU allocation for groups
[`query server-groups-disk-usage`](docs/README.query.md#query-server-groups-disk-usage) | Retrieve an approximation of the disk usage for groups
[`query tool-available-metrics`](docs/README.query.md#query-tool-available-metrics) | list all available metrics for a given tool
[`query tool-errors`](docs/README.query.md#query-tool-errors) | Summarize percent of tool runs in error over the past weeks for all tools that have failed (most popular tools first)
[`query tool-last-used-date`](docs/README.query.md#query-tool-last-used-date) | When was the most recent invocation of every tool
[`query tool-likely-broken`](docs/README.query.md#query-tool-likely-broken) | Find tools that have been executed in recent weeks that are (or were due to job running) likely substantially broken
[`query tool-metrics`](docs/README.query.md#query-tool-metrics) | See values of a specific metric
[`query tool-new-errors`](docs/README.query.md#query-tool-new-errors) | Summarize percent of tool runs in error over the past weeks for "new tools"
[`query tool-popularity`](docs/README.query.md#query-tool-popularity) | Most run tools by month
[`query tool-usage`](docs/README.query.md#query-tool-usage) | Counts of tool runs in the past weeks (default = all)
[`query training-list`](docs/README.query.md#query-training-list) | List known trainings
[`query training-members-remove`](docs/README.query.md#query-training-members-remove) | Remove a user from a training
[`query training-members`](docs/README.query.md#query-training-members) | List users in a specific training
[`query training-queue`](docs/README.query.md#query-training-queue) | Jobs currently being run by people in a given training
[`query ts-repos`](docs/README.query.md#query-ts-repos) | Counts of toolshed repositories by toolshed and owner.
[`query upload-gb-in-past-hour`](docs/README.query.md#query-upload-gb-in-past-hour) | Sum in bytes of files uploaded in the past hour
[`query user-cpu-years`](docs/README.query.md#query-user-cpu-years) | CPU years allocated to tools by user
[`query user-disk-usage`](docs/README.query.md#query-user-disk-usage) | Retrieve an approximation of the disk usage for users
[`query user-disk-quota`](docs/README.query.md#query-user-disk-quota) | Retrieve the disk quota for users
[`query user-recent-aggregate-jobs`](docs/README.query.md#query-user-recent-aggregate-jobs) | Show aggregate information for jobs in past N days for user
[`query users-count`](docs/README.query.md#query-users-count) | Shows sums of active/external/deleted/purged accounts
[`query users-total`](docs/README.query.md#query-users-total) | Total number of Galaxy users (incl deleted, purged, inactive)
[`query users-with-oidc`](docs/README.query.md#query-users-with-oidc) | How many users logged in with OIDC
[`query workflow-connections`](docs/README.query.md#query-workflow-connections) | The connections of tools, from output to input, in the latest (or all) versions of user workflows
[`query workflow-invocation-status`](docs/README.query.md#query-workflow-invocation-status) | Report on how many workflows are in new state by handler

### report

Command | Description
------- | -----------
[`report assigned-to-handler`](docs/README.report.md#report-assigned-to-handler) | Report what items are assigned to a handler currently.
[`report job-info`](docs/README.report.md#report-job-info) | Information about a specific job
[`report user-info`](docs/README.report.md#report-user-info) | Quick overview of a Galaxy user in your system

### uwsgi

Command | Description
------- | -----------
[`uwsgi handler-restart`](docs/README.uwsgi.md#uwsgi-handler-restart) | Restart all handlers
[`uwsgi handler-strace`](docs/README.uwsgi.md#uwsgi-handler-strace) | Strace a handler
[`uwsgi lastlog`](docs/README.uwsgi.md#uwsgi-lastlog) | Fetch the number of seconds since the last log message was written
[`uwsgi memory`](docs/README.uwsgi.md#uwsgi-memory) | Current system memory usage
[`uwsgi pids`](docs/README.uwsgi.md#uwsgi-pids) | Galaxy process PIDs
[`uwsgi stats-influx`](docs/README.uwsgi.md#uwsgi-stats-influx) | InfluxDB formatted output for the current stats
`uwsgi stats_influx` | Deprecated, use uwsgi stats-influx
[`uwsgi stats`](docs/README.uwsgi.md#uwsgi-stats) | uwsgi stats
[`uwsgi status`](docs/README.uwsgi.md#uwsgi-status) | Current system status
[`uwsgi zerg-scale-up`](docs/README.uwsgi.md#uwsgi-zerg-scale-up) | Add another zergling to deal with high load
[`uwsgi zerg-strace`](docs/README.uwsgi.md#uwsgi-zerg-strace) | Strace a zergling
[`uwsgi zerg-swap`](docs/README.uwsgi.md#uwsgi-zerg-swap) | Swap zerglings in order (unintelligent version)

