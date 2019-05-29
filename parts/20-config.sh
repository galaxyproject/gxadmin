config_validate() { ## : validate config files
	handle_help "$@" <<-EOF
		Validate the configuration files
		**Warning**:
		- This requires you to have \`\$GALAXY_DIST\` set and to have config under \`\$GALAXY_DIST/config\`.
		- This only validates that it is well formed XML, and does **not** validate against any schemas.

		    $ gxadmin validate
		      OK: galaxy-dist/data_manager_conf.xml
		      ...
		      OK: galaxy-dist/config/tool_data_table_conf.xml
		      OK: galaxy-dist/config/tool_sheds_conf.xml
		    All XML files validated
	EOF

	assert_set_env GALAXY_CONFIG_DIR
	assert_set_env GALAXY_MUTABLE_CONFIG_DIR

	fail_count=0
	for file in ${GALAXY_CONFIG_DIR}/*.xml; do
		xmllint "$file" > /dev/null 2>/dev/null;
		ec=$?
		if (( ec > 0 )); then
			fail_count=$(echo "$fail_count + 1" | bc)
			error "  FAIL: $file ($ec)";
		else
			success "  OK: $file";
		fi
	done;

	for file in ${GALAXY_MUTABLE_CONFIG_DIR}/*.xml; do
		xmllint "$file" > /dev/null 2>/dev/null;
		ec=$?
		if (( ec > 0 )); then
			fail_count=$(echo "$fail_count + 1" | bc)
			error "  FAIL: $file ($ec)";
		else
			success "  OK: $file";
		fi
	done;

	if (( fail_count == 0 )); then
		success "All XML files validated"
	else
		error "XML validation failed, cancelling any actions."
		exit 1
	fi
}

config_dump() { ## : Dump Galaxy configuration as JSON
	handle_help "$@" <<-EOF
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
	EOF

	assert_set_env GALAXY_ROOT
	assert_set_env GALAXY_CONFIG_FILE

	dump_config_python=$(cat <<EOF
import argparse
import json
import os
import sys

sys.path.insert(1, '$GALAXY_ROOT/lib')

import galaxy.config
from galaxy.util.script import app_properties_from_args, populate_config_args

parser = argparse.ArgumentParser()
populate_config_args(parser)
args = parser.parse_args()
args.config_file = '$GALAXY_CONFIG_FILE'

app_properties = app_properties_from_args(args)
config = galaxy.config.Configuration(**app_properties)

sys.stdout.write(json.dumps(config.__dict__, default=lambda o: '<fail>'))
EOF
)
	echo "$dump_config_python" | python
}

