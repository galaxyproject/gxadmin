registered_subcommands="$registered_subcommands mutate"
_mutate_short_help="DB Mutations, CSV/TSV queries are NOT available"

txn_prefix() {
	if [[ "$1" == "--very-unsafe" ]]; then
		printf "";
	else
		printf "BEGIN TRANSACTION;\n"
	fi
}

txn_postfix() {
	if [[ "$1" == "--commit" ]] || [[ "$1" == "1" ]]; then
		printf "\nCOMMIT;\n"
	elif [[ "$1" == "--very-unsafe" ]]; then
		printf "";
	else
		printf "\nROLLBACK;\n"
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

	txn_pre=$(txn_prefix "$1")
	txn_pos=$(txn_postfix "$1")
	QUERY="$txn_pre $QUERY; $txn_pos"
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

	txn_pre=$(txn_prefix  "$2")
	txn_pos=$(txn_postfix "$2")
	QUERY="$txn_pre $QUERY; $txn_pos"
}

mutate_fail-history() { ## <history_id> [--commit]: Mark all jobs within a history to state error
	meta <<-EOF
		ADDED: 12
	EOF
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

	txn_pre=$(txn_prefix  "$2")
	txn_pos=$(txn_postfix "$2")
	QUERY="$txn_pre $QUERY; $txn_pos"
}

mutate_delete-group-role() { ## <group_name> [--commit]: Remove the group, role, and any user-group + user-role associations
	meta <<-EOF
		ADDED: 12
	EOF
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

	txn_pre=$(txn_prefix  "$2")
	txn_pos=$(txn_postfix "$2")
	QUERY="$txn_pre $QUERY; $txn_pos"
}

mutate_assign-unassigned-workflows() { ## <handler_prefix> <handler_count> [--commit]: Randomly assigns unassigned workflows to handlers. Workaround for galaxyproject/galaxy#8209
	meta <<-EOF
		ADDED: 13
	EOF
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

	txn_pre=$(txn_prefix  "$3")
	txn_pos=$(txn_postfix "$3")
	QUERY="$txn_pre $QUERY; $txn_pos"
}

mutate_reassign-workflows-to-handler() { ## <handler_from> <handler_to> [--commit]: Reassign workflows in 'new' state to a different handler.
	meta <<-EOF
		ADDED: 14
	EOF
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

	txn_pre=$(txn_prefix  "$3")
	txn_pos=$(txn_postfix "$3")
	QUERY="$txn_pre $QUERY; $txn_pos"
}

mutate_reassign-active-workflows-to-handler() { ## <handler_from> <handler_to> [--commit]: Reassign workflows with state 'scheduled' or 'new' to a different handler.
	meta <<-EOF
		ADDED: 20
	EOF
	handle_help "$@" <<-EOF
		Another workaround for https://github.com/galaxyproject/galaxy/issues/8209

		Need to use the full handler names e.g. handler_main_0
	EOF

	assert_count_ge $# 1 "Must supply a handler_from"
	assert_count_ge $# 2 "Must supply a handler_to"

	read -r -d '' QUERY <<-EOF
		UPDATE workflow_invocation
		SET handler = '$2'
		WHERE (state = 'scheduled' or state = 'new' or state = 'ready') and handler = '$1'
		RETURNING workflow_invocation.id
	EOF

	txn_pre=$(txn_prefix  "$3")
	txn_pos=$(txn_postfix "$3")
	QUERY="$txn_pre $QUERY; $txn_pos"
}

mutate_approve-user() { ## <username|email|user_id>: Approve a user in the database
	meta <<-EOF
		ADDED: 13
	EOF
	handle_help "$@" <<-EOF
		There is no --commit flag on this because it is relatively safe
	EOF

	assert_count_ge $# 1 "Must supply a username/email/user-id"

	user_filter=$(get_user_filter "$1")

	read -r -d '' QUERY <<-EOF
		UPDATE galaxy_user
		SET active = true
		WHERE $user_filter
	EOF
}

mutate_oidc-role-find-affected() { ## : Find users affected by galaxyproject/galaxy#8244
	meta <<-EOF
		ADDED: 13
	EOF
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
	meta <<-EOF
		ADDED: 13
	EOF
	handle_help "$@" <<-EOF
		Workaround for https://github.com/galaxyproject/galaxy/issues/8244
	EOF

	user_filter=$(get_user_filter "$1")

	# Coerce to user ID
	read -r -d '' qstr <<-EOF
		SELECT id, email
		FROM galaxy_user
		WHERE $user_filter
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
	meta <<-EOF
		ADDED: 14
	EOF
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

	txn_pre=$(txn_prefix  "$3")
	txn_pos=$(txn_postfix "$3")
	QUERY="$txn_pre $QUERY; $txn_pos"
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

	txn_pre=$(txn_prefix  "$1")
	txn_pos=$(txn_postfix "$1")
	QUERY="$txn_pre $QUERY; $txn_pos"
}

mutate_restart-jobs() { ## [--commit] <-|job_id [job_id [...]]> : Restart some jobs
	meta <<-EOF
		ADDED: 15
	EOF
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

	# shellcheck disable=SC2068
	job_ids_string=$(join_by ',' ${job_ids[@]})

	read -r -d '' QUERY <<-EOF
		UPDATE job
		SET state = 'new'
		WHERE job.id in ($job_ids_string)
	EOF

	txn_pre=$(txn_prefix  "$commit_flag")
	txn_pos=$(txn_postfix "$commit_flag")
	QUERY="$txn_pre $QUERY; $txn_pos"
}

mutate_generate-unset-api-keys() { ## [--commit]: Generate API keys for users which do not have one set.
	meta <<-EOF
		ADDED: 15
	EOF
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

	txn_pre=$(txn_prefix  "$commit_flag")
	txn_pos=$(txn_postfix "$commit_flag")
	QUERY="$txn_pre $QUERY; $txn_pos"

}

