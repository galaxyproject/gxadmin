registered_subcommands="$registered_subcommands mutate"
_mutate_short_help="mutate:  DB Mutations, CSV/TSV queries are NOT available"

should_commit() {
	if [[ $1 == "--commit" ]]; then
		printf "COMMIT;"
	else
		printf "ROLLBACK;"
	fi
}

mutate_fail-terminal-datasets() { ## [--commit]: Causes the output datasets of jobs which were manually failed, to be marked as failed
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

		!> This does NOT currently work on collections

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

	read -r -d '' QUERY <<-EOF
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
				AND dataset.state IN ('queued', 'running', 'new')
				AND job.state
					IN ('deleted', 'deleted_new', 'error', 'error_manually_dropped', 'new_manually_dropped');

		SELECT
			date_trunc('month', ds_create) as jobs_per_month_to_be_failed, count(*)
		FROM terminal_jobs_temp
		GROUP BY jobs_per_month_to_be_failed
		ORDER BY date_trunc('month', ds_create) desc;

		UPDATE dataset
		SET
			state = 'error'
		WHERE id in (select ds_id from terminal_jobs_temp);

		UPDATE history_dataset_association
		SET
			blurb = 'execution error',
			info = 'This dataset''s job failed and has been manually addressed by a Galaxy administrator. Please use the bug icon to report this if you need assistance.'
		WHERE id in (select hda_id from terminal_jobs_temp)
	EOF

	commit=$(should_commit "$1")
	QUERY="BEGIN TRANSACTION; $QUERY; $commit"
}

mutate_fail-job() { ## <job_id> [--commit]: Sets a job state to error
	handle_help "$@" <<-EOF
		Sets a job's state to "error"
	EOF

	assert_count_ge $# 1 "Must supply a job ID"
	id=$1

	read -r -d '' QUERY <<-EOF
		UPDATE
			job
		SET
			state = 'error'
		WHERE
			id = '$id'
	EOF

	commit=$(should_commit "$2")
	QUERY="BEGIN TRANSACTION; $QUERY; $commit"
}

mutate_fail-history() { ## <history_id> [--commit]: Mark all jobs within a history to state error
	handle_help "$@" <<-EOF
		Set all jobs within a history to error
	EOF

	assert_count_ge $# 1 "Must supply a history ID"
	id=$1

	read -r -d '' QUERY <<-EOF
		SELECT
			id, state
		FROM
			job
		WHERE
			id
			IN (
					SELECT
						job_id
					FROM
						job_to_output_dataset
					WHERE
						dataset_id
						IN (
								SELECT
									id
								FROM
									history_dataset_association
								WHERE
									history_id = $1
							)
				)
			AND state NOT IN ('ok', 'error')
	EOF

	commit=$(should_commit "$2")
	QUERY="BEGIN TRANSACTION; $QUERY; $commit"
}

mutate_delete-group-role() { ## <group_name> [--commit]: Remove the group, role, and any user-group + user-role associations
	handle_help "$@" <<-EOF
		Wipe out a group+role, and user associations.
	EOF

	assert_count_ge $# 1 "Must supply a group name"
	id=$1

	read -r -d '' QUERY <<-EOF
		DELETE FROM group_role_association
		WHERE group_id = (SELECT id FROM galaxy_group WHERE name = '$1');

		DELETE FROM user_group_association
		WHERE group_id = (SELECT id FROM galaxy_group WHERE name = '$1');

		DELETE FROM user_role_association
		WHERE role_id = (SELECT role_id FROM group_role_association WHERE group_id= (SELECT id FROM galaxy_group WHERE name = '$1'));

		DELETE FROM role
		WHERE id = (SELECT role_id FROM group_role_association WHERE group_id = (SELECT id FROM galaxy_group WHERE name = '$1'));

		DELETE FROM galaxy_group
		WHERE name = '$1'
	EOF

	commit=$(should_commit "$2")
	QUERY="BEGIN TRANSACTION; $QUERY; $commit"
}

