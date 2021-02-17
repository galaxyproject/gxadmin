# Galaxy Admin Utility

A command line tool for [Galaxy](https://github.com/galaxyproject/galaxy)
administrators to run common queries against our Postgres databases. It additionally
includes some code for managing zerglings under systemd, and other utilities.

This script strictly expects a postgres database and has **no** plans to support
mysql or sqlite3.

## Installation

```
curl -L https://github.com/galaxyproject/gxadmin/releases/latest/download/gxadmin > /usr/bin/gxadmin
chmod +x /usr/bin/gxadmin
```

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

