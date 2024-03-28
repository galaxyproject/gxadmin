# mutate

Command | Description
------- | -----------
[`mutate anonymise-db-for-release`](#mutate-anonymise-db-for-release) | This will attempt to make a database completely safe to release publicly.
[`mutate approve-user`](#mutate-approve-user) | Approve a user in the database
[`mutate assign-unassigned-workflows`](#mutate-assign-unassigned-workflows) | Randomly assigns unassigned workflows to handlers. Workaround for galaxyproject/galaxy#8209
[`mutate dataset-mark-purged`](#mutate-dataset-mark-purged) | Purge dataset and mark downstream HDAs as purged as well
[`mutate delete-group-role`](#mutate-delete-group-role) | Remove the group, role, and any user-group + user-role associations
[`mutate derive-missing-username-from-email`](#mutate-derive-missing-username-from-email) | Set empty username to email address for users created before 2011
[`mutate drop-extraneous-workflow-step-output-associations`](#mutate-drop-extraneous-workflow-step-output-associations) | #8418, drop extraneous connection
[`mutate fail-history`](#mutate-fail-history) | Mark all jobs within a history to state error
[`mutate fail-job`](#mutate-fail-job) | Sets a job state to error
[`mutate fail-misbehaving-gxits`](#mutate-fail-misbehaving-gxits) | Fails misbehaving GxITs.
[`mutate fail-terminal-datasets`](#mutate-fail-terminal-datasets) | Causes the output datasets of jobs which were manually failed, to be marked as failed
[`mutate fail-wfi`](#mutate-fail-wfi) | Sets a workflow invocation state to failed
[`mutate force-publish-history`](#mutate-force-publish-history) | Removes the access restriction on every dataset in a specified history
[`mutate generate-unset-api-keys`](#mutate-generate-unset-api-keys) | Generate API keys for users which do not have one set.
[`mutate oidc-by-emails`](#mutate-oidc-by-emails) | Reassign OIDC account between users.
[`mutate oidc-role-find-affected`](#mutate-oidc-role-find-affected) | Find users affected by galaxyproject/galaxy#8244
[`mutate oidc-role-fix`](#mutate-oidc-role-fix) | Fix permissions for users logged in via OIDC. Workaround for galaxyproject/galaxy#8244
[`mutate purge-old-job-metrics`](#mutate-purge-old-job-metrics) | Purge job metrics older than 1 year.
[`mutate reassign-active-workflows-to-handler`](#mutate-reassign-active-workflows-to-handler) | Reassign workflows with state 'scheduled' or 'new' to a different handler.
[`mutate reassign-job-to-handler`](#mutate-reassign-job-to-handler) | Reassign a job to a different handler
[`mutate reassign-workflows-to-handler`](#mutate-reassign-workflows-to-handler) | Reassign workflows in 'new' state to a different handler.
[`mutate restart-jobs`](#mutate-restart-jobs) | Restart some jobs
[`mutate scale-table-autovacuum`](#mutate-scale-table-autovacuum) | Update autovacuum and autoanalyze scale for large tables.
[`mutate set-missing-username-to-random-uuid`](#mutate-set-missing-username-to-random-uuid) | Set empty username to random uuid
[`mutate set-quota-for-oidc-user`](#mutate-set-quota-for-oidc-user) | Set quota for OIDC users.

## mutate anonymise-db-for-release

([*source*](https://github.com/galaxyproject/gxadmin/search?q=mutate_anonymise-db-for-release&type=Code))
mutate anonymise-db-for-release -  This will attempt to make a database completely safe to release publicly.

**SYNOPSIS**

    gxadmin mutate anonymise-db-for-release [--commit|--very-unsafe]

**NOTES**

THIS WILL DESTROY YOUR DATABASE.

--commit will do it and wrap it in a transaction
--very-unsafe will just run it without the transaction


## mutate approve-user

([*source*](https://github.com/galaxyproject/gxadmin/search?q=mutate_approve-user&type=Code))
mutate approve-user -  Approve a user in the database

**SYNOPSIS**

    gxadmin mutate approve-user <username|email|user_id>

**NOTES**

There is no --commit flag on this because it is relatively safe


## mutate assign-unassigned-workflows

([*source*](https://github.com/galaxyproject/gxadmin/search?q=mutate_assign-unassigned-workflows&type=Code))
mutate assign-unassigned-workflows -  Randomly assigns unassigned workflows to handlers. Workaround for galaxyproject/galaxy#8209

**SYNOPSIS**

    gxadmin mutate assign-unassigned-workflows <handler_prefix> <handler_count> [--commit]

**NOTES**

Workaround for https://github.com/galaxyproject/galaxy/issues/8209

Handler names should have number as postfix, so "some_string_##". In
this case handler_prefix is "some_string_" and count is however many
handlers you want to schedule workflows across.


## mutate dataset-mark-purged

([*source*](https://github.com/galaxyproject/gxadmin/search?q=mutate_dataset-mark-purged&type=Code))
mutate dataset-mark-purged -  Purge dataset and mark downstream HDAs as purged as well

**SYNOPSIS**

    gxadmin mutate dataset-mark-purged <dataset_uuid> [--commit]


## mutate delete-group-role

([*source*](https://github.com/galaxyproject/gxadmin/search?q=mutate_delete-group-role&type=Code))
mutate delete-group-role -  Remove the group, role, and any user-group + user-role associations

**SYNOPSIS**

    gxadmin mutate delete-group-role <group_name> [--commit]

**NOTES**

Wipe out a group+role, and user associations.


## mutate derive-missing-username-from-email

([*source*](https://github.com/galaxyproject/gxadmin/search?q=mutate_derive-missing-username-from-email&type=Code))
mutate derive-missing-username-from-email -  Set empty username to email address for users created before 2011

**SYNOPSIS**

    gxadmin mutate derive-missing-username-from-email [--commit]

**NOTES**

Galaxy did not require setting a username for users registered prior to 2011.
This will set the username to the lowercased substring of the email addres before the first @.
The username for a user with the email address "Jane.DoE@example.com"
will be set to "jane.doe" if the the user did not have a username and no other user
has been registered with that username.
It is recommended that usernames that could not be changed due to conflicts are fixed
using mutate set-missing-username-to-random-uuid()


## mutate drop-extraneous-workflow-step-output-associations

([*source*](https://github.com/galaxyproject/gxadmin/search?q=mutate_drop-extraneous-workflow-step-output-associations&type=Code))
mutate drop-extraneous-workflow-step-output-associations -  #8418, drop extraneous connection

**SYNOPSIS**

    gxadmin mutate drop-extraneous-workflow-step-output-associations [--commit]

**NOTES**

Per https://github.com/galaxyproject/galaxy/pull/8418, this drops the
workflow step output associations that are not necessary.

This only needs to be run once, on servers which have run Galaxy<=19.05
to remove duplicate entries in the following tables:

- workflow_invocation_step_output_dataset_association
- workflow_invocation_step_output_dataset_collection_association


## mutate fail-history

([*source*](https://github.com/galaxyproject/gxadmin/search?q=mutate_fail-history&type=Code))
mutate fail-history -  Mark all jobs within a history to state error

**SYNOPSIS**

    gxadmin mutate fail-history <history_id> [--commit]

**NOTES**

Set all jobs within a history to error


## mutate fail-job

([*source*](https://github.com/galaxyproject/gxadmin/search?q=mutate_fail-job&type=Code))
mutate fail-job -  Sets a job state to error

**SYNOPSIS**

    gxadmin mutate fail-job <job_id> [--commit]

**NOTES**

Sets a job's state to "error"


## mutate fail-misbehaving-gxits

([*source*](https://github.com/galaxyproject/gxadmin/search?q=mutate_fail-misbehaving-gxits&type=Code))
mutate fail-misbehaving-gxits -  Fails misbehaving GxITs.

**SYNOPSIS**

    gxadmin mutate fail-misbehaving-gxits [--commit]

**NOTES**

Set quota for OIDC users.


## mutate fail-terminal-datasets

([*source*](https://github.com/galaxyproject/gxadmin/search?q=mutate_fail-terminal-datasets&type=Code))
mutate fail-terminal-datasets -  Causes the output datasets of jobs which were manually failed, to be marked as failed

**SYNOPSIS**

    gxadmin mutate fail-terminal-datasets [--commit]

**NOTES**

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


## mutate fail-wfi

([*source*](https://github.com/galaxyproject/gxadmin/search?q=mutate_fail-wfi&type=Code))
mutate fail-wfi -  Sets a workflow invocation state to failed

**SYNOPSIS**

    gxadmin mutate fail-wfi <wf-invocation-d> [--commit]

**NOTES**

Sets a workflow invocation's state to "failed"


## mutate force-publish-history

([*source*](https://github.com/galaxyproject/gxadmin/search?q=mutate_force-publish-history&type=Code))
mutate force-publish-history -  Removes the access restriction on every dataset in a specified history

**SYNOPSIS**

    gxadmin mutate force-publish-history <history_id> [--commit]

**NOTES**

Workaround for Galaxy bug https://github.com/galaxyproject/galaxy/issues/13001


## mutate generate-unset-api-keys

([*source*](https://github.com/galaxyproject/gxadmin/search?q=mutate_generate-unset-api-keys&type=Code))
mutate generate-unset-api-keys -  Generate API keys for users which do not have one set.

**SYNOPSIS**

    gxadmin mutate generate-unset-api-keys [--commit]

**NOTES**

For some use cases (IEs), it is preferrable that everyone has an API
key set for them, if they don't choose to set one themselves. So we set
a base64'd key to be a bit extra secure just in case. These work just
fine like hex keys.


## mutate oidc-by-emails

([*source*](https://github.com/galaxyproject/gxadmin/search?q=mutate_oidc-by-emails&type=Code))
mutate oidc-by-emails -  Reassign OIDC account between users.

**SYNOPSIS**

    gxadmin mutate oidc-by-emails <email_from> <email_to> [--commit]

**NOTES**

Workaround for users creating a new account by clicking the OIDC button, with case mismatching between existing accounts.
Please note that this function is case-sensitive. Fixes https://github.com/galaxyproject/galaxy/issues/9981.


## mutate oidc-role-find-affected

([*source*](https://github.com/galaxyproject/gxadmin/search?q=mutate_oidc-role-find-affected&type=Code))
mutate oidc-role-find-affected -  Find users affected by galaxyproject/galaxy#8244

**SYNOPSIS**

    gxadmin mutate oidc-role-find-affected

**NOTES**

Workaround for https://github.com/galaxyproject/galaxy/issues/8244

This finds all of the OIDC authenticated users which do not have any
roles associated to them. (Should be sufficient?)


## mutate oidc-role-fix

([*source*](https://github.com/galaxyproject/gxadmin/search?q=mutate_oidc-role-fix&type=Code))
mutate oidc-role-fix -  Fix permissions for users logged in via OIDC. Workaround for galaxyproject/galaxy#8244

**SYNOPSIS**

    gxadmin mutate oidc-role-fix <username|email|user_id>

**NOTES**

Workaround for https://github.com/galaxyproject/galaxy/issues/8244


## mutate purge-old-job-metrics

([*source*](https://github.com/galaxyproject/gxadmin/search?q=mutate_purge-old-job-metrics&type=Code))
mutate purge-old-job-metrics -  Purge job metrics older than 1 year.

**SYNOPSIS**

    gxadmin mutate purge-old-job-metrics [--commit]


## mutate reassign-active-workflows-to-handler

([*source*](https://github.com/galaxyproject/gxadmin/search?q=mutate_reassign-active-workflows-to-handler&type=Code))
mutate reassign-active-workflows-to-handler -  Reassign workflows with state 'scheduled' or 'new' to a different handler.

**SYNOPSIS**

    gxadmin mutate reassign-active-workflows-to-handler <handler_from> <handler_to> [--commit]

**NOTES**

Another workaround for https://github.com/galaxyproject/galaxy/issues/8209

Need to use the full handler names e.g. handler_main_0


## mutate reassign-job-to-handler

([*source*](https://github.com/galaxyproject/gxadmin/search?q=mutate_reassign-job-to-handler&type=Code))
mutate reassign-job-to-handler -  Reassign a job to a different handler

**SYNOPSIS**

    gxadmin mutate reassign-job-to-handler <job_id> <handler_id> [--commit]


## mutate reassign-workflows-to-handler

([*source*](https://github.com/galaxyproject/gxadmin/search?q=mutate_reassign-workflows-to-handler&type=Code))
mutate reassign-workflows-to-handler -  Reassign workflows in 'new' state to a different handler.

**SYNOPSIS**

    gxadmin mutate reassign-workflows-to-handler <handler_from> <handler_to> [--commit]

**NOTES**

Another workaround for https://github.com/galaxyproject/galaxy/issues/8209

Need to use the full handler names e.g. handler_main_0


## mutate restart-jobs

([*source*](https://github.com/galaxyproject/gxadmin/search?q=mutate_restart-jobs&type=Code))
mutate restart-jobs -  Restart some jobs

**SYNOPSIS**

    gxadmin mutate restart-jobs [--commit] <-|job_id [job_id [...]]>

**NOTES**

Restart jobs


## mutate scale-table-autovacuum

([*source*](https://github.com/galaxyproject/gxadmin/search?q=mutate_scale-table-autovacuum&type=Code))
mutate scale-table-autovacuum -  Update autovacuum and autoanalyze scale for large tables.

**SYNOPSIS**

    gxadmin mutate scale-table-autovacuum [--shift=16] [--commit]

**NOTES**

Set autovacuum_vacuum_scale_factor and autovacuum_analyze_scale_factor dynamically based on size for
large tables. See https://www.enterprisedb.com/blog/postgresql-vacuum-and-analyze-best-practice-tips

Table row counts are shifted right by --shift, any shifted value over 1 will have its autovacuum scale
adjusted to 0.2/log(rows >> [shift]) and autoanalyze scale adjusted to 0.1/log(rows >> [shift]).


## mutate set-missing-username-to-random-uuid

([*source*](https://github.com/galaxyproject/gxadmin/search?q=mutate_set-missing-username-to-random-uuid&type=Code))
mutate set-missing-username-to-random-uuid -  Set empty username to random uuid

**SYNOPSIS**

    gxadmin mutate set-missing-username-to-random-uuid [--commit]

**NOTES**

Galaxy did not require setting a username for users registered prior to 2011.
This will set the username column to a random uuid.


## mutate set-quota-for-oidc-user

([*source*](https://github.com/galaxyproject/gxadmin/search?q=mutate_set-quota-for-oidc-user&type=Code))
mutate set-quota-for-oidc-user -  Set quota for OIDC users.

**SYNOPSIS**

    gxadmin mutate set-quota-for-oidc-user <provider_name> <quota_name> [--commit]

**NOTES**

Set quota for OIDC users.