mutate_anonymise-db-for-release() { ## [--commit|--very-unsafe]: This will attempt to make a database completely safe to release publicly.
	meta <<-EOF
		ADDED: 17
	EOF
	handle_help "$@" <<-EOF
		THIS WILL DESTROY YOUR DATABASE.

		--commit will do it and wrap it in a transaction
		--very-unsafe will just run it without the transaction
	EOF

	commit_flag=""
	if [[ "$1" == "--commit" ]] || [[ "$1" == "--very-unsafe" ]]; then
		commit_flag="$1"
		shift;
	fi

	read -r -d '' QUERY <<-EOF
--DONE
		CREATE OR REPLACE FUNCTION gxadmin_digest_value(input text)
		RETURNS float
		AS \$\$
			SELECT
				('0.' || abs(('x' || substr(md5(current_date ||input::text),1,16))::bit(64)::bigint))::float
		\$\$ LANGUAGE SQL STABLE;

--DONE
		CREATE OR REPLACE FUNCTION gxadmin_random_seed(input text, size integer)
		RETURNS table(value float)
		AS \$\$
			SELECT gxadmin_digest_value(input::text || generate_series) as value
			FROM generate_series(1, size)
		\$\$ LANGUAGE SQL STABLE;

-- DONE
		CREATE OR REPLACE FUNCTION gxadmin_random_number(input text, size integer)
		RETURNS integer
		AS \$\$
			SELECT (power(10, size) * gxadmin_digest_value(input))::integer
		\$\$ LANGUAGE SQL IMMUTABLE;

-- DONE
		CREATE OR REPLACE FUNCTION gxadmin_random_word(input text, size integer)
		RETURNS text
		AS \$\$
			SELECT array_to_string(
				ARRAY(
					SELECT chr((97 + round(value * 25)) :: integer)
					FROM gxadmin_random_seed(input, size)
				),
				''
			);
		\$\$ LANGUAGE SQL STABLE;

-- DONE
		CREATE OR REPLACE FUNCTION gxadmin_random_slug(input text, size integer)
		RETURNS text
		AS \$\$
			SELECT
				substr(
					gxadmin_random_word(input || 'a' || size, 5 + (gxadmin_digest_value(input || 'a' || size) * size)::integer)
					|| '-' ||
					gxadmin_random_word(input || 'b' || size, 3 + (gxadmin_digest_value(input || 'b' || size) * size)::integer)
					|| '-' ||
					gxadmin_random_word(input || 'c' || size, 4 + (gxadmin_digest_value(input || 'c' || size) * size)::integer)
				, 1, size)
		\$\$ LANGUAGE SQL STABLE;

-- DONEish
		CREATE OR REPLACE FUNCTION gxadmin_random_email(input text)
		RETURNS text
		AS \$\$
			with tmp as (
				select gxadmin_digest_value(input) as a
			)
			SELECT
				CASE
					WHEN a < 0.3 THEN gxadmin_random_number(input, 7) || '@example.com'
					WHEN a < 0.8 THEN gxadmin_random_slug(input, 6) || '@example.com'
					ELSE gxadmin_random_slug(input, 20) || '@example.com'
				END
			from tmp
		\$\$ LANGUAGE SQL STABLE;

-- DONE
		CREATE OR REPLACE FUNCTION gxadmin_random_ip(input text)
		RETURNS text
		AS \$\$
			-- Uses documentation range IPs
			with tmp as (
				select gxadmin_digest_value(input::text) as a
			)
			SELECT
				CASE
					WHEN a < 0.7 THEN '192.0.2.' || (gxadmin_digest_value(input) * 255)::integer
					ELSE '2001:0db8:85a3:8d3:1319:8a2e:0370:' || to_hex((gxadmin_digest_value(input) * 65536)::integer)
				END
			from tmp
		\$\$ LANGUAGE SQL STABLE;

-- DONE
		CREATE OR REPLACE FUNCTION gxadmin_random_string(input text, size integer, start integer, width integer)
		RETURNS text
		AS \$\$
			SELECT array_to_string(
				ARRAY(
					SELECT chr((start + round(value * width)) :: integer)
					FROM gxadmin_random_seed(input, size)
				),
				''
			);
		\$\$ LANGUAGE SQL STABLE;

-- DONE
		CREATE OR REPLACE FUNCTION gxadmin_random_tag(input text)
		RETURNS text
		AS \$\$
			with tmp as (
				select gxadmin_digest_value(input) as a
			)
			SELECT
				CASE
					WHEN a < 0.1 THEN gxadmin_random_string(input, 3 + gxadmin_random_number(input, 1), 65, 26)
					WHEN a < 0.2 THEN gxadmin_random_string(input, 3 + gxadmin_random_number(input, 1), 192, 200)
					WHEN a < 0.3 THEN gxadmin_random_string(input, 3 + gxadmin_random_number(input, 1), 1025, 100)
					WHEN a < 0.4 THEN gxadmin_random_string(input, 3 + gxadmin_random_number(input, 1), 5121, 200)
					WHEN a < 0.5 THEN gxadmin_random_string(input, 3 + gxadmin_random_number(input, 1), 9728, 400)
					WHEN a < 0.6 THEN gxadmin_random_string(input, 3 + gxadmin_random_number(input, 1), 14300, 100)
					WHEN a < 0.8 THEN gxadmin_random_slug(input, 3 + gxadmin_random_number(input, 1))
					ELSE gxadmin_random_string(input, 3 + gxadmin_random_number(input, 1), 48, 10)
				END
			from tmp
		\$\$ LANGUAGE SQL;

-- DONE
		CREATE OR REPLACE FUNCTION gxadmin_random_pw(input text, size integer)
		RETURNS text
		AS \$\$
			SELECT gxadmin_random_string(input, size, 48, 59);
		\$\$ LANGUAGE SQL STABLE;

-- DONE
		CREATE OR REPLACE FUNCTION gxadmin_random_text(input text, size integer)
		RETURNS text
		AS \$\$
			SELECT array_to_string(
				ARRAY(
					SELECT gxadmin_random_tag(input || generate_series)
					FROM generate_series(1, size)
				),
				' '
			);
		\$\$ LANGUAGE SQL;

-- DONE
		-- https://stackoverflow.com/a/48901446
		CREATE OR REPLACE FUNCTION gxadmin_round_sf(n numeric, digits integer)
		RETURNS numeric
		AS \$\$
			SELECT floor(n / (10 ^ floor(log(n) - digits + 1))) * (10 ^ floor(log(n) - digits + 1))
		\$\$ LANGUAGE SQL IMMUTABLE STRICT;


		-- api_keys
		COPY (SELECT 'api_keys') to STDOUT;
			update api_keys set key = 'random-key-' || user_id;

		-- cleanup_event                                        is OK
		-- cleanup_event_dataset_association                    is OK
		-- cleanup_event_hda_association                        is OK
		-- cleanup_event_his tory_association                   is OK
		-- cleanup_event_icda_association                       is OK
		-- cleanup_event_ldda_association                       is EMPTY on AU
		-- cleanup_event_library_association                    is EMPTY on AU
		-- cleanup_event_library_dataset_association            is EMPTY on AU
		-- cleanup_event_library_folder_association             is EMPTY on AU
		-- cleanup_event_metadata_file_association              is OK
		-- cleanup_event_user_association                       is EMPTY on AU, EU
		-- cloudauthz                                           is EMPTY on AU, EU
		-- custos_authnz_token                                  is EMPTY on AU, EU
		-- data_manager_history_association                     is OK (user_id, history_id)
		-- data_manager_job_association                         is OK (job_id, DM id)
		-- dataset
		COPY (SELECT 'dataset') to STDOUT;
			-- TODO: Do external_filename, and _extra_files_path need to be cleaned?
			-- TODO: this is imperfect, we do something better in GRT where we take 2 SDs
			-- https://stackoverflow.com/questions/48900936/postgresql-rounding-to-significant-figures
			-- MAYBE use synthetic data here?
			update dataset set
				file_size = round(file_size, -3),
				total_size = round(total_size, -3);
		-- dataset_collection                                   is OK (type, count, etc.)
		-- dataset_collection_element
		COPY (SELECT 'dataset_collection_element') to STDOUT;
			update dataset_collection_element set
				element_identifier = gxadmin_random_slug(id::text, 10);
		-- dataset_hash                                         is EMPTY on AU, EU
		-- dataset_permissions                                  is OK (role, dataset)
		-- dataset_source
		COPY (SELECT 'dataset_source') to STDOUT;
			update dataset_source set
				source_uri = 'https://example.org/test.dat';

		-- dataset_source_hash                                  is EMPTY on AU, EU
		-- dataset_tag_association                              is EMPTY on AU, EU
		-- default_history_permissions                          is OK (hist_id, action, role_id)
		-- default_quota_association                            is OK
		-- default_user_permissions                             is OK (user, action, role)
		-- deferred_job                                         is EMPTY on AU, EU
		-- dynamic_tool                                         is EMPTY on AU, EU
		-- event                                                is EMPTY on AU, EU
		-- extended_metadata                                    is EMPTY on AU, EU
		-- extended_metadata_index                              is EMPTY on AU, EU
		-- external_service                                     is EMPTY on AU, EU
		-- form_definition                                      is EMPTY on AU, EU
		-- form_definition_current                              is EMPTY on AU, EU
		-- form_values                                          is EMPTY on AU, EU
		-- galaxy_group
		COPY (SELECT 'galaxy_group') to STDOUT;
			update galaxy_group set
				name = 'group-' || id;

		-- galaxy_session
		COPY (SELECT 'galaxy_session') to STDOUT;
			update galaxy_session set
				remote_host = gxadmin_random_ip(remote_host)
				where remote_host is not null;

			update galaxy_session set
				remote_addr = gxadmin_random_ip(remote_addr)
				where remote_addr is not null;
			update galaxy_session set
				referer = 'https://example.org'
				where  referer is not null;

			update galaxy_session set
				session_key = gxadmin_random_pw(id::text, 16), prev_session_id = null;

		-- galaxy_session_to_history                            is OK (time, session_id, hist_id)
		-- galaxy_user
		COPY (SELECT 'galaxy_user') to STDOUT;
			-- TODO: better email length/content distribution
			-- TODO: better username length/content distribution. UNICODE.
			-- TODO: rounding to SDs.
			update galaxy_user set
				email = 'user-' || id || '@example.org',
				password = 'x',
				username = 'user-' || id,
				form_values_id = null,
				activation_token = '',
				disk_usage = round(disk_usage, -5);

		-- galaxy_user_openid
		COPY (SELECT 'galaxy_user_openid') to STDOUT;
			update galaxy_user_openid set
				openid = 'https://example.org/identity/' || user_id;

		-- genome_index_tool_data                               is EMPTY on AU, EU
		-- group_quota_association                              is OK (group_id, quota id)
		-- group_role_association                               is OK (group_id, role id)
		-- history
		COPY (SELECT 'history') to STDOUT;

			-- TODO: better name distribution. UNICODE. (I see greek, chinese, etc on EU)
			update history set
				name = gxadmin_random_tag(id::text)
				where name != 'Unnamed history';

			update history set
				slug = gxadmin_random_slug(id::text, 30)
				where  slug != '' or slug is not null;

		-- history_annotation_association
		COPY (SELECT 'history_annotation_association') to STDOUT;
			-- TODO: better distribution. UNICODE.
			update history_annotation_association set
				annotation = gxadmin_random_text(id::text, 30)
				where  annotation is not null;

		-- history_dataset_association
		COPY (SELECT 'history_dataset_association') to STDOUT;
			-- TODO: SIGNIFICANT validation needed.
			update history_dataset_association set
				name = gxadmin_random_tag(id::text) || '.' || extension;

			update history_dataset_association set
				peek = 'redacted' where peek is not null;

			update history_dataset_association set
				designation = 'hda-' || id::text
				where designation is not null;

			update history_dataset_association set
				info = 'redacted'
				where info is not null and info != 'Job output deleted by user before job completed';

			update history_dataset_association set
				metadata = null;

		-- history_dataset_association_annotation_association
		COPY (SELECT 'history_dataset_association_annotation_association') to STDOUT;

			update history_dataset_association_annotation_association set
				annotation = gxadmin_random_text(id::text, 30)
				where annotation is not null;

		-- history_dataset_association_display_at_authorization is OK (user_id, hda, site=ucsc_main)
		-- history_dataset_association_history
		COPY (SELECT 'history_dataset_association_history') to STDOUT;

			-- TODO: distribution. Consistency with HDA?
			update history_dataset_association_history set
				name = gxadmin_random_tag(history_dataset_association_id::text) || '.' || extension;


			update history_dataset_association_history set
				metadata = null;

		-- history_dataset_association_rating_association       is EMPTY on AU, EU
		-- history_dataset_association_subset                   is OK (hda id, hdas id, location)
		-- history_dataset_association_tag_association
		COPY (SELECT 'history_dataset_association_tag_association') to STDOUT;

			-- user_tname == 'group' and 'name' are special.
			update history_dataset_association_tag_association set
				value = lower(gxadmin_random_tag(id::text)),
				user_value = gxadmin_random_tag(id::text)
				where user_tname in ('group', 'name');

			-- Sometimes people use a diffferent prefix
			update history_dataset_association_tag_association set
				user_tname = gxadmin_random_tag(id::text || 'tname'),
				value = lower(gxadmin_random_tag(id::text)),
				user_value = gxadmin_random_tag(id::text)
				where user_tname not in ('group', 'name') and user_tname is not null;

			-- Otherwise just set some data
			update history_dataset_association_tag_association set
				user_tname = gxadmin_random_tag(id::text)
				where user_tname is null;

		-- history_dataset_collection_annotation_association    is EMPTY on AU, EU
		-- history_dataset_collection_association
		COPY (SELECT 'history_dataset_collection_association') to STDOUT;

			update history_dataset_collection_association set
				name = 'hdca-' || id;

		-- history_dataset_collection_rating_association        is EMPTY on AU
		-- history_dataset_collection_tag_association
		COPY (SELECT 'history_dataset_collection_tag_association') to STDOUT;

			-- user_tname == 'group' and 'name' are special.
			update history_dataset_collection_tag_association set
				value = lower(gxadmin_random_tag(id::text)),
				user_value = gxadmin_random_tag(id::text)
				where user_tname in ('group', 'name');

			-- Sometimes people use a diffferent prefix
			update history_dataset_collection_tag_association set
				user_tname = gxadmin_random_tag(id::text || 'tname'),
				value = lower(gxadmin_random_tag(id::text)),
				user_value = gxadmin_random_tag(id::text)
				where user_tname not in ('group', 'name') and user_tname is not null;

			-- Otherwise just set some data
			update history_dataset_collection_tag_association set
				user_tname = gxadmin_random_tag(id::text)
				where user_tname is null;

		-- history_rating_association is OK
		-- history_tag_association
		COPY (SELECT 'history_tag_association') to STDOUT;

			-- user_tname == 'group' and 'name' are special.
			update history_tag_association set
				value = lower(gxadmin_random_tag(id::text)),
				user_value = gxadmin_random_tag(id::text)
				where user_tname in ('group', 'name');

			-- Sometimes people use a diffferent prefix
			update history_tag_association set
				user_tname = gxadmin_random_tag(id::text || 'tname'),
				value = lower(gxadmin_random_tag(id::text)),
				user_value = gxadmin_random_tag(id::text)
				where user_tname not in ('group', 'name') and user_tname is not null;

			-- Otherwise just set some data
			update history_tag_association set
				user_tname = gxadmin_random_tag(id::text)
				where user_tname is null;

		-- history_user_share_association                       is MAYBE OK (hist_id, user_id) You can determine networks, but same with groups.
		-- implicit_collection_jobs                             is OK (id, pop state)
		-- implicit_collection_jobs_job_association             is OK
		-- implicitly_converted_dataset_association             is OK
		-- implicitly_created_dataset_collection_inputs         is OK
		-- interactivetool_entry_point                          is EMPTY on AU
		-- job
		COPY (SELECT 'job') to STDOUT;
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
		COPY (SELECT 'job_container_association') to STDOUT;

			update job_container_association set
				container_name = '',
				container_info = '';

		-- job_export_history_archive
		COPY (SELECT 'job_export_history_archive') to STDOUT;

			update job_export_history_archive set
				history_attrs_filename = '/tmp/tmp' || gxadmin_random_pw(id::text || 'h', 6),
				datasets_attrs_filename = '/tmp/tmp' || gxadmin_random_pw(id::text || 'd', 6),
				jobs_attrs_filename = '/tmp/tmp' || gxadmin_random_pw(id::text || 'j', 6);

		-- job_external_output_metadata
		COPY (SELECT 'job_external_output_metadata') to STDOUT;

			update job_external_output_metadata set
				filename_in = '/tmp/job_working_directory/' || job_id || '/metadata_in_' || gxadmin_random_pw(id::text || 'i', 6),
				filename_out = '/tmp/job_working_directory/' || job_id || '/metadata_out_' || gxadmin_random_pw(id::text || 'o', 6),
				filename_results_code = '/tmp/job_working_directory/' || job_id || '/metadata_results_' || gxadmin_random_pw(id::text || 'm', 6),
				filename_kwds = '/tmp/job_working_directory/' || job_id || '/metadata_kwds_' || gxadmin_random_pw(id::text || 'k', 6),
				filename_override_metadata = '/tmp/job_working_directory/' || job_id || '/metadata_override_' || gxadmin_random_pw(id::text || 'o', 6);

		-- job_import_history_archive
		COPY (SELECT 'job_import_history_archive') to STDOUT;

			update job_import_history_archive set
				archive_dir = '/tmp/tmp' || gxadmin_random_pw(id::text, 6);

		-- job_metric_numeric is OK
		-- job_metric_text
		COPY (SELECT 'job_metric_text') to STDOUT;

			truncate job_metric_text;

		-- job_parameter
		COPY (SELECT 'job_parameter') to STDOUT;

			-- TODO: length distribution? Name distribution?
			update job_parameter set
				name = 'param-name',
				value = 'param-value';

		-- job_state_history                          is OK
		-- job_to_implicit_output_dataset_collection  is MAYBE OK (param name?)
		-- job_to_input_dataset                       is MAYBE OK (param name?)
		-- job_to_input_dataset_collection            is MAYBE OK (param name?)
		-- job_to_input_library_dataset               is EMPTY on AU
		-- job_to_output_dataset                      is MAYBE OK (param name?)
		-- job_to_output_dataset_collection           is MAYBE OK (param name?)
		-- job_to_output_library_dataset              is OK
		-- kombu_message
		COPY (SELECT 'kombu_message') to STDOUT;
			truncate kombu_message;
		-- kombu_queue                                        is OK (queue name only)
		-- library
		COPY (SELECT 'library') to STDOUT;

			update library set
				name = gxadmin_random_tag(id::text),
				description = gxadmin_random_tag(id::text || 'desc'),
				synopsis = gxadmin_random_tag(id::text || 'synopsis');

		-- library_dataset
		COPY (SELECT 'library_dataset') to STDOUT;

			update library_dataset set
				name = 'lda-' || id,
				info = '';

		-- library_dataset_collection_annotation_association    is EMPTY on AU, EU
		-- library_dataset_collection_association               is EMPTY on AU, EU
		-- library_dataset_collection_rating_association        is EMPTY on AU, EU
		-- library_dataset_collection_tag_association           is EMPTY on AU, EU
		-- library_dataset_dataset_association
		COPY (SELECT 'library_dataset_dataset_association') to STDOUT;

			-- TODO: SIGNIFICANT validation needed.
			update library_dataset_dataset_association set
				name = gxadmin_random_tag(id::text) || '.' || extension;

			update library_dataset_dataset_association set
				peek = 'redacted' where peek is not null;

			update library_dataset_dataset_association set
				designation = 'hda-' || id::text
				where designation is not null;

			update library_dataset_dataset_association set
				info = 'redacted' where info is not null;

			update library_dataset_dataset_association set
				message = 'redacted' where message is not null;

			update library_dataset_dataset_association set
				metadata = null;



		-- library_dataset_dataset_association_permissions      is OK (permissions, ldda id, role id)
		-- library_dataset_dataset_association_tag_association  is EMPTY on AU, EU
		-- library_dataset_dataset_info_association             is EMPTY on AU, EU
		-- library_dataset_permissions                          is OK (permissions, ld id, role id)
		-- library_folder
		COPY (SELECT 'library_folder') to STDOUT;

			update library_folder set
				name = gxadmin_random_tag(id::text),
				description = gxadmin_random_text(id::text || 'desc', 10);

		-- library_folder_info_association                      is EMPTY on AU, EU
		-- library_folder_permissions                           is OK (permissions, lf id, role id)
		-- library_info_association                             is EMPTY on AU
		-- library_permissions                                  is OK (permissions, lib id, role id)
		-- metadata_file                                        is OK
		-- migrate_tools                                        is EMPTY on AU, EU
		-- migrate_version                                      is OK
		-- oidc_user_authnz_tokens
		COPY (SELECT 'oidc_user_authnz_tokens') to STDOUT;

			update oidc_user_authnz_tokens set
				uid = 'redacted',
				extra_data = null;

		-- page
		COPY (SELECT 'page') to STDOUT;

			update page set
				title = gxadmin_random_tag(id::text),
				slug = gxadmin_random_slug(id::text, 10);

		-- page_annotation_association
		COPY (SELECT 'page_annotation_association') to STDOUT;

			update page_annotation_association set
				annotation = gxadmin_random_tag(id::text);

		-- page_rating_association                              is EMPTY on AU
		-- page_revision
		COPY (SELECT 'page_revision') to STDOUT;

			update page_revision set
				content = '<p>Some <b>content</b></p>';

		-- page_tag_association                                 is EMPTY on AU

			-- user_tname == 'group' and 'name' are special.
			update page_tag_association set
				value = lower(gxadmin_random_tag(id::text)),
				user_value = gxadmin_random_tag(id::text)
				where user_tname in ('group', 'name');

			-- Sometimes people use a diffferent prefix
			update page_tag_association set
				user_tname = gxadmin_random_tag(id::text || 'tname'),
				value = lower(gxadmin_random_tag(id::text)),
				user_value = gxadmin_random_tag(id::text)
				where user_tname not in ('group', 'name') and user_tname is not null;

			-- Otherwise just set some data
			update page_tag_association set
				user_tname = gxadmin_random_tag(id::text)
				where user_tname is null;

		-- page_user_share_association                          is EMPTY on AU, fine though
		-- password_reset_token
		COPY (SELECT 'password_reset_token') to STDOUT;

			update password_reset_token set
				token = md5('x' || random());

		-- post_job_action
		COPY (SELECT 'post_job_action') to STDOUT;

			update post_job_action set
				action_arguments = convert_to('{}', 'UTF8')
				where action_type != 'RenameDatasetAction';

			update post_job_action set
				action_arguments = convert_to('{"newname": "Control check"}', 'UTF8')
				where action_type = 'RenameDatasetAction';

		-- post_job_action_association                          is OK
		-- psa_association
		COPY (SELECT 'psa_association') to STDOUT;

			update psa_association set
				handle = 'redacted',
				assoc_type = 'redacted';

		-- psa_code                                             is EMPTY on AU, EU
		-- psa_nonce                                            is EMPTY on AU, EU
		-- psa_partial                                          is EMPTY on AU, EU
		-- quota
		COPY (SELECT 'quota') to STDOUT;

			update quota set
				name = pg_size_pretty(bytes),
				description = '';

		-- repository_dependency                                is EMPTY on AU, OK on EU (ts repo id)
		-- repository_repository_dependency_association         is EMPTY on AU, OK on EU
		-- request                                              is EMPTY on AU, EU
		-- request_event                                        is EMPTY on AU, EU
		-- request_type                                         is EMPTY on AU, EU
		-- request_type_external_service_association            is EMPTY on AU, EU
		-- request_type_permissions                             is EMPTY on AU, EU
		-- request_type_run_association                         is EMPTY on AU, EU
		-- role
		COPY (SELECT 'role') to STDOUT;

			update role set
				name = gxadmin_random_email(id::text),
				description = 'Private role for ' || gxadmin_random_email(id::text)
				where type = 'private';

			update role set
				name = gxadmin_random_text(id::text, 3),
				description = 'System role'
				where type = 'system';

			update role set
				name = gxadmin_random_text(id::text, 5),
				description = 'Sharing role'
				where type = 'sharing';

			update role set
				name = gxadmin_random_text(id::text, 2),
				description = ''
				where type not in ('private', 'system', 'sharing');

		-- run                                                  is EMPTY on AU, EU
		-- sample                                               is EMPTY on AU, EU
		-- sample_dataset                                       is EMPTY on AU, EU
		-- sample_event                                         is EMPTY on AU, EU
		-- sample_run_association                               is EMPTY on AU, EU
		-- sample_state                                         is EMPTY on AU, EU
		-- stored_workflow
		COPY (SELECT 'stored_workflow') to STDOUT;

			update stored_workflow set
				name = gxadmin_random_tag(id::text),
				slug = gxadmin_random_slug(id::text, 10);

		-- stored_workflow_annotation_association
		COPY (SELECT 'stored_workflow_annotation_association') to STDOUT;

			update stored_workflow set
				annotation = gxadmin_random_text(id::text)
				where annotation is not null;

		-- stored_workflow_menu_entry                           is OK
		-- stored_workflow_rating_association                   is OK
		-- stored_workflow_tag_association
		COPY (SELECT 'stored_workflow_tag_association') to STDOUT;

			-- user_tname == 'group' and 'name' are special.
			update stored_workflow_tag_association set
				value = lower(gxadmin_random_tag(id::text)),
				user_value = gxadmin_random_tag(id::text)
				where user_tname in ('group', 'name');

			-- Sometimes people use a diffferent prefix
			update stored_workflow_tag_association set
				user_tname = gxadmin_random_tag(tag_id::text),
				value = lower(gxadmin_random_tag(id::text)),
				user_value = gxadmin_random_tag(id::text)
				where user_tname not in ('group', 'name') and user_tname is not null;

			-- Otherwise just set some data
			update stored_workflow_tag_association set
				user_tname = gxadmin_random_tag(tag_id::text)
				where user_tname is null;

		-- stored_workflow_user_share_connection is OK
		-- tag
		COPY (SELECT 'tag') to STDOUT;

			update tag set
				name = gxadmin_random_tag(id::text)
				where name not in ('name', 'group');

		-- task                                                 is EMPTY on AU, not on EU

			update task set
				command_line = '',
				param_filename = '',
				runner_name = '',
				tool_stdout = '',
				tool_stderr = '',
				task_runner_name = '',
				task_runner_external_id = '',
				prepare_input_files_cmd = '',
				working_directory = '',
				info = '',
				job_messages = '',
				job_stdout = '',
				job_stderr = '';

		-- task_metric_numeric                                  is EMPTY on AU, EU
		-- task_metric_text                                     is EMPTY on AU, EU
		-- tool_dependency                                      is EMPTY on AU, OK on EU
		-- tool_shed_repository                                 is EMPTY on AU, OK on EU
		-- tool_tag_association                                 is EMPTY on AU, EU
		-- tool_version                                         is EMPTY on AU, OK on EU
		-- tool_version_association                             is EMPTY on AU, EU
		-- transfer_job                                         is EMPTY on AU, OK on EU
		-- user_action                                          is EMPTY on AU, EU
		-- user_address
		COPY (SELECT 'user_address') to STDOUT;

			update user_address set
				"desc" = gxadmin_random_text(id::text, 1),
				name = gxadmin_random_text(id::text || 'name', 1),
				institution = gxadmin_random_text(id::text || 'inst', 1),
				address     = gxadmin_random_text(id::text || 'addr', 1),
				city        = gxadmin_random_text(id::text || 'city', 1),
				state       = gxadmin_random_text(id::text || 'stat', 1),
				postal_code = gxadmin_random_number(id::text, 5),
				country     = 'Australia',
				phone       = gxadmin_random_number(id::text, 10);

		-- user_group_association                                          is OK
		-- user_preference
		COPY (SELECT 'user_preference') to STDOUT;

			-- TODO: make this better? I just don't feel safe given genomespace tokens, etc.
			truncate user_preference;

		-- user_quota_association                                          is OK
		-- user_role_association                                           is OK
		-- validation_error                                                is EMPTY on AU
		-- visualization
		COPY (SELECT 'visualization') to STDOUT;

			update visualization set
				title = gxadmin_random_text(id::text, 3),
				slug = gxadmin_random_slug(id::text, 20);

		-- visualization_annotation_association                            is EMPTY on AU

			update visualization_annotation_association set
				annotation = gxadmin_random_text(id::text, 10);

		-- visualization_rating_association                                is EMPTY on AU
		-- visualization_revision                                          is MAYBE OK
		-- visualization_tag_association                                   is EMPTY on AU
		-- visualization_user_share_association                            is EMPTY on AU
		-- worker_process                                                  is OK
		-- workflow
		COPY (SELECT 'workflow') to STDOUT;

			update workflow set
				name = gxadmin_random_text(id::text, 3);

			update workflow set
				reports_config = convert_to('{}', 'UTF8')
				where  reports_config is not null;

		-- workflow_invocation                                             is OK
		-- workflow_invocation_output_dataset_association                  is OK
		-- workflow_invocation_output_dataset_collection_association       is OK
		-- workflow_invocation_output_value                                is EMPTY on AU
		-- workflow_invocation_step                                        is OK
		-- workflow_invocation_step_output_dataset_association             is MAYBE OK (output_name?)
		-- workflow_invocation_step_output_dataset_collection_association  is MAYBE OK (output_name?)
		-- workflow_invocation_to_subworkflow_invocation_association       is OK
		-- workflow_output                                                 is MAYBE OK (output_name)
		-- workflow_request_input_parameters                               is OK
		-- workflow_request_input_step_parameter
		COPY (SELECT 'workflow_request_input_step_parameter') to STDOUT;

			update workflow_request_input_step_parameter set
				parameter_value = convert_to('asdf', 'UTF8');
		-- workflow_request_step_states
		COPY (SELECT 'workflow_request_step_states') to STDOUT;

			update workflow_request_step_states set
				value = convert_to('{}', 'UTF8');

		-- workflow_request_to_input_collection_dataset                    is OK
		-- workflow_request_to_input_dataset                               is OK
		-- workflow_step
		COPY (SELECT 'workflow_step') to STDOUT;

			update workflow_step set
				tool_inputs = convert_to('{}', 'UTF8');

			update workflow_step set
				label = gxadmin_random_slug(id::text, 10)
				where label is not null;

		-- workflow_step_annotation_association
		COPY (SELECT 'workflow_step_annotation_association') to STDOUT;

			update workflow_step_annotation_association set
				annotation = gxadmin_random_text(id::text, 10);

		-- workflow_step_connection                                        is OK
		-- workflow_step_input                                             is OK
		-- workflow_step_tag_association                                   is EMPTY on AU, EU
		-- workflow_tag_association                                        is EMPTY on AU, EU
	EOF



	txn_pre=$(txn_prefix  "$commit_flag")
	txn_pos=$(txn_postfix "$commit_flag")
	QUERY="$txn_pre $QUERY; $txn_pos"
}

