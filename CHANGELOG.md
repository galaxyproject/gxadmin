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
	- Improved `latest-users` to include any groups they're part of and their registration status (ack'd email/not)
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
	- removed all temporary tables for CTEs, allowing tsv/csv queries for everything
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
- removed all support for legacy `_` calls
- Fancy new automatically updated help function

# 3

- Added migration to sqlite for toolshed install database
- Removed some EU specific stuff

# 2

- Added training-queue and job-history functions
- replaced `_` with `-`

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
