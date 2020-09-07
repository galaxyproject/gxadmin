# Galaxy Admin Utility [![Build Status](https://travis-ci.org/usegalaxy-eu/gxadmin.svg?branch=master)](https://travis-ci.org/usegalaxy-eu/gxadmin)

A command line tool for [Galaxy](https://github.com/galaxyproject/galaxy)
administrators to run common queries against our Postgres databases. It additionally
includes some code for managing zerglings under systemd, and other utilities.

Mostly gxadmin acts as a repository for the common queries we all run regularly
but fail to share with each other. We even include some [unlisted
queries](./parts/27-unlisted.sh) which may be useful as examples, but are not generically useful.

It comes with around 90 commonly useful queries included (180+ commands total),
but you can easily add more to your installation with local functions. gxadmin
attempts to be a very readable bash script and avoids using fancy new bash
features.

This script strictly expects a postgres database and has no plans to support
mysql or sqlite3.

## Installation

```
curl -L https://github.com/usegalaxy-eu/gxadmin/releases/latest/download/gxadmin > /usr/bin/gxadmin
chmod +x /usr/bin/gxadmin
```

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md)

## Changelog

[Changelog](CHANGELOG.md)

## Contributors

- Helena Rasche, BDFL ([@hexylena](https://github.com/hexylena))
- Nate Coraor ([@natefoo](https://github.com/natefoo))
- Simon Gladman ([@slugger70](https://github.com/slugger70))
- Anthony Bretaudeau ([@abretaud](https://github.com/abretaud))
- John Chilton ([@jmchilton](https://github.com/jmchilton))
- Gianmauro Cuccuru ([@gmauro](https://github.com/gmauro))
- Lucille Delisle ([@lldelisle](https://github.com/lldelisle))
- Manuel Messner (mm@skellet.io)
- Kim Brügger ([@bruggerk](https://github.com/bruggerk))

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

### InfluxDB

In order to use functions like `gxadmin meta influx-post`, `gxadmin` requires
a few environment variables to be set. Namely
*  `INFLUX_URL`
*  `INFLUX_PASS`
*  `INFLUX_USER`
*  `INFLUX_DB`

### GDPR

You may want to set `GDPR_MODE=1`. Please determine your own legal responsibilities, the authors take no responsibility for anything you may have done wrong.

If you want to publish data, first be careful! Second, the `GDPR_MODE` variable is part of the hash, so you can set it to something like `GDPR_MODE=$(openssl rand -hex 24 2>/dev/null) gxadmin query ...` for hashing and "throwing away the key"

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
