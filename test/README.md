# Query regression checks

Run the normal shellcheck/Bats checks with `make test`.

The metric regression checks additionally require `psql` and a PostgreSQL
connection supplied through the usual libpq environment variables:

```sh
make gxadmin
PGDATABASE=galaxy ./test/metric-queries.sh
```

The checks shadow all source relations with temporary fixture tables inside a
transaction and roll back. They neither read nor modify permanent Galaxy data.
The connection must allow temporary tables; do not run with a read-only role.
The test is separate from `make test`, which requires no database.

The fixtures exercise differing HDA/dataset IDs, plugin collisions, equal and
conflicting duplicates, null and missing observations, zeros, cgroup v1/v2
memory/CPU, memory-plus-swap exclusion, missing slots, and matched-population
resource ratios. Expected quantities are hand calculated, including monthly
allocated core-hours. These checks establish query behavior, not measurement
trust or production performance.
