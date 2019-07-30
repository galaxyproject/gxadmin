# mutate

Command | Description
------- | -----------
[`mutate approve-user`](#mutate-approve-user) | Approve a user in the database
[`mutate assign-unassigned-workflows`](#mutate-assign-unassigned-workflows) | Randomly assigns unassigned workflows to handlers. Workaround for galaxyproject/galaxy#8209
[`mutate delete-group-role`](#mutate-delete-group-role) | Remove the group, role, and any user-group + user-role associations
[`mutate fail-history`](#mutate-fail-history) | Mark all jobs within a history to state error
[`mutate fail-job`](#mutate-fail-job) | Sets a job state to error
[`mutate fail-terminal-datasets`](#mutate-fail-terminal-datasets) | Causes the output datasets of jobs which were manually failed, to be marked as failed
[`mutate oidc-role-find-affected`](#mutate-oidc-role-find-affected) | Find users affected by galaxyproject/galaxy#8244
[`mutate oidc-role-fix`](#mutate-oidc-role-fix) | Fix permissions for users logged in via OIDC. Workaround for galaxyproject/galaxy#8244
[`mutate reassign-job-to-handler`](#mutate-reassign-job-to-handler) | Reassign a job to a different handler

## mutate approve-user

mutate approve-user -  Approve a user in the database

**SYNOPSIS**

    gxadmin mutate approve-user <username|email|user_id>

**NOTES**

There is no --commit flag on this because it is relatively safe


## mutate assign-unassigned-workflows

mutate assign-unassigned-workflows -  Randomly assigns unassigned workflows to handlers. Workaround for galaxyproject/galaxy#8209

**SYNOPSIS**

    gxadmin mutate assign-unassigned-workflows <handler_prefix> <handler_count> [--commit]

**NOTES**

Workaround for https://github.com/galaxyproject/galaxy/issues/8209

Handler names should have number as postfix, so "some_string_##". In
this case handler_prefix is "some_string_" and count is however many
handlers you want to schedule workflows across.


## mutate delete-group-role

mutate delete-group-role -  Remove the group, role, and any user-group + user-role associations

**SYNOPSIS**

    gxadmin mutate delete-group-role <group_name> [--commit]

**NOTES**

Wipe out a group+role, and user associations.


## mutate fail-history

mutate fail-history -  Mark all jobs within a history to state error

**SYNOPSIS**

    gxadmin mutate fail-history <history_id> [--commit]

**NOTES**

Set all jobs within a history to error


## mutate fail-job

mutate fail-job -  Sets a job state to error

**SYNOPSIS**

    gxadmin mutate fail-job <job_id> [--commit]

**NOTES**

Sets a job's state to "error"


## mutate fail-terminal-datasets

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


## mutate oidc-role-find-affected

mutate oidc-role-find-affected -  Find users affected by galaxyproject/galaxy#8244

**SYNOPSIS**

    gxadmin mutate oidc-role-find-affected

**NOTES**

Workaround for https://github.com/galaxyproject/galaxy/issues/8244

This finds all of the OIDC authenticated users which do not have any
roles associated to them. (Should be sufficient?)


## mutate oidc-role-fix

mutate oidc-role-fix -  Fix permissions for users logged in via OIDC. Workaround for galaxyproject/galaxy#8244

**SYNOPSIS**

    gxadmin mutate oidc-role-fix <username|email|user_id>

**NOTES**

Workaround for https://github.com/galaxyproject/galaxy/issues/8244


## mutate reassign-job-to-handler

mutate reassign-job-to-handler -  Reassign a job to a different handler

**SYNOPSIS**

    gxadmin mutate reassign-job-to-handler <job_id> <handler_id>

