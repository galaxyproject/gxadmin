# 23-pre

# 22

- Added:
	- filter histogram: replaces bit.ly's data_hacks with a built-in AWK program to calculate a histogram. May not be entirely portable @hexylena.
	- mutate scale-table-autovacuum: Dynamically update autovacuum and autoanalyze scale for large tables. @natefoo
	- query tools-usage-per-month from @lldelisle
	- mutate derive-missing-username-from-email and mutate set-missing-username-to-random-uuid from @mvdbeek
	- query monthly-jobs-by-new-multiday-users @afgane
	- query users-engaged-multiday @afgane
	- query monthly-jobs-by-new-users @afgane
- Updated:
	- query monthly-cpu-stats to add --nb_users --filter_email by @lldelisle
	- query monthly-users-active to add YYYY-MM parameter @afgane
	- query monthly-users-registered to add YYYY-MM parameter @afgane
	- query monthly-jobs to add YYYY-MM and --by_state parameters @afgane
	- query total-jobs to add date and --total parameters @afgane
- Fixed:
	- Replaced hardcoded metric_name with the variable in query_tool-metrics function @sanjaysrikakulam
	- improved man pages a tad
	- fixed query monthly-cpu-stats when year was specified

# 21

- Added:
	- query queue-detail-drm, from @cat-bro and @slugger70, a better version of queue-details potentially.
	- mutate reassign-active-workflows-to-handler, from @mira-miracoli, as workaround for [galaxyproject/galaxy#8209](https://github.com/galaxyproject/galaxy/issues/8209)
	- --help-man can now be used in addition to --help on specific query/function commands. It assumes that pandoc is installed, and will render the help instead as a manual page.
	- query large-old-histories, finds old large and probably easily removable histories, @hexylena
	- query potentially-duplicated-datasets, finds duplicate datasets @hexylena
	- query potentially-duplicated-reclaimable-space, finds the potential reclaimable space, @hexylena
	- CGI mode, use sudo fcgiwrap -s unix:/run/cgi.sock -f -p pwd/gxadmin to activate, wrap in nginx, @hexylena
	- server users-with-oidc command to get history of OIDC user creations, thanks @abretaud
	- server disk-usage command to get history of disk usage, thanks @abretaud
- Updated:
	- Add summary and limit options to tool-metrics query, by @natefoo.
	- Updated the Wonderful Argument Parser with a fancier version, @hexylena
	- Gunicorn handler-restart uses now a two-batches-approach instead of restarting handlers one-by-one @sanjaysrikakulam @mira-miracoli
- Fixed:
	- Wonderful Argument Parser arg values could not contain spaces, @natefoo
- Removed:
	- uwsgi series of commands are now completely deprecated, as Galaxy no longer supports uwsgi. If you need these commands, please install an older version of gxadmin.

# 20

- Fixed:
	- Broken things in preview anonymisation script
	- Unified uwsgi-status command (thanks @gmauro)
	- Unified galaxy user/email/id filtering and made it stricter in what it accepts ([#60](https://github.com/galaxyproject/gxadmin/issues/60)).
	- Updated "query user-disk-usage" to add a "--use-precalc" flag which uses the value calculated by Galaxy.
	- Enabled GXADMIN_PYTHON from the environment, by @gmauro.
	- Updated "galaxy cleanup" to avoid to set update_time on updated objects, by @gmauro.
	- fixed broken latest-users query
	- fixed broken errored-jobs query, by @gmauro.
	- several fixes in galaxy ie-show command, @gmauro.
	- Generalized the "uwsgi lastlog" function to proper handle journalctl's output, by @gmauro.
	- Updated "query upload-gb-in-past-hour" to include also datasets created by the DATA_FETCH tool, by @gmauro.
- Added:
	- query dump-users, for @shiltemann
	- "did you mean" when a command isn't found.
	- query job-metrics, by @anuprulez and @simonbray.
	- uwsgi active-user count
	- exports PGAPPNAME setting the application name for postgres connections. This becomes visible in pg_stat_activity.
	- mutate set_quota_for_oidc_user, by @gmauro.
	- iquery support for queue-detail query
	- query tool-usage-over-time which can be used to make charts of specific tools over time.
	- improved use of FZF for both the search and 'typo' functions, when it is available.
	- query pulsar-gb-transferred: sums up data in/out (minus collections) of pulsar.
	- mutate fail-misbehaving-gxits: Works aroud a gxit issue.
	- galaxy prune-gxit-routes: Prunes dead routes
	- mutate force-publish-history: Workaround for [galaxyproject/galaxy#13001](https://github.com/galaxyproject/galaxy/issues/13001)
	- report group-info, by @pavanvidem
	- query tool-use-by-group, by @gavindi
	- query job-state-stats, by @gavindi
	- query disk-usage-library, by @gregvonkuster
	- query monthly-workflow-invocations, by @gmauro.
	- query monthly-job-runtimes, by @gregvonkuster
	- query job-state, by @natefoo
	- query largest-dataset-users, by @hexylena
	- query dataset-usage-and-imports, by @hexylena
	- mutate dataset-mark-purged, by @hexylena
- Updated:
	- Add option to include error counts in tool-popularity query, thanks @natefoo
	- Add option to exclude unsuccessful jobs from tool-metrics query, thanks @natefoo

# 19

- Fixed:
	- Fixed broken slurping from previous release (Thanks @slugger70 for catching it.)
	- Made changelog updates mandatory so I don't have to ask people for it. Finally.
- Added:
	- encode/decode ID
	- Benchmarking via ASV (preview)
	- anonymise-db-for-release (preview)
	- Add '--by_group' flag to several monthly queries (Thanks @slugger70)
	- query monthly-cpu-stats (Thanks @gmauro)
	- workflow trace archive commands
	- query queue has a new optional parameter for splitting queues by various attributes (Thanks @natefoo)
	- query pg-rows-per-table to find out which tables have data.
	- mutate fail-wfi
	- mutate oidc-by-emails, mutate users affected by [galaxyproject/galaxy#9981](https://github.com/galaxyproject/galaxy/issues/9981)
	- mutate now supports echo/explain prefixes.
	- very-unsafe flag to most mutate methods, avoiding the transaction.
	- added the [wonderful argument parsing](https://github.com/hexylena/wap) for parsing function signatures into arguments automatically, making contribution easier.

# 18

- Fixed:
	- All previous '--nice' flags are rewritten to '--human' (Thanks @lldelisle)
	- Update 'user-disk-usage' to support iquery (Thanks @lldelisle)
	- Update 'largest-histories' to support iquery (Thanks @lldelisle)
	- uwsgi-memory now looks at workflow schedulers
	- Exposed bash autocompletion and documented it
- Added:
	- query workers, only works on Galaxy 20.01 or newer and retrieves the hostname and PID of Galaxy worker processes
	- '--details' option to query errored-jobs to include the job_stderr column
	- total number of jobs with exit states for galaxxy instance (Thanks @bruggerk)
	- query workflow-invocation-totals
	- server subcommand exposing previously hidden functions
- Removed:
	- filter hexdecodelines, this is now replaced by a built-in postgres function
- Changed:
	- Refactored internal function search to unify local, query, mutate, with the rest.

# 17

Testing our new release message

- Fixed:
	- Issue with py3 only machines
- Added:
	- jobs ready to run

# 16

- Fixed:
	- figured out how to decode hex blobs in postgres

# 15

- Fancy [new docs site](https://galaxyproject.github.io/gxadmin/#/)
- Added:
	- search :(
	- query server-groups-allocated-cpu, thanks @selten
	- query server-groups-disk-usage, thanks @selten
	- query user-disk-quota, thanks @selten
	- query job-info, thanks @selten
	- query queue-detail-by-handler
	- mutate reassign-job-to-handler
	- a LOT of query pg-... commands from [heroku's pg-extras](https://github.com/heroku/heroku-pg-extras/tree/master/commands)
	- mutate drop-extraneous-workflow-step-output-associations
	- mutate reassign-workflows-to-handler
	- query data-origin-distribution
	- query data-origin-distribution-summary
	- query user-history-list

# 14

- Added:
	- Job working directory cleaner
	- meta slurp-upto
	- meta slurp-day
	- Imported jobs-queued-internal-by-handler and jobs-queued queries from main
	- query users-with-oidc
	- Three new queries for checking history execution time, thanks @mmiladi
		- query history-runtime-system-by-tool
		- query history-runtime-system
		- query history-runtime-wallclock
	- Three new queries for checking potentially broken tools, thanks @jmchilton
		- query tool-new-errors
		- query tool-errors
		- query tool-likely-broken
	- Import script from https://github.com/galaxyproject/grafana-dashboards
	- query for datasets uploaded in last N hours
	- mutate to approve users
	- mutate assign-unassigned-workflow: workaround for [galaxyproject/galaxy#8209](https://github.com/galaxyproject/galaxy/issues/8209)
	- mutate oidc-role-find-affected: workaround for [galaxyproject/galaxy#8244](https://github.com/galaxyproject/galaxy/issues/8244)
	- mutate oidc-role-fix: workaround for [galaxyproject/galaxy#8244](https://github.com/galaxyproject/galaxy/issues/8244)
	- query user-disk-usage, thanks @selten
	- query group-cpu-seconds, thanks @selten
- Fixed:
	- Correct bug in queue-detail and a couple other functions which did not
	  correctly include data from anonymous users.

# 13

- Added:
	- local functions support querying when prefixed with "query-"
	- "meta influx-post" and "meta influx-query" were added to get data into and out of Influx
	- "explainquery" is added as an alternative to csv/tsv/etc queries, which does an "EXPLAIN ANALYZE" of the current SQL
	- "explainjsonquery" added for use with http://tatiyants.com/pev/
	- "time" prefix for all functions added to print execution time to stderr
	- Function to fail a specific job ID
	- "query user-recent-aggregate-jobs"
	- "query history-contents"
	- "query hdca-info"
	- "query hdca-datasets"
	- "mutate fail-history", when failing individual jobs is too slow
	- "galaxy migrate-tool-install-from-sqlite"
	- "query user-cpu-years"
	- Shellchecking of entire script
- Fixed:
	- Escaped commas in influx outputs, switched to tabs to further prevent comma issues.
	- Correct date filter in "query {server-groups,server-datasets}"
	- Removed unnecessary function name duplication, e.g. "query_filter() { ## query filter [id]: Does thing" can now be written as "query_filter() { ## [id]: Does thing"

# 12

- Added:
	- local functions, users can add functions to a separate file which are
	  made available in gxadmin. @erasche resisted implementing these for a
	  long time for fears that they won't be contributed back and everyone
	  would keep their precious sql private. So they may nag you occasionally
	  to contribute them back.
	- (semi) EU specific systemd handler/zergling management commands
	- filter digest-color: command to colour some text
	- filter identicon: command to generate an identicon
	- Some basic testing of the overall script
- Fixed:
	- Correct time zones in all queries to be client-side time zones rather
	  than UTC encoded timestamps as stored in db (Thanks @slugger70)
	- Renamed: "query monthly-users" → "query monthly-users-active"
- Removed:
	- Removed highly EU specific handler and zerg functions
	- Deprecated: "query active-users"
- Changed:
	- Major internal reorganisation and split into parts for easier editing. A
	  bash script that needs a build system, truly horrifying.
	- User info query now shows recent WF invocations and whether their largest
	  histories are deleted or purged or not.
	- Separated out 'report' types that are markdown-only outputs and don't
	  support tsv/csv queries

# 11

- Added:
	- filter hexdecode: to help decode hex blobs in postgres queries
	- uwsgi stats\_influx: which fetches stats from uWSGI zerglings
	- filter pg2md: Convert postgres tables into markdown compatible tables
	- "GDPR_MODE" env var which blanks out usernames and emails
	- errored-jobs: Lists jobs that errored in the last N hours
	- workflow-connections: Exports worfklow connections, input to output tools
	- dump-config: Dump Galaxy configuration as JSON
	- tool-popularity: Most popular tools per month
- Changed:
	- user-details: now reports in markdown compatible output and with more
	  information about the user
	- job-info: now reports in markdown compatible output, including job inputs
	  + outputs
	- queue-overview: now includes user ID by default ("GDPR_MODE=1" will set
	  the value to "0"), and allows using shorter tool IDs
	- user-details: renamed to user-info
	- user-info: includes largest histories

# 10

- Added:
	- old-histories: Old histories query to find histories that haven't been
	  used for X weeks.
	- user-details: query details about a specific user ID
- Fixed:
	- Included date in cleanup logs

# 9

- Added:
	- Influx queries for:
		- active-users
		- collection-usage
		- disk-usage
		- groups-list
		- largest-collection
		- queue
		- queue-overview
		- tool-usage
		- ts-repos
		- users-count
		- users-total
	- tool-metrics
	- tool-available-metrics
	- largest-collection
- Fixed:
	- Improved "latest-users" to include any groups they're part of and their
	  registration status (ack'd email/not)
	- Influx queries now functional (but not automatic)
	- Collection usage

# 8

- Added:
	- Help documentation in-tool
- Fixed:
	- rewrote internals to use functions + case/esac

# 7

- Added:
	- cleanup
- Fixed:
	- removed all temporary tables for CTEs, allowing tsv/csv queries for
	  everything
	- internal cleanup

# 6

- Added functions:
	- active-users
	- training-memberof
	- training-remove-member
- Fixed:
	- update script
	- removed more EU paths for env vars


# 5

- Added functions:
	- disk-usage
	- users-count
	- users-total
	- groups-list
	- collection-usage
	- ts-repos
- Fixed job-inputs/job-outputs
- Fixed internal variable names

# 4

- Implemented update function
- removed all support for legacy "_" calls
- Fancy new automatically updated help function

# 3

- Added migration to sqlite for toolshed install database
- Removed some EU specific stuff

# 2

- Added training-queue and job-history functions
- replaced "_" with "-"

# 1 - Initial Release

Included functions for:

- validating configs
- zerg tasks
- handler tasks
- queries:
	- latest-users
	- tool-usage
	- job-info
	- job-outputs
	- queue
	- queue-detail
	- recent-jobs
	- jobs-per-user
	- runtime-per-user
	- training
	- training-members
	- queue-time
	- datasets-created-daily