mutate_fail-wfi() { ## <wf-invocation-d> [--commit]: Sets a workflow invocation state to failed
	meta <<-EOF
		ADDED: 17
	EOF
	handle_help "$@" <<-EOF
		Sets a workflow invocation's state to "failed"
	EOF

	assert_count_ge $# 1 "Must supply a wf-invocation-id"
	id=$1

	read -r -d '' QUERY <<-EOF
		UPDATE
			workflow_invocation
		SET
			state = 'failed'
		WHERE
			id = '$id'
	EOF

	txn_pre=$(txn_prefix  "$2")
	txn_pos=$(txn_postfix "$2")
	QUERY="$txn_pre $QUERY; $txn_pos"
}

mutate_oidc-by-emails() { ## <email_from> <email_to> [--commit]: Reassign OIDC account between users.
	meta <<-EOF
		ADDED: 17
	EOF
	handle_help "$@" <<-EOF
		Workaround for users creating a new account by clicking the OIDC button, with case mismatching between existing accounts.
		Please note that this function is case-sensitive. Fixes https://github.com/galaxyproject/galaxy/issues/9981.
	EOF

	assert_count_ge $# 2 "Must supply an email_from and an email_to";

	read -r -d '' QUERY <<-EOF
		UPDATE oidc_user_authnz_tokens
		SET user_id=correctuser.id
		FROM (
			SELECT id FROM galaxy_user WHERE email='$2'
		) AS correctuser
		WHERE user_id = (SELECT id FROM galaxy_user WHERE email='$1')
	EOF

	txn_pre=$(txn_prefix  "$3")
	txn_pos=$(txn_postfix "$3")
	QUERY="$txn_pre $QUERY; $txn_pos"
}

