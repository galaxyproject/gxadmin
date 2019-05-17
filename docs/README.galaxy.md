# galaxy

Command | Description
------- | -----------
[`galaxy amqp-test`](#galaxy-amqp-test) | (NEW) Test a given AMQP URL for connectivity
[`galaxy cleanup`](#galaxy-cleanup) | Cleanup histories/hdas/etc for past N days (default=30)
[`galaxy migrate-tool-install-from-sqlite`](#galaxy-migrate-tool-install-from-sqlite) | (NEW) Converts normal SQLite version into normal potsgres toolshed repository tables
[`galaxy migrate-tool-install-to-sqlite`](#galaxy-migrate-tool-install-to-sqlite) | Converts normal potsgres toolshed repository tables into the SQLite version

### galaxy amqp-test

**NAME**

galaxy amqp-test -  (NEW) Test a given AMQP URL for connectivity

**SYNOPSIS**

`gxadmin galaxy amqp-test <amqp_url>`

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


### galaxy cleanup

**NAME**

galaxy cleanup -  Cleanup histories/hdas/etc for past N days (default=30)

**SYNOPSIS**

`gxadmin galaxy cleanup [days]`

**NOTES**

Cleanup histories/hdas/etc for past N days using the python objects-based method


### galaxy migrate-tool-install-from-sqlite

**NAME**

galaxy migrate-tool-install-from-sqlite -  (NEW) Converts normal SQLite version into normal potsgres toolshed repository tables

**SYNOPSIS**

`gxadmin galaxy migrate-tool-install-from-sqlite [sqlite-db]`

**NOTES**

    $ gxadmin migrate-tool-install-from-sqlite db.sqlite
    Migrating tables
      export: tool_shed_repository
      import: tool_shed_repository
      ...
      export: repository_repository_dependency_association
      import: repository_repository_dependency_association
    Complete


### galaxy migrate-tool-install-to-sqlite

**NAME**

galaxy migrate-tool-install-to-sqlite -  Converts normal potsgres toolshed repository tables into the SQLite version

**SYNOPSIS**

`gxadmin galaxy migrate-tool-install-to-sqlite`

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