mutate_assign-unassigned-workflows() { ## <handler_prefix> <handler_count> [--commit]: Randomly assigns unassigned workflows to handlers. Workaround for galaxyproject/galaxy#8209
	handle_help "$@" <<-EOF
		Workaround for https://github.com/galaxyproject/galaxy/issues/8209

		Handler names should have number as postfix, so "some_string_##". In
		this case handler_prefix is "some_string_" and count is however many
		handlers you want to schedule workflows across.
	EOF

	assert_count_ge $# 1 "Must supply a handler_prefix"
	assert_count_ge $# 2 "Must supply a count"

	prefix=$1
	count=$2

	read -r -d '' QUERY <<-EOF
		UPDATE workflow_invocation
		SET handler = '$prefix' || (random() * $count)::integer
		WHERE state = 'new' and handler = '_default_'
		RETURNING workflow_invocation.id
	EOF

	commit=$(should_commit "$3")
	QUERY="BEGIN TRANSACTION; $QUERY; $commit"
}

mutate_reassign-workflows-to-handler() { ## <handler_from> <handler_to> [--commit]: Reassign workflows in 'new' state to a different handler.
	handle_help "$@" <<-EOF
		Another workaround for https://github.com/galaxyproject/galaxy/issues/8209

		Need to use the full handler names e.g. handler_main_0
	EOF

	assert_count_ge $# 1 "Must supply a handler_from"
	assert_count_ge $# 2 "Must supply a handler_to"

	read -r -d '' QUERY <<-EOF
		UPDATE workflow_invocation
		SET handler = '$2'
		WHERE state = 'new' and handler = '$1'
		RETURNING workflow_invocation.id
	EOF

	commit=$(should_commit "$3")
	QUERY="BEGIN TRANSACTION; $QUERY; $commit"
}

mutate_approve-user() { ## <username|email|user_id>: Approve a user in the database
	handle_help "$@" <<-EOF
		There is no --commit flag on this because it is relatively safe
	EOF

	assert_count_ge $# 1 "Must supply a username/email/user-id"

	user_filter="(galaxy_user.email = '$1' or galaxy_user.username = '$1' or galaxy_user.id = CAST(REGEXP_REPLACE(COALESCE('$1','0'), '[^0-9]+', '0', 'g') AS INTEGER))"

	read -r -d '' QUERY <<-EOF
		UPDATE galaxy_user
		SET active = true
		WHERE $user_filter
	EOF
}

mutate_oidc-role-find-affected() { ## : Find users affected by galaxyproject/galaxy#8244
	handle_help "$@" <<-EOF
		Workaround for https://github.com/galaxyproject/galaxy/issues/8244

		This finds all of the OIDC authenticated users which do not have any
		roles associated to them. (Should be sufficient?)
	EOF

	read -r -d '' QUERY <<-EOF
		SELECT
			user_id
		FROM
			oidc_user_authnz_tokens AS ouat
		WHERE
			ouat.user_id NOT IN (SELECT user_id FROM user_role_association)
	EOF

	# Not proud of this.
	FLAVOR='tsv'
}