mutate_set-quota-for-oidc-user() { ##? <provider_name> <quota_name> [--commit]: Set quota for OIDC users.
	meta <<-EOF
		ADDED: 19
	EOF
	handle_help "$@" <<-EOF
		Set quota for OIDC users.
	EOF

	read -r -d '' QUERY <<-EOF
		WITH qid AS (
		   SELECT id FROM quota WHERE name='$arg_quota_name'
		)
		DELETE FROM user_quota_association WHERE quota_id = ( SELECT id FROM qid );

		WITH qid AS (
			SELECT id FROM quota WHERE name='$arg_quota_name'
		), t AS (
			SELECT user_id, ( SELECT id FROM qid ), now(), now() FROM oidc_user_authnz_tokens WHERE provider='$arg_provider_name'
		)
		INSERT INTO user_quota_association (user_id, quota_id, create_time, update_time)
		SELECT * FROM t
	EOF

	txn_pre=$(txn_prefix "$arg_commit")
	txn_pos=$(txn_postfix "$arg_commit")
	QUERY="$txn_pre $QUERY; $txn_pos"
}

mutate_fail-misbehaving-gxits() { ##? [--commit]: Fails misbehaving GxITs.
	meta <<-EOF
		ADDED: 19
	EOF
	handle_help "$@" <<-EOF
		Set quota for OIDC users.
	EOF

	read -r -d '' QUERY <<-EOF
		WITH qid AS (
			SELECT host, port, count(*)
			FROM interactivetool_entry_point
			LEFT JOIN job on job_id = job.id
			WHERE job.state = 'running'
			GROUP BY host, port
			ORDER BY count desc
		), bad AS (
			select host || ':' || port as hp from qid where count > 1
		), bad_jobs AS (
			select job_id from interactivetool_entry_point where host || ':' || port in (select hp from bad)
		)
		UPDATE job
		SET state = 'error'
		WHERE job.id IN (SELECT job_id FROM bad_jobs)
	EOF

	txn_pre=$(txn_prefix "$arg_commit")
	txn_pos=$(txn_postfix "$arg_commit")
	QUERY="$txn_pre $QUERY; $txn_pos"
}

