# server

Command | Description
------- | -----------
[`server allocated-cpu`](#server-allocated-cpu) | CPU time per job runner
[`server allocated-gpu`](#server-allocated-gpu) | GPU time per job runner
[`server datasets`](#server-datasets) | Counts of datasets
[`server disk-usage`](#server-disk-usage) | Retrieve an approximation of the global disk usage
[`server groups`](#server-groups) | Counts of group memberships
[`server groups-allocated-cpu`](#server-groups-allocated-cpu) | Retrieve an approximation of the CPU allocation for groups
[`server groups-allocated-gpu`](#server-groups-allocated-gpu) | Retrieve an approximation of the GPU allocation for groups
[`server groups-disk-usage`](#server-groups-disk-usage) | Retrieve an approximation of the disk usage for groups
[`server hda`](#server-hda) | Counts of HDAs
[`server histories`](#server-histories) | Counts of histories and sharing
[`server jobs`](#server-jobs) | Counts of jobs
[`server ts-repos`](#server-ts-repos) | Counts of TS repos
[`server users`](#server-users) | Count of different classifications of users
[`server users-with-oidc`](#server-users-with-oidc) | How many users logged in with OIDC
[`server workflow-invocations`](#server-workflow-invocations) | Counts of workflow invocations
[`server workflow-trace-archive-jobs`](#server-workflow-trace-archive-jobs) | [Workflow Trace Archive] Export jobs
[`server workflow-trace-archive-metrics`](#server-workflow-trace-archive-metrics) | [Workflow Trace Archive] Export numeric metrics
[`server workflow-trace-archive-workflow-connections`](#server-workflow-trace-archive-workflow-connections) | [Workflow Trace Archive] Export workflow connections
[`server workflow-trace-archive-workflow-invocation-steps`](#server-workflow-trace-archive-workflow-invocation-steps) | [Workflow Trace Archive] Export workflow invocation steps
[`server workflow-trace-archive-workflow-invocations`](#server-workflow-trace-archive-workflow-invocations) | [Workflow Trace Archive] Export workflow invocations
[`server workflow-trace-archive-workflow-step-input`](#server-workflow-trace-archive-workflow-step-input) | [Workflow Trace Archive] Export workflow step-input
[`server workflow-trace-archive-workflow-steps`](#server-workflow-trace-archive-workflow-steps) | [Workflow Trace Archive] Export workflow steps
[`server workflow-trace-archive-workflows`](#server-workflow-trace-archive-workflows) | [Workflow Trace Archive] Export workflows
[`server workflows`](#server-workflows) | Counts of workflows

## server allocated-cpu

([*source*](https://github.com/galaxyproject/gxadmin/search?q=server_allocated-cpu&type=Code))
server allocated-cpu -  CPU time per job runner

**SYNOPSIS**

    gxadmin server allocated-cpu [--op=<...>] [--date=<yyyy-mm-dd>]


## server allocated-gpu

([*source*](https://github.com/galaxyproject/gxadmin/search?q=server_allocated-gpu&type=Code))
server allocated-gpu -  GPU time per job runner

**SYNOPSIS**

    gxadmin server allocated-gpu [--op=<...>] [--date=<yyyy-mm-dd>]


## server datasets

([*source*](https://github.com/galaxyproject/gxadmin/search?q=server_datasets&type=Code))
server datasets -  Counts of datasets

**SYNOPSIS**

    gxadmin server datasets [--op=<...>] [--date=<yyyy-mm-dd>]


## server disk-usage

([*source*](https://github.com/galaxyproject/gxadmin/search?q=server_disk-usage&type=Code))
server disk-usage -  Retrieve an approximation of the global disk usage

**SYNOPSIS**

    gxadmin server disk-usage [--op=<...>] [--date=<yyyy-mm-dd>]

**NOTES**

ADDED: 21
AUTHORS: abretaud


## server groups

([*source*](https://github.com/galaxyproject/gxadmin/search?q=server_groups&type=Code))
server groups -  Counts of group memberships

**SYNOPSIS**

    gxadmin server groups [--op=<...>] [--date=<yyyy-mm-dd>]


## server groups-allocated-cpu

([*source*](https://github.com/galaxyproject/gxadmin/search?q=server_groups-allocated-cpu&type=Code))
server groups-allocated-cpu -  Retrieve an approximation of the CPU allocation for groups

**SYNOPSIS**

    gxadmin server groups-allocated-cpu [--op=<...>] [--date=<yyyy-mm-dd>]


## server groups-allocated-gpu

([*source*](https://github.com/galaxyproject/gxadmin/search?q=server_groups-allocated-gpu&type=Code))
server groups-allocated-gpu -  Retrieve an approximation of the GPU allocation for groups

**SYNOPSIS**

    gxadmin server groups-allocated-gpu [--op=<...>] [--date=<yyyy-mm-dd>]


## server groups-disk-usage

([*source*](https://github.com/galaxyproject/gxadmin/search?q=server_groups-disk-usage&type=Code))
server groups-disk-usage -  Retrieve an approximation of the disk usage for groups

**SYNOPSIS**

    gxadmin server groups-disk-usage [--op=<...>] [--date=<yyyy-mm-dd>]


## server hda

([*source*](https://github.com/galaxyproject/gxadmin/search?q=server_hda&type=Code))
server hda -  Counts of HDAs

**SYNOPSIS**

    gxadmin server hda [--op=<...>] [--date=<yyyy-mm-dd>]


## server histories

([*source*](https://github.com/galaxyproject/gxadmin/search?q=server_histories&type=Code))
server histories -  Counts of histories and sharing

**SYNOPSIS**

    gxadmin server histories [--op=<...>] [--date=<yyyy-mm-dd>]


## server jobs

([*source*](https://github.com/galaxyproject/gxadmin/search?q=server_jobs&type=Code))
server jobs -  Counts of jobs

**SYNOPSIS**

    gxadmin server jobs [--op=<...>] [--date=<yyyy-mm-dd>]


## server ts-repos

([*source*](https://github.com/galaxyproject/gxadmin/search?q=server_ts-repos&type=Code))
server ts-repos -  Counts of TS repos

**SYNOPSIS**

    gxadmin server ts-repos [--op=<...>] [--date=<yyyy-mm-dd>]


## server users

([*source*](https://github.com/galaxyproject/gxadmin/search?q=server_users&type=Code))
server users -  Count of different classifications of users

**SYNOPSIS**

    gxadmin server users [--op=<...>] [--date=<yyyy-mm-dd>]


## server users-with-oidc

([*source*](https://github.com/galaxyproject/gxadmin/search?q=server_users-with-oidc&type=Code))
server users-with-oidc -  How many users logged in with OIDC

**SYNOPSIS**

    gxadmin server users-with-oidc [--op=<...>] [--date=<yyyy-mm-dd>]


## server workflow-invocations

([*source*](https://github.com/galaxyproject/gxadmin/search?q=server_workflow-invocations&type=Code))
server workflow-invocations -  Counts of workflow invocations

**SYNOPSIS**

    gxadmin server workflow-invocations [--op=<...>] [--date=<yyyy-mm-dd>]


## server workflow-trace-archive-jobs

([*source*](https://github.com/galaxyproject/gxadmin/search?q=server_workflow-trace-archive-jobs&type=Code))
server workflow-trace-archive-jobs -  [Workflow Trace Archive] Export jobs

**SYNOPSIS**

    gxadmin server workflow-trace-archive-jobs

**NOTES**

Helper for WTA


## server workflow-trace-archive-metrics

([*source*](https://github.com/galaxyproject/gxadmin/search?q=server_workflow-trace-archive-metrics&type=Code))
server workflow-trace-archive-metrics -  [Workflow Trace Archive] Export numeric metrics

**SYNOPSIS**

    gxadmin server workflow-trace-archive-metrics

**NOTES**

Helper for WTA


## server workflow-trace-archive-workflow-connections

([*source*](https://github.com/galaxyproject/gxadmin/search?q=server_workflow-trace-archive-workflow-connections&type=Code))
server workflow-trace-archive-workflow-connections -  [Workflow Trace Archive] Export workflow connections

**SYNOPSIS**

    gxadmin server workflow-trace-archive-workflow-connections

**NOTES**

Helper for WTA


## server workflow-trace-archive-workflow-invocation-steps

([*source*](https://github.com/galaxyproject/gxadmin/search?q=server_workflow-trace-archive-workflow-invocation-steps&type=Code))
server workflow-trace-archive-workflow-invocation-steps -  [Workflow Trace Archive] Export workflow invocation steps

**SYNOPSIS**

    gxadmin server workflow-trace-archive-workflow-invocation-steps

**NOTES**

Helper for WTA


## server workflow-trace-archive-workflow-invocations

([*source*](https://github.com/galaxyproject/gxadmin/search?q=server_workflow-trace-archive-workflow-invocations&type=Code))
server workflow-trace-archive-workflow-invocations -  [Workflow Trace Archive] Export workflow invocations

**SYNOPSIS**

    gxadmin server workflow-trace-archive-workflow-invocations

**NOTES**

Helper for WTA


## server workflow-trace-archive-workflow-step-input

([*source*](https://github.com/galaxyproject/gxadmin/search?q=server_workflow-trace-archive-workflow-step-input&type=Code))
server workflow-trace-archive-workflow-step-input -  [Workflow Trace Archive] Export workflow step-input

**SYNOPSIS**

    gxadmin server workflow-trace-archive-workflow-step-input

**NOTES**

Helper for WTA


## server workflow-trace-archive-workflow-steps

([*source*](https://github.com/galaxyproject/gxadmin/search?q=server_workflow-trace-archive-workflow-steps&type=Code))
server workflow-trace-archive-workflow-steps -  [Workflow Trace Archive] Export workflow steps

**SYNOPSIS**

    gxadmin server workflow-trace-archive-workflow-steps

**NOTES**

Helper for WTA


## server workflow-trace-archive-workflows

([*source*](https://github.com/galaxyproject/gxadmin/search?q=server_workflow-trace-archive-workflows&type=Code))
server workflow-trace-archive-workflows -  [Workflow Trace Archive] Export workflows

**SYNOPSIS**

    gxadmin server workflow-trace-archive-workflows

**NOTES**

Helper for WTA


## server workflows

([*source*](https://github.com/galaxyproject/gxadmin/search?q=server_workflows&type=Code))
server workflows -  Counts of workflows

**SYNOPSIS**

    gxadmin server workflows [--op=<...>] [--date=<yyyy-mm-dd>]

