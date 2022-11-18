# mutate

Command | Description
------- | -----------
[`mutate anonymise-db-for-release`](#mutate-anonymise-db-for-release) | This will attempt to make a database completely safe to release publicly.
[`mutate approve-user`](#mutate-approve-user) | Approve a user in the database
[`mutate assign-unassigned-workflows`](#mutate-assign-unassigned-workflows) | Randomly assigns unassigned workflows to handlers. Workaround for galaxyproject/galaxy#8209
[`mutate dataset-mark-purged`](#mutate-dataset-mark-purged) | Purge dataset and mark downstream HDAs as purged as well
[`mutate delete-group-role`](#mutate-delete-group-role) | Remove the group, role, and any user-group + user-role associations
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

## mutate delete-group-role

([*source*](https://github.com/galaxyproject/gxadmin/search?q=mutate_delete-group-role&type=Code))
mutate delete-group-role -  Remove the group, role, and any user-group + user-role associations

**SYNOPSIS**

    gxadmin mutate delete-group-role <group_name> [--commit]

**NOTES**

Wipe out a group+role, and user associations.


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