mutate_force-publish-history() { ##? <history_id> [--commit]: Removes the access restriction on every dataset in a specified history
	meta <<-EOF
		ADDED: 19
	EOF
	handle_help "$@" <<-EOF
		Workaround for Galaxy bug https://github.com/galaxyproject/galaxy/issues/13001
	EOF

	read -r -d '' QUERY <<-EOF
		DELETE FROM dataset_permissions
		WHERE
			action = 'access'
			AND dataset_id in (
				SELECT dataset_id
				FROM history_dataset_association
				WHERE history_id = $arg_history_id
			)
	EOF

	txn_pre=$(txn_prefix "$arg_commit")
	txn_pos=$(txn_postfix "$arg_commit")
	QUERY="$txn_pre $QUERY; $txn_pos"
}

mutate_dataset-mark-purged() { ##? <dataset_uuid> [--commit]: Purge dataset and mark downstream HDAs as purged as well
	meta <<-EOF
		ADDED: 19
	EOF
	handle_help "$@" <<-EOF
	EOF

	read -r -d '' QUERY <<-EOF
		WITH to_delete as (
			UPDATE dataset
			SET
				deleted = true,
				purged = true
			WHERE uuid = translate('$arg_dataset_uuid','-','')
			RETURNING
				id
		)
		UPDATE
			history_dataset_association
		SET
			deleted = true,
			purged = true
		WHERE dataset_id IN (select * from to_delete)
	EOF

	txn_pre=$(txn_prefix "$arg_commit")
	txn_pos=$(txn_postfix "$arg_commit")
	QUERY="$txn_pre $QUERY; $txn_pos"
}