mutate_oidc-role-fix() { ## <username|email|user_id>: Fix permissions for users logged in via OIDC. Workaround for galaxyproject/galaxy#8244
	handle_help "$@" <<-EOF
		Workaround for https://github.com/galaxyproject/galaxy/issues/8244
	EOF

	# Coerce to user ID
	read -r -d '' qstr <<-EOF
		SELECT id, email FROM galaxy_user WHERE (galaxy_user.email = '$1' or galaxy_user.username = '$1' or galaxy_user.id = CAST(REGEXP_REPLACE(COALESCE('$1','0'), '[^0-9]+', '0', 'g') AS INTEGER))
	EOF
	echo "QUERY: $qstr"
	results="$(query_tsv "$qstr")"
	echo "RESULTS: $results"
	user_id=$(echo "$results" | awk '{print $1}')
	email=$(echo "$results" | awk '{print $2}')


	# check if there is an existing role.
	read -r -d '' qstr <<-EOF
		select count(*) from user_role_association left join role on user_role_association.role_id = role.id where user_id = $user_id and role.type = 'private'
	EOF
	echo "QUERY: $qstr"
	results="$(query_tsv "$qstr")"
	echo "RESULTS: $results"

	# Some (mild) sanity checking. Should probably wrap this up in some nice.
	if (( results != 0 )); then
		error "A default private role already exists for this account."
		exit 1
	fi


	# Create the role since it does not exist
	read -r -d '' qstr <<-EOF
		INSERT INTO role (create_time, update_time, name, description, type, deleted)
		VALUES (now(), now(), '$email', 'Private Role for $email', 'private', false)
		RETURNING id
	EOF
	echo "QUERY: $qstr"
	role_id="$(query_tsv "$qstr")"
	echo "RESULTS: $results"

	# Associate with the user
	read -r -d '' qstr <<-EOF
		INSERT INTO user_role_association (user_id, role_id, create_time, update_time)
		VALUES ($user_id, $role_id, now(), now())
	EOF
	echo "QUERY: $qstr"
	query_tbl "$qstr"

	# Insert into their personal default user permissions
	read -r -d '' qstr <<-EOF
		INSERT INTO default_user_permissions (user_id, action, role_id)
		VALUES ($user_id, 'manage permissions', $role_id), ($user_id, 'access', $role_id)
	EOF
	echo "QUERY: $qstr"
	results="$(query_tbl "$qstr")"
	echo "RESULTS: $results"

	# Fix dataset_permissions. Manage rows are created but have a null entry in their role_id
	read -r -d '' qstr <<-EOF
		UPDATE dataset_permissions
		SET role_id = $role_id
		WHERE
			id
			IN (
					SELECT
						id
					FROM
						dataset_permissions
					WHERE
						dataset_id
						IN (
								SELECT
									ds.id
								FROM
									history AS h
									LEFT JOIN history_dataset_association AS hda ON
											h.id = hda.history_id
									LEFT JOIN dataset AS ds ON hda.dataset_id = ds.id
								WHERE
									h.user_id = $user_id
							)
						AND role_id IS NULL
						AND action = 'manage permissions'
				)
	EOF
	echo "QUERY: $qstr"
	results="$(query_tbl "$qstr")"
	echo "RESULTS: $results"

	# We could update history permissions but this would make those histories
	# private and the current behaviour is that they're public, if the user has
	# tried to share, then we'd be changing permissions and going against user
	# expectations.
	read -r -d '' QUERY <<-EOF
		select 'done'
	EOF
}

mutate_reassign-job-to-handler() { ## <job_id> <handler_id> [--commit]: Reassign a job to a different handler
	handle_help "$@" <<-EOF
	EOF

	assert_count_ge $# 2 "Must supply a job and handler ID"
	job_id=$1
	handler_id=$2

	read -r -d '' QUERY <<-EOF
		UPDATE
			job
		SET
			handler = '$handler_id'
		WHERE
			job.id = $job_id
	EOF

	commit=$(should_commit "$3")
	QUERY="BEGIN TRANSACTION; $QUERY; $commit"
}

mutate_drop-extraneous-workflow-step-output-associations() { ## [--commit]: #8418, drop extraneous connection
	handle_help "$@" <<-EOF
		Per https://github.com/galaxyproject/galaxy/pull/8418, this drops the
		workflow step output associations that are not necessary.

		This only needs to be run once, on servers which have run Galaxy<=19.05
		to remove duplicate entries in the following tables:

		- workflow_invocation_step_output_dataset_association
		- workflow_invocation_step_output_dataset_collection_association
	EOF

	read -r -d '' QUERY <<-EOF
		WITH exclude_list AS (
			SELECT max(w.id) as id
			FROM workflow_invocation_step_output_dataset_association as w
			GROUP BY workflow_invocation_step_id, dataset_id, output_name
		)

		DELETE
		FROM workflow_invocation_step_output_dataset_association wisoda
		WHERE NOT EXISTS (SELECT 1 FROM exclude_list WHERE wisoda.id = exclude_list.id);


		WITH exclude_list AS (
			SELECT max(w.id) as id
			FROM workflow_invocation_step_output_dataset_collection_association as w
			GROUP BY workflow_invocation_step_id, dataset_collection_id, output_name
		)

		DELETE
		FROM workflow_invocation_step_output_dataset_collection_association wisodca
		WHERE NOT EXISTS (SELECT 1 FROM exclude_list WHERE wisodca.id = exclude_list.id)
	EOF

	commit=$(should_commit "$1")
	QUERY="BEGIN TRANSACTION; $QUERY; $commit"
}

