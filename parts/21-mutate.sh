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
		WHERE id in (select hda_id from terminal_jobs_temp);

		$commit
	EOF
}

mutate_fail-job() { ## <job_id> [--commit]: Sets a job state to error
	handle_help "$@" <<-EOF
		Sets a job's state to "error"
	EOF

	assert_count_ge $# 1 "Must supply a job ID"
	id=$1

	commit="ROLLBACK;"
	if [[ $2 == "--commit" ]]; then
		commit="COMMIT;"
	fi


	read -r -d '' QUERY <<-EOF
		BEGIN TRANSACTION;

		UPDATE
			job
		SET
			state = 'error'
		WHERE
			id = '$id'

		$commit
	EOF
}