mutate_purge-old-job-metrics() { ##? [--commit]: Purge job metrics older than 1 year.
	meta <<-EOF
		ADDED: 20
	EOF
	handle_help "$@" <<-EOF
	EOF

	read -r -d '' QUERY <<-EOF
		DELETE FROM job_metric_text USING job WHERE job_id=job.id AND (job.state='ok' OR CURRENT_TIMESTAMP - job.update_time > '1 year');
		VACUUM FULL job_metric_text;
		DELETE FROM job_metric_numeric USING job WHERE job_id=job.id AND job.state IN ('deleted', 'error') AND CURRENT_TIMESTAMP - job.update_time > '1 year';
		VACUUM FULL job_metric_numeric
	EOF

	txn_pre=$(txn_prefix "$arg_commit")
	txn_pos=$(txn_postfix "$arg_commit")
	QUERY="$txn_pre $QUERY; $txn_pos"
}

mutate_derive_missing_username_from_email() { ##? [--commit]: Set empty username to email address for users created before 2011
	meta <<-EOF
		ADDED: 22
	EOF
	handle_help "$@" <<-EOF
		Galaxy did not require setting a username for users registered prior to 2011.
		This will set the username to the lowercased substring of the email addres before the first @.
		The username for a user with the email address "Jane.DoE@example.com"
		will be set to "jane.doe" if the the user did not have a username and no other user
		has been registered with that username.
		It is recommended that usernames that could not be changed due to conflicts are fixed
		using mutate_set_missing_username_to_random_uuid()
	EOF

	read -r -d '' QUERY <<-EOF
		WITH extracted_emails AS (
		    SELECT LOWER(SPLIT_PART(email, '@', 1)) AS extracted_email
		    FROM galaxy_user gu
		    WHERE username IS NULL
		    AND NOT EXISTS (
		        SELECT 1
		        FROM galaxy_user
		        WHERE LOWER(SPLIT_PART(email, '@', 1)) = LOWER(SPLIT_PART(gu.email, '@', 1))
		        AND username IS NOT NULL
		    )
		)
		UPDATE galaxy_user gu
		SET username = e.extracted_email
		FROM extracted_emails e
		WHERE gu.username IS NULL
		AND LOWER(SPLIT_PART(gu.email, '@', 1)) = e.extracted_email
	EOF

	txn_pre=$(txn_prefix "$arg_commit")
	txn_pos=$(txn_postfix "$arg_commit")
	QUERY="$txn_pre $QUERY; $txn_pos"
}

