cleanup() { ## cleanup [days]: Cleanup histories/hdas/etc for past N days (default=30)
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
		python $GALAXY_ROOT/scripts/cleanup_datasets/pgcleanup.py \
			-c $GALAXY_CONFIG_FILE \
			-o $days \
			-l $GALAXY_LOG_DIR \
			-s $action \
			-w 128MB \
			 >> "$GALAXY_LOG_DIR/cleanup-${run_date}-${action}.log" \
			2>> "$GALAXY_LOG_DIR/cleanup-${run_date}-${action}.err";

		# Something that telegraf can consume
		ec=$?
		if (( ec == 0 )); then
			echo "cleanup_datasets,group=$action success=1"
		else
			echo "cleanup_datasets,group=$action success=0"
		fi
	done
}

migrate_to_sqlite() { ## migrate-tool-install-to-sqlite: Converts normal potsgres toolshed repository tables into the SQLite version
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
	" > ${empty_schema}
	sqlite3 galaxy_install.sqlite < ${empty_schema}
	rm ${empty_schema}

	success "Migrating tables"

	# tool_shed_repository is special :(
	table=tool_shed_repository
	success "  export: ${table}"
	export_csv=$(mktemp /tmp/tmp.gxadmin.${table}.XXXXXXXXXXX)
	psql -c "COPY (select
		id, create_time, update_time, tool_shed, name, description, owner, changeset_revision, case when deleted then 1 else 0 end, metadata, includes_datatypes, installed_changeset_revision, uninstalled, dist_to_shed, ctx_rev, status, error_message, tool_shed_status from $table) to STDOUT with CSV" > $export_csv;

	success "  import: ${table}"
	echo ".mode csv
.import ${export_csv} ${table}" | sqlite3 galaxy_install.sqlite
	if (( $? == 0 )); then
		rm ${export_csv}
	else
		error "  sql: ${export_csv}"
	fi

	sqlite3 galaxy_install.sqlite "insert into migrate_version values ('ToolShedInstall', 'lib/galaxy/model/tool_shed_install/migrate', 17)"
	# the rest are sane!
	for table in {tool_version,tool_version_association,migrate_tools,tool_dependency,repository_dependency,repository_repository_dependency_association}; do
		success "  export: ${table}"
		export_csv=$(mktemp /tmp/tmp.gxadmin.${table}.XXXXXXXXXXX)
		psql -c "COPY (select * from $table) to STDOUT with CSV" > $export_csv;

		success "  import: ${table}"
		echo ".mode csv
.import ${export_csv} ${table}" | sqlite3 galaxy_install.sqlite
		if (( $? == 0 )); then
			rm ${export_csv}
		else
			error "  sql: ${export_csv}"
		fi
	done

	success "Complete"
}


#mutate_fail_job() { # mutate fail-job <job-id>: Cause a specific job and all of its outputs to be marked as failing
	#handle_help "$@" <<-EOF
	#EOF

	#commit="ROLLBACK;"
	##if [[ $1 == "--commit" ]]; then
		##commit="COMMIT;"
	##fi

	#read -r -d '' QUERY <<-EOF
		#BEGIN TRANSACTION;

		#UPDATE dataset
		#SET
			#state = 'error'
		#WHERE id in (select id from dataset where )

		#UPDATE history_dataset_association
		#SET
			#blurb = 'execution error',
			#info = 'This dataset''s job failed and has been manually addressed by a Galaxy administrator. Please use the bug icon to report this if you need assistance.'
		#WHERE id in (select hda_id from terminal_jobs_temp)

		#$COMMIT
	#EOF
#}

mutate_fail_terminal_datasets() { ## mutate fail-terminal-datasets [--commit]: Causes the output datasets of jobs which were manually failed, to be marked as failed
	handle_help "$@" <<-EOF
		Whenever an admin marks a job as failed manually (e.g. by updating the
		state in the database), the output datasets are not accordingly updated
		by default. And this causes users to mistakenly think their jobs are
		still running when they have long since failed.

		This command provides a way to select those jobs in error states
		(deleted, deleted_new, error, error_manually_dropped,
		new_manually_dropped), find their associated output datasets, and fail
		them with a blurb mentionining that they should contact the admin in
		case of any question

		Running without any arguments will execute the command within a
		transaction and then roll it back, allowing you to see counts of rows
		and giving you an idea if it is doing the right thing.

		**WARNINGS**

		This does NOT currently work on collections

		**EXAMPLES**

		The process is to first query how many datasets will be failed, if this looks correct you're ready to go.

		    $ gxadmin mutate fail-terminal-datasets
		    BEGIN
		    SELECT 1
		    jobs_per_month_to_be_failed | count
		    -----------------------------+-------
		    2019-02-01 00:00:00         |     1
		    (1 row)

		    UPDATE 1
		    UPDATE 1
		    ROLLBACK

		Then to run with the --commit flag to commit the changes

		    $ gxadmin mutate fail-terminal-datasets --commit
		    BEGIN
		    SELECT 1
		    jobs_per_month_to_be_failed | count
		    -----------------------------+-------
		    2019-02-01 00:00:00         |     1
		    (1 row)

		    UPDATE 1
		    UPDATE 1
		    COMMIT
	EOF
	# TODO(hxr): support collections

	commit="ROLLBACK;"
	if [[ $1 == "--commit" ]]; then
		commit="COMMIT;"
	fi

	read -r -d '' QUERY <<-EOF
		BEGIN TRANSACTION;

		CREATE TEMP TABLE terminal_jobs_temp AS
			SELECT
				dataset.id as ds_id,
				history_dataset_association.id as hda_id,
				dataset.create_time AT TIME ZONE 'UTC' as ds_create
			FROM
				dataset,
				history_dataset_association,
				job_to_output_dataset,
				job
			WHERE
				dataset.id = history_dataset_association.dataset_id
				AND history_dataset_association.id = job_to_output_dataset.dataset_id
				AND job.id = job_to_output_dataset.job_id
				AND dataset.state IN ('queued', 'running')
				AND job.state
					IN ('deleted', 'deleted_new', 'error', 'error_manually_dropped', 'new_manually_dropped');

		SELECT date_trunc('month', ds_create) as jobs_per_month_to_be_failed, count(*) from terminal_jobs_temp group by jobs_per_month_to_be_failed;

		UPDATE dataset
		SET
			state = 'error'
		WHERE id in (select ds_id from terminal_jobs_temp);

		UPDATE history_dataset_association
		SET
			blurb = 'execution error',
			info = 'This dataset''s job failed and has been manually addressed by a Galaxy administrator. Please use the bug icon to report this if you need assistance.'
		WHERE id in (select hda_id from terminal_jobs_temp);

		$commit
	EOF
}

