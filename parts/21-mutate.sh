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

mutate_drop-workflow-step-output-associations() { ## : #8418, drop extraneous connection
	handle_help "$@" <<-EOF
		Per https://github.com/galaxyproject/galaxy/pull/8418, this drops the
		workflow step output associations that are not necessary.
	EOF

	read -r -d '' QUERY <<-EOF
		DELETE FROM
			workflow_invocation_step_output_dataset_association
		WHERE id NOT IN (
			SELECT max(w.id) FROM
			workflow_invocation_step_output_dataset_association as w GROUP BY workflow_invocation_step_id, dataset_id, output_name
		)
	EOF

	commit=$(should_commit "$3")
	QUERY="BEGIN TRANSACTION; $QUERY; $commit"
}

mutate_drop-workflow-step-output-associations2() { ## : #8418, drop extraneous connection, v2 for large sites
	handle_help "$@" <<-EOF
		Per https://github.com/galaxyproject/galaxy/pull/8418, this drops the
		workflow step output associations that are not necessary.

		This version was rewritten to be a bit faster for large databases.
	EOF

	read -r -d '' QUERY <<-EOF
		WITH exclude_list AS (
			SELECT max(w.id) as id
			FROM workflow_invocation_step_output_dataset_association as w
			GROUP BY workflow_invocation_step_id, dataset_id, output_name
		)

		DELETE
		FROM workflow_invocation_step_output_dataset_association wisoda
		WHERE NOT EXISTS (SELECT 1 FROM exclude_list WHERE wisoda.id = exclude_list.id)
	EOF

	commit=$(should_commit "$3")
	QUERY="BEGIN TRANSACTION; $QUERY; $commit"
}