mutate_set_missing_username_to_random_uuid() { ##? [--commit]: Set empty username to random uuid
	meta <<-EOF
		ADDED: 22
	EOF
	handle_help "$@" <<-EOF
		Galaxy did not require setting a username for users registered prior to 2011.
		This will set the username column to a random uuid.
	EOF

	read -r -d '' QUERY <<-EOF
		UPDATE galaxy_user gu
		SET username = gen_random_uuid()
		WHERE gu.username IS NULL
	EOF

	txn_pre=$(txn_prefix "$arg_commit")
	txn_pos=$(txn_postfix "$arg_commit")
	QUERY="$txn_pre $QUERY; $txn_pos"
}

mutate_scale-table-autovacuum() { ##? [--shift=16] [--commit]: Update autovacuum and autoanalyze scale for large tables.
	meta <<-EOF
		ADDED: 22
		AUTHORS: natefoo
	EOF
	handle_help "$@" <<-EOF
		Set autovacuum_vacuum_scale_factor and autovacuum_analyze_scale_factor dynamically based on size for
		large tables. See https://www.enterprisedb.com/blog/postgresql-vacuum-and-analyze-best-practice-tips

		Table row counts are shifted right by --shift, any shifted value over 1 will have its autovacuum scale
		adjusted to 0.2/log(rows >> [shift]) and autoanalyze scale adjusted to 0.1/log(rows >> [shift]).
	EOF

	local qstr table vacscale anscale

	read -r -d '' qstr <<-EOF
		SELECT
			s.oid,
			to_char(0.2 / s.shiftlog, 'FM0.9999') AS vacscale,
			to_char(0.1 / s.shiftlog, 'FM0.9999') AS anscale
		FROM (
			SELECT
				oid::REGCLASS,
				reltuples::INT8,
				log(reltuples::INT8 >> $arg_shift) AS shiftlog
			FROM
				pg_class
			WHERE
				relkind = 'r'
				AND relowner = (SELECT usesysid FROM pg_user WHERE usename = (SELECT current_user))
				AND (reltuples::INT8 >> $arg_shift) > 0
				AND log(reltuples::INT8 >> $arg_shift) > 1
		) AS s
		ORDER BY
			s.reltuples
	EOF

	while read table vacscale anscale; do
		QUERY="$(printf '%s;\n%s' "$QUERY" \
			"ALTER TABLE $table SET (autovacuum_vacuum_scale_factor = $vacscale, autovacuum_analyze_scale_factor = $anscale)")"
	done< <(query_tsv "$qstr")

	txn_pre=$(txn_prefix "$arg_commit")
	txn_pos=$(txn_postfix "$arg_commit")
	QUERY="$txn_pre $QUERY; $txn_pos"
}