mutate_restart-jobs() { ## [--commit] <-|job_id [job_id [...]]> : Restart some jobs
	handle_help "$@" <<-EOF
		Restart jobs
	EOF

	commit_flag=""
	if [[ $1 == "--commit" ]]; then
		commit_flag="$1"
		shift;
	fi

	if [[ "$1" == "-" ]]; then
		# read jobs from stdin
		job_ids=$(cat | paste -s -d' ')
	else
		# read from $@
		job_ids=$@;
	fi

	job_ids_string=$(join_by ',' ${job_ids[@]})

	read -r -d '' QUERY <<-EOF
		UPDATE job
		SET state = 'new'
		WHERE job.id in ($job_ids_string)
	EOF

	commit=$(should_commit "$commit_flag")
	QUERY="BEGIN TRANSACTION; $QUERY; $commit"
}

mutate_generate-unset-api-keys() { ## [--commit]: Generate API keys for users which do not have one set.
	handle_help "$@" <<-EOF
		For some use cases (IEs), it is preferrable that everyone has an API
		key set for them, if they don't choose to set one themselves. So we set
		a base64'd key to be a bit extra secure just in case. These work just
		fine like hex keys.
	EOF

	commit_flag=""
	if [[ $1 == "--commit" ]]; then
		commit_flag="$1"
		shift;
	fi

	read -r -d '' QUERY <<-EOF
		INSERT INTO api_keys (create_time, user_id, key)
		(
			SELECT
				now(),
				galaxy_user.id,
				substring(regexp_replace(encode(random_bytea(64), 'base64')::TEXT, '[^a-z0-9A-Z]', '', 'g'), 0, 32)
			FROM
				galaxy_user LEFT JOIN api_keys ON galaxy_user.id = api_keys.user_id
			WHERE
				api_keys.key IS NULL
		)
	EOF

	commit=$(should_commit "$commit_flag")
	QUERY="BEGIN TRANSACTION; $QUERY; $commit"

}


