# mutate

Command | Description
------- | -----------
[`mutate approve-user`](#mutate-approve-user) | Approve a user in the database
[`mutate delete-group-role`](#mutate-delete-group-role) | Remove the group, role, and any user-group + user-role associations
[`mutate fail-history`](#mutate-fail-history) | Mark all jobs within a history to state error
[`mutate fail-job`](#mutate-fail-job) | Sets a job state to error
[`mutate fail-terminal-datasets`](#mutate-fail-terminal-datasets) | Causes the output datasets of jobs which were manually failed, to be marked as failed

### mutate approve-user

**NAME**

mutate approve-user -  Approve a user in the database

**SYNOPSIS**

`gxadmin mutate approve-user <username|email|user_id>`

**NOTES**

There is no --commit flag on this because it is relatively safe


### mutate delete-group-role

**NAME**

mutate delete-group-role -  Remove the group, role, and any user-group + user-role associations

**SYNOPSIS**

`gxadmin mutate delete-group-role <group_name> [--commit]`

**NOTES**

Wipe out a group+role, and user associations.


### mutate fail-history

**NAME**

mutate fail-history -  Mark all jobs within a history to state error

**SYNOPSIS**

`gxadmin mutate fail-history <history_id> [--commit]`

**NOTES**

Set all jobs within a history to error


### mutate fail-job

**NAME**

mutate fail-job -  Sets a job state to error

**SYNOPSIS**

`gxadmin mutate fail-job <job_id> [--commit]`

**NOTES**

Sets a job's state to "error"


### mutate fail-terminal-datasets

**NAME**

mutate fail-terminal-datasets -  Causes the output datasets of jobs which were manually failed, to be marked as failed

**SYNOPSIS**

`gxadmin mutate fail-terminal-datasets [--commit]`

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

