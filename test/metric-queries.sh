#!/usr/bin/env bash
# Regression checks against source-shaped temporary tables. Permanent data is
# never changed. Requires PostgreSQL and its normal libpq connection settings.
set -euo pipefail
cd "$(dirname "$0")/.."
GXADMIN=${GXADMIN:-./gxadmin}
export GXADMIN_BUGGER_OFF=1
{
	cat test/metric-queries.sql
	printf 'CREATE TEMP TABLE actual_jobs AS\n'
	"$GXADMIN" echoquery job-metrics
	printf ';\nCREATE TEMP TABLE actual_inputs AS\n'
	"$GXADMIN" echoquery tool-memory-per-inputs 'fixture_%' --like
	printf ';\nCREATE TEMP TABLE actual_memory AS\n'
	"$GXADMIN" echoquery tool-memory-efficiency --min-job-count=0 --min-runtime=-1 --min-mem=0 --newer-than=100y
	printf ';\nCREATE TEMP TABLE actual_resources AS\n'
	"$GXADMIN" echoquery tool-resource-usage --limit=100 --newer-than=100y
	printf ';\nCREATE TEMP TABLE actual_monthly AS\n'
	"$GXADMIN" echoquery monthly-cpu-stats --nb-users 2090
	printf ';\nCREATE TEMP TABLE actual_years AS\n'
	"$GXADMIN" echoquery monthly-cpu-years
	printf ';\n'
	cat test/metric-assertions.sql
} | psql -X -v ON_ERROR_STOP=1