mutate-anonymise-db-for-release() { ## : This will attempt to make a database completely safe to release publicly.
	handle_help "$@" <<-EOF
		THIS WILL DESTROY YOUR DATABASE.
	EOF

	commit_flag=""
	if [[ $1 == "--commit" ]]; then
		commit_flag="$1"
		shift;
	fi

	read -r -d '' QUERY <<-EOF
		-- api_keys
			update api_keys set key = 'random-key-' || user_id;

		-- cleanup_event_user_association empty on EU
		-- cloudauthz                     empty on EU
		-- custos_authnz_token            empty on EU

		-- dataset
		-- TODO: Do external_filename, and _extra_files_path need to be cleaned?
		-- TODO: this is imperfect, we do something better in GRT where we take 2 SDs
		-- https://stackoverflow.com/questions/48900936/postgresql-rounding-to-significant-figures
		-- MAYBE use synthetic data here?
			update dataset set
				file_size = round(file_size, -3),
				total_size = round(total_size, -3);

		-- dataset_collection is OK
		-- dataset_collection_element
			update dataset_collection_element set
				element_identifier = random() -- TODO: better distribution. Unicode.

		-- dataset_hash                   empty on EU
		-- dataset_permissions            is OK
		-- dataset_source
			update dataset_source set
				source_uri = 'https://example.org';

		-- dataset_source_hash            empty on EU
		-- dataset_tag_association        empty on EU
		-- default_history_permissions    is OK (hist_id, action, role_id)
		-- default_quota_association      is OK
		-- default_user_permissions       is OK(user, action, role)
		-- deferred_job                   empty on EU
		-- deferred_job                   empty on EU
		-- event                          empty on EU
		-- extended_metadata              empty on EU
		-- extended_metadata_index        empty on EU
		-- external_service               empty on EU
		-- form_definition                empty on EU
		-- form_definition_current        empty on EU
		-- form_values                    empty on EU
		-- galaxy_group
			update galaxy_group set
				name = 'group-' || id;

		-- galaxy_session
			update galaxy_session set
				remote_host = 'www.xxx.yyy.zzz'
				when remote_host is not null;
			update galaxy_session set
				remote_addr = 'www.xxx.yyy.zzz'
				when remote_addr is not null;
			update galaxy_session set
				referer = 'https://example.org'
				when referer is not null;

			update galaxy_session set
				session_key = '', prev_session_id = '';

		-- galaxy_session_to_history is OK (time, session_id, hist_id)
		-- galaxy_user

			-- TODO: better email length/content distribution
			-- TODO: better username length/content distribution. UNICODE.
			-- TODO: rounding to SDs.
			update galaxy_user set
				email = 'user-' || id || '@example.org',
				username = 'user-' || id,
				disk_usage = round(disk_usage, -5)

		-- galaxy_user_openid empty on EU
		-- genome_index_tool_data empty on EU
		-- group_quota_association is OK (group_id, quota id)
		-- group_role_association is OK (group_id, role id)
		-- history
			-- TODO: better name distribution. UNICODE. (I see greek, chinese, etc on EU)
			update history set
				name = 'history-' || id;

			update history set
				slug = 'slug-' || id
				when slug != '' or slug is not null;

		-- history_annotation_association
			-- TODO: better distribution. UNICODE.
			update history_annotation_association set
				annotation = 'something'
				when annotation is not null;

		-- history_dataset_association
			-- TODO: SIGNIFICANT validation needed.
			update history_dataset_association set
				name = 'hda-' || id,
				peek = 'redacted',
				metadata = null,
				designation = '';

		-- history_dataset_association_annotation_association
			-- TODO: distribution
			update history_dataset_association_annotation_association set
				annotation = '';

		-- history_dataset_association_display_at_authorization UNKNOWN. site is in Ucscmain/archae/test on EU. nothing else incriminating.

		-- history_dataset_association_history
			-- TODO: distribution. Consistency with HDA?
			update history_dataset_association_history set
				name = 'hda-' || history_dataset_association_id,
				metadata = null,
				extended_metadata_id = null;

		-- history_dataset_association_rating_association    empty on EU
		-- history_dataset_association_subset                empty on EU
		-- history_dataset_association_tag_association
		    -- TODO: distribution, unicode, name: vs group: vs none.

			update history_dataset_association_tag_association set
				user_tname = 'tag-' || id,
				value = 'tag-' || id,
				user_value = 'tag-' || id;

		-- history_dataset_collection_annotation_association empty on EU
		-- history_dataset_collection_association
			-- TODO: distribution, etc.
			-- implicit_output_name ??
			update history_dataset_collection_association set
				name = 'hdca-' || id;


		-- history_dataset_collection_rating_association     empty on EU
		-- history_dataset_collection_tag_association
		    -- TODO: distribution, unicode, name: vs group: vs none.

			update history_dataset_collection_tag_association set
				user_tname = 'tag-' || id,
				value = 'tag-' || id,
				user_value = 'tag-' || id;

		-- history_rating_association                  is OK
		-- history_tag_association
		    -- TODO: distribution, unicode, name: vs group: vs none.

			update history_tag_association set
				user_tname = 'tag-' || id,
				value = 'tag-' || id,
				user_value = 'tag-' || id;

		-- history_user_share_association is OK (hist_id, user_id)
		-- implicit_collection_jobs is OK (id, pop state)
		-- implicit_collection_jobs_job_association is OK
		-- implicitly_converted_dataset_association is OK
		-- implicitly_created_dataset_collection_inputs is OK
		-- interactivetool_entry_point

			-- TODO: fix disributions? Meh.
			update interactivetool_entry_point set
				name = 'NAME',
				token = 'token-' || job_id,
				host = '',
				port = '',
				protocol = '',
				entry_url = '',
				info = null;

		-- job
			-- TODO: anonymize tool IDs?
			update job set
				command_line = 'redacted',
				destination_params = null,
				dependencies = null;

			update job set
				tool_stdout = 'redacted'
				where tool_stdout != null;

			update job set
				tool_stderr = 'redacted'
				where tool_stderr != null;

			update job set
				traceback = 'redacted'
				where traceback != null;

			update job set
				params = 'redacted'
				where params != null;

			update job set
				job_messages = 'redacted'
				where job_messages != null;

			update job set
				job_stdout = 'redacted'
				where job_stdout != null;

			update job set
				job_stderr = 'redacted'
				where job_stderr != null;

		-- job_container_association
			update job_container_association set
				container_name = '',
				container_info = '';

		-- job_export_history_archive
			update job_export_history_archive set
				history_attrs_filename = '/tmp/does-not-exist',
				datasets_attrs_filename = '/tmp/does-not-exist',
				jobs_attrs_filename = '/tmp/does-not-exist';

		-- job_external_output_metadata
			update job_external_output_metadata set
				filename_in  = '/tmp/does-not-exist',
				filename_out = '/tmp/does-not-exist',
				filename_results_code = '/tmp/does-not-exist',
				filename_kwds = '/tmp/does-not-exist',
				filename_override_metadata = '/tmp/does-not-exist',

		-- job_import_history_archive
			update job_import_history_archive set
				archive_dir = '/tmp/dne';

		-- job_metric_numeric is OK
		-- job_metric_text
			truncate job_metric_text;

		-- job_parameter
			-- TODO: length distribution? Name distribution?
			update job_parameter set
				name = 'param-name',
				value = 'param-value';

		-- job_state_history
		-- job_to_implicit_output_dataset_collection

			update job_to_implicit_output_dataset_collection set
				name = 'jtiodc-' || id;

		-- job_to_input_dataset
			update job_to_input_dataset set
				name = 'jtid-' || id;

		-- library_dataset_collection_annotation_association empty on EU
		-- library_dataset_collection_association            empty on EU
		-- library_dataset_collection_rating_association     empty on EU
		-- library_dataset_collection_tag_association        empty on EU
		-- library_dataset_dataset_info_association          empty on EU
		-- library_folder_info_association                   empty on EU
		-- migrate_tools                                     empty on EU
		-- migrate_version                                   empty on EU
		-- page_tag_association                              empty on EU
		-- psa_code                                          empty on EU
		-- psa_nonce                                         empty on EU
		-- psa_partial                                       empty on EU
		-- request                                           empty on EU
		-- request_event                                     empty on EU
		-- request_type                                      empty on EU
		-- request_type_external_service_association         empty on EU
		-- request_type_permissions                          empty on EU
		-- request_type_run_association                      empty on EU
		-- run                                               empty on EU
		-- sample                                            empty on EU
		-- sample_dataset                                    empty on EU
		-- sample_event                                      empty on EU
		-- sample_run_association                            empty on EU
		-- sample_state                                      empty on EU
		-- task_metric_text                                  empty on EU
		-- tool_tag_association                              empty on EU
		-- transfer_job                                      empty on EU
		-- user_action                                       empty on EU
		-- visualization_rating_association                  empty on EU
		-- workflow_tag_association                          empty on EU













	EOF



	commit=$(should_commit "$commit_flag")
	QUERY="BEGIN TRANSACTION; $QUERY; $commit"

}
