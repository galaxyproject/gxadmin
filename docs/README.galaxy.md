# galaxy

Command | Description
------- | -----------
[`galaxy amqp-test`](#galaxy-amqp-test) | Test a given AMQP URL for connectivity
[`galaxy cleanup`](#galaxy-cleanup) | Cleanup histories/hdas/etc for past N days (default=30)
[`galaxy cleanup-jwd`](#galaxy-cleanup-jwd) | (NEW) Cleanup job working directories
[`galaxy fav_tools`](#galaxy-fav_tools) | Favourite tools in Galaxy DB
[`galaxy fix-conda-env`](#galaxy-fix-conda-env) | Fix broken conda environments
[`galaxy migrate-tool-install-from-sqlite`](#galaxy-migrate-tool-install-from-sqlite) | Converts SQLite version into normal potsgres toolshed repository tables
[`galaxy migrate-tool-install-to-sqlite`](#galaxy-migrate-tool-install-to-sqlite) | Converts normal potsgres toolshed repository tables into the SQLite version

## galaxy amqp-test

galaxy amqp-test -  Test a given AMQP URL for connectivity

**SYNOPSIS**

    gxadmin galaxy amqp-test <amqp_url>

**NOTES**

**Note**: must be run in Galaxy Virtualenv

Simple script to test an AMQP URL. If connection works, it will
immediately exit with a python object:

    $ gxadmin galaxy amqp-test pyamqp://user:pass@host:port/vhost
    <kombu.transport.pyamqp.Channel object at 0x7fe56a836290>

    $ gxadmin galaxy amqp-test pyamqp://user:pass@host:port/vhost?ssl=1
    <kombu.transport.pyamqp.Channel object at 0x7fe56a836290>

Some errors look weird:

*wrong password*:

    $ gxadmin galaxy amqp-test ...
    Traceback
    ...
    amqp.exceptions.AccessRefused: (0, 0): (403) ACCESS_REFUSED - Login was refused using authentication mechanism AMQPLAIN. For details see the broker logfile.

*wrong host*, *inaccessible host*, basically any other problem:

    $ gxadmin galaxy amqp-test ...
    [hangs forever]

Basically any error results in a hang forever. It is recommended you run it with a timeout:

    $ timeout 1 gxadmin galaxy amqp-test
    $


## galaxy cleanup

galaxy cleanup -  Cleanup histories/hdas/etc for past N days (default=30)

**SYNOPSIS**

    gxadmin galaxy cleanup [days]

**NOTES**

Cleanup histories/hdas/etc for past N days using the python objects-based method


## galaxy cleanup-jwd

galaxy cleanup-jwd -  (NEW) Cleanup job working directories

**SYNOPSIS**

    gxadmin galaxy cleanup-jwd <working_dir> [1|months ago]

**NOTES**

Scans through a provided job working directory subfolder, e.g.
job_working_directory/ without the 005 subdir to find all folders which
were changed less recently than N months.

 Then it takes the first 1000 entries and cleans them up. This was more
of a hack to handle the fact that the list produced by find is really
long, and the for loop hangs until it's done generating the list.


## galaxy fav_tools

galaxy fav_tools -  Favourite tools in Galaxy DB

**SYNOPSIS**

    gxadmin galaxy fav_tools

**NOTES**

What are people's fav tools


## galaxy fix-conda-env

galaxy fix-conda-env -  Fix broken conda environments

**SYNOPSIS**

    gxadmin galaxy fix-conda-env <conda_dir/envs/>

**NOTES**

Fixes any broken conda environments which are missing the activate scripts in their correct locations.

MUST end in /envs/


## galaxy migrate-tool-install-from-sqlite

galaxy migrate-tool-install-from-sqlite -  Converts SQLite version into normal potsgres toolshed repository tables

**SYNOPSIS**

    gxadmin galaxy migrate-tool-install-from-sqlite [sqlite-db]

**NOTES**

    $ gxadmin migrate-tool-install-from-sqlite db.sqlite
    Migrating tables
      export: tool_shed_repository
      import: tool_shed_repository
      ...
      export: repository_repository_dependency_association
      import: repository_repository_dependency_association
    Complete


## galaxy migrate-tool-install-to-sqlite

galaxy migrate-tool-install-to-sqlite -  Converts normal potsgres toolshed repository tables into the SQLite version

**SYNOPSIS**

    gxadmin galaxy migrate-tool-install-to-sqlite

**NOTES**

    $ gxadmin migrate-tool-install-to-sqlite
    Creating new sqlite database: galaxy_install.sqlite
    Migrating tables
      export: tool_shed_repository
      import: tool_shed_repository
      ...
      export: repository_repository_dependency_association
      import: repository_repository_dependency_association
    Complete

