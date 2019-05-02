# 13 - pre

- Added:
	- local functions support querying when prefixed with "query-"
	- "meta influx-post" and "meta influx-query" were added to get data into
	  and out of Influx
	- "explainquery" is added as an alternative to csv/tsv/etc queries, which
	  does an "EXPLAIN ANALYZE" of the current SQL
	- "explainjsonquery" added for use with http://tatiyants.com/pev/
	- "time" prefix for all functions added to print execution time to stderr
	- Function to fail a specific job ID
	- "query user-recent-aggregate-jobs"
	- "query history-contents"
	- "query hdca-info"
	- "query hdca-datasets"
- Fixed:
	- Escaped commas in influx outputs, switched to tabs to further prevent
	  comma issues.
	- Correct date filter in "query {server-groups,server-datasets}"

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
	  than UTC encoded timestamps as stored in db (Thanks @slugger70!)
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
