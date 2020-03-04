# config

Command | Description
------- | -----------
[`config dump`](#config-dump) | Dump Galaxy configuration as JSON
[`config validate`](#config-validate) | validate config files

## config dump

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=config_dump&type=Code))
config dump -  Dump Galaxy configuration as JSON

**SYNOPSIS**

    gxadmin config dump

**NOTES**

This function was added with the intention to use it internally, but it may be useful in your workflows. It uses the python code from the Galaxy codebase in order to properly load the configuration which is then dumped as JSON.

    (.venv)$ gxadmin dump-config | jq -S . | head
    {
      "activation_grace_period": 3,
      "admin_users": "hxr@local.host",
      "admin_users_list": [
        "hxr@local.host"
      ],
      "allow_library_path_paste": false,
      "allow_path_paste": false,
      "allow_user_creation": true,
      "allow_user_dataset_purge": true,


## config validate

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=config_validate&type=Code))
config validate -  validate config files

**SYNOPSIS**

    gxadmin config validate

**NOTES**

Validate the configuration files

**Warning**:

!> - This requires you to have `$GALAXY_DIST` set and to have config under `$GALAXY_DIST/config`.
!> - This only validates that it is well formed XML, and does **not** validate against any schemas.
!>
!>     $ gxadmin validate
!>       OK: galaxy-dist/data_manager_conf.xml
!>       ...
!>       OK: galaxy-dist/config/tool_data_table_conf.xml
!>       OK: galaxy-dist/config/tool_sheds_conf.xml
!>     All XML files validated

