# galaxy

Command | Description
------- | -----------
[`galaxy cleanup`](#filter-pg2md) | Cleanup histories/hdas/etc for past N days (default=30)
[`galaxy migrate-tool-install-to-sqlite`](#filter-pg2md) | Converts normal potsgres toolshed repository tables into the SQLite version

### galaxy cleanup

**NAME**

galaxy cleanup -  Cleanup histories/hdas/etc for past N days (default=30)

**SYNOPSIS**

gxadmin galaxy cleanup [days]

**NOTES**

Cleanup histories/hdas/etc for past N days using the python objects-based method


### galaxy migrate-tool-install-to-sqlite

**NAME**

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

