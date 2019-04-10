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

## Changelog

[Changelog](CHANGELOG.md)

## Contributors

- Helena Rasche ([@erasche](https://github.com/erasche))
- Nate Coraor ([@natefoo](https://github.com/natefoo))
- Simon Gladman ([@slugger70](https://github.com/slugger70))
- Anthony Bretaudeau ([@abretaud](https://github.com/abretaud))
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
local_cats() { ## cats: Makes cat noises
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

meta_cmdlist
## Commands

Command | Description
------- | -----------
[`config dump`](README.config.md#config-dump) | Dump Galaxy configuration as JSON
[`config validate`](README.config.md#config-validate) | validate config files
[`filter digest-color`](README.config.md#filter-digest-color) | Color an input stream based on the contents (e.g. hostname)
[`filter hexdecode`](README.config.md#filter-hexdecode) | Decodes any hex blobs from postgres outputs
[`filter identicon`](README.config.md#filter-identicon) | Convert an input data stream into an identicon (e.g. with hostname)
[`filter pg2md`](README.config.md#filter-pg2md) | Convert postgres table format outputs to something that can be pasted as markdown
[`galaxy cleanup`](README.config.md#galaxy-cleanup) | Cleanup histories/hdas/etc for past N days (default=30)
[`galaxy migrate-tool-install-to-sqlite`](README.config.md#galaxy-migrate-tool-install-to-sqlite) | Converts normal potsgres toolshed repository tables into the SQLite version
[`meta slurp-current`](README.config.md#meta-slurp-current) | Executes what used to be "Galaxy Slurp"
[`meta update`](README.config.md#meta-update) | Update the script
[`mutate fail-terminal-datasets`](README.config.md#mutate-fail-terminal-datasets) | Causes the output datasets of jobs which were manually failed, to be marked as failed
`query active-users` | Deprecated, use monthly-users-active
[`query collection-usage`](README.config.md#query-collection-usage) | Information about how many collections of various types are used
[`query datasets-created-daily`](README.config.md#query-datasets-created-daily) | The min/max/average/p95/p99 of total size of datasets created in a single day.
[`query disk-usage`](README.config.md#query-disk-usage) | Disk usage per object store.
[`query errored-jobs`](README.config.md#query-errored-jobs) | Lists jobs that errored in the last N hours.
[`query groups-list`](README.config.md#query-groups-list) | List all groups known to Galaxy
[`query job-history`](README.config.md#query-job-history) | Job state history for a specific job
[`query job-inputs`](README.config.md#query-job-inputs) | Input datasets to a specific job
[`query job-outputs`](README.config.md#query-job-outputs) | Output datasets from a specific job
[`query jobs-max-by-cpu-hours`](README.config.md#query-jobs-max-by-cpu-hours) | Top 10 jobs by CPU hours consumed (requires CGroups metrics)
[`query jobs-nonterminal`](README.config.md#query-jobs-nonterminal) | Job info of nonterminal jobs separated by user
[`query jobs-per-user`](README.config.md#query-jobs-per-user) | Number of jobs run by a specific user
[`query largest-collection`](README.config.md#query-largest-collection) | Returns the size of the single largest collection
[`query largest-histories`](README.config.md#query-largest-histories) | Largest histories in Galaxy
[`query latest-users`](README.config.md#query-latest-users) | 40 recently registered users
[`query monthly-cpu-years`](README.config.md#query-monthly-cpu-years) | CPU years allocated to tools by month
[`query monthly-data`](README.config.md#query-monthly-data) | Number of active users per month, running jobs
[`query monthly-jobs`](README.config.md#query-monthly-jobs) | Number of jobs run each month
[`query monthly-users-active`](README.config.md#query-monthly-users-active) | Number of active users per month, running jobs
`query monthly-users` | Deprecated, use monthly-users-active
[`query monthly-users-registered`](README.config.md#query-monthly-users-registered) | Number of users registered each month
[`query old-histories`](README.config.md#query-old-histories) | Lists histories that haven't been updated (used) for <weeks>
[`query queue`](README.config.md#query-queue) | Brief overview of currently running jobs
[`query queue-detail`](README.config.md#query-queue-detail) | Detailed overview of running and queued jobs
[`query queue-overview`](README.config.md#query-queue-overview) | View used mostly for monitoring
[`query queue-time`](README.config.md#query-queue-time) | The average/95%/99% a specific tool spends in queue state.
[`query recent-jobs`](README.config.md#query-recent-jobs) | Jobs run in the past <hours> (in any state)
[`query runtime-per-user`](README.config.md#query-runtime-per-user) | computation time of user (by email)
[`query server-datasets`](README.config.md#query-server-datasets) | query server-datasets
[`query server-disk-usage`](README.config.md#query-server-disk-usage) | query server-disk-usage
[`query server-groups`](README.config.md#query-server-groups) | query server-groups
[`query server-hda`](README.config.md#query-server-hda) | query server-hda [date]
[`query server-histories`](README.config.md#query-server-histories) | query server-histories [date]
[`query server-jobs-cumulative`](README.config.md#query-server-jobs-cumulative) | query server-jobs-cumulative [date]
[`query server-jobs`](README.config.md#query-server-jobs) | query server-jobs [date]
[`query server-ts-repos`](README.config.md#query-server-ts-repos) | query server-ts-repos
[`query server-users-cumulative`](README.config.md#query-server-users-cumulative) | query server-users-cumulative [date]
[`query server-users`](README.config.md#query-server-users) | query server-users [date]
[`query server-workflow-invocations`](README.config.md#query-server-workflow-invocations) | query server-workflow-invocations [yyyy-mm-dd]
[`query server-workflows`](README.config.md#query-server-workflows) | query server-workflows [date]
[`query tool-available-metrics`](README.config.md#query-tool-available-metrics) | list all available metrics for a given tool
[`query tool-last-used-date`](README.config.md#query-tool-last-used-date) | When was the most recent invocation of every tool
[`query tool-metrics`](README.config.md#query-tool-metrics) | See values of a specific metric
[`query tool-popularity`](README.config.md#query-tool-popularity) | Most run tools by month
[`query tool-usage`](README.config.md#query-tool-usage) | Counts of tool runs in the past weeks (default = all)
[`query training-list`](README.config.md#query-training-list) | List known trainings
[`query training-members-remove`](README.config.md#query-training-members-remove) | Remove a user from a training
[`query training-members`](README.config.md#query-training-members) | List users in a specific training
[`query training-queue`](README.config.md#query-training-queue) | Jobs currently being run by people in a given training
[`query ts-repos`](README.config.md#query-ts-repos) | Counts of toolshed repositories by toolshed and owner.
[`query users-count`](README.config.md#query-users-count) | Shows sums of active/external/deleted/purged accounts
[`query users-total`](README.config.md#query-users-total) | Total number of Galaxy users (incl deleted, purged, inactive)
[`query workflow-connections`](README.config.md#query-workflow-connections) | The connections of tools, from output to input, in the latest (or all) versions of user workflows
[`report job-info`](README.config.md#report-job-info) | Information about a specific job
[`report user-info`](README.config.md#report-user-info) | Quick overview of a Galaxy user in your system
[`uwsgi handler-restart`](README.config.md#uwsgi-handler-restart) | Restart all handlers
[`uwsgi handler-strace`](README.config.md#uwsgi-handler-strace) | Strace a handler
[`uwsgi memory`](README.config.md#uwsgi-memory) | Current system memory usage
[`uwsgi pids`](README.config.md#uwsgi-pids) | Galaxy process PIDs
[`uwsgi stats_influx`](README.config.md#uwsgi-stats_influx) | InfluxDB formatted output for the current stats
[`uwsgi stats`](README.config.md#uwsgi-stats) | uwsgi stats
[`uwsgi status`](README.config.md#uwsgi-status) | Current system status
[`uwsgi zerg-scale-down`](README.config.md#uwsgi-zerg-scale-down) | Remove an extraneous zergling
[`uwsgi zerg-scale-up`](README.config.md#uwsgi-zerg-scale-up) | Add another zergling to deal with high load
[`uwsgi zerg-strace`](README.config.md#uwsgi-zerg-strace) | Strace a zergling
[`uwsgi zerg-swap`](README.config.md#uwsgi-zerg-swap) | Swap zerglings in order (unintelligent version)
[`config dump`](README.filter.md#config-dump) | Dump Galaxy configuration as JSON
[`config validate`](README.filter.md#config-validate) | validate config files
[`filter digest-color`](README.filter.md#filter-digest-color) | Color an input stream based on the contents (e.g. hostname)
[`filter hexdecode`](README.filter.md#filter-hexdecode) | Decodes any hex blobs from postgres outputs
[`filter identicon`](README.filter.md#filter-identicon) | Convert an input data stream into an identicon (e.g. with hostname)
[`filter pg2md`](README.filter.md#filter-pg2md) | Convert postgres table format outputs to something that can be pasted as markdown
[`galaxy cleanup`](README.filter.md#galaxy-cleanup) | Cleanup histories/hdas/etc for past N days (default=30)
[`galaxy migrate-tool-install-to-sqlite`](README.filter.md#galaxy-migrate-tool-install-to-sqlite) | Converts normal potsgres toolshed repository tables into the SQLite version
[`meta slurp-current`](README.filter.md#meta-slurp-current) | Executes what used to be "Galaxy Slurp"
[`meta update`](README.filter.md#meta-update) | Update the script
[`mutate fail-terminal-datasets`](README.filter.md#mutate-fail-terminal-datasets) | Causes the output datasets of jobs which were manually failed, to be marked as failed
`query active-users` | Deprecated, use monthly-users-active
[`query collection-usage`](README.filter.md#query-collection-usage) | Information about how many collections of various types are used
[`query datasets-created-daily`](README.filter.md#query-datasets-created-daily) | The min/max/average/p95/p99 of total size of datasets created in a single day.
[`query disk-usage`](README.filter.md#query-disk-usage) | Disk usage per object store.
[`query errored-jobs`](README.filter.md#query-errored-jobs) | Lists jobs that errored in the last N hours.
[`query groups-list`](README.filter.md#query-groups-list) | List all groups known to Galaxy
[`query job-history`](README.filter.md#query-job-history) | Job state history for a specific job
[`query job-inputs`](README.filter.md#query-job-inputs) | Input datasets to a specific job
[`query job-outputs`](README.filter.md#query-job-outputs) | Output datasets from a specific job
[`query jobs-max-by-cpu-hours`](README.filter.md#query-jobs-max-by-cpu-hours) | Top 10 jobs by CPU hours consumed (requires CGroups metrics)
[`query jobs-nonterminal`](README.filter.md#query-jobs-nonterminal) | Job info of nonterminal jobs separated by user
[`query jobs-per-user`](README.filter.md#query-jobs-per-user) | Number of jobs run by a specific user
[`query largest-collection`](README.filter.md#query-largest-collection) | Returns the size of the single largest collection
[`query largest-histories`](README.filter.md#query-largest-histories) | Largest histories in Galaxy
[`query latest-users`](README.filter.md#query-latest-users) | 40 recently registered users
[`query monthly-cpu-years`](README.filter.md#query-monthly-cpu-years) | CPU years allocated to tools by month
[`query monthly-data`](README.filter.md#query-monthly-data) | Number of active users per month, running jobs
[`query monthly-jobs`](README.filter.md#query-monthly-jobs) | Number of jobs run each month
[`query monthly-users-active`](README.filter.md#query-monthly-users-active) | Number of active users per month, running jobs
`query monthly-users` | Deprecated, use monthly-users-active
[`query monthly-users-registered`](README.filter.md#query-monthly-users-registered) | Number of users registered each month
[`query old-histories`](README.filter.md#query-old-histories) | Lists histories that haven't been updated (used) for <weeks>
[`query queue`](README.filter.md#query-queue) | Brief overview of currently running jobs
[`query queue-detail`](README.filter.md#query-queue-detail) | Detailed overview of running and queued jobs
[`query queue-overview`](README.filter.md#query-queue-overview) | View used mostly for monitoring
[`query queue-time`](README.filter.md#query-queue-time) | The average/95%/99% a specific tool spends in queue state.
[`query recent-jobs`](README.filter.md#query-recent-jobs) | Jobs run in the past <hours> (in any state)
[`query runtime-per-user`](README.filter.md#query-runtime-per-user) | computation time of user (by email)
[`query server-datasets`](README.filter.md#query-server-datasets) | query server-datasets
[`query server-disk-usage`](README.filter.md#query-server-disk-usage) | query server-disk-usage
[`query server-groups`](README.filter.md#query-server-groups) | query server-groups
[`query server-hda`](README.filter.md#query-server-hda) | query server-hda [date]
[`query server-histories`](README.filter.md#query-server-histories) | query server-histories [date]
[`query server-jobs-cumulative`](README.filter.md#query-server-jobs-cumulative) | query server-jobs-cumulative [date]
[`query server-jobs`](README.filter.md#query-server-jobs) | query server-jobs [date]
[`query server-ts-repos`](README.filter.md#query-server-ts-repos) | query server-ts-repos
[`query server-users-cumulative`](README.filter.md#query-server-users-cumulative) | query server-users-cumulative [date]
[`query server-users`](README.filter.md#query-server-users) | query server-users [date]
[`query server-workflow-invocations`](README.filter.md#query-server-workflow-invocations) | query server-workflow-invocations [yyyy-mm-dd]
[`query server-workflows`](README.filter.md#query-server-workflows) | query server-workflows [date]
[`query tool-available-metrics`](README.filter.md#query-tool-available-metrics) | list all available metrics for a given tool
[`query tool-last-used-date`](README.filter.md#query-tool-last-used-date) | When was the most recent invocation of every tool
[`query tool-metrics`](README.filter.md#query-tool-metrics) | See values of a specific metric
[`query tool-popularity`](README.filter.md#query-tool-popularity) | Most run tools by month
[`query tool-usage`](README.filter.md#query-tool-usage) | Counts of tool runs in the past weeks (default = all)
[`query training-list`](README.filter.md#query-training-list) | List known trainings
[`query training-members-remove`](README.filter.md#query-training-members-remove) | Remove a user from a training
[`query training-members`](README.filter.md#query-training-members) | List users in a specific training
[`query training-queue`](README.filter.md#query-training-queue) | Jobs currently being run by people in a given training
[`query ts-repos`](README.filter.md#query-ts-repos) | Counts of toolshed repositories by toolshed and owner.
[`query users-count`](README.filter.md#query-users-count) | Shows sums of active/external/deleted/purged accounts
[`query users-total`](README.filter.md#query-users-total) | Total number of Galaxy users (incl deleted, purged, inactive)
[`query workflow-connections`](README.filter.md#query-workflow-connections) | The connections of tools, from output to input, in the latest (or all) versions of user workflows
[`report job-info`](README.filter.md#report-job-info) | Information about a specific job
[`report user-info`](README.filter.md#report-user-info) | Quick overview of a Galaxy user in your system
[`uwsgi handler-restart`](README.filter.md#uwsgi-handler-restart) | Restart all handlers
[`uwsgi handler-strace`](README.filter.md#uwsgi-handler-strace) | Strace a handler
[`uwsgi memory`](README.filter.md#uwsgi-memory) | Current system memory usage
[`uwsgi pids`](README.filter.md#uwsgi-pids) | Galaxy process PIDs
[`uwsgi stats_influx`](README.filter.md#uwsgi-stats_influx) | InfluxDB formatted output for the current stats
[`uwsgi stats`](README.filter.md#uwsgi-stats) | uwsgi stats
[`uwsgi status`](README.filter.md#uwsgi-status) | Current system status
[`uwsgi zerg-scale-down`](README.filter.md#uwsgi-zerg-scale-down) | Remove an extraneous zergling
[`uwsgi zerg-scale-up`](README.filter.md#uwsgi-zerg-scale-up) | Add another zergling to deal with high load
[`uwsgi zerg-strace`](README.filter.md#uwsgi-zerg-strace) | Strace a zergling
[`uwsgi zerg-swap`](README.filter.md#uwsgi-zerg-swap) | Swap zerglings in order (unintelligent version)
[`config dump`](README.galaxy.md#config-dump) | Dump Galaxy configuration as JSON
[`config validate`](README.galaxy.md#config-validate) | validate config files
[`filter digest-color`](README.galaxy.md#filter-digest-color) | Color an input stream based on the contents (e.g. hostname)
[`filter hexdecode`](README.galaxy.md#filter-hexdecode) | Decodes any hex blobs from postgres outputs
[`filter identicon`](README.galaxy.md#filter-identicon) | Convert an input data stream into an identicon (e.g. with hostname)
[`filter pg2md`](README.galaxy.md#filter-pg2md) | Convert postgres table format outputs to something that can be pasted as markdown
[`galaxy cleanup`](README.galaxy.md#galaxy-cleanup) | Cleanup histories/hdas/etc for past N days (default=30)
[`galaxy migrate-tool-install-to-sqlite`](README.galaxy.md#galaxy-migrate-tool-install-to-sqlite) | Converts normal potsgres toolshed repository tables into the SQLite version
[`meta slurp-current`](README.galaxy.md#meta-slurp-current) | Executes what used to be "Galaxy Slurp"
[`meta update`](README.galaxy.md#meta-update) | Update the script
[`mutate fail-terminal-datasets`](README.galaxy.md#mutate-fail-terminal-datasets) | Causes the output datasets of jobs which were manually failed, to be marked as failed
`query active-users` | Deprecated, use monthly-users-active
[`query collection-usage`](README.galaxy.md#query-collection-usage) | Information about how many collections of various types are used
[`query datasets-created-daily`](README.galaxy.md#query-datasets-created-daily) | The min/max/average/p95/p99 of total size of datasets created in a single day.
[`query disk-usage`](README.galaxy.md#query-disk-usage) | Disk usage per object store.
[`query errored-jobs`](README.galaxy.md#query-errored-jobs) | Lists jobs that errored in the last N hours.
[`query groups-list`](README.galaxy.md#query-groups-list) | List all groups known to Galaxy
[`query job-history`](README.galaxy.md#query-job-history) | Job state history for a specific job
[`query job-inputs`](README.galaxy.md#query-job-inputs) | Input datasets to a specific job
[`query job-outputs`](README.galaxy.md#query-job-outputs) | Output datasets from a specific job
[`query jobs-max-by-cpu-hours`](README.galaxy.md#query-jobs-max-by-cpu-hours) | Top 10 jobs by CPU hours consumed (requires CGroups metrics)
[`query jobs-nonterminal`](README.galaxy.md#query-jobs-nonterminal) | Job info of nonterminal jobs separated by user
[`query jobs-per-user`](README.galaxy.md#query-jobs-per-user) | Number of jobs run by a specific user
[`query largest-collection`](README.galaxy.md#query-largest-collection) | Returns the size of the single largest collection
[`query largest-histories`](README.galaxy.md#query-largest-histories) | Largest histories in Galaxy
[`query latest-users`](README.galaxy.md#query-latest-users) | 40 recently registered users
[`query monthly-cpu-years`](README.galaxy.md#query-monthly-cpu-years) | CPU years allocated to tools by month
[`query monthly-data`](README.galaxy.md#query-monthly-data) | Number of active users per month, running jobs
[`query monthly-jobs`](README.galaxy.md#query-monthly-jobs) | Number of jobs run each month
[`query monthly-users-active`](README.galaxy.md#query-monthly-users-active) | Number of active users per month, running jobs
`query monthly-users` | Deprecated, use monthly-users-active
[`query monthly-users-registered`](README.galaxy.md#query-monthly-users-registered) | Number of users registered each month
[`query old-histories`](README.galaxy.md#query-old-histories) | Lists histories that haven't been updated (used) for <weeks>
[`query queue`](README.galaxy.md#query-queue) | Brief overview of currently running jobs
[`query queue-detail`](README.galaxy.md#query-queue-detail) | Detailed overview of running and queued jobs
[`query queue-overview`](README.galaxy.md#query-queue-overview) | View used mostly for monitoring
[`query queue-time`](README.galaxy.md#query-queue-time) | The average/95%/99% a specific tool spends in queue state.
[`query recent-jobs`](README.galaxy.md#query-recent-jobs) | Jobs run in the past <hours> (in any state)
[`query runtime-per-user`](README.galaxy.md#query-runtime-per-user) | computation time of user (by email)
[`query server-datasets`](README.galaxy.md#query-server-datasets) | query server-datasets
[`query server-disk-usage`](README.galaxy.md#query-server-disk-usage) | query server-disk-usage
[`query server-groups`](README.galaxy.md#query-server-groups) | query server-groups
[`query server-hda`](README.galaxy.md#query-server-hda) | query server-hda [date]
[`query server-histories`](README.galaxy.md#query-server-histories) | query server-histories [date]
[`query server-jobs-cumulative`](README.galaxy.md#query-server-jobs-cumulative) | query server-jobs-cumulative [date]
[`query server-jobs`](README.galaxy.md#query-server-jobs) | query server-jobs [date]
[`query server-ts-repos`](README.galaxy.md#query-server-ts-repos) | query server-ts-repos
[`query server-users-cumulative`](README.galaxy.md#query-server-users-cumulative) | query server-users-cumulative [date]
[`query server-users`](README.galaxy.md#query-server-users) | query server-users [date]
[`query server-workflow-invocations`](README.galaxy.md#query-server-workflow-invocations) | query server-workflow-invocations [yyyy-mm-dd]
[`query server-workflows`](README.galaxy.md#query-server-workflows) | query server-workflows [date]
[`query tool-available-metrics`](README.galaxy.md#query-tool-available-metrics) | list all available metrics for a given tool
[`query tool-last-used-date`](README.galaxy.md#query-tool-last-used-date) | When was the most recent invocation of every tool
[`query tool-metrics`](README.galaxy.md#query-tool-metrics) | See values of a specific metric
[`query tool-popularity`](README.galaxy.md#query-tool-popularity) | Most run tools by month
[`query tool-usage`](README.galaxy.md#query-tool-usage) | Counts of tool runs in the past weeks (default = all)
[`query training-list`](README.galaxy.md#query-training-list) | List known trainings
[`query training-members-remove`](README.galaxy.md#query-training-members-remove) | Remove a user from a training
[`query training-members`](README.galaxy.md#query-training-members) | List users in a specific training
[`query training-queue`](README.galaxy.md#query-training-queue) | Jobs currently being run by people in a given training
[`query ts-repos`](README.galaxy.md#query-ts-repos) | Counts of toolshed repositories by toolshed and owner.
[`query users-count`](README.galaxy.md#query-users-count) | Shows sums of active/external/deleted/purged accounts
[`query users-total`](README.galaxy.md#query-users-total) | Total number of Galaxy users (incl deleted, purged, inactive)
[`query workflow-connections`](README.galaxy.md#query-workflow-connections) | The connections of tools, from output to input, in the latest (or all) versions of user workflows
[`report job-info`](README.galaxy.md#report-job-info) | Information about a specific job
[`report user-info`](README.galaxy.md#report-user-info) | Quick overview of a Galaxy user in your system
[`uwsgi handler-restart`](README.galaxy.md#uwsgi-handler-restart) | Restart all handlers
[`uwsgi handler-strace`](README.galaxy.md#uwsgi-handler-strace) | Strace a handler
[`uwsgi memory`](README.galaxy.md#uwsgi-memory) | Current system memory usage
[`uwsgi pids`](README.galaxy.md#uwsgi-pids) | Galaxy process PIDs
[`uwsgi stats_influx`](README.galaxy.md#uwsgi-stats_influx) | InfluxDB formatted output for the current stats
[`uwsgi stats`](README.galaxy.md#uwsgi-stats) | uwsgi stats
[`uwsgi status`](README.galaxy.md#uwsgi-status) | Current system status
[`uwsgi zerg-scale-down`](README.galaxy.md#uwsgi-zerg-scale-down) | Remove an extraneous zergling
[`uwsgi zerg-scale-up`](README.galaxy.md#uwsgi-zerg-scale-up) | Add another zergling to deal with high load
[`uwsgi zerg-strace`](README.galaxy.md#uwsgi-zerg-strace) | Strace a zergling
[`uwsgi zerg-swap`](README.galaxy.md#uwsgi-zerg-swap) | Swap zerglings in order (unintelligent version)
[`config dump`](README.meta.md#config-dump) | Dump Galaxy configuration as JSON
[`config validate`](README.meta.md#config-validate) | validate config files
[`filter digest-color`](README.meta.md#filter-digest-color) | Color an input stream based on the contents (e.g. hostname)
[`filter hexdecode`](README.meta.md#filter-hexdecode) | Decodes any hex blobs from postgres outputs
[`filter identicon`](README.meta.md#filter-identicon) | Convert an input data stream into an identicon (e.g. with hostname)
[`filter pg2md`](README.meta.md#filter-pg2md) | Convert postgres table format outputs to something that can be pasted as markdown
[`galaxy cleanup`](README.meta.md#galaxy-cleanup) | Cleanup histories/hdas/etc for past N days (default=30)
[`galaxy migrate-tool-install-to-sqlite`](README.meta.md#galaxy-migrate-tool-install-to-sqlite) | Converts normal potsgres toolshed repository tables into the SQLite version
[`meta slurp-current`](README.meta.md#meta-slurp-current) | Executes what used to be "Galaxy Slurp"
[`meta update`](README.meta.md#meta-update) | Update the script
[`mutate fail-terminal-datasets`](README.meta.md#mutate-fail-terminal-datasets) | Causes the output datasets of jobs which were manually failed, to be marked as failed
`query active-users` | Deprecated, use monthly-users-active
[`query collection-usage`](README.meta.md#query-collection-usage) | Information about how many collections of various types are used
[`query datasets-created-daily`](README.meta.md#query-datasets-created-daily) | The min/max/average/p95/p99 of total size of datasets created in a single day.
[`query disk-usage`](README.meta.md#query-disk-usage) | Disk usage per object store.
[`query errored-jobs`](README.meta.md#query-errored-jobs) | Lists jobs that errored in the last N hours.
[`query groups-list`](README.meta.md#query-groups-list) | List all groups known to Galaxy
[`query job-history`](README.meta.md#query-job-history) | Job state history for a specific job
[`query job-inputs`](README.meta.md#query-job-inputs) | Input datasets to a specific job
[`query job-outputs`](README.meta.md#query-job-outputs) | Output datasets from a specific job
[`query jobs-max-by-cpu-hours`](README.meta.md#query-jobs-max-by-cpu-hours) | Top 10 jobs by CPU hours consumed (requires CGroups metrics)
[`query jobs-nonterminal`](README.meta.md#query-jobs-nonterminal) | Job info of nonterminal jobs separated by user
[`query jobs-per-user`](README.meta.md#query-jobs-per-user) | Number of jobs run by a specific user
[`query largest-collection`](README.meta.md#query-largest-collection) | Returns the size of the single largest collection
[`query largest-histories`](README.meta.md#query-largest-histories) | Largest histories in Galaxy
[`query latest-users`](README.meta.md#query-latest-users) | 40 recently registered users
[`query monthly-cpu-years`](README.meta.md#query-monthly-cpu-years) | CPU years allocated to tools by month
[`query monthly-data`](README.meta.md#query-monthly-data) | Number of active users per month, running jobs
[`query monthly-jobs`](README.meta.md#query-monthly-jobs) | Number of jobs run each month
[`query monthly-users-active`](README.meta.md#query-monthly-users-active) | Number of active users per month, running jobs
`query monthly-users` | Deprecated, use monthly-users-active
[`query monthly-users-registered`](README.meta.md#query-monthly-users-registered) | Number of users registered each month
[`query old-histories`](README.meta.md#query-old-histories) | Lists histories that haven't been updated (used) for <weeks>
[`query queue`](README.meta.md#query-queue) | Brief overview of currently running jobs
[`query queue-detail`](README.meta.md#query-queue-detail) | Detailed overview of running and queued jobs
[`query queue-overview`](README.meta.md#query-queue-overview) | View used mostly for monitoring
[`query queue-time`](README.meta.md#query-queue-time) | The average/95%/99% a specific tool spends in queue state.
[`query recent-jobs`](README.meta.md#query-recent-jobs) | Jobs run in the past <hours> (in any state)
[`query runtime-per-user`](README.meta.md#query-runtime-per-user) | computation time of user (by email)
[`query server-datasets`](README.meta.md#query-server-datasets) | query server-datasets
[`query server-disk-usage`](README.meta.md#query-server-disk-usage) | query server-disk-usage
[`query server-groups`](README.meta.md#query-server-groups) | query server-groups
[`query server-hda`](README.meta.md#query-server-hda) | query server-hda [date]
[`query server-histories`](README.meta.md#query-server-histories) | query server-histories [date]
[`query server-jobs-cumulative`](README.meta.md#query-server-jobs-cumulative) | query server-jobs-cumulative [date]
[`query server-jobs`](README.meta.md#query-server-jobs) | query server-jobs [date]
[`query server-ts-repos`](README.meta.md#query-server-ts-repos) | query server-ts-repos
[`query server-users-cumulative`](README.meta.md#query-server-users-cumulative) | query server-users-cumulative [date]
[`query server-users`](README.meta.md#query-server-users) | query server-users [date]
[`query server-workflow-invocations`](README.meta.md#query-server-workflow-invocations) | query server-workflow-invocations [yyyy-mm-dd]
[`query server-workflows`](README.meta.md#query-server-workflows) | query server-workflows [date]
[`query tool-available-metrics`](README.meta.md#query-tool-available-metrics) | list all available metrics for a given tool
[`query tool-last-used-date`](README.meta.md#query-tool-last-used-date) | When was the most recent invocation of every tool
[`query tool-metrics`](README.meta.md#query-tool-metrics) | See values of a specific metric
[`query tool-popularity`](README.meta.md#query-tool-popularity) | Most run tools by month
[`query tool-usage`](README.meta.md#query-tool-usage) | Counts of tool runs in the past weeks (default = all)
[`query training-list`](README.meta.md#query-training-list) | List known trainings
[`query training-members-remove`](README.meta.md#query-training-members-remove) | Remove a user from a training
[`query training-members`](README.meta.md#query-training-members) | List users in a specific training
[`query training-queue`](README.meta.md#query-training-queue) | Jobs currently being run by people in a given training
[`query ts-repos`](README.meta.md#query-ts-repos) | Counts of toolshed repositories by toolshed and owner.
[`query users-count`](README.meta.md#query-users-count) | Shows sums of active/external/deleted/purged accounts
[`query users-total`](README.meta.md#query-users-total) | Total number of Galaxy users (incl deleted, purged, inactive)
[`query workflow-connections`](README.meta.md#query-workflow-connections) | The connections of tools, from output to input, in the latest (or all) versions of user workflows
[`report job-info`](README.meta.md#report-job-info) | Information about a specific job
[`report user-info`](README.meta.md#report-user-info) | Quick overview of a Galaxy user in your system
[`uwsgi handler-restart`](README.meta.md#uwsgi-handler-restart) | Restart all handlers
[`uwsgi handler-strace`](README.meta.md#uwsgi-handler-strace) | Strace a handler
[`uwsgi memory`](README.meta.md#uwsgi-memory) | Current system memory usage
[`uwsgi pids`](README.meta.md#uwsgi-pids) | Galaxy process PIDs
[`uwsgi stats_influx`](README.meta.md#uwsgi-stats_influx) | InfluxDB formatted output for the current stats
[`uwsgi stats`](README.meta.md#uwsgi-stats) | uwsgi stats
[`uwsgi status`](README.meta.md#uwsgi-status) | Current system status
[`uwsgi zerg-scale-down`](README.meta.md#uwsgi-zerg-scale-down) | Remove an extraneous zergling
[`uwsgi zerg-scale-up`](README.meta.md#uwsgi-zerg-scale-up) | Add another zergling to deal with high load
[`uwsgi zerg-strace`](README.meta.md#uwsgi-zerg-strace) | Strace a zergling
[`uwsgi zerg-swap`](README.meta.md#uwsgi-zerg-swap) | Swap zerglings in order (unintelligent version)
[`config dump`](README.mutate.md#config-dump) | Dump Galaxy configuration as JSON
[`config validate`](README.mutate.md#config-validate) | validate config files
[`filter digest-color`](README.mutate.md#filter-digest-color) | Color an input stream based on the contents (e.g. hostname)
[`filter hexdecode`](README.mutate.md#filter-hexdecode) | Decodes any hex blobs from postgres outputs
[`filter identicon`](README.mutate.md#filter-identicon) | Convert an input data stream into an identicon (e.g. with hostname)
[`filter pg2md`](README.mutate.md#filter-pg2md) | Convert postgres table format outputs to something that can be pasted as markdown
[`galaxy cleanup`](README.mutate.md#galaxy-cleanup) | Cleanup histories/hdas/etc for past N days (default=30)
[`galaxy migrate-tool-install-to-sqlite`](README.mutate.md#galaxy-migrate-tool-install-to-sqlite) | Converts normal potsgres toolshed repository tables into the SQLite version
[`meta slurp-current`](README.mutate.md#meta-slurp-current) | Executes what used to be "Galaxy Slurp"
[`meta update`](README.mutate.md#meta-update) | Update the script
[`mutate fail-terminal-datasets`](README.mutate.md#mutate-fail-terminal-datasets) | Causes the output datasets of jobs which were manually failed, to be marked as failed
`query active-users` | Deprecated, use monthly-users-active
[`query collection-usage`](README.mutate.md#query-collection-usage) | Information about how many collections of various types are used
[`query datasets-created-daily`](README.mutate.md#query-datasets-created-daily) | The min/max/average/p95/p99 of total size of datasets created in a single day.
[`query disk-usage`](README.mutate.md#query-disk-usage) | Disk usage per object store.
[`query errored-jobs`](README.mutate.md#query-errored-jobs) | Lists jobs that errored in the last N hours.
[`query groups-list`](README.mutate.md#query-groups-list) | List all groups known to Galaxy
[`query job-history`](README.mutate.md#query-job-history) | Job state history for a specific job
[`query job-inputs`](README.mutate.md#query-job-inputs) | Input datasets to a specific job
[`query job-outputs`](README.mutate.md#query-job-outputs) | Output datasets from a specific job
[`query jobs-max-by-cpu-hours`](README.mutate.md#query-jobs-max-by-cpu-hours) | Top 10 jobs by CPU hours consumed (requires CGroups metrics)
[`query jobs-nonterminal`](README.mutate.md#query-jobs-nonterminal) | Job info of nonterminal jobs separated by user
[`query jobs-per-user`](README.mutate.md#query-jobs-per-user) | Number of jobs run by a specific user
[`query largest-collection`](README.mutate.md#query-largest-collection) | Returns the size of the single largest collection
[`query largest-histories`](README.mutate.md#query-largest-histories) | Largest histories in Galaxy
[`query latest-users`](README.mutate.md#query-latest-users) | 40 recently registered users
[`query monthly-cpu-years`](README.mutate.md#query-monthly-cpu-years) | CPU years allocated to tools by month
[`query monthly-data`](README.mutate.md#query-monthly-data) | Number of active users per month, running jobs
[`query monthly-jobs`](README.mutate.md#query-monthly-jobs) | Number of jobs run each month
[`query monthly-users-active`](README.mutate.md#query-monthly-users-active) | Number of active users per month, running jobs
`query monthly-users` | Deprecated, use monthly-users-active
[`query monthly-users-registered`](README.mutate.md#query-monthly-users-registered) | Number of users registered each month
[`query old-histories`](README.mutate.md#query-old-histories) | Lists histories that haven't been updated (used) for <weeks>
[`query queue`](README.mutate.md#query-queue) | Brief overview of currently running jobs
[`query queue-detail`](README.mutate.md#query-queue-detail) | Detailed overview of running and queued jobs
[`query queue-overview`](README.mutate.md#query-queue-overview) | View used mostly for monitoring
[`query queue-time`](README.mutate.md#query-queue-time) | The average/95%/99% a specific tool spends in queue state.
[`query recent-jobs`](README.mutate.md#query-recent-jobs) | Jobs run in the past <hours> (in any state)
[`query runtime-per-user`](README.mutate.md#query-runtime-per-user) | computation time of user (by email)
[`query server-datasets`](README.mutate.md#query-server-datasets) | query server-datasets
[`query server-disk-usage`](README.mutate.md#query-server-disk-usage) | query server-disk-usage
[`query server-groups`](README.mutate.md#query-server-groups) | query server-groups
[`query server-hda`](README.mutate.md#query-server-hda) | query server-hda [date]
[`query server-histories`](README.mutate.md#query-server-histories) | query server-histories [date]
[`query server-jobs-cumulative`](README.mutate.md#query-server-jobs-cumulative) | query server-jobs-cumulative [date]
[`query server-jobs`](README.mutate.md#query-server-jobs) | query server-jobs [date]
[`query server-ts-repos`](README.mutate.md#query-server-ts-repos) | query server-ts-repos
[`query server-users-cumulative`](README.mutate.md#query-server-users-cumulative) | query server-users-cumulative [date]
[`query server-users`](README.mutate.md#query-server-users) | query server-users [date]
[`query server-workflow-invocations`](README.mutate.md#query-server-workflow-invocations) | query server-workflow-invocations [yyyy-mm-dd]
[`query server-workflows`](README.mutate.md#query-server-workflows) | query server-workflows [date]
[`query tool-available-metrics`](README.mutate.md#query-tool-available-metrics) | list all available metrics for a given tool
[`query tool-last-used-date`](README.mutate.md#query-tool-last-used-date) | When was the most recent invocation of every tool
[`query tool-metrics`](README.mutate.md#query-tool-metrics) | See values of a specific metric
[`query tool-popularity`](README.mutate.md#query-tool-popularity) | Most run tools by month
[`query tool-usage`](README.mutate.md#query-tool-usage) | Counts of tool runs in the past weeks (default = all)
[`query training-list`](README.mutate.md#query-training-list) | List known trainings
[`query training-members-remove`](README.mutate.md#query-training-members-remove) | Remove a user from a training
[`query training-members`](README.mutate.md#query-training-members) | List users in a specific training
[`query training-queue`](README.mutate.md#query-training-queue) | Jobs currently being run by people in a given training
[`query ts-repos`](README.mutate.md#query-ts-repos) | Counts of toolshed repositories by toolshed and owner.
[`query users-count`](README.mutate.md#query-users-count) | Shows sums of active/external/deleted/purged accounts
[`query users-total`](README.mutate.md#query-users-total) | Total number of Galaxy users (incl deleted, purged, inactive)
[`query workflow-connections`](README.mutate.md#query-workflow-connections) | The connections of tools, from output to input, in the latest (or all) versions of user workflows
[`report job-info`](README.mutate.md#report-job-info) | Information about a specific job
[`report user-info`](README.mutate.md#report-user-info) | Quick overview of a Galaxy user in your system
[`uwsgi handler-restart`](README.mutate.md#uwsgi-handler-restart) | Restart all handlers
[`uwsgi handler-strace`](README.mutate.md#uwsgi-handler-strace) | Strace a handler
[`uwsgi memory`](README.mutate.md#uwsgi-memory) | Current system memory usage
[`uwsgi pids`](README.mutate.md#uwsgi-pids) | Galaxy process PIDs
[`uwsgi stats_influx`](README.mutate.md#uwsgi-stats_influx) | InfluxDB formatted output for the current stats
[`uwsgi stats`](README.mutate.md#uwsgi-stats) | uwsgi stats
[`uwsgi status`](README.mutate.md#uwsgi-status) | Current system status
[`uwsgi zerg-scale-down`](README.mutate.md#uwsgi-zerg-scale-down) | Remove an extraneous zergling
[`uwsgi zerg-scale-up`](README.mutate.md#uwsgi-zerg-scale-up) | Add another zergling to deal with high load
[`uwsgi zerg-strace`](README.mutate.md#uwsgi-zerg-strace) | Strace a zergling
[`uwsgi zerg-swap`](README.mutate.md#uwsgi-zerg-swap) | Swap zerglings in order (unintelligent version)
[`config dump`](README.query.md#config-dump) | Dump Galaxy configuration as JSON
[`config validate`](README.query.md#config-validate) | validate config files
[`filter digest-color`](README.query.md#filter-digest-color) | Color an input stream based on the contents (e.g. hostname)
[`filter hexdecode`](README.query.md#filter-hexdecode) | Decodes any hex blobs from postgres outputs
[`filter identicon`](README.query.md#filter-identicon) | Convert an input data stream into an identicon (e.g. with hostname)
[`filter pg2md`](README.query.md#filter-pg2md) | Convert postgres table format outputs to something that can be pasted as markdown
[`galaxy cleanup`](README.query.md#galaxy-cleanup) | Cleanup histories/hdas/etc for past N days (default=30)
[`galaxy migrate-tool-install-to-sqlite`](README.query.md#galaxy-migrate-tool-install-to-sqlite) | Converts normal potsgres toolshed repository tables into the SQLite version
[`meta slurp-current`](README.query.md#meta-slurp-current) | Executes what used to be "Galaxy Slurp"
[`meta update`](README.query.md#meta-update) | Update the script
[`mutate fail-terminal-datasets`](README.query.md#mutate-fail-terminal-datasets) | Causes the output datasets of jobs which were manually failed, to be marked as failed
`query active-users` | Deprecated, use monthly-users-active
[`query collection-usage`](README.query.md#query-collection-usage) | Information about how many collections of various types are used
[`query datasets-created-daily`](README.query.md#query-datasets-created-daily) | The min/max/average/p95/p99 of total size of datasets created in a single day.
[`query disk-usage`](README.query.md#query-disk-usage) | Disk usage per object store.
[`query errored-jobs`](README.query.md#query-errored-jobs) | Lists jobs that errored in the last N hours.
[`query groups-list`](README.query.md#query-groups-list) | List all groups known to Galaxy
[`query job-history`](README.query.md#query-job-history) | Job state history for a specific job
[`query job-inputs`](README.query.md#query-job-inputs) | Input datasets to a specific job
[`query job-outputs`](README.query.md#query-job-outputs) | Output datasets from a specific job
[`query jobs-max-by-cpu-hours`](README.query.md#query-jobs-max-by-cpu-hours) | Top 10 jobs by CPU hours consumed (requires CGroups metrics)
[`query jobs-nonterminal`](README.query.md#query-jobs-nonterminal) | Job info of nonterminal jobs separated by user
[`query jobs-per-user`](README.query.md#query-jobs-per-user) | Number of jobs run by a specific user
[`query largest-collection`](README.query.md#query-largest-collection) | Returns the size of the single largest collection
[`query largest-histories`](README.query.md#query-largest-histories) | Largest histories in Galaxy
[`query latest-users`](README.query.md#query-latest-users) | 40 recently registered users
[`query monthly-cpu-years`](README.query.md#query-monthly-cpu-years) | CPU years allocated to tools by month
[`query monthly-data`](README.query.md#query-monthly-data) | Number of active users per month, running jobs
[`query monthly-jobs`](README.query.md#query-monthly-jobs) | Number of jobs run each month
[`query monthly-users-active`](README.query.md#query-monthly-users-active) | Number of active users per month, running jobs
`query monthly-users` | Deprecated, use monthly-users-active
[`query monthly-users-registered`](README.query.md#query-monthly-users-registered) | Number of users registered each month
[`query old-histories`](README.query.md#query-old-histories) | Lists histories that haven't been updated (used) for <weeks>
[`query queue`](README.query.md#query-queue) | Brief overview of currently running jobs
[`query queue-detail`](README.query.md#query-queue-detail) | Detailed overview of running and queued jobs
[`query queue-overview`](README.query.md#query-queue-overview) | View used mostly for monitoring
[`query queue-time`](README.query.md#query-queue-time) | The average/95%/99% a specific tool spends in queue state.
[`query recent-jobs`](README.query.md#query-recent-jobs) | Jobs run in the past <hours> (in any state)
[`query runtime-per-user`](README.query.md#query-runtime-per-user) | computation time of user (by email)
[`query server-datasets`](README.query.md#query-server-datasets) | query server-datasets
[`query server-disk-usage`](README.query.md#query-server-disk-usage) | query server-disk-usage
[`query server-groups`](README.query.md#query-server-groups) | query server-groups
[`query server-hda`](README.query.md#query-server-hda) | query server-hda [date]
[`query server-histories`](README.query.md#query-server-histories) | query server-histories [date]
[`query server-jobs-cumulative`](README.query.md#query-server-jobs-cumulative) | query server-jobs-cumulative [date]
[`query server-jobs`](README.query.md#query-server-jobs) | query server-jobs [date]
[`query server-ts-repos`](README.query.md#query-server-ts-repos) | query server-ts-repos
[`query server-users-cumulative`](README.query.md#query-server-users-cumulative) | query server-users-cumulative [date]
[`query server-users`](README.query.md#query-server-users) | query server-users [date]
[`query server-workflow-invocations`](README.query.md#query-server-workflow-invocations) | query server-workflow-invocations [yyyy-mm-dd]
[`query server-workflows`](README.query.md#query-server-workflows) | query server-workflows [date]
[`query tool-available-metrics`](README.query.md#query-tool-available-metrics) | list all available metrics for a given tool
[`query tool-last-used-date`](README.query.md#query-tool-last-used-date) | When was the most recent invocation of every tool
[`query tool-metrics`](README.query.md#query-tool-metrics) | See values of a specific metric
[`query tool-popularity`](README.query.md#query-tool-popularity) | Most run tools by month
[`query tool-usage`](README.query.md#query-tool-usage) | Counts of tool runs in the past weeks (default = all)
[`query training-list`](README.query.md#query-training-list) | List known trainings
[`query training-members-remove`](README.query.md#query-training-members-remove) | Remove a user from a training
[`query training-members`](README.query.md#query-training-members) | List users in a specific training
[`query training-queue`](README.query.md#query-training-queue) | Jobs currently being run by people in a given training
[`query ts-repos`](README.query.md#query-ts-repos) | Counts of toolshed repositories by toolshed and owner.
[`query users-count`](README.query.md#query-users-count) | Shows sums of active/external/deleted/purged accounts
[`query users-total`](README.query.md#query-users-total) | Total number of Galaxy users (incl deleted, purged, inactive)
[`query workflow-connections`](README.query.md#query-workflow-connections) | The connections of tools, from output to input, in the latest (or all) versions of user workflows
[`report job-info`](README.query.md#report-job-info) | Information about a specific job
[`report user-info`](README.query.md#report-user-info) | Quick overview of a Galaxy user in your system
[`uwsgi handler-restart`](README.query.md#uwsgi-handler-restart) | Restart all handlers
[`uwsgi handler-strace`](README.query.md#uwsgi-handler-strace) | Strace a handler
[`uwsgi memory`](README.query.md#uwsgi-memory) | Current system memory usage
[`uwsgi pids`](README.query.md#uwsgi-pids) | Galaxy process PIDs
[`uwsgi stats_influx`](README.query.md#uwsgi-stats_influx) | InfluxDB formatted output for the current stats
[`uwsgi stats`](README.query.md#uwsgi-stats) | uwsgi stats
[`uwsgi status`](README.query.md#uwsgi-status) | Current system status
[`uwsgi zerg-scale-down`](README.query.md#uwsgi-zerg-scale-down) | Remove an extraneous zergling
[`uwsgi zerg-scale-up`](README.query.md#uwsgi-zerg-scale-up) | Add another zergling to deal with high load
[`uwsgi zerg-strace`](README.query.md#uwsgi-zerg-strace) | Strace a zergling
[`uwsgi zerg-swap`](README.query.md#uwsgi-zerg-swap) | Swap zerglings in order (unintelligent version)
[`config dump`](README.report.md#config-dump) | Dump Galaxy configuration as JSON
[`config validate`](README.report.md#config-validate) | validate config files
[`filter digest-color`](README.report.md#filter-digest-color) | Color an input stream based on the contents (e.g. hostname)
[`filter hexdecode`](README.report.md#filter-hexdecode) | Decodes any hex blobs from postgres outputs
[`filter identicon`](README.report.md#filter-identicon) | Convert an input data stream into an identicon (e.g. with hostname)
[`filter pg2md`](README.report.md#filter-pg2md) | Convert postgres table format outputs to something that can be pasted as markdown
[`galaxy cleanup`](README.report.md#galaxy-cleanup) | Cleanup histories/hdas/etc for past N days (default=30)
[`galaxy migrate-tool-install-to-sqlite`](README.report.md#galaxy-migrate-tool-install-to-sqlite) | Converts normal potsgres toolshed repository tables into the SQLite version
[`meta slurp-current`](README.report.md#meta-slurp-current) | Executes what used to be "Galaxy Slurp"
[`meta update`](README.report.md#meta-update) | Update the script
[`mutate fail-terminal-datasets`](README.report.md#mutate-fail-terminal-datasets) | Causes the output datasets of jobs which were manually failed, to be marked as failed
`query active-users` | Deprecated, use monthly-users-active
[`query collection-usage`](README.report.md#query-collection-usage) | Information about how many collections of various types are used
[`query datasets-created-daily`](README.report.md#query-datasets-created-daily) | The min/max/average/p95/p99 of total size of datasets created in a single day.
[`query disk-usage`](README.report.md#query-disk-usage) | Disk usage per object store.
[`query errored-jobs`](README.report.md#query-errored-jobs) | Lists jobs that errored in the last N hours.
[`query groups-list`](README.report.md#query-groups-list) | List all groups known to Galaxy
[`query job-history`](README.report.md#query-job-history) | Job state history for a specific job
[`query job-inputs`](README.report.md#query-job-inputs) | Input datasets to a specific job
[`query job-outputs`](README.report.md#query-job-outputs) | Output datasets from a specific job
[`query jobs-max-by-cpu-hours`](README.report.md#query-jobs-max-by-cpu-hours) | Top 10 jobs by CPU hours consumed (requires CGroups metrics)
[`query jobs-nonterminal`](README.report.md#query-jobs-nonterminal) | Job info of nonterminal jobs separated by user
[`query jobs-per-user`](README.report.md#query-jobs-per-user) | Number of jobs run by a specific user
[`query largest-collection`](README.report.md#query-largest-collection) | Returns the size of the single largest collection
[`query largest-histories`](README.report.md#query-largest-histories) | Largest histories in Galaxy
[`query latest-users`](README.report.md#query-latest-users) | 40 recently registered users
[`query monthly-cpu-years`](README.report.md#query-monthly-cpu-years) | CPU years allocated to tools by month
[`query monthly-data`](README.report.md#query-monthly-data) | Number of active users per month, running jobs
[`query monthly-jobs`](README.report.md#query-monthly-jobs) | Number of jobs run each month
[`query monthly-users-active`](README.report.md#query-monthly-users-active) | Number of active users per month, running jobs
`query monthly-users` | Deprecated, use monthly-users-active
[`query monthly-users-registered`](README.report.md#query-monthly-users-registered) | Number of users registered each month
[`query old-histories`](README.report.md#query-old-histories) | Lists histories that haven't been updated (used) for <weeks>
[`query queue`](README.report.md#query-queue) | Brief overview of currently running jobs
[`query queue-detail`](README.report.md#query-queue-detail) | Detailed overview of running and queued jobs
[`query queue-overview`](README.report.md#query-queue-overview) | View used mostly for monitoring
[`query queue-time`](README.report.md#query-queue-time) | The average/95%/99% a specific tool spends in queue state.
[`query recent-jobs`](README.report.md#query-recent-jobs) | Jobs run in the past <hours> (in any state)
[`query runtime-per-user`](README.report.md#query-runtime-per-user) | computation time of user (by email)
[`query server-datasets`](README.report.md#query-server-datasets) | query server-datasets
[`query server-disk-usage`](README.report.md#query-server-disk-usage) | query server-disk-usage
[`query server-groups`](README.report.md#query-server-groups) | query server-groups
[`query server-hda`](README.report.md#query-server-hda) | query server-hda [date]
[`query server-histories`](README.report.md#query-server-histories) | query server-histories [date]
[`query server-jobs-cumulative`](README.report.md#query-server-jobs-cumulative) | query server-jobs-cumulative [date]
[`query server-jobs`](README.report.md#query-server-jobs) | query server-jobs [date]
[`query server-ts-repos`](README.report.md#query-server-ts-repos) | query server-ts-repos
[`query server-users-cumulative`](README.report.md#query-server-users-cumulative) | query server-users-cumulative [date]
[`query server-users`](README.report.md#query-server-users) | query server-users [date]
[`query server-workflow-invocations`](README.report.md#query-server-workflow-invocations) | query server-workflow-invocations [yyyy-mm-dd]
[`query server-workflows`](README.report.md#query-server-workflows) | query server-workflows [date]
[`query tool-available-metrics`](README.report.md#query-tool-available-metrics) | list all available metrics for a given tool
[`query tool-last-used-date`](README.report.md#query-tool-last-used-date) | When was the most recent invocation of every tool
[`query tool-metrics`](README.report.md#query-tool-metrics) | See values of a specific metric
[`query tool-popularity`](README.report.md#query-tool-popularity) | Most run tools by month
[`query tool-usage`](README.report.md#query-tool-usage) | Counts of tool runs in the past weeks (default = all)
[`query training-list`](README.report.md#query-training-list) | List known trainings
[`query training-members-remove`](README.report.md#query-training-members-remove) | Remove a user from a training
[`query training-members`](README.report.md#query-training-members) | List users in a specific training
[`query training-queue`](README.report.md#query-training-queue) | Jobs currently being run by people in a given training
[`query ts-repos`](README.report.md#query-ts-repos) | Counts of toolshed repositories by toolshed and owner.
[`query users-count`](README.report.md#query-users-count) | Shows sums of active/external/deleted/purged accounts
[`query users-total`](README.report.md#query-users-total) | Total number of Galaxy users (incl deleted, purged, inactive)
[`query workflow-connections`](README.report.md#query-workflow-connections) | The connections of tools, from output to input, in the latest (or all) versions of user workflows
[`report job-info`](README.report.md#report-job-info) | Information about a specific job
[`report user-info`](README.report.md#report-user-info) | Quick overview of a Galaxy user in your system
[`uwsgi handler-restart`](README.report.md#uwsgi-handler-restart) | Restart all handlers
[`uwsgi handler-strace`](README.report.md#uwsgi-handler-strace) | Strace a handler
[`uwsgi memory`](README.report.md#uwsgi-memory) | Current system memory usage
[`uwsgi pids`](README.report.md#uwsgi-pids) | Galaxy process PIDs
[`uwsgi stats_influx`](README.report.md#uwsgi-stats_influx) | InfluxDB formatted output for the current stats
[`uwsgi stats`](README.report.md#uwsgi-stats) | uwsgi stats
[`uwsgi status`](README.report.md#uwsgi-status) | Current system status
[`uwsgi zerg-scale-down`](README.report.md#uwsgi-zerg-scale-down) | Remove an extraneous zergling
[`uwsgi zerg-scale-up`](README.report.md#uwsgi-zerg-scale-up) | Add another zergling to deal with high load
[`uwsgi zerg-strace`](README.report.md#uwsgi-zerg-strace) | Strace a zergling
[`uwsgi zerg-swap`](README.report.md#uwsgi-zerg-swap) | Swap zerglings in order (unintelligent version)
[`config dump`](README.uwsgi.md#config-dump) | Dump Galaxy configuration as JSON
[`config validate`](README.uwsgi.md#config-validate) | validate config files
[`filter digest-color`](README.uwsgi.md#filter-digest-color) | Color an input stream based on the contents (e.g. hostname)
[`filter hexdecode`](README.uwsgi.md#filter-hexdecode) | Decodes any hex blobs from postgres outputs
[`filter identicon`](README.uwsgi.md#filter-identicon) | Convert an input data stream into an identicon (e.g. with hostname)
[`filter pg2md`](README.uwsgi.md#filter-pg2md) | Convert postgres table format outputs to something that can be pasted as markdown
[`galaxy cleanup`](README.uwsgi.md#galaxy-cleanup) | Cleanup histories/hdas/etc for past N days (default=30)
[`galaxy migrate-tool-install-to-sqlite`](README.uwsgi.md#galaxy-migrate-tool-install-to-sqlite) | Converts normal potsgres toolshed repository tables into the SQLite version
[`meta slurp-current`](README.uwsgi.md#meta-slurp-current) | Executes what used to be "Galaxy Slurp"
[`meta update`](README.uwsgi.md#meta-update) | Update the script
[`mutate fail-terminal-datasets`](README.uwsgi.md#mutate-fail-terminal-datasets) | Causes the output datasets of jobs which were manually failed, to be marked as failed
`query active-users` | Deprecated, use monthly-users-active
[`query collection-usage`](README.uwsgi.md#query-collection-usage) | Information about how many collections of various types are used
[`query datasets-created-daily`](README.uwsgi.md#query-datasets-created-daily) | The min/max/average/p95/p99 of total size of datasets created in a single day.
[`query disk-usage`](README.uwsgi.md#query-disk-usage) | Disk usage per object store.
[`query errored-jobs`](README.uwsgi.md#query-errored-jobs) | Lists jobs that errored in the last N hours.
[`query groups-list`](README.uwsgi.md#query-groups-list) | List all groups known to Galaxy
[`query job-history`](README.uwsgi.md#query-job-history) | Job state history for a specific job
[`query job-inputs`](README.uwsgi.md#query-job-inputs) | Input datasets to a specific job
[`query job-outputs`](README.uwsgi.md#query-job-outputs) | Output datasets from a specific job
[`query jobs-max-by-cpu-hours`](README.uwsgi.md#query-jobs-max-by-cpu-hours) | Top 10 jobs by CPU hours consumed (requires CGroups metrics)
[`query jobs-nonterminal`](README.uwsgi.md#query-jobs-nonterminal) | Job info of nonterminal jobs separated by user
[`query jobs-per-user`](README.uwsgi.md#query-jobs-per-user) | Number of jobs run by a specific user
[`query largest-collection`](README.uwsgi.md#query-largest-collection) | Returns the size of the single largest collection
[`query largest-histories`](README.uwsgi.md#query-largest-histories) | Largest histories in Galaxy
[`query latest-users`](README.uwsgi.md#query-latest-users) | 40 recently registered users
[`query monthly-cpu-years`](README.uwsgi.md#query-monthly-cpu-years) | CPU years allocated to tools by month
[`query monthly-data`](README.uwsgi.md#query-monthly-data) | Number of active users per month, running jobs
[`query monthly-jobs`](README.uwsgi.md#query-monthly-jobs) | Number of jobs run each month
[`query monthly-users-active`](README.uwsgi.md#query-monthly-users-active) | Number of active users per month, running jobs
`query monthly-users` | Deprecated, use monthly-users-active
[`query monthly-users-registered`](README.uwsgi.md#query-monthly-users-registered) | Number of users registered each month
[`query old-histories`](README.uwsgi.md#query-old-histories) | Lists histories that haven't been updated (used) for <weeks>
[`query queue`](README.uwsgi.md#query-queue) | Brief overview of currently running jobs
[`query queue-detail`](README.uwsgi.md#query-queue-detail) | Detailed overview of running and queued jobs
[`query queue-overview`](README.uwsgi.md#query-queue-overview) | View used mostly for monitoring
[`query queue-time`](README.uwsgi.md#query-queue-time) | The average/95%/99% a specific tool spends in queue state.
[`query recent-jobs`](README.uwsgi.md#query-recent-jobs) | Jobs run in the past <hours> (in any state)
[`query runtime-per-user`](README.uwsgi.md#query-runtime-per-user) | computation time of user (by email)
[`query server-datasets`](README.uwsgi.md#query-server-datasets) | query server-datasets
[`query server-disk-usage`](README.uwsgi.md#query-server-disk-usage) | query server-disk-usage
[`query server-groups`](README.uwsgi.md#query-server-groups) | query server-groups
[`query server-hda`](README.uwsgi.md#query-server-hda) | query server-hda [date]
[`query server-histories`](README.uwsgi.md#query-server-histories) | query server-histories [date]
[`query server-jobs-cumulative`](README.uwsgi.md#query-server-jobs-cumulative) | query server-jobs-cumulative [date]
[`query server-jobs`](README.uwsgi.md#query-server-jobs) | query server-jobs [date]
[`query server-ts-repos`](README.uwsgi.md#query-server-ts-repos) | query server-ts-repos
[`query server-users-cumulative`](README.uwsgi.md#query-server-users-cumulative) | query server-users-cumulative [date]
[`query server-users`](README.uwsgi.md#query-server-users) | query server-users [date]
[`query server-workflow-invocations`](README.uwsgi.md#query-server-workflow-invocations) | query server-workflow-invocations [yyyy-mm-dd]
[`query server-workflows`](README.uwsgi.md#query-server-workflows) | query server-workflows [date]
[`query tool-available-metrics`](README.uwsgi.md#query-tool-available-metrics) | list all available metrics for a given tool
[`query tool-last-used-date`](README.uwsgi.md#query-tool-last-used-date) | When was the most recent invocation of every tool
[`query tool-metrics`](README.uwsgi.md#query-tool-metrics) | See values of a specific metric
[`query tool-popularity`](README.uwsgi.md#query-tool-popularity) | Most run tools by month
[`query tool-usage`](README.uwsgi.md#query-tool-usage) | Counts of tool runs in the past weeks (default = all)
[`query training-list`](README.uwsgi.md#query-training-list) | List known trainings
[`query training-members-remove`](README.uwsgi.md#query-training-members-remove) | Remove a user from a training
[`query training-members`](README.uwsgi.md#query-training-members) | List users in a specific training
[`query training-queue`](README.uwsgi.md#query-training-queue) | Jobs currently being run by people in a given training
[`query ts-repos`](README.uwsgi.md#query-ts-repos) | Counts of toolshed repositories by toolshed and owner.
[`query users-count`](README.uwsgi.md#query-users-count) | Shows sums of active/external/deleted/purged accounts
[`query users-total`](README.uwsgi.md#query-users-total) | Total number of Galaxy users (incl deleted, purged, inactive)
[`query workflow-connections`](README.uwsgi.md#query-workflow-connections) | The connections of tools, from output to input, in the latest (or all) versions of user workflows
[`report job-info`](README.uwsgi.md#report-job-info) | Information about a specific job
[`report user-info`](README.uwsgi.md#report-user-info) | Quick overview of a Galaxy user in your system
[`uwsgi handler-restart`](README.uwsgi.md#uwsgi-handler-restart) | Restart all handlers
[`uwsgi handler-strace`](README.uwsgi.md#uwsgi-handler-strace) | Strace a handler
[`uwsgi memory`](README.uwsgi.md#uwsgi-memory) | Current system memory usage
[`uwsgi pids`](README.uwsgi.md#uwsgi-pids) | Galaxy process PIDs
[`uwsgi stats_influx`](README.uwsgi.md#uwsgi-stats_influx) | InfluxDB formatted output for the current stats
[`uwsgi stats`](README.uwsgi.md#uwsgi-stats) | uwsgi stats
[`uwsgi status`](README.uwsgi.md#uwsgi-status) | Current system status
[`uwsgi zerg-scale-down`](README.uwsgi.md#uwsgi-zerg-scale-down) | Remove an extraneous zergling
[`uwsgi zerg-scale-up`](README.uwsgi.md#uwsgi-zerg-scale-up) | Add another zergling to deal with high load
[`uwsgi zerg-strace`](README.uwsgi.md#uwsgi-zerg-strace) | Strace a zergling
[`uwsgi zerg-swap`](README.uwsgi.md#uwsgi-zerg-swap) | Swap zerglings in order (unintelligent version)

