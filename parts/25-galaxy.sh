galaxy_cleanup() { ## [days]: Cleanup histories/hdas/etc for past N days (default=30)
	handle_help "$@" <<-EOF
		Cleanup histories/hdas/etc for past N days using the python objects-based method
	EOF

	days=30
	if (( $# > 0 )); then
		days=$1
	fi

	assert_set_env GALAXY_ROOT
	assert_set_env GALAXY_CONFIG_FILE
	assert_set_env GALAXY_LOG_DIR

	run_date=$(date --rfc-3339=seconds)

	for action in {delete_userless_histories,delete_exported_histories,purge_deleted_histories,purge_deleted_hdas,delete_datasets,purge_datasets}; do
		start_time=$(date +%s)
		$GXADMIN_PYTHON \
			"$GALAXY_ROOT/scripts/cleanup_datasets/pgcleanup.py" \
			-c "$GALAXY_CONFIG_FILE" \
			-o "$days" \
			-l "$GALAXY_LOG_DIR" \
			-s $action \
			-w 128MB \
			 >> "$GALAXY_LOG_DIR/cleanup-${run_date}-${action}.log" \
			2>> "$GALAXY_LOG_DIR/cleanup-${run_date}-${action}.err";
		finish_time=$(date +%s)
		runtime=$(( finish_time - start_time ))

		# Something that telegraf can consume
		ec=$?
		if (( ec == 0 )); then
			echo "cleanup_datasets,group=$action success=1,runtime=$runtime"
		else
			echo "cleanup_datasets,group=$action success=0,runtime=$runtime"
		fi
	done
}

galaxy_migrate-tool-install-to-sqlite() { ## : Converts normal potsgres toolshed repository tables into the SQLite version
	handle_help "$@" <<-EOF
		    $ gxadmin migrate-tool-install-to-sqlite
		    Creating new sqlite database: galaxy_install.sqlite
		    Migrating tables
		      export: tool_shed_repository
		      import: tool_shed_repository
		      ...
		      export: repository_repository_dependency_association
		      import: repository_repository_dependency_association
		    Complete
	EOF

	# Export tables
	if [[ -f  galaxy_install.sqlite ]]; then
		error "galaxy_install.sqlite exists, not overwriting"
		exit 1
	fi

	success "Creating new sqlite database: galaxy_install.sqlite"
	empty_schema=$(mktemp)
	echo "
	PRAGMA foreign_keys=OFF;
	BEGIN TRANSACTION;
	CREATE TABLE migrate_version (
		repository_id VARCHAR(250) NOT NULL,
		repository_path TEXT,
		version INTEGER,
		PRIMARY KEY (repository_id)
	);
	CREATE TABLE tool_shed_repository (
		id INTEGER NOT NULL,
		create_time DATETIME,
		update_time DATETIME,
		tool_shed VARCHAR(255),
		name VARCHAR(255),
		description TEXT,
		owner VARCHAR(255),
		changeset_revision VARCHAR(255),
		deleted BOOLEAN,
		metadata BLOB,
		includes_datatypes BOOLEAN,
		installed_changeset_revision VARCHAR(255),
		uninstalled BOOLEAN,
		dist_to_shed BOOLEAN,
		ctx_rev VARCHAR(10),
		status VARCHAR(255),
		error_message TEXT,
		tool_shed_status BLOB,
		PRIMARY KEY (id),
		CHECK (deleted IN (0, 1))
	);
	CREATE TABLE tool_version (
		id INTEGER NOT NULL,
		create_time DATETIME,
		update_time DATETIME,
		tool_id VARCHAR(255),
		tool_shed_repository_id INTEGER,
		PRIMARY KEY (id),
		FOREIGN KEY(tool_shed_repository_id) REFERENCES tool_shed_repository (id)
	);
	CREATE TABLE tool_version_association (
		id INTEGER NOT NULL,
		tool_id INTEGER NOT NULL,
		parent_id INTEGER NOT NULL,
		PRIMARY KEY (id),
		FOREIGN KEY(tool_id) REFERENCES tool_version (id),
		FOREIGN KEY(parent_id) REFERENCES tool_version (id)
	);
	CREATE TABLE migrate_tools (
		repository_id VARCHAR(255),
		repository_path TEXT,
		version INTEGER
	);
	CREATE TABLE tool_dependency (
		id INTEGER NOT NULL,
		create_time DATETIME,
		update_time DATETIME,
		tool_shed_repository_id INTEGER NOT NULL,
		name VARCHAR(255),
		version VARCHAR(40),
		type VARCHAR(40),
		status VARCHAR(255),
		error_message TEXT,
		PRIMARY KEY (id),
		FOREIGN KEY(tool_shed_repository_id) REFERENCES tool_shed_repository (id)
	);
	CREATE TABLE repository_dependency (
		id INTEGER NOT NULL,
		create_time DATETIME,
		update_time DATETIME,
		tool_shed_repository_id INTEGER NOT NULL,
		PRIMARY KEY (id),
		FOREIGN KEY(tool_shed_repository_id) REFERENCES tool_shed_repository (id)
	);
	CREATE TABLE repository_repository_dependency_association (
		id INTEGER NOT NULL,
		create_time DATETIME,
		update_time DATETIME,
		tool_shed_repository_id INTEGER,
		repository_dependency_id INTEGER,
		PRIMARY KEY (id),
		FOREIGN KEY(tool_shed_repository_id) REFERENCES tool_shed_repository (id),
		FOREIGN KEY(repository_dependency_id) REFERENCES repository_dependency (id)
	);
	CREATE INDEX ix_tool_shed_repository_name ON tool_shed_repository (name);
	CREATE INDEX ix_tool_shed_repository_deleted ON tool_shed_repository (deleted);
	CREATE INDEX ix_tool_shed_repository_tool_shed ON tool_shed_repository (tool_shed);
	CREATE INDEX ix_tool_shed_repository_changeset_revision ON tool_shed_repository (changeset_revision);
	CREATE INDEX ix_tool_shed_repository_owner ON tool_shed_repository (owner);
	CREATE INDEX ix_tool_shed_repository_includes_datatypes ON tool_shed_repository (includes_datatypes);
	CREATE INDEX ix_tool_version_tool_shed_repository_id ON tool_version (tool_shed_repository_id);
	CREATE INDEX ix_tool_version_association_tool_id ON tool_version_association (tool_id);
	CREATE INDEX ix_tool_version_association_parent_id ON tool_version_association (parent_id);
	CREATE INDEX ix_tool_dependency_tool_shed_repository_id ON tool_dependency (tool_shed_repository_id);
	CREATE INDEX ix_repository_dependency_tool_shed_repository_id ON repository_dependency (tool_shed_repository_id);
	CREATE INDEX ix_repository_repository_dependency_association_tool_shed_repository_id ON repository_repository_dependency_association (tool_shed_repository_id);
	CREATE INDEX ix_repository_repository_dependency_association_repository_dependency_id ON repository_repository_dependency_association (repository_dependency_id);
	COMMIT;
	" > "${empty_schema}"
	sqlite3 galaxy_install.sqlite < "${empty_schema}"
	rm "${empty_schema}"

	success "Migrating tables"

	# tool_shed_repository is special :(
	table=tool_shed_repository
	success "  export: ${table}"
	export_csv=$(mktemp /tmp/tmp.gxadmin.${table}.XXXXXXXXXXX)
	psql -c "COPY (select
		id, create_time, update_time, tool_shed, name, description, owner, changeset_revision, case when deleted then 1 else 0 end, metadata, includes_datatypes, installed_changeset_revision, uninstalled, dist_to_shed, ctx_rev, status, error_message, tool_shed_status from $table) to STDOUT with CSV" > "$export_csv";

	success "  import: ${table}"
	echo ".mode csv
.import ${export_csv} ${table}" | sqlite3 galaxy_install.sqlite
	ec=$?
	if (( ec == 0 )); then
		rm "${export_csv}";
	else
		error "  sql: ${export_csv}"
	fi

	sqlite3 galaxy_install.sqlite "insert into migrate_version values ('ToolShedInstall', 'lib/galaxy/model/tool_shed_install/migrate', 17)"
	# the rest are sane!
	for table in {tool_version,tool_version_association,migrate_tools,tool_dependency,repository_dependency,repository_repository_dependency_association}; do
		success "  export: ${table}"
		export_csv=$(mktemp /tmp/tmp.gxadmin.${table}.XXXXXXXXXXX)
		psql -c "COPY (select * from $table) to STDOUT with CSV" > "$export_csv";

		success "  import: ${table}"
		echo ".mode csv
.import ${export_csv} ${table}" | sqlite3 galaxy_install.sqlite
		ec=$?
		if (( ec == 0 )); then
			rm "${export_csv}"
		else
			error "  sql: ${export_csv}"
		fi
	done

	success "Complete"
}

galaxy_migrate-tool-install-from-sqlite() { ## [sqlite-db]: Converts SQLite version into normal potsgres toolshed repository tables
	handle_help "$@" <<-EOF
		    $ gxadmin migrate-tool-install-from-sqlite db.sqlite
		    Migrating tables
		      export: tool_shed_repository
		      import: tool_shed_repository
		      ...
		      export: repository_repository_dependency_association
		      import: repository_repository_dependency_association
		    Complete
	EOF
	assert_count $# 1 "Must provide database"

	success "Migrating tables"

	# Truncate first, since need to be removed in a specific ordering (probably
	# cascade would work but cascade is SCARY)
	psql -c "TRUNCATE TABLE repository_repository_dependency_association, repository_dependency, tool_dependency, migrate_tools, tool_version_association, tool_version, tool_shed_repository"
	ec1=$?

	# If you truncate this one, then it also removes galaxy codebase version,
	# breaking everything.
	psql -c "delete from migrate_version where repository_id = 'ToolShedInstall'"
	ec2=$?

	if (( ec1 == 0  && ec2 == 0 )); then
		success "  Cleaned"
	else
		error "  Failed to clean"
	fi

	# Then load data in same 'safe' order as in sqlite version
	for table in {migrate_version,tool_shed_repository,tool_version,tool_version_association,migrate_tools,tool_dependency,repository_dependency,repository_repository_dependency_association}; do
		success "  export: ${table}"
		export_csv=$(mktemp /tmp/tmp.gxadmin.${table}.XXXXXXXXXXX)

		if [[ "$table" == "tool_shed_repository" ]]; then
			# Might have json instead of hexencoded json
			sqlite3 -csv "$1" "select * from $table" | python -c "$hexencodefield9" > "$export_csv";
		elif [[ "$table" == "tool_version" ]]; then
			# Might have null values quoted as empty string
			sqlite3 -csv "$1" "select * from $table" | sed 's/""$//' > "$export_csv";
		else
			sqlite3 -csv "$1" "select * from $table" > "$export_csv";
		fi

		psql -c "COPY $table FROM STDIN with CSV" < "$export_csv";
		ec=$?

		if (( ec == 0 )); then
			rm "${export_csv}"
			success "  import: ${table}"
		else
			error "  csv: ${export_csv}"
			break
		fi
	done

	# Update sequences
	success "Updating sequences"
	for table in {tool_shed_repository,tool_version,tool_version_association,tool_dependency,repository_dependency,repository_repository_dependency_association}; do
		psql -c "SELECT setval('${table}_id_seq', (SELECT MAX(id) FROM ${table}));"
	done

	success "Comparing table counts"

	for table in {migrate_version,tool_shed_repository,tool_version,tool_version_association,migrate_tools,tool_dependency,repository_dependency,repository_repository_dependency_association}; do
		postgres=$(psql -c "COPY (select count(*) from $table) to STDOUT with CSV")
		sqlite=$(sqlite3 -csv "$1" "select count(*) from $table")

		if (( postgres == sqlite )); then
			success "  $table: $postgres == $sqlite"
		else
			error "  $table: $postgres != $sqlite"
		fi
	done

	success "Complete"
}

galaxy_amqp-test() { ## <amqp_url>: Test a given AMQP URL for connectivity
	handle_help "$@" <<-EOF
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

	EOF
	assert_count $# 1 "Must provide URL"

	URL="$1"

	script=$(cat <<EOF
from kombu import Connection
from kombu import Exchange

with Connection('$URL') as conn:
    print(conn.default_channel)
EOF
)

	python -c "$script"
}


galaxy_cleanup-jwd() { ## <working_dir> [1|months ago]: (NEW) Cleanup job working directories
	handle_help "$@" <<-EOF
		Scans through a provided job working directory subfolder, e.g.
		job_working_directory/ without the 005 subdir to find all folders which
		were changed less recently than N months.

		 Then it takes the first 1000 entries and cleans them up. This was more
		of a hack to handle the fact that the list produced by find is really
		long, and the for loop hangs until it's done generating the list.
	EOF

	assert_count_ge $# 1 "Must supply at least working dir"

	jwd=$1
	months=${2:-1}

	# scan a given directory for jwds.
	for possible_dir in $(find "$jwd" -maxdepth 3 -mindepth 3  -not -newermt "$months month ago" | grep -v _cleared_contents | head -n 1000); do
			job_id=$(basename "$possible_dir")
			if [[ "$job_id" =~ ^[0-9]{3,}$ ]]; then
					state=$(psql -c "COPY (select state from job where id = $job_id) to STDOUT with CSV")
					if [[ "$state" == "error" ]] || [[ "$state" == "ok" ]] || [[ "$state" == "deleted" ]] || [[ "$state" == "paused" ]] || [[ "$state" == "new_manually_dropped" ]]; then
							echo "- $possible_dir $job_id $state"
							rm -rf "$possible_dir"
					else
							echo "? $possible_dir $job_id $state"
					fi
			fi
	done
}

galaxy_fix-conda-env() { ## <conda_dir/envs/>: Fix broken conda environments
	handle_help "$@" <<-EOF
		Fixes any broken conda environments which are missing the activate scripts in their correct locations.

		MUST end in /envs/
	EOF

	conda_dir=$(dirname $1)

	for i in $(find ${conda_dir}/envs/ -mindepth 1 -maxdepth 1 -type d);
	do
		if [ ! -f $i/bin/conda ]; then
			${conda_dir}/bin/conda ..checkenv bash $i
		fi
	done
}

galaxy_fav_tools() { ## : Favourite tools in Galaxy DB
	handle_help "$@" <<-EOF
		What are people's fav tools
	EOF

	psql -qAt -c "select value::json->'tools' from user_preference where name = 'favorites'" | jq -s add | jq '. | @tsv' -r | sed 's/\t/\n/g' | sort | uniq -c | sort -n
}

galaxy_ie-list() { ## : List GIEs
	handle_help "$@" <<-EOF
		List running IEs (based on output of queue-detail)

		    $ gxadmin local ie-list
		    running  6134209  jupyter_notebook  helena-rasche

	EOF

	gxadmin query queue-detail  | grep interactive | awk -F'|' '{print $1" "$2" "$4" "$5}' | sed 's/interactive_tool_//g' | column -t
}

galaxy_ie-show() { ## [gie-galaxy-job-id]: Report on a GIE [HTCondor Only!]
	handle_help "$@" <<-EOF
		The new versions of IEs are IMPOSSIBLE to track down, so here's a handy
		function for you to make you hate life a lil bit less.


		    root@sn04:/opt/galaxy/server$ gxadmin local ie-show 6134209
		    Galaxy ID: 6134209
		    Condor ID: 1489026
		    Container: jupyter_notebook
		    Running on: cn032.bi.uni-freiburg.de
		    Job script: /data/dnb01/galaxy_db/pbs/galaxy_6134209.sh
		    Working dir: /data/dnb02/galaxy_db/job_working_directory/006/134/6134209
		    Container name: 20aa70fc1aa04d97bdc709a4c76dbcbd
		    Runtime:
		    {
		      8888: {
		        host: 132.230.68.65,
		        port: 1035,
		        protocol: tcp,
		        tool_port: 8888
		      }
		    }

		    Mapping
		    Key: aaaabbbbccccdddd
		    KeyType: interactivetoolentrypoint
		    Token: 00001111222233334444555566667777
		    URL: https://aaaabbbbccccdddd-00001111222233334444555566667777.interactivetoolentrypoint.interactivetool.usegalaxy.eu

		It's probably only going to work for us? Sorry :)
	EOF
	id=$1

	cluster_id=$(gxadmin jsonquery queue-detail | jq ".[] | select(.id == $1) | .extid" -r)
	cluster_id_c=$(echo -n "$cluster_id" | wc -c)
	echo "Galaxy ID: $id"
	echo "Condor ID: $cluster_id"
	if (( cluster_id_c  == 0 )); then
		exit 1
	fi

	container=$(condor_q $cluster_id -autoformat JobDescription | sed 's/interactive_tool_//g')
	echo "Container: $container"
	running_on=$(condor_q $cluster_id -autoformat RemoteHost | sed 's/.*@//g')
	echo "Running on: $running_on"

	job_script=$(condor_q $cluster_id -autoformat Cmd)
	echo "Job script: $job_script"

	working_dir=$(grep ^cd $job_script | sed 's/^cd //g')
	echo "Working dir: $working_dir"

	container_name=$(cat $working_dir/container_config.json | jq .container_name -r)
	echo "Container name: $container_name"

	echo "Runtime:"
	cat $working_dir/container_runtime.json  | jq -S

	port=$(cat $working_dir/container_runtime.json  | jq .[].port -r)
	host=$(cat $working_dir/container_runtime.json  | jq .[].host -r)

	echo
	echo "Mapping"

	token=$(gxadmin tsvquery q "select token from interactivetool_entry_point where job_id = $id")

	key=$(sqlite3 /opt/galaxy/mutable-config/interactivetools_map.sqlite 'select key from gxitproxy where token="'$token'"')
	key_type=$(sqlite3 /opt/galaxy/mutable-config/interactivetools_map.sqlite 'select key_type from gxitproxy where token="'$token'"')
	token=$(sqlite3 /opt/galaxy/mutable-config/interactivetools_map.sqlite 'select token from gxitproxy where token="'$token'"')

	echo "Key: $key"
	echo "KeyType: $key_type"
	echo "Token: $token"

	echo "URL: https://${key}-${token}.${key_type}.interactivetool.usegalaxy.eu"
}

