# mutate

Command | Description
------- | -----------
[`mutate approve-user`](#mutate-approve-user) | Approve a user in the database
[`mutate assign-unassigned-workflows`](#mutate-assign-unassigned-workflows) | Randomly assigns unassigned workflows to handlers. Workaround for galaxyproject/galaxy#8209
[`mutate delete-group-role`](#mutate-delete-group-role) | Remove the group, role, and any user-group + user-role associations
[`mutate drop-extraneous-workflow-step-output-associations`](#mutate-drop-extraneous-workflow-step-output-associations) | #8418, drop extraneous connection
[`mutate fail-history`](#mutate-fail-history) | Mark all jobs within a history to state error
[`mutate fail-job`](#mutate-fail-job) | Sets a job state to error
[`mutate fail-terminal-datasets`](#mutate-fail-terminal-datasets) | Causes the output datasets of jobs which were manually failed, to be marked as failed
[`mutate fail-wfi`](#mutate-fail-wfi) | Sets a workflow invocation state to failed
[`mutate generate-unset-api-keys`](#mutate-generate-unset-api-keys) | Generate API keys for users which do not have one set.
[`mutate oidc-by-emails`](#mutate-oidc-by-emails) | Reassign OIDC account between users.
[`mutate oidc-role-find-affected`](#mutate-oidc-role-find-affected) | Find users affected by galaxyproject/galaxy#8244
[`mutate oidc-role-fix`](#mutate-oidc-role-fix) | Fix permissions for users logged in via OIDC. Workaround for galaxyproject/galaxy#8244
[`mutate reassign-job-to-handler`](#mutate-reassign-job-to-handler) | Reassign a job to a different handler
[`mutate reassign-workflows-to-handler`](#mutate-reassign-workflows-to-handler) | Reassign workflows in 'new' state to a different handler.
[`mutate restart-jobs`](#mutate-restart-jobs) | Restart some jobs

## mutate approve-user

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=mutate_approve-user&type=Code))
mutate approve-user -  Approve a user in the database

**SYNOPSIS**

    gxadmin mutate approve-user <username|email|user_id>

**NOTES**

There is no --commit flag on this because it is relatively safe


## mutate assign-unassigned-workflows

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=mutate_assign-unassigned-workflows&type=Code))
mutate assign-unassigned-workflows -  Randomly assigns unassigned workflows to handlers. Workaround for galaxyproject/galaxy#8209

**SYNOPSIS**

    gxadmin mutate assign-unassigned-workflows <handler_prefix> <handler_count> [--commit]

**NOTES**

Workaround for https://github.com/galaxyproject/galaxy/issues/8209

Handler names should have number as postfix, so "some_string_##". In
this case handler_prefix is "some_string_" and count is however many
handlers you want to schedule workflows across.


## mutate delete-group-role

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=mutate_delete-group-role&type=Code))
mutate delete-group-role -  Remove the group, role, and any user-group + user-role associations

**SYNOPSIS**

    gxadmin mutate delete-group-role <group_name> [--commit]

**NOTES**

Wipe out a group+role, and user associations.


## mutate drop-extraneous-workflow-step-output-associations

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=mutate_drop-extraneous-workflow-step-output-associations&type=Code))
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

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=mutate_fail-history&type=Code))
mutate fail-history -  Mark all jobs within a history to state error

**SYNOPSIS**

    gxadmin mutate fail-history <history_id> [--commit]

**NOTES**

Set all jobs within a history to error


## mutate fail-job

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=mutate_fail-job&type=Code))
mutate fail-job -  Sets a job state to error

**SYNOPSIS**

    gxadmin mutate fail-job <job_id> [--commit]

**NOTES**

Sets a job's state to "error"


## mutate fail-terminal-datasets

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=mutate_fail-terminal-datasets&type=Code))
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

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=mutate_fail-wfi&type=Code))
mutate fail-wfi -  Sets a workflow invocation state to failed

**SYNOPSIS**

    gxadmin mutate fail-wfi <wf-invocation-d> [--commit]

**NOTES**

Sets a workflow invocation's state to "failed"


## mutate generate-unset-api-keys

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=mutate_generate-unset-api-keys&type=Code))
mutate generate-unset-api-keys -  Generate API keys for users which do not have one set.

**SYNOPSIS**

    gxadmin mutate generate-unset-api-keys [--commit]

**NOTES**

For some use cases (IEs), it is preferrable that everyone has an API
key set for them, if they don't choose to set one themselves. So we set
a base64'd key to be a bit extra secure just in case. These work just
fine like hex keys.


## mutate oidc-by-emails

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=mutate_oidc-by-emails&type=Code))
mutate oidc-by-emails -  Reassign OIDC account between users.

**SYNOPSIS**

    gxadmin mutate oidc-by-emails <email_from> <email_to> [--commit]

**NOTES**

Workaround for users creating a new account by clicking the OIDC button, with case mismatching between existing accounts.
Please note that this function is case-sensitive. Fixes https://github.com/galaxyproject/galaxy/issues/9981.


## mutate oidc-role-find-affected

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=mutate_oidc-role-find-affected&type=Code))
mutate oidc-role-find-affected -  Find users affected by galaxyproject/galaxy#8244

**SYNOPSIS**

    gxadmin mutate oidc-role-find-affected

**NOTES**

Workaround for https://github.com/galaxyproject/galaxy/issues/8244

This finds all of the OIDC authenticated users which do not have any
roles associated to them. (Should be sufficient?)


## mutate oidc-role-fix

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=mutate_oidc-role-fix&type=Code))
mutate oidc-role-fix -  Fix permissions for users logged in via OIDC. Workaround for galaxyproject/galaxy#8244

**SYNOPSIS**

    gxadmin mutate oidc-role-fix <username|email|user_id>

**NOTES**

Workaround for https://github.com/galaxyproject/galaxy/issues/8244


## mutate reassign-job-to-handler

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=mutate_reassign-job-to-handler&type=Code))
mutate reassign-job-to-handler -  Reassign a job to a different handler

**SYNOPSIS**

    gxadmin mutate reassign-job-to-handler <job_id> <handler_id> [--commit]


## mutate reassign-workflows-to-handler

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=mutate_reassign-workflows-to-handler&type=Code))
mutate reassign-workflows-to-handler -  Reassign workflows in 'new' state to a different handler.

**SYNOPSIS**

    gxadmin mutate reassign-workflows-to-handler <handler_from> <handler_to> [--commit]

**NOTES**

Another workaround for https://github.com/galaxyproject/galaxy/issues/8209

Need to use the full handler names e.g. handler_main_0


## mutate restart-jobs

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=mutate_restart-jobs&type=Code))
mutate restart-jobs -  Restart some jobs

**SYNOPSIS**

    gxadmin mutate restart-jobs [--commit] <-|job_id [job_id [...]]>

**NOTES**

Restart jobs

