# server

Command | Description
------- | -----------
[`server allocated-cpu`](#server-allocated-cpu) | CPU time per job runner
[`server allocated-gpu`](#server-allocated-gpu) | GPU time per job runner
[`server datasets`](#server-datasets) | Counts of datasets
[`server groups-allocated-cpu`](#server-groups-allocated-cpu) | Retrieve an approximation of the CPU allocation for groups
[`server groups-allocated-gpu`](#server-groups-allocated-gpu) | Retrieve an approximation of the GPU allocation for groups
[`server groups`](#server-groups) | Counts of group memberships
[`server groups-disk-usage`](#server-groups-disk-usage) | Retrieve an approximation of the disk usage for groups
[`server hda`](#server-hda) | Counts of HDAs
[`server histories`](#server-histories) | Counts of histories and sharing
[`server jobs`](#server-jobs) | Counts of jobs
[`server ts-repos`](#server-ts-repos) | Counts of TS repos
[`server users`](#server-users) | Count of different classifications of users
[`server workflow-invocations`](#server-workflow-invocations) | Counts of workflow invocations
[`server workflows`](#server-workflows) | Counts of workflows

## server allocated-cpu

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=server_allocated-cpu&type=Code))
gxadmin usage:

DB Queries:
  'query' can be exchanged with 'tsvquery' or 'csvquery' for tab- and comma-separated variants.
  In some cases 'iquery' is supported for InfluxDB compatible output.
  In all cases 'explainquery' will show you the query plan, in case you need to optimise or index data. 'explainjsonquery' is useful with PEV: http://tatiyants.com/pev/

    query aq <table> <column> <-|job_id [job_id [...]]>             Given a list of IDs from a table (e.g. 'job'), access a specific column from that table
    query collection-usage                                          Information about how many collections of various types are used
    query data-origin-distribution [--human]                        data sources (uploaded vs derived)
    query data-origin-distribution-summary [--human]                breakdown of data sources (uploaded vs derived)
    query datasets-created-daily                                    The min/max/average/p95/p99 of total size of datasets created in a single day.
    query disk-usage [--human]                                      Disk usage per object store.
    query errored-jobs <hours> [--details]                          Lists jobs that errored in the last N hours.
    query good-for-pulsar                                           Look for jobs EU would like to send to pulsar
    query group-cpu-seconds [group]                                 Retrieve an approximation of the CPU time in seconds for group(s)
    query group-gpu-time [group]                                    Retrieve an approximation of the GPU time for users
    query groups-list                                               List all groups known to Galaxy
    query hdca-datasets <hdca_id>                                   List of files in a dataset collection
    query hdca-info <hdca_id>                                       Information on a dataset collection
    query history-connections                                       The connections of tools, from output to input, in histories (tool_predictions)
    query history-contents <history_id> [--dataset|--collection]    List datasets and/or collections in a history
    query history-runtime-system-by-tool <history_id>               Sum of runtimes by all jobs in a history, split by tool
    query history-runtime-system <history_id>                       Sum of runtimes by all jobs in a history
    query history-runtime-wallclock <history_id>                    Time as elapsed by a clock on the wall
    query job-history <id>                                          Job state history for a specific job
    query job-info <-|job_id [job_id [...]]>                        Retrieve information about jobs given some job IDs
    query job-inputs <id>                                           Input datasets to a specific job
    query job-outputs <id>                                          Output datasets from a specific job
    query jobs-max-by-cpu-hours                                     Top 10 jobs by CPU hours consumed (requires CGroups metrics)
    query jobs-nonterminal [username|id|email]                      Job info of nonterminal jobs separated by user
    query jobs-per-user <email>                                     Number of jobs run by a specific user
    query jobs-queued                                               How many queued jobs have external cluster IDs
    query jobs-queued-internal-by-handler                           How many queued jobs do not have external IDs, by handler
    query jobs-ready-to-run                                         Find jobs ready to run (Mostly a performance test)
    query largest-collection                                        Returns the size of the single largest collection
    query largest-histories [--human]                               Largest histories in Galaxy
    query latest-users                                              40 recently registered users
    query monthly-cpu-stats [year]                                  CPU years/hours allocated to tools by month
    query monthly-cpu-years                                         CPU years allocated to tools by month
    query monthly-data [year] [--human]                             Number of active users per month, running jobs
    query monthly-gpu-years                                         GPU years allocated to tools by month
    query monthly-jobs [year]                                       Number of jobs run each month
    query monthly-users-active [year]                               Number of active users per month, running jobs
    query monthly-users-registered [year]                           Number of users registered each month
    query old-histories <weeks>                                     Lists histories that haven't been updated (used) for <weeks>
    query pg-cache-hit                                              Check postgres in-memory cache hit ratio
    query pg-index-size [--human]                                   show table and index bloat in your database ordered by most wasteful
    query pg-index-usage                                            calculates your index hit rate (effective databases are at 99% and up)
    query pg-long-running-queries                                   show all queries longer than five minutes by descending duration
    query pg-mandelbrot                                             show the mandlebrot set
    query pg-stat-bgwriter                                          Stats about the behaviour of the bgwriter, checkpoints, buffers, etc.
    query pg-stat-user-tables                                       stats about tables (tuples, index scans, vacuums, analyzes)
    query pg-table-bloat [--human]                                  show table and index bloat in your database ordered by most wasteful
    query pg-table-size [--human]                                   show the size of the tables (excluding indexes), descending by size
    query pg-unused-indexes [--human]                               show unused and almost unused indexes
    query pg-vacuum-stats                                           show dead rows and whether an automatic vacuum is expected to be triggered
    query q <query>                                                 Passes a raw SQL query directly through to the database
    query queue                                                     Brief overview of currently running jobs
    query queue-detail [--all] [--seconds]                          Detailed overview of running and queued jobs
    query queue-detail-by-handler <handler_id>                      List jobs for a specific handler
    query queue-overview [--short-tool-id]                          View used mostly for monitoring
    query queue-time <tool_id>                                      The average/95%/99% a specific tool spends in queue state.
    query recent-jobs <hours>                                       Jobs run in the past <hours> (in any state)
    query runtime-per-user <email>                                  computation time of user (by email)
    query tool-available-metrics <tool_id>                          list all available metrics for a given tool
    query tool-errors [--short-tool-id] [weeks|4]                   Summarize percent of tool runs in error over the past weeks for all tools that have failed (most popular tools first)
    query tool-last-used-date                                       When was the most recent invocation of every tool
    query tool-likely-broken [--short-tool-id] [weeks|4]            Find tools that have been executed in recent weeks that are (or were due to job running) likely substantially broken
    query tool-metrics <tool_id> <metric_id> [--like]               See values of a specific metric
    query tool-new-errors [weeks|4]                                 Summarize percent of tool runs in error over the past weeks for "new tools"
    query tool-popularity [months|24]                               Most run tools by month (tool_predictions)
    query tool-usage [weeks]                                        Counts of tool runs in the past weeks (default = all)
    query total-jobs [year]                                         Total number of jobs run by galaxy instance
    query training-list [--all]                                     List known trainings
    query training-members-remove <training> <username> [YESDOIT]   Remove a user from a training
    query training-members <tr_id>                                  List users in a specific training
    query training-queue <training_id>                              Jobs currently being run by people in a given training
    query ts-repos                                                  Counts of toolshed repositories by toolshed and owner.
    query upload-gb-in-past-hour [hours|1]                          Sum in bytes of files uploaded in the past hour
    query user-cpu-years                                            CPU years allocated to tools by user
    query user-disk-quota                                           Retrieves the 50 users with the largest quotas
    query user-disk-usage [--human]                                 Retrieve an approximation of the disk usage for users
    query user-gpu-years                                            GPU years allocated to tools by user
    query user-history-list <username|id|email> [--size]            Shows the ID of the history, it's size and when it was last updated.
    query user-recent-aggregate-jobs <username|id|email> [days|7]   Show aggregate information for jobs in past N days for user
    query users-count                                               Shows sums of active/external/deleted/purged accounts
    query users-total                                               Total number of Galaxy users (incl deleted, purged, inactive)
    query users-with-oidc                                           How many users logged in with OIDC
    query workers                                                   Retrieve a list of Galaxy worker processes
    query workflow-connections [--all]                              The connections of tools, from output to input, in the latest (or all) versions of user workflows (tool_predictions)
    query workflow-invocation-status                                Report on how many workflows are in new state by handler
    query workflow-invocation-totals                                Report on overall workflow counts, to ensure throughput

All commands can be prefixed with "time" to print execution time to stderr

help / -h / --help : this message. Invoke '--help' on any subcommand for help specific to that subcommand
Tip: Run "gxadmin meta whatsnew" to find out what's new in this release!

## server allocated-gpu

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=server_allocated-gpu&type=Code))
gxadmin usage:

DB Queries:
  'query' can be exchanged with 'tsvquery' or 'csvquery' for tab- and comma-separated variants.
  In some cases 'iquery' is supported for InfluxDB compatible output.
  In all cases 'explainquery' will show you the query plan, in case you need to optimise or index data. 'explainjsonquery' is useful with PEV: http://tatiyants.com/pev/

    query aq <table> <column> <-|job_id [job_id [...]]>             Given a list of IDs from a table (e.g. 'job'), access a specific column from that table
    query collection-usage                                          Information about how many collections of various types are used
    query data-origin-distribution [--human]                        data sources (uploaded vs derived)
    query data-origin-distribution-summary [--human]                breakdown of data sources (uploaded vs derived)
    query datasets-created-daily                                    The min/max/average/p95/p99 of total size of datasets created in a single day.
    query disk-usage [--human]                                      Disk usage per object store.
    query errored-jobs <hours> [--details]                          Lists jobs that errored in the last N hours.
    query good-for-pulsar                                           Look for jobs EU would like to send to pulsar
    query group-cpu-seconds [group]                                 Retrieve an approximation of the CPU time in seconds for group(s)
    query group-gpu-time [group]                                    Retrieve an approximation of the GPU time for users
    query groups-list                                               List all groups known to Galaxy
    query hdca-datasets <hdca_id>                                   List of files in a dataset collection
    query hdca-info <hdca_id>                                       Information on a dataset collection
    query history-connections                                       The connections of tools, from output to input, in histories (tool_predictions)
    query history-contents <history_id> [--dataset|--collection]    List datasets and/or collections in a history
    query history-runtime-system-by-tool <history_id>               Sum of runtimes by all jobs in a history, split by tool
    query history-runtime-system <history_id>                       Sum of runtimes by all jobs in a history
    query history-runtime-wallclock <history_id>                    Time as elapsed by a clock on the wall
    query job-history <id>                                          Job state history for a specific job
    query job-info <-|job_id [job_id [...]]>                        Retrieve information about jobs given some job IDs
    query job-inputs <id>                                           Input datasets to a specific job
    query job-outputs <id>                                          Output datasets from a specific job
    query jobs-max-by-cpu-hours                                     Top 10 jobs by CPU hours consumed (requires CGroups metrics)
    query jobs-nonterminal [username|id|email]                      Job info of nonterminal jobs separated by user
    query jobs-per-user <email>                                     Number of jobs run by a specific user
    query jobs-queued                                               How many queued jobs have external cluster IDs
    query jobs-queued-internal-by-handler                           How many queued jobs do not have external IDs, by handler
    query jobs-ready-to-run                                         Find jobs ready to run (Mostly a performance test)
    query largest-collection                                        Returns the size of the single largest collection
    query largest-histories [--human]                               Largest histories in Galaxy
    query latest-users                                              40 recently registered users
    query monthly-cpu-stats [year]                                  CPU years/hours allocated to tools by month
    query monthly-cpu-years                                         CPU years allocated to tools by month
    query monthly-data [year] [--human]                             Number of active users per month, running jobs
    query monthly-gpu-years                                         GPU years allocated to tools by month
    query monthly-jobs [year]                                       Number of jobs run each month
    query monthly-users-active [year]                               Number of active users per month, running jobs
    query monthly-users-registered [year]                           Number of users registered each month
    query old-histories <weeks>                                     Lists histories that haven't been updated (used) for <weeks>
    query pg-cache-hit                                              Check postgres in-memory cache hit ratio
    query pg-index-size [--human]                                   show table and index bloat in your database ordered by most wasteful
    query pg-index-usage                                            calculates your index hit rate (effective databases are at 99% and up)
    query pg-long-running-queries                                   show all queries longer than five minutes by descending duration
    query pg-mandelbrot                                             show the mandlebrot set
    query pg-stat-bgwriter                                          Stats about the behaviour of the bgwriter, checkpoints, buffers, etc.
    query pg-stat-user-tables                                       stats about tables (tuples, index scans, vacuums, analyzes)
    query pg-table-bloat [--human]                                  show table and index bloat in your database ordered by most wasteful
    query pg-table-size [--human]                                   show the size of the tables (excluding indexes), descending by size
    query pg-unused-indexes [--human]                               show unused and almost unused indexes
    query pg-vacuum-stats                                           show dead rows and whether an automatic vacuum is expected to be triggered
    query q <query>                                                 Passes a raw SQL query directly through to the database
    query queue                                                     Brief overview of currently running jobs
    query queue-detail [--all] [--seconds]                          Detailed overview of running and queued jobs
    query queue-detail-by-handler <handler_id>                      List jobs for a specific handler
    query queue-overview [--short-tool-id]                          View used mostly for monitoring
    query queue-time <tool_id>                                      The average/95%/99% a specific tool spends in queue state.
    query recent-jobs <hours>                                       Jobs run in the past <hours> (in any state)
    query runtime-per-user <email>                                  computation time of user (by email)
    query tool-available-metrics <tool_id>                          list all available metrics for a given tool
    query tool-errors [--short-tool-id] [weeks|4]                   Summarize percent of tool runs in error over the past weeks for all tools that have failed (most popular tools first)
    query tool-last-used-date                                       When was the most recent invocation of every tool
    query tool-likely-broken [--short-tool-id] [weeks|4]            Find tools that have been executed in recent weeks that are (or were due to job running) likely substantially broken
    query tool-metrics <tool_id> <metric_id> [--like]               See values of a specific metric
    query tool-new-errors [weeks|4]                                 Summarize percent of tool runs in error over the past weeks for "new tools"
    query tool-popularity [months|24]                               Most run tools by month (tool_predictions)
    query tool-usage [weeks]                                        Counts of tool runs in the past weeks (default = all)
    query total-jobs [year]                                         Total number of jobs run by galaxy instance
    query training-list [--all]                                     List known trainings
    query training-members-remove <training> <username> [YESDOIT]   Remove a user from a training
    query training-members <tr_id>                                  List users in a specific training
    query training-queue <training_id>                              Jobs currently being run by people in a given training
    query ts-repos                                                  Counts of toolshed repositories by toolshed and owner.
    query upload-gb-in-past-hour [hours|1]                          Sum in bytes of files uploaded in the past hour
    query user-cpu-years                                            CPU years allocated to tools by user
    query user-disk-quota                                           Retrieves the 50 users with the largest quotas
    query user-disk-usage [--human]                                 Retrieve an approximation of the disk usage for users
    query user-gpu-years                                            GPU years allocated to tools by user
    query user-history-list <username|id|email> [--size]            Shows the ID of the history, it's size and when it was last updated.
    query user-recent-aggregate-jobs <username|id|email> [days|7]   Show aggregate information for jobs in past N days for user
    query users-count                                               Shows sums of active/external/deleted/purged accounts
    query users-total                                               Total number of Galaxy users (incl deleted, purged, inactive)
    query users-with-oidc                                           How many users logged in with OIDC
    query workers                                                   Retrieve a list of Galaxy worker processes
    query workflow-connections [--all]                              The connections of tools, from output to input, in the latest (or all) versions of user workflows (tool_predictions)
    query workflow-invocation-status                                Report on how many workflows are in new state by handler
    query workflow-invocation-totals                                Report on overall workflow counts, to ensure throughput

All commands can be prefixed with "time" to print execution time to stderr

help / -h / --help : this message. Invoke '--help' on any subcommand for help specific to that subcommand
Tip: Run "gxadmin meta whatsnew" to find out what's new in this release!

## server datasets

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=server_datasets&type=Code))
gxadmin usage:

DB Queries:
  'query' can be exchanged with 'tsvquery' or 'csvquery' for tab- and comma-separated variants.
  In some cases 'iquery' is supported for InfluxDB compatible output.
  In all cases 'explainquery' will show you the query plan, in case you need to optimise or index data. 'explainjsonquery' is useful with PEV: http://tatiyants.com/pev/

    query aq <table> <column> <-|job_id [job_id [...]]>             Given a list of IDs from a table (e.g. 'job'), access a specific column from that table
    query collection-usage                                          Information about how many collections of various types are used
    query data-origin-distribution [--human]                        data sources (uploaded vs derived)
    query data-origin-distribution-summary [--human]                breakdown of data sources (uploaded vs derived)
    query datasets-created-daily                                    The min/max/average/p95/p99 of total size of datasets created in a single day.
    query disk-usage [--human]                                      Disk usage per object store.
    query errored-jobs <hours> [--details]                          Lists jobs that errored in the last N hours.
    query good-for-pulsar                                           Look for jobs EU would like to send to pulsar
    query group-cpu-seconds [group]                                 Retrieve an approximation of the CPU time in seconds for group(s)
    query group-gpu-time [group]                                    Retrieve an approximation of the GPU time for users
    query groups-list                                               List all groups known to Galaxy
    query hdca-datasets <hdca_id>                                   List of files in a dataset collection
    query hdca-info <hdca_id>                                       Information on a dataset collection
    query history-connections                                       The connections of tools, from output to input, in histories (tool_predictions)
    query history-contents <history_id> [--dataset|--collection]    List datasets and/or collections in a history
    query history-runtime-system-by-tool <history_id>               Sum of runtimes by all jobs in a history, split by tool
    query history-runtime-system <history_id>                       Sum of runtimes by all jobs in a history
    query history-runtime-wallclock <history_id>                    Time as elapsed by a clock on the wall
    query job-history <id>                                          Job state history for a specific job
    query job-info <-|job_id [job_id [...]]>                        Retrieve information about jobs given some job IDs
    query job-inputs <id>                                           Input datasets to a specific job
    query job-outputs <id>                                          Output datasets from a specific job
    query jobs-max-by-cpu-hours                                     Top 10 jobs by CPU hours consumed (requires CGroups metrics)
    query jobs-nonterminal [username|id|email]                      Job info of nonterminal jobs separated by user
    query jobs-per-user <email>                                     Number of jobs run by a specific user
    query jobs-queued                                               How many queued jobs have external cluster IDs
    query jobs-queued-internal-by-handler                           How many queued jobs do not have external IDs, by handler
    query jobs-ready-to-run                                         Find jobs ready to run (Mostly a performance test)
    query largest-collection                                        Returns the size of the single largest collection
    query largest-histories [--human]                               Largest histories in Galaxy
    query latest-users                                              40 recently registered users
    query monthly-cpu-stats [year]                                  CPU years/hours allocated to tools by month
    query monthly-cpu-years                                         CPU years allocated to tools by month
    query monthly-data [year] [--human]                             Number of active users per month, running jobs
    query monthly-gpu-years                                         GPU years allocated to tools by month
    query monthly-jobs [year]                                       Number of jobs run each month
    query monthly-users-active [year]                               Number of active users per month, running jobs
    query monthly-users-registered [year]                           Number of users registered each month
    query old-histories <weeks>                                     Lists histories that haven't been updated (used) for <weeks>
    query pg-cache-hit                                              Check postgres in-memory cache hit ratio
    query pg-index-size [--human]                                   show table and index bloat in your database ordered by most wasteful
    query pg-index-usage                                            calculates your index hit rate (effective databases are at 99% and up)
    query pg-long-running-queries                                   show all queries longer than five minutes by descending duration
    query pg-mandelbrot                                             show the mandlebrot set
    query pg-stat-bgwriter                                          Stats about the behaviour of the bgwriter, checkpoints, buffers, etc.
    query pg-stat-user-tables                                       stats about tables (tuples, index scans, vacuums, analyzes)
    query pg-table-bloat [--human]                                  show table and index bloat in your database ordered by most wasteful
    query pg-table-size [--human]                                   show the size of the tables (excluding indexes), descending by size
    query pg-unused-indexes [--human]                               show unused and almost unused indexes
    query pg-vacuum-stats                                           show dead rows and whether an automatic vacuum is expected to be triggered
    query q <query>                                                 Passes a raw SQL query directly through to the database
    query queue                                                     Brief overview of currently running jobs
    query queue-detail [--all] [--seconds]                          Detailed overview of running and queued jobs
    query queue-detail-by-handler <handler_id>                      List jobs for a specific handler
    query queue-overview [--short-tool-id]                          View used mostly for monitoring
    query queue-time <tool_id>                                      The average/95%/99% a specific tool spends in queue state.
    query recent-jobs <hours>                                       Jobs run in the past <hours> (in any state)
    query runtime-per-user <email>                                  computation time of user (by email)
    query tool-available-metrics <tool_id>                          list all available metrics for a given tool
    query tool-errors [--short-tool-id] [weeks|4]                   Summarize percent of tool runs in error over the past weeks for all tools that have failed (most popular tools first)
    query tool-last-used-date                                       When was the most recent invocation of every tool
    query tool-likely-broken [--short-tool-id] [weeks|4]            Find tools that have been executed in recent weeks that are (or were due to job running) likely substantially broken
    query tool-metrics <tool_id> <metric_id> [--like]               See values of a specific metric
    query tool-new-errors [weeks|4]                                 Summarize percent of tool runs in error over the past weeks for "new tools"
    query tool-popularity [months|24]                               Most run tools by month (tool_predictions)
    query tool-usage [weeks]                                        Counts of tool runs in the past weeks (default = all)
    query total-jobs [year]                                         Total number of jobs run by galaxy instance
    query training-list [--all]                                     List known trainings
    query training-members-remove <training> <username> [YESDOIT]   Remove a user from a training
    query training-members <tr_id>                                  List users in a specific training
    query training-queue <training_id>                              Jobs currently being run by people in a given training
    query ts-repos                                                  Counts of toolshed repositories by toolshed and owner.
    query upload-gb-in-past-hour [hours|1]                          Sum in bytes of files uploaded in the past hour
    query user-cpu-years                                            CPU years allocated to tools by user
    query user-disk-quota                                           Retrieves the 50 users with the largest quotas
    query user-disk-usage [--human]                                 Retrieve an approximation of the disk usage for users
    query user-gpu-years                                            GPU years allocated to tools by user
    query user-history-list <username|id|email> [--size]            Shows the ID of the history, it's size and when it was last updated.
    query user-recent-aggregate-jobs <username|id|email> [days|7]   Show aggregate information for jobs in past N days for user
    query users-count                                               Shows sums of active/external/deleted/purged accounts
    query users-total                                               Total number of Galaxy users (incl deleted, purged, inactive)
    query users-with-oidc                                           How many users logged in with OIDC
    query workers                                                   Retrieve a list of Galaxy worker processes
    query workflow-connections [--all]                              The connections of tools, from output to input, in the latest (or all) versions of user workflows (tool_predictions)
    query workflow-invocation-status                                Report on how many workflows are in new state by handler
    query workflow-invocation-totals                                Report on overall workflow counts, to ensure throughput

All commands can be prefixed with "time" to print execution time to stderr

help / -h / --help : this message. Invoke '--help' on any subcommand for help specific to that subcommand
Tip: Run "gxadmin meta whatsnew" to find out what's new in this release!

## server groups-allocated-cpu

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=server_groups-allocated-cpu&type=Code))
gxadmin usage:

DB Queries:
  'query' can be exchanged with 'tsvquery' or 'csvquery' for tab- and comma-separated variants.
  In some cases 'iquery' is supported for InfluxDB compatible output.
  In all cases 'explainquery' will show you the query plan, in case you need to optimise or index data. 'explainjsonquery' is useful with PEV: http://tatiyants.com/pev/

    query aq <table> <column> <-|job_id [job_id [...]]>             Given a list of IDs from a table (e.g. 'job'), access a specific column from that table
    query collection-usage                                          Information about how many collections of various types are used
    query data-origin-distribution [--human]                        data sources (uploaded vs derived)
    query data-origin-distribution-summary [--human]                breakdown of data sources (uploaded vs derived)
    query datasets-created-daily                                    The min/max/average/p95/p99 of total size of datasets created in a single day.
    query disk-usage [--human]                                      Disk usage per object store.
    query errored-jobs <hours> [--details]                          Lists jobs that errored in the last N hours.
    query good-for-pulsar                                           Look for jobs EU would like to send to pulsar
    query group-cpu-seconds [group]                                 Retrieve an approximation of the CPU time in seconds for group(s)
    query group-gpu-time [group]                                    Retrieve an approximation of the GPU time for users
    query groups-list                                               List all groups known to Galaxy
    query hdca-datasets <hdca_id>                                   List of files in a dataset collection
    query hdca-info <hdca_id>                                       Information on a dataset collection
    query history-connections                                       The connections of tools, from output to input, in histories (tool_predictions)
    query history-contents <history_id> [--dataset|--collection]    List datasets and/or collections in a history
    query history-runtime-system-by-tool <history_id>               Sum of runtimes by all jobs in a history, split by tool
    query history-runtime-system <history_id>                       Sum of runtimes by all jobs in a history
    query history-runtime-wallclock <history_id>                    Time as elapsed by a clock on the wall
    query job-history <id>                                          Job state history for a specific job
    query job-info <-|job_id [job_id [...]]>                        Retrieve information about jobs given some job IDs
    query job-inputs <id>                                           Input datasets to a specific job
    query job-outputs <id>                                          Output datasets from a specific job
    query jobs-max-by-cpu-hours                                     Top 10 jobs by CPU hours consumed (requires CGroups metrics)
    query jobs-nonterminal [username|id|email]                      Job info of nonterminal jobs separated by user
    query jobs-per-user <email>                                     Number of jobs run by a specific user
    query jobs-queued                                               How many queued jobs have external cluster IDs
    query jobs-queued-internal-by-handler                           How many queued jobs do not have external IDs, by handler
    query jobs-ready-to-run                                         Find jobs ready to run (Mostly a performance test)
    query largest-collection                                        Returns the size of the single largest collection
    query largest-histories [--human]                               Largest histories in Galaxy
    query latest-users                                              40 recently registered users
    query monthly-cpu-stats [year]                                  CPU years/hours allocated to tools by month
    query monthly-cpu-years                                         CPU years allocated to tools by month
    query monthly-data [year] [--human]                             Number of active users per month, running jobs
    query monthly-gpu-years                                         GPU years allocated to tools by month
    query monthly-jobs [year]                                       Number of jobs run each month
    query monthly-users-active [year]                               Number of active users per month, running jobs
    query monthly-users-registered [year]                           Number of users registered each month
    query old-histories <weeks>                                     Lists histories that haven't been updated (used) for <weeks>
    query pg-cache-hit                                              Check postgres in-memory cache hit ratio
    query pg-index-size [--human]                                   show table and index bloat in your database ordered by most wasteful
    query pg-index-usage                                            calculates your index hit rate (effective databases are at 99% and up)
    query pg-long-running-queries                                   show all queries longer than five minutes by descending duration
    query pg-mandelbrot                                             show the mandlebrot set
    query pg-stat-bgwriter                                          Stats about the behaviour of the bgwriter, checkpoints, buffers, etc.
    query pg-stat-user-tables                                       stats about tables (tuples, index scans, vacuums, analyzes)
    query pg-table-bloat [--human]                                  show table and index bloat in your database ordered by most wasteful
    query pg-table-size [--human]                                   show the size of the tables (excluding indexes), descending by size
    query pg-unused-indexes [--human]                               show unused and almost unused indexes
    query pg-vacuum-stats                                           show dead rows and whether an automatic vacuum is expected to be triggered
    query q <query>                                                 Passes a raw SQL query directly through to the database
    query queue                                                     Brief overview of currently running jobs
    query queue-detail [--all] [--seconds]                          Detailed overview of running and queued jobs
    query queue-detail-by-handler <handler_id>                      List jobs for a specific handler
    query queue-overview [--short-tool-id]                          View used mostly for monitoring
    query queue-time <tool_id>                                      The average/95%/99% a specific tool spends in queue state.
    query recent-jobs <hours>                                       Jobs run in the past <hours> (in any state)
    query runtime-per-user <email>                                  computation time of user (by email)
    query tool-available-metrics <tool_id>                          list all available metrics for a given tool
    query tool-errors [--short-tool-id] [weeks|4]                   Summarize percent of tool runs in error over the past weeks for all tools that have failed (most popular tools first)
    query tool-last-used-date                                       When was the most recent invocation of every tool
    query tool-likely-broken [--short-tool-id] [weeks|4]            Find tools that have been executed in recent weeks that are (or were due to job running) likely substantially broken
    query tool-metrics <tool_id> <metric_id> [--like]               See values of a specific metric
    query tool-new-errors [weeks|4]                                 Summarize percent of tool runs in error over the past weeks for "new tools"
    query tool-popularity [months|24]                               Most run tools by month (tool_predictions)
    query tool-usage [weeks]                                        Counts of tool runs in the past weeks (default = all)
    query total-jobs [year]                                         Total number of jobs run by galaxy instance
    query training-list [--all]                                     List known trainings
    query training-members-remove <training> <username> [YESDOIT]   Remove a user from a training
    query training-members <tr_id>                                  List users in a specific training
    query training-queue <training_id>                              Jobs currently being run by people in a given training
    query ts-repos                                                  Counts of toolshed repositories by toolshed and owner.
    query upload-gb-in-past-hour [hours|1]                          Sum in bytes of files uploaded in the past hour
    query user-cpu-years                                            CPU years allocated to tools by user
    query user-disk-quota                                           Retrieves the 50 users with the largest quotas
    query user-disk-usage [--human]                                 Retrieve an approximation of the disk usage for users
    query user-gpu-years                                            GPU years allocated to tools by user
    query user-history-list <username|id|email> [--size]            Shows the ID of the history, it's size and when it was last updated.
    query user-recent-aggregate-jobs <username|id|email> [days|7]   Show aggregate information for jobs in past N days for user
    query users-count                                               Shows sums of active/external/deleted/purged accounts
    query users-total                                               Total number of Galaxy users (incl deleted, purged, inactive)
    query users-with-oidc                                           How many users logged in with OIDC
    query workers                                                   Retrieve a list of Galaxy worker processes
    query workflow-connections [--all]                              The connections of tools, from output to input, in the latest (or all) versions of user workflows (tool_predictions)
    query workflow-invocation-status                                Report on how many workflows are in new state by handler
    query workflow-invocation-totals                                Report on overall workflow counts, to ensure throughput

All commands can be prefixed with "time" to print execution time to stderr

help / -h / --help : this message. Invoke '--help' on any subcommand for help specific to that subcommand
Tip: Run "gxadmin meta whatsnew" to find out what's new in this release!

## server groups-allocated-gpu

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=server_groups-allocated-gpu&type=Code))
gxadmin usage:

DB Queries:
  'query' can be exchanged with 'tsvquery' or 'csvquery' for tab- and comma-separated variants.
  In some cases 'iquery' is supported for InfluxDB compatible output.
  In all cases 'explainquery' will show you the query plan, in case you need to optimise or index data. 'explainjsonquery' is useful with PEV: http://tatiyants.com/pev/

    query aq <table> <column> <-|job_id [job_id [...]]>             Given a list of IDs from a table (e.g. 'job'), access a specific column from that table
    query collection-usage                                          Information about how many collections of various types are used
    query data-origin-distribution [--human]                        data sources (uploaded vs derived)
    query data-origin-distribution-summary [--human]                breakdown of data sources (uploaded vs derived)
    query datasets-created-daily                                    The min/max/average/p95/p99 of total size of datasets created in a single day.
    query disk-usage [--human]                                      Disk usage per object store.
    query errored-jobs <hours> [--details]                          Lists jobs that errored in the last N hours.
    query good-for-pulsar                                           Look for jobs EU would like to send to pulsar
    query group-cpu-seconds [group]                                 Retrieve an approximation of the CPU time in seconds for group(s)
    query group-gpu-time [group]                                    Retrieve an approximation of the GPU time for users
    query groups-list                                               List all groups known to Galaxy
    query hdca-datasets <hdca_id>                                   List of files in a dataset collection
    query hdca-info <hdca_id>                                       Information on a dataset collection
    query history-connections                                       The connections of tools, from output to input, in histories (tool_predictions)
    query history-contents <history_id> [--dataset|--collection]    List datasets and/or collections in a history
    query history-runtime-system-by-tool <history_id>               Sum of runtimes by all jobs in a history, split by tool
    query history-runtime-system <history_id>                       Sum of runtimes by all jobs in a history
    query history-runtime-wallclock <history_id>                    Time as elapsed by a clock on the wall
    query job-history <id>                                          Job state history for a specific job
    query job-info <-|job_id [job_id [...]]>                        Retrieve information about jobs given some job IDs
    query job-inputs <id>                                           Input datasets to a specific job
    query job-outputs <id>                                          Output datasets from a specific job
    query jobs-max-by-cpu-hours                                     Top 10 jobs by CPU hours consumed (requires CGroups metrics)
    query jobs-nonterminal [username|id|email]                      Job info of nonterminal jobs separated by user
    query jobs-per-user <email>                                     Number of jobs run by a specific user
    query jobs-queued                                               How many queued jobs have external cluster IDs
    query jobs-queued-internal-by-handler                           How many queued jobs do not have external IDs, by handler
    query jobs-ready-to-run                                         Find jobs ready to run (Mostly a performance test)
    query largest-collection                                        Returns the size of the single largest collection
    query largest-histories [--human]                               Largest histories in Galaxy
    query latest-users                                              40 recently registered users
    query monthly-cpu-stats [year]                                  CPU years/hours allocated to tools by month
    query monthly-cpu-years                                         CPU years allocated to tools by month
    query monthly-data [year] [--human]                             Number of active users per month, running jobs
    query monthly-gpu-years                                         GPU years allocated to tools by month
    query monthly-jobs [year]                                       Number of jobs run each month
    query monthly-users-active [year]                               Number of active users per month, running jobs
    query monthly-users-registered [year]                           Number of users registered each month
    query old-histories <weeks>                                     Lists histories that haven't been updated (used) for <weeks>
    query pg-cache-hit                                              Check postgres in-memory cache hit ratio
    query pg-index-size [--human]                                   show table and index bloat in your database ordered by most wasteful
    query pg-index-usage                                            calculates your index hit rate (effective databases are at 99% and up)
    query pg-long-running-queries                                   show all queries longer than five minutes by descending duration
    query pg-mandelbrot                                             show the mandlebrot set
    query pg-stat-bgwriter                                          Stats about the behaviour of the bgwriter, checkpoints, buffers, etc.
    query pg-stat-user-tables                                       stats about tables (tuples, index scans, vacuums, analyzes)
    query pg-table-bloat [--human]                                  show table and index bloat in your database ordered by most wasteful
    query pg-table-size [--human]                                   show the size of the tables (excluding indexes), descending by size
    query pg-unused-indexes [--human]                               show unused and almost unused indexes
    query pg-vacuum-stats                                           show dead rows and whether an automatic vacuum is expected to be triggered
    query q <query>                                                 Passes a raw SQL query directly through to the database
    query queue                                                     Brief overview of currently running jobs
    query queue-detail [--all] [--seconds]                          Detailed overview of running and queued jobs
    query queue-detail-by-handler <handler_id>                      List jobs for a specific handler
    query queue-overview [--short-tool-id]                          View used mostly for monitoring
    query queue-time <tool_id>                                      The average/95%/99% a specific tool spends in queue state.
    query recent-jobs <hours>                                       Jobs run in the past <hours> (in any state)
    query runtime-per-user <email>                                  computation time of user (by email)
    query tool-available-metrics <tool_id>                          list all available metrics for a given tool
    query tool-errors [--short-tool-id] [weeks|4]                   Summarize percent of tool runs in error over the past weeks for all tools that have failed (most popular tools first)
    query tool-last-used-date                                       When was the most recent invocation of every tool
    query tool-likely-broken [--short-tool-id] [weeks|4]            Find tools that have been executed in recent weeks that are (or were due to job running) likely substantially broken
    query tool-metrics <tool_id> <metric_id> [--like]               See values of a specific metric
    query tool-new-errors [weeks|4]                                 Summarize percent of tool runs in error over the past weeks for "new tools"
    query tool-popularity [months|24]                               Most run tools by month (tool_predictions)
    query tool-usage [weeks]                                        Counts of tool runs in the past weeks (default = all)
    query total-jobs [year]                                         Total number of jobs run by galaxy instance
    query training-list [--all]                                     List known trainings
    query training-members-remove <training> <username> [YESDOIT]   Remove a user from a training
    query training-members <tr_id>                                  List users in a specific training
    query training-queue <training_id>                              Jobs currently being run by people in a given training
    query ts-repos                                                  Counts of toolshed repositories by toolshed and owner.
    query upload-gb-in-past-hour [hours|1]                          Sum in bytes of files uploaded in the past hour
    query user-cpu-years                                            CPU years allocated to tools by user
    query user-disk-quota                                           Retrieves the 50 users with the largest quotas
    query user-disk-usage [--human]                                 Retrieve an approximation of the disk usage for users
    query user-gpu-years                                            GPU years allocated to tools by user
    query user-history-list <username|id|email> [--size]            Shows the ID of the history, it's size and when it was last updated.
    query user-recent-aggregate-jobs <username|id|email> [days|7]   Show aggregate information for jobs in past N days for user
    query users-count                                               Shows sums of active/external/deleted/purged accounts
    query users-total                                               Total number of Galaxy users (incl deleted, purged, inactive)
    query users-with-oidc                                           How many users logged in with OIDC
    query workers                                                   Retrieve a list of Galaxy worker processes
    query workflow-connections [--all]                              The connections of tools, from output to input, in the latest (or all) versions of user workflows (tool_predictions)
    query workflow-invocation-status                                Report on how many workflows are in new state by handler
    query workflow-invocation-totals                                Report on overall workflow counts, to ensure throughput

All commands can be prefixed with "time" to print execution time to stderr

help / -h / --help : this message. Invoke '--help' on any subcommand for help specific to that subcommand
Tip: Run "gxadmin meta whatsnew" to find out what's new in this release!

## server groups

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=server_groups&type=Code))
gxadmin usage:

DB Queries:
  'query' can be exchanged with 'tsvquery' or 'csvquery' for tab- and comma-separated variants.
  In some cases 'iquery' is supported for InfluxDB compatible output.
  In all cases 'explainquery' will show you the query plan, in case you need to optimise or index data. 'explainjsonquery' is useful with PEV: http://tatiyants.com/pev/

    query aq <table> <column> <-|job_id [job_id [...]]>             Given a list of IDs from a table (e.g. 'job'), access a specific column from that table
    query collection-usage                                          Information about how many collections of various types are used
    query data-origin-distribution [--human]                        data sources (uploaded vs derived)
    query data-origin-distribution-summary [--human]                breakdown of data sources (uploaded vs derived)
    query datasets-created-daily                                    The min/max/average/p95/p99 of total size of datasets created in a single day.
    query disk-usage [--human]                                      Disk usage per object store.
    query errored-jobs <hours> [--details]                          Lists jobs that errored in the last N hours.
    query good-for-pulsar                                           Look for jobs EU would like to send to pulsar
    query group-cpu-seconds [group]                                 Retrieve an approximation of the CPU time in seconds for group(s)
    query group-gpu-time [group]                                    Retrieve an approximation of the GPU time for users
    query groups-list                                               List all groups known to Galaxy
    query hdca-datasets <hdca_id>                                   List of files in a dataset collection
    query hdca-info <hdca_id>                                       Information on a dataset collection
    query history-connections                                       The connections of tools, from output to input, in histories (tool_predictions)
    query history-contents <history_id> [--dataset|--collection]    List datasets and/or collections in a history
    query history-runtime-system-by-tool <history_id>               Sum of runtimes by all jobs in a history, split by tool
    query history-runtime-system <history_id>                       Sum of runtimes by all jobs in a history
    query history-runtime-wallclock <history_id>                    Time as elapsed by a clock on the wall
    query job-history <id>                                          Job state history for a specific job
    query job-info <-|job_id [job_id [...]]>                        Retrieve information about jobs given some job IDs
    query job-inputs <id>                                           Input datasets to a specific job
    query job-outputs <id>                                          Output datasets from a specific job
    query jobs-max-by-cpu-hours                                     Top 10 jobs by CPU hours consumed (requires CGroups metrics)
    query jobs-nonterminal [username|id|email]                      Job info of nonterminal jobs separated by user
    query jobs-per-user <email>                                     Number of jobs run by a specific user
    query jobs-queued                                               How many queued jobs have external cluster IDs
    query jobs-queued-internal-by-handler                           How many queued jobs do not have external IDs, by handler
    query jobs-ready-to-run                                         Find jobs ready to run (Mostly a performance test)
    query largest-collection                                        Returns the size of the single largest collection
    query largest-histories [--human]                               Largest histories in Galaxy
    query latest-users                                              40 recently registered users
    query monthly-cpu-stats [year]                                  CPU years/hours allocated to tools by month
    query monthly-cpu-years                                         CPU years allocated to tools by month
    query monthly-data [year] [--human]                             Number of active users per month, running jobs
    query monthly-gpu-years                                         GPU years allocated to tools by month
    query monthly-jobs [year]                                       Number of jobs run each month
    query monthly-users-active [year]                               Number of active users per month, running jobs
    query monthly-users-registered [year]                           Number of users registered each month
    query old-histories <weeks>                                     Lists histories that haven't been updated (used) for <weeks>
    query pg-cache-hit                                              Check postgres in-memory cache hit ratio
    query pg-index-size [--human]                                   show table and index bloat in your database ordered by most wasteful
    query pg-index-usage                                            calculates your index hit rate (effective databases are at 99% and up)
    query pg-long-running-queries                                   show all queries longer than five minutes by descending duration
    query pg-mandelbrot                                             show the mandlebrot set
    query pg-stat-bgwriter                                          Stats about the behaviour of the bgwriter, checkpoints, buffers, etc.
    query pg-stat-user-tables                                       stats about tables (tuples, index scans, vacuums, analyzes)
    query pg-table-bloat [--human]                                  show table and index bloat in your database ordered by most wasteful
    query pg-table-size [--human]                                   show the size of the tables (excluding indexes), descending by size
    query pg-unused-indexes [--human]                               show unused and almost unused indexes
    query pg-vacuum-stats                                           show dead rows and whether an automatic vacuum is expected to be triggered
    query q <query>                                                 Passes a raw SQL query directly through to the database
    query queue                                                     Brief overview of currently running jobs
    query queue-detail [--all] [--seconds]                          Detailed overview of running and queued jobs
    query queue-detail-by-handler <handler_id>                      List jobs for a specific handler
    query queue-overview [--short-tool-id]                          View used mostly for monitoring
    query queue-time <tool_id>                                      The average/95%/99% a specific tool spends in queue state.
    query recent-jobs <hours>                                       Jobs run in the past <hours> (in any state)
    query runtime-per-user <email>                                  computation time of user (by email)
    query tool-available-metrics <tool_id>                          list all available metrics for a given tool
    query tool-errors [--short-tool-id] [weeks|4]                   Summarize percent of tool runs in error over the past weeks for all tools that have failed (most popular tools first)
    query tool-last-used-date                                       When was the most recent invocation of every tool
    query tool-likely-broken [--short-tool-id] [weeks|4]            Find tools that have been executed in recent weeks that are (or were due to job running) likely substantially broken
    query tool-metrics <tool_id> <metric_id> [--like]               See values of a specific metric
    query tool-new-errors [weeks|4]                                 Summarize percent of tool runs in error over the past weeks for "new tools"
    query tool-popularity [months|24]                               Most run tools by month (tool_predictions)
    query tool-usage [weeks]                                        Counts of tool runs in the past weeks (default = all)
    query total-jobs [year]                                         Total number of jobs run by galaxy instance
    query training-list [--all]                                     List known trainings
    query training-members-remove <training> <username> [YESDOIT]   Remove a user from a training
    query training-members <tr_id>                                  List users in a specific training
    query training-queue <training_id>                              Jobs currently being run by people in a given training
    query ts-repos                                                  Counts of toolshed repositories by toolshed and owner.
    query upload-gb-in-past-hour [hours|1]                          Sum in bytes of files uploaded in the past hour
    query user-cpu-years                                            CPU years allocated to tools by user
    query user-disk-quota                                           Retrieves the 50 users with the largest quotas
    query user-disk-usage [--human]                                 Retrieve an approximation of the disk usage for users
    query user-gpu-years                                            GPU years allocated to tools by user
    query user-history-list <username|id|email> [--size]            Shows the ID of the history, it's size and when it was last updated.
    query user-recent-aggregate-jobs <username|id|email> [days|7]   Show aggregate information for jobs in past N days for user
    query users-count                                               Shows sums of active/external/deleted/purged accounts
    query users-total                                               Total number of Galaxy users (incl deleted, purged, inactive)
    query users-with-oidc                                           How many users logged in with OIDC
    query workers                                                   Retrieve a list of Galaxy worker processes
    query workflow-connections [--all]                              The connections of tools, from output to input, in the latest (or all) versions of user workflows (tool_predictions)
    query workflow-invocation-status                                Report on how many workflows are in new state by handler
    query workflow-invocation-totals                                Report on overall workflow counts, to ensure throughput

All commands can be prefixed with "time" to print execution time to stderr

help / -h / --help : this message. Invoke '--help' on any subcommand for help specific to that subcommand
Tip: Run "gxadmin meta whatsnew" to find out what's new in this release!

## server groups-disk-usage

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=server_groups-disk-usage&type=Code))
gxadmin usage:

DB Queries:
  'query' can be exchanged with 'tsvquery' or 'csvquery' for tab- and comma-separated variants.
  In some cases 'iquery' is supported for InfluxDB compatible output.
  In all cases 'explainquery' will show you the query plan, in case you need to optimise or index data. 'explainjsonquery' is useful with PEV: http://tatiyants.com/pev/

    query aq <table> <column> <-|job_id [job_id [...]]>             Given a list of IDs from a table (e.g. 'job'), access a specific column from that table
    query collection-usage                                          Information about how many collections of various types are used
    query data-origin-distribution [--human]                        data sources (uploaded vs derived)
    query data-origin-distribution-summary [--human]                breakdown of data sources (uploaded vs derived)
    query datasets-created-daily                                    The min/max/average/p95/p99 of total size of datasets created in a single day.
    query disk-usage [--human]                                      Disk usage per object store.
    query errored-jobs <hours> [--details]                          Lists jobs that errored in the last N hours.
    query good-for-pulsar                                           Look for jobs EU would like to send to pulsar
    query group-cpu-seconds [group]                                 Retrieve an approximation of the CPU time in seconds for group(s)
    query group-gpu-time [group]                                    Retrieve an approximation of the GPU time for users
    query groups-list                                               List all groups known to Galaxy
    query hdca-datasets <hdca_id>                                   List of files in a dataset collection
    query hdca-info <hdca_id>                                       Information on a dataset collection
    query history-connections                                       The connections of tools, from output to input, in histories (tool_predictions)
    query history-contents <history_id> [--dataset|--collection]    List datasets and/or collections in a history
    query history-runtime-system-by-tool <history_id>               Sum of runtimes by all jobs in a history, split by tool
    query history-runtime-system <history_id>                       Sum of runtimes by all jobs in a history
    query history-runtime-wallclock <history_id>                    Time as elapsed by a clock on the wall
    query job-history <id>                                          Job state history for a specific job
    query job-info <-|job_id [job_id [...]]>                        Retrieve information about jobs given some job IDs
    query job-inputs <id>                                           Input datasets to a specific job
    query job-outputs <id>                                          Output datasets from a specific job
    query jobs-max-by-cpu-hours                                     Top 10 jobs by CPU hours consumed (requires CGroups metrics)
    query jobs-nonterminal [username|id|email]                      Job info of nonterminal jobs separated by user
    query jobs-per-user <email>                                     Number of jobs run by a specific user
    query jobs-queued                                               How many queued jobs have external cluster IDs
    query jobs-queued-internal-by-handler                           How many queued jobs do not have external IDs, by handler
    query jobs-ready-to-run                                         Find jobs ready to run (Mostly a performance test)
    query largest-collection                                        Returns the size of the single largest collection
    query largest-histories [--human]                               Largest histories in Galaxy
    query latest-users                                              40 recently registered users
    query monthly-cpu-stats [year]                                  CPU years/hours allocated to tools by month
    query monthly-cpu-years                                         CPU years allocated to tools by month
    query monthly-data [year] [--human]                             Number of active users per month, running jobs
    query monthly-gpu-years                                         GPU years allocated to tools by month
    query monthly-jobs [year]                                       Number of jobs run each month
    query monthly-users-active [year]                               Number of active users per month, running jobs
    query monthly-users-registered [year]                           Number of users registered each month
    query old-histories <weeks>                                     Lists histories that haven't been updated (used) for <weeks>
    query pg-cache-hit                                              Check postgres in-memory cache hit ratio
    query pg-index-size [--human]                                   show table and index bloat in your database ordered by most wasteful
    query pg-index-usage                                            calculates your index hit rate (effective databases are at 99% and up)
    query pg-long-running-queries                                   show all queries longer than five minutes by descending duration
    query pg-mandelbrot                                             show the mandlebrot set
    query pg-stat-bgwriter                                          Stats about the behaviour of the bgwriter, checkpoints, buffers, etc.
    query pg-stat-user-tables                                       stats about tables (tuples, index scans, vacuums, analyzes)
    query pg-table-bloat [--human]                                  show table and index bloat in your database ordered by most wasteful
    query pg-table-size [--human]                                   show the size of the tables (excluding indexes), descending by size
    query pg-unused-indexes [--human]                               show unused and almost unused indexes
    query pg-vacuum-stats                                           show dead rows and whether an automatic vacuum is expected to be triggered
    query q <query>                                                 Passes a raw SQL query directly through to the database
    query queue                                                     Brief overview of currently running jobs
    query queue-detail [--all] [--seconds]                          Detailed overview of running and queued jobs
    query queue-detail-by-handler <handler_id>                      List jobs for a specific handler
    query queue-overview [--short-tool-id]                          View used mostly for monitoring
    query queue-time <tool_id>                                      The average/95%/99% a specific tool spends in queue state.
    query recent-jobs <hours>                                       Jobs run in the past <hours> (in any state)
    query runtime-per-user <email>                                  computation time of user (by email)
    query tool-available-metrics <tool_id>                          list all available metrics for a given tool
    query tool-errors [--short-tool-id] [weeks|4]                   Summarize percent of tool runs in error over the past weeks for all tools that have failed (most popular tools first)
    query tool-last-used-date                                       When was the most recent invocation of every tool
    query tool-likely-broken [--short-tool-id] [weeks|4]            Find tools that have been executed in recent weeks that are (or were due to job running) likely substantially broken
    query tool-metrics <tool_id> <metric_id> [--like]               See values of a specific metric
    query tool-new-errors [weeks|4]                                 Summarize percent of tool runs in error over the past weeks for "new tools"
    query tool-popularity [months|24]                               Most run tools by month (tool_predictions)
    query tool-usage [weeks]                                        Counts of tool runs in the past weeks (default = all)
    query total-jobs [year]                                         Total number of jobs run by galaxy instance
    query training-list [--all]                                     List known trainings
    query training-members-remove <training> <username> [YESDOIT]   Remove a user from a training
    query training-members <tr_id>                                  List users in a specific training
    query training-queue <training_id>                              Jobs currently being run by people in a given training
    query ts-repos                                                  Counts of toolshed repositories by toolshed and owner.
    query upload-gb-in-past-hour [hours|1]                          Sum in bytes of files uploaded in the past hour
    query user-cpu-years                                            CPU years allocated to tools by user
    query user-disk-quota                                           Retrieves the 50 users with the largest quotas
    query user-disk-usage [--human]                                 Retrieve an approximation of the disk usage for users
    query user-gpu-years                                            GPU years allocated to tools by user
    query user-history-list <username|id|email> [--size]            Shows the ID of the history, it's size and when it was last updated.
    query user-recent-aggregate-jobs <username|id|email> [days|7]   Show aggregate information for jobs in past N days for user
    query users-count                                               Shows sums of active/external/deleted/purged accounts
    query users-total                                               Total number of Galaxy users (incl deleted, purged, inactive)
    query users-with-oidc                                           How many users logged in with OIDC
    query workers                                                   Retrieve a list of Galaxy worker processes
    query workflow-connections [--all]                              The connections of tools, from output to input, in the latest (or all) versions of user workflows (tool_predictions)
    query workflow-invocation-status                                Report on how many workflows are in new state by handler
    query workflow-invocation-totals                                Report on overall workflow counts, to ensure throughput

All commands can be prefixed with "time" to print execution time to stderr

help / -h / --help : this message. Invoke '--help' on any subcommand for help specific to that subcommand
Tip: Run "gxadmin meta whatsnew" to find out what's new in this release!

## server hda

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=server_hda&type=Code))
gxadmin usage:

DB Queries:
  'query' can be exchanged with 'tsvquery' or 'csvquery' for tab- and comma-separated variants.
  In some cases 'iquery' is supported for InfluxDB compatible output.
  In all cases 'explainquery' will show you the query plan, in case you need to optimise or index data. 'explainjsonquery' is useful with PEV: http://tatiyants.com/pev/

    query aq <table> <column> <-|job_id [job_id [...]]>             Given a list of IDs from a table (e.g. 'job'), access a specific column from that table
    query collection-usage                                          Information about how many collections of various types are used
    query data-origin-distribution [--human]                        data sources (uploaded vs derived)
    query data-origin-distribution-summary [--human]                breakdown of data sources (uploaded vs derived)
    query datasets-created-daily                                    The min/max/average/p95/p99 of total size of datasets created in a single day.
    query disk-usage [--human]                                      Disk usage per object store.
    query errored-jobs <hours> [--details]                          Lists jobs that errored in the last N hours.
    query good-for-pulsar                                           Look for jobs EU would like to send to pulsar
    query group-cpu-seconds [group]                                 Retrieve an approximation of the CPU time in seconds for group(s)
    query group-gpu-time [group]                                    Retrieve an approximation of the GPU time for users
    query groups-list                                               List all groups known to Galaxy
    query hdca-datasets <hdca_id>                                   List of files in a dataset collection
    query hdca-info <hdca_id>                                       Information on a dataset collection
    query history-connections                                       The connections of tools, from output to input, in histories (tool_predictions)
    query history-contents <history_id> [--dataset|--collection]    List datasets and/or collections in a history
    query history-runtime-system-by-tool <history_id>               Sum of runtimes by all jobs in a history, split by tool
    query history-runtime-system <history_id>                       Sum of runtimes by all jobs in a history
    query history-runtime-wallclock <history_id>                    Time as elapsed by a clock on the wall
    query job-history <id>                                          Job state history for a specific job
    query job-info <-|job_id [job_id [...]]>                        Retrieve information about jobs given some job IDs
    query job-inputs <id>                                           Input datasets to a specific job
    query job-outputs <id>                                          Output datasets from a specific job
    query jobs-max-by-cpu-hours                                     Top 10 jobs by CPU hours consumed (requires CGroups metrics)
    query jobs-nonterminal [username|id|email]                      Job info of nonterminal jobs separated by user
    query jobs-per-user <email>                                     Number of jobs run by a specific user
    query jobs-queued                                               How many queued jobs have external cluster IDs
    query jobs-queued-internal-by-handler                           How many queued jobs do not have external IDs, by handler
    query jobs-ready-to-run                                         Find jobs ready to run (Mostly a performance test)
    query largest-collection                                        Returns the size of the single largest collection
    query largest-histories [--human]                               Largest histories in Galaxy
    query latest-users                                              40 recently registered users
    query monthly-cpu-stats [year]                                  CPU years/hours allocated to tools by month
    query monthly-cpu-years                                         CPU years allocated to tools by month
    query monthly-data [year] [--human]                             Number of active users per month, running jobs
    query monthly-gpu-years                                         GPU years allocated to tools by month
    query monthly-jobs [year]                                       Number of jobs run each month
    query monthly-users-active [year]                               Number of active users per month, running jobs
    query monthly-users-registered [year]                           Number of users registered each month
    query old-histories <weeks>                                     Lists histories that haven't been updated (used) for <weeks>
    query pg-cache-hit                                              Check postgres in-memory cache hit ratio
    query pg-index-size [--human]                                   show table and index bloat in your database ordered by most wasteful
    query pg-index-usage                                            calculates your index hit rate (effective databases are at 99% and up)
    query pg-long-running-queries                                   show all queries longer than five minutes by descending duration
    query pg-mandelbrot                                             show the mandlebrot set
    query pg-stat-bgwriter                                          Stats about the behaviour of the bgwriter, checkpoints, buffers, etc.
    query pg-stat-user-tables                                       stats about tables (tuples, index scans, vacuums, analyzes)
    query pg-table-bloat [--human]                                  show table and index bloat in your database ordered by most wasteful
    query pg-table-size [--human]                                   show the size of the tables (excluding indexes), descending by size
    query pg-unused-indexes [--human]                               show unused and almost unused indexes
    query pg-vacuum-stats                                           show dead rows and whether an automatic vacuum is expected to be triggered
    query q <query>                                                 Passes a raw SQL query directly through to the database
    query queue                                                     Brief overview of currently running jobs
    query queue-detail [--all] [--seconds]                          Detailed overview of running and queued jobs
    query queue-detail-by-handler <handler_id>                      List jobs for a specific handler
    query queue-overview [--short-tool-id]                          View used mostly for monitoring
    query queue-time <tool_id>                                      The average/95%/99% a specific tool spends in queue state.
    query recent-jobs <hours>                                       Jobs run in the past <hours> (in any state)
    query runtime-per-user <email>                                  computation time of user (by email)
    query tool-available-metrics <tool_id>                          list all available metrics for a given tool
    query tool-errors [--short-tool-id] [weeks|4]                   Summarize percent of tool runs in error over the past weeks for all tools that have failed (most popular tools first)
    query tool-last-used-date                                       When was the most recent invocation of every tool
    query tool-likely-broken [--short-tool-id] [weeks|4]            Find tools that have been executed in recent weeks that are (or were due to job running) likely substantially broken
    query tool-metrics <tool_id> <metric_id> [--like]               See values of a specific metric
    query tool-new-errors [weeks|4]                                 Summarize percent of tool runs in error over the past weeks for "new tools"
    query tool-popularity [months|24]                               Most run tools by month (tool_predictions)
    query tool-usage [weeks]                                        Counts of tool runs in the past weeks (default = all)
    query total-jobs [year]                                         Total number of jobs run by galaxy instance
    query training-list [--all]                                     List known trainings
    query training-members-remove <training> <username> [YESDOIT]   Remove a user from a training
    query training-members <tr_id>                                  List users in a specific training
    query training-queue <training_id>                              Jobs currently being run by people in a given training
    query ts-repos                                                  Counts of toolshed repositories by toolshed and owner.
    query upload-gb-in-past-hour [hours|1]                          Sum in bytes of files uploaded in the past hour
    query user-cpu-years                                            CPU years allocated to tools by user
    query user-disk-quota                                           Retrieves the 50 users with the largest quotas
    query user-disk-usage [--human]                                 Retrieve an approximation of the disk usage for users
    query user-gpu-years                                            GPU years allocated to tools by user
    query user-history-list <username|id|email> [--size]            Shows the ID of the history, it's size and when it was last updated.
    query user-recent-aggregate-jobs <username|id|email> [days|7]   Show aggregate information for jobs in past N days for user
    query users-count                                               Shows sums of active/external/deleted/purged accounts
    query users-total                                               Total number of Galaxy users (incl deleted, purged, inactive)
    query users-with-oidc                                           How many users logged in with OIDC
    query workers                                                   Retrieve a list of Galaxy worker processes
    query workflow-connections [--all]                              The connections of tools, from output to input, in the latest (or all) versions of user workflows (tool_predictions)
    query workflow-invocation-status                                Report on how many workflows are in new state by handler
    query workflow-invocation-totals                                Report on overall workflow counts, to ensure throughput

All commands can be prefixed with "time" to print execution time to stderr

help / -h / --help : this message. Invoke '--help' on any subcommand for help specific to that subcommand
Tip: Run "gxadmin meta whatsnew" to find out what's new in this release!

## server histories

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=server_histories&type=Code))
gxadmin usage:

DB Queries:
  'query' can be exchanged with 'tsvquery' or 'csvquery' for tab- and comma-separated variants.
  In some cases 'iquery' is supported for InfluxDB compatible output.
  In all cases 'explainquery' will show you the query plan, in case you need to optimise or index data. 'explainjsonquery' is useful with PEV: http://tatiyants.com/pev/

    query aq <table> <column> <-|job_id [job_id [...]]>             Given a list of IDs from a table (e.g. 'job'), access a specific column from that table
    query collection-usage                                          Information about how many collections of various types are used
    query data-origin-distribution [--human]                        data sources (uploaded vs derived)
    query data-origin-distribution-summary [--human]                breakdown of data sources (uploaded vs derived)
    query datasets-created-daily                                    The min/max/average/p95/p99 of total size of datasets created in a single day.
    query disk-usage [--human]                                      Disk usage per object store.
    query errored-jobs <hours> [--details]                          Lists jobs that errored in the last N hours.
    query good-for-pulsar                                           Look for jobs EU would like to send to pulsar
    query group-cpu-seconds [group]                                 Retrieve an approximation of the CPU time in seconds for group(s)
    query group-gpu-time [group]                                    Retrieve an approximation of the GPU time for users
    query groups-list                                               List all groups known to Galaxy
    query hdca-datasets <hdca_id>                                   List of files in a dataset collection
    query hdca-info <hdca_id>                                       Information on a dataset collection
    query history-connections                                       The connections of tools, from output to input, in histories (tool_predictions)
    query history-contents <history_id> [--dataset|--collection]    List datasets and/or collections in a history
    query history-runtime-system-by-tool <history_id>               Sum of runtimes by all jobs in a history, split by tool
    query history-runtime-system <history_id>                       Sum of runtimes by all jobs in a history
    query history-runtime-wallclock <history_id>                    Time as elapsed by a clock on the wall
    query job-history <id>                                          Job state history for a specific job
    query job-info <-|job_id [job_id [...]]>                        Retrieve information about jobs given some job IDs
    query job-inputs <id>                                           Input datasets to a specific job
    query job-outputs <id>                                          Output datasets from a specific job
    query jobs-max-by-cpu-hours                                     Top 10 jobs by CPU hours consumed (requires CGroups metrics)
    query jobs-nonterminal [username|id|email]                      Job info of nonterminal jobs separated by user
    query jobs-per-user <email>                                     Number of jobs run by a specific user
    query jobs-queued                                               How many queued jobs have external cluster IDs
    query jobs-queued-internal-by-handler                           How many queued jobs do not have external IDs, by handler
    query jobs-ready-to-run                                         Find jobs ready to run (Mostly a performance test)
    query largest-collection                                        Returns the size of the single largest collection
    query largest-histories [--human]                               Largest histories in Galaxy
    query latest-users                                              40 recently registered users
    query monthly-cpu-stats [year]                                  CPU years/hours allocated to tools by month
    query monthly-cpu-years                                         CPU years allocated to tools by month
    query monthly-data [year] [--human]                             Number of active users per month, running jobs
    query monthly-gpu-years                                         GPU years allocated to tools by month
    query monthly-jobs [year]                                       Number of jobs run each month
    query monthly-users-active [year]                               Number of active users per month, running jobs
    query monthly-users-registered [year]                           Number of users registered each month
    query old-histories <weeks>                                     Lists histories that haven't been updated (used) for <weeks>
    query pg-cache-hit                                              Check postgres in-memory cache hit ratio
    query pg-index-size [--human]                                   show table and index bloat in your database ordered by most wasteful
    query pg-index-usage                                            calculates your index hit rate (effective databases are at 99% and up)
    query pg-long-running-queries                                   show all queries longer than five minutes by descending duration
    query pg-mandelbrot                                             show the mandlebrot set
    query pg-stat-bgwriter                                          Stats about the behaviour of the bgwriter, checkpoints, buffers, etc.
    query pg-stat-user-tables                                       stats about tables (tuples, index scans, vacuums, analyzes)
    query pg-table-bloat [--human]                                  show table and index bloat in your database ordered by most wasteful
    query pg-table-size [--human]                                   show the size of the tables (excluding indexes), descending by size
    query pg-unused-indexes [--human]                               show unused and almost unused indexes
    query pg-vacuum-stats                                           show dead rows and whether an automatic vacuum is expected to be triggered
    query q <query>                                                 Passes a raw SQL query directly through to the database
    query queue                                                     Brief overview of currently running jobs
    query queue-detail [--all] [--seconds]                          Detailed overview of running and queued jobs
    query queue-detail-by-handler <handler_id>                      List jobs for a specific handler
    query queue-overview [--short-tool-id]                          View used mostly for monitoring
    query queue-time <tool_id>                                      The average/95%/99% a specific tool spends in queue state.
    query recent-jobs <hours>                                       Jobs run in the past <hours> (in any state)
    query runtime-per-user <email>                                  computation time of user (by email)
    query tool-available-metrics <tool_id>                          list all available metrics for a given tool
    query tool-errors [--short-tool-id] [weeks|4]                   Summarize percent of tool runs in error over the past weeks for all tools that have failed (most popular tools first)
    query tool-last-used-date                                       When was the most recent invocation of every tool
    query tool-likely-broken [--short-tool-id] [weeks|4]            Find tools that have been executed in recent weeks that are (or were due to job running) likely substantially broken
    query tool-metrics <tool_id> <metric_id> [--like]               See values of a specific metric
    query tool-new-errors [weeks|4]                                 Summarize percent of tool runs in error over the past weeks for "new tools"
    query tool-popularity [months|24]                               Most run tools by month (tool_predictions)
    query tool-usage [weeks]                                        Counts of tool runs in the past weeks (default = all)
    query total-jobs [year]                                         Total number of jobs run by galaxy instance
    query training-list [--all]                                     List known trainings
    query training-members-remove <training> <username> [YESDOIT]   Remove a user from a training
    query training-members <tr_id>                                  List users in a specific training
    query training-queue <training_id>                              Jobs currently being run by people in a given training
    query ts-repos                                                  Counts of toolshed repositories by toolshed and owner.
    query upload-gb-in-past-hour [hours|1]                          Sum in bytes of files uploaded in the past hour
    query user-cpu-years                                            CPU years allocated to tools by user
    query user-disk-quota                                           Retrieves the 50 users with the largest quotas
    query user-disk-usage [--human]                                 Retrieve an approximation of the disk usage for users
    query user-gpu-years                                            GPU years allocated to tools by user
    query user-history-list <username|id|email> [--size]            Shows the ID of the history, it's size and when it was last updated.
    query user-recent-aggregate-jobs <username|id|email> [days|7]   Show aggregate information for jobs in past N days for user
    query users-count                                               Shows sums of active/external/deleted/purged accounts
    query users-total                                               Total number of Galaxy users (incl deleted, purged, inactive)
    query users-with-oidc                                           How many users logged in with OIDC
    query workers                                                   Retrieve a list of Galaxy worker processes
    query workflow-connections [--all]                              The connections of tools, from output to input, in the latest (or all) versions of user workflows (tool_predictions)
    query workflow-invocation-status                                Report on how many workflows are in new state by handler
    query workflow-invocation-totals                                Report on overall workflow counts, to ensure throughput

All commands can be prefixed with "time" to print execution time to stderr

help / -h / --help : this message. Invoke '--help' on any subcommand for help specific to that subcommand
Tip: Run "gxadmin meta whatsnew" to find out what's new in this release!

## server jobs

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=server_jobs&type=Code))
gxadmin usage:

DB Queries:
  'query' can be exchanged with 'tsvquery' or 'csvquery' for tab- and comma-separated variants.
  In some cases 'iquery' is supported for InfluxDB compatible output.
  In all cases 'explainquery' will show you the query plan, in case you need to optimise or index data. 'explainjsonquery' is useful with PEV: http://tatiyants.com/pev/

    query aq <table> <column> <-|job_id [job_id [...]]>             Given a list of IDs from a table (e.g. 'job'), access a specific column from that table
    query collection-usage                                          Information about how many collections of various types are used
    query data-origin-distribution [--human]                        data sources (uploaded vs derived)
    query data-origin-distribution-summary [--human]                breakdown of data sources (uploaded vs derived)
    query datasets-created-daily                                    The min/max/average/p95/p99 of total size of datasets created in a single day.
    query disk-usage [--human]                                      Disk usage per object store.
    query errored-jobs <hours> [--details]                          Lists jobs that errored in the last N hours.
    query good-for-pulsar                                           Look for jobs EU would like to send to pulsar
    query group-cpu-seconds [group]                                 Retrieve an approximation of the CPU time in seconds for group(s)
    query group-gpu-time [group]                                    Retrieve an approximation of the GPU time for users
    query groups-list                                               List all groups known to Galaxy
    query hdca-datasets <hdca_id>                                   List of files in a dataset collection
    query hdca-info <hdca_id>                                       Information on a dataset collection
    query history-connections                                       The connections of tools, from output to input, in histories (tool_predictions)
    query history-contents <history_id> [--dataset|--collection]    List datasets and/or collections in a history
    query history-runtime-system-by-tool <history_id>               Sum of runtimes by all jobs in a history, split by tool
    query history-runtime-system <history_id>                       Sum of runtimes by all jobs in a history
    query history-runtime-wallclock <history_id>                    Time as elapsed by a clock on the wall
    query job-history <id>                                          Job state history for a specific job
    query job-info <-|job_id [job_id [...]]>                        Retrieve information about jobs given some job IDs
    query job-inputs <id>                                           Input datasets to a specific job
    query job-outputs <id>                                          Output datasets from a specific job
    query jobs-max-by-cpu-hours                                     Top 10 jobs by CPU hours consumed (requires CGroups metrics)
    query jobs-nonterminal [username|id|email]                      Job info of nonterminal jobs separated by user
    query jobs-per-user <email>                                     Number of jobs run by a specific user
    query jobs-queued                                               How many queued jobs have external cluster IDs
    query jobs-queued-internal-by-handler                           How many queued jobs do not have external IDs, by handler
    query jobs-ready-to-run                                         Find jobs ready to run (Mostly a performance test)
    query largest-collection                                        Returns the size of the single largest collection
    query largest-histories [--human]                               Largest histories in Galaxy
    query latest-users                                              40 recently registered users
    query monthly-cpu-stats [year]                                  CPU years/hours allocated to tools by month
    query monthly-cpu-years                                         CPU years allocated to tools by month
    query monthly-data [year] [--human]                             Number of active users per month, running jobs
    query monthly-gpu-years                                         GPU years allocated to tools by month
    query monthly-jobs [year]                                       Number of jobs run each month
    query monthly-users-active [year]                               Number of active users per month, running jobs
    query monthly-users-registered [year]                           Number of users registered each month
    query old-histories <weeks>                                     Lists histories that haven't been updated (used) for <weeks>
    query pg-cache-hit                                              Check postgres in-memory cache hit ratio
    query pg-index-size [--human]                                   show table and index bloat in your database ordered by most wasteful
    query pg-index-usage                                            calculates your index hit rate (effective databases are at 99% and up)
    query pg-long-running-queries                                   show all queries longer than five minutes by descending duration
    query pg-mandelbrot                                             show the mandlebrot set
    query pg-stat-bgwriter                                          Stats about the behaviour of the bgwriter, checkpoints, buffers, etc.
    query pg-stat-user-tables                                       stats about tables (tuples, index scans, vacuums, analyzes)
    query pg-table-bloat [--human]                                  show table and index bloat in your database ordered by most wasteful
    query pg-table-size [--human]                                   show the size of the tables (excluding indexes), descending by size
    query pg-unused-indexes [--human]                               show unused and almost unused indexes
    query pg-vacuum-stats                                           show dead rows and whether an automatic vacuum is expected to be triggered
    query q <query>                                                 Passes a raw SQL query directly through to the database
    query queue                                                     Brief overview of currently running jobs
    query queue-detail [--all] [--seconds]                          Detailed overview of running and queued jobs
    query queue-detail-by-handler <handler_id>                      List jobs for a specific handler
    query queue-overview [--short-tool-id]                          View used mostly for monitoring
    query queue-time <tool_id>                                      The average/95%/99% a specific tool spends in queue state.
    query recent-jobs <hours>                                       Jobs run in the past <hours> (in any state)
    query runtime-per-user <email>                                  computation time of user (by email)
    query tool-available-metrics <tool_id>                          list all available metrics for a given tool
    query tool-errors [--short-tool-id] [weeks|4]                   Summarize percent of tool runs in error over the past weeks for all tools that have failed (most popular tools first)
    query tool-last-used-date                                       When was the most recent invocation of every tool
    query tool-likely-broken [--short-tool-id] [weeks|4]            Find tools that have been executed in recent weeks that are (or were due to job running) likely substantially broken
    query tool-metrics <tool_id> <metric_id> [--like]               See values of a specific metric
    query tool-new-errors [weeks|4]                                 Summarize percent of tool runs in error over the past weeks for "new tools"
    query tool-popularity [months|24]                               Most run tools by month (tool_predictions)
    query tool-usage [weeks]                                        Counts of tool runs in the past weeks (default = all)
    query total-jobs [year]                                         Total number of jobs run by galaxy instance
    query training-list [--all]                                     List known trainings
    query training-members-remove <training> <username> [YESDOIT]   Remove a user from a training
    query training-members <tr_id>                                  List users in a specific training
    query training-queue <training_id>                              Jobs currently being run by people in a given training
    query ts-repos                                                  Counts of toolshed repositories by toolshed and owner.
    query upload-gb-in-past-hour [hours|1]                          Sum in bytes of files uploaded in the past hour
    query user-cpu-years                                            CPU years allocated to tools by user
    query user-disk-quota                                           Retrieves the 50 users with the largest quotas
    query user-disk-usage [--human]                                 Retrieve an approximation of the disk usage for users
    query user-gpu-years                                            GPU years allocated to tools by user
    query user-history-list <username|id|email> [--size]            Shows the ID of the history, it's size and when it was last updated.
    query user-recent-aggregate-jobs <username|id|email> [days|7]   Show aggregate information for jobs in past N days for user
    query users-count                                               Shows sums of active/external/deleted/purged accounts
    query users-total                                               Total number of Galaxy users (incl deleted, purged, inactive)
    query users-with-oidc                                           How many users logged in with OIDC
    query workers                                                   Retrieve a list of Galaxy worker processes
    query workflow-connections [--all]                              The connections of tools, from output to input, in the latest (or all) versions of user workflows (tool_predictions)
    query workflow-invocation-status                                Report on how many workflows are in new state by handler
    query workflow-invocation-totals                                Report on overall workflow counts, to ensure throughput

All commands can be prefixed with "time" to print execution time to stderr

help / -h / --help : this message. Invoke '--help' on any subcommand for help specific to that subcommand
Tip: Run "gxadmin meta whatsnew" to find out what's new in this release!

## server ts-repos

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=server_ts-repos&type=Code))
server ts-repos -  Counts of TS repos

**SYNOPSIS**

    gxadmin server ts-repos


## server users

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=server_users&type=Code))
gxadmin usage:

DB Queries:
  'query' can be exchanged with 'tsvquery' or 'csvquery' for tab- and comma-separated variants.
  In some cases 'iquery' is supported for InfluxDB compatible output.
  In all cases 'explainquery' will show you the query plan, in case you need to optimise or index data. 'explainjsonquery' is useful with PEV: http://tatiyants.com/pev/

    query aq <table> <column> <-|job_id [job_id [...]]>             Given a list of IDs from a table (e.g. 'job'), access a specific column from that table
    query collection-usage                                          Information about how many collections of various types are used
    query data-origin-distribution [--human]                        data sources (uploaded vs derived)
    query data-origin-distribution-summary [--human]                breakdown of data sources (uploaded vs derived)
    query datasets-created-daily                                    The min/max/average/p95/p99 of total size of datasets created in a single day.
    query disk-usage [--human]                                      Disk usage per object store.
    query errored-jobs <hours> [--details]                          Lists jobs that errored in the last N hours.
    query good-for-pulsar                                           Look for jobs EU would like to send to pulsar
    query group-cpu-seconds [group]                                 Retrieve an approximation of the CPU time in seconds for group(s)
    query group-gpu-time [group]                                    Retrieve an approximation of the GPU time for users
    query groups-list                                               List all groups known to Galaxy
    query hdca-datasets <hdca_id>                                   List of files in a dataset collection
    query hdca-info <hdca_id>                                       Information on a dataset collection
    query history-connections                                       The connections of tools, from output to input, in histories (tool_predictions)
    query history-contents <history_id> [--dataset|--collection]    List datasets and/or collections in a history
    query history-runtime-system-by-tool <history_id>               Sum of runtimes by all jobs in a history, split by tool
    query history-runtime-system <history_id>                       Sum of runtimes by all jobs in a history
    query history-runtime-wallclock <history_id>                    Time as elapsed by a clock on the wall
    query job-history <id>                                          Job state history for a specific job
    query job-info <-|job_id [job_id [...]]>                        Retrieve information about jobs given some job IDs
    query job-inputs <id>                                           Input datasets to a specific job
    query job-outputs <id>                                          Output datasets from a specific job
    query jobs-max-by-cpu-hours                                     Top 10 jobs by CPU hours consumed (requires CGroups metrics)
    query jobs-nonterminal [username|id|email]                      Job info of nonterminal jobs separated by user
    query jobs-per-user <email>                                     Number of jobs run by a specific user
    query jobs-queued                                               How many queued jobs have external cluster IDs
    query jobs-queued-internal-by-handler                           How many queued jobs do not have external IDs, by handler
    query jobs-ready-to-run                                         Find jobs ready to run (Mostly a performance test)
    query largest-collection                                        Returns the size of the single largest collection
    query largest-histories [--human]                               Largest histories in Galaxy
    query latest-users                                              40 recently registered users
    query monthly-cpu-stats [year]                                  CPU years/hours allocated to tools by month
    query monthly-cpu-years                                         CPU years allocated to tools by month
    query monthly-data [year] [--human]                             Number of active users per month, running jobs
    query monthly-gpu-years                                         GPU years allocated to tools by month
    query monthly-jobs [year]                                       Number of jobs run each month
    query monthly-users-active [year]                               Number of active users per month, running jobs
    query monthly-users-registered [year]                           Number of users registered each month
    query old-histories <weeks>                                     Lists histories that haven't been updated (used) for <weeks>
    query pg-cache-hit                                              Check postgres in-memory cache hit ratio
    query pg-index-size [--human]                                   show table and index bloat in your database ordered by most wasteful
    query pg-index-usage                                            calculates your index hit rate (effective databases are at 99% and up)
    query pg-long-running-queries                                   show all queries longer than five minutes by descending duration
    query pg-mandelbrot                                             show the mandlebrot set
    query pg-stat-bgwriter                                          Stats about the behaviour of the bgwriter, checkpoints, buffers, etc.
    query pg-stat-user-tables                                       stats about tables (tuples, index scans, vacuums, analyzes)
    query pg-table-bloat [--human]                                  show table and index bloat in your database ordered by most wasteful
    query pg-table-size [--human]                                   show the size of the tables (excluding indexes), descending by size
    query pg-unused-indexes [--human]                               show unused and almost unused indexes
    query pg-vacuum-stats                                           show dead rows and whether an automatic vacuum is expected to be triggered
    query q <query>                                                 Passes a raw SQL query directly through to the database
    query queue                                                     Brief overview of currently running jobs
    query queue-detail [--all] [--seconds]                          Detailed overview of running and queued jobs
    query queue-detail-by-handler <handler_id>                      List jobs for a specific handler
    query queue-overview [--short-tool-id]                          View used mostly for monitoring
    query queue-time <tool_id>                                      The average/95%/99% a specific tool spends in queue state.
    query recent-jobs <hours>                                       Jobs run in the past <hours> (in any state)
    query runtime-per-user <email>                                  computation time of user (by email)
    query tool-available-metrics <tool_id>                          list all available metrics for a given tool
    query tool-errors [--short-tool-id] [weeks|4]                   Summarize percent of tool runs in error over the past weeks for all tools that have failed (most popular tools first)
    query tool-last-used-date                                       When was the most recent invocation of every tool
    query tool-likely-broken [--short-tool-id] [weeks|4]            Find tools that have been executed in recent weeks that are (or were due to job running) likely substantially broken
    query tool-metrics <tool_id> <metric_id> [--like]               See values of a specific metric
    query tool-new-errors [weeks|4]                                 Summarize percent of tool runs in error over the past weeks for "new tools"
    query tool-popularity [months|24]                               Most run tools by month (tool_predictions)
    query tool-usage [weeks]                                        Counts of tool runs in the past weeks (default = all)
    query total-jobs [year]                                         Total number of jobs run by galaxy instance
    query training-list [--all]                                     List known trainings
    query training-members-remove <training> <username> [YESDOIT]   Remove a user from a training
    query training-members <tr_id>                                  List users in a specific training
    query training-queue <training_id>                              Jobs currently being run by people in a given training
    query ts-repos                                                  Counts of toolshed repositories by toolshed and owner.
    query upload-gb-in-past-hour [hours|1]                          Sum in bytes of files uploaded in the past hour
    query user-cpu-years                                            CPU years allocated to tools by user
    query user-disk-quota                                           Retrieves the 50 users with the largest quotas
    query user-disk-usage [--human]                                 Retrieve an approximation of the disk usage for users
    query user-gpu-years                                            GPU years allocated to tools by user
    query user-history-list <username|id|email> [--size]            Shows the ID of the history, it's size and when it was last updated.
    query user-recent-aggregate-jobs <username|id|email> [days|7]   Show aggregate information for jobs in past N days for user
    query users-count                                               Shows sums of active/external/deleted/purged accounts
    query users-total                                               Total number of Galaxy users (incl deleted, purged, inactive)
    query users-with-oidc                                           How many users logged in with OIDC
    query workers                                                   Retrieve a list of Galaxy worker processes
    query workflow-connections [--all]                              The connections of tools, from output to input, in the latest (or all) versions of user workflows (tool_predictions)
    query workflow-invocation-status                                Report on how many workflows are in new state by handler
    query workflow-invocation-totals                                Report on overall workflow counts, to ensure throughput

All commands can be prefixed with "time" to print execution time to stderr

help / -h / --help : this message. Invoke '--help' on any subcommand for help specific to that subcommand
Tip: Run "gxadmin meta whatsnew" to find out what's new in this release!

## server workflow-invocations

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=server_workflow-invocations&type=Code))
gxadmin usage:

DB Queries:
  'query' can be exchanged with 'tsvquery' or 'csvquery' for tab- and comma-separated variants.
  In some cases 'iquery' is supported for InfluxDB compatible output.
  In all cases 'explainquery' will show you the query plan, in case you need to optimise or index data. 'explainjsonquery' is useful with PEV: http://tatiyants.com/pev/

    query aq <table> <column> <-|job_id [job_id [...]]>             Given a list of IDs from a table (e.g. 'job'), access a specific column from that table
    query collection-usage                                          Information about how many collections of various types are used
    query data-origin-distribution [--human]                        data sources (uploaded vs derived)
    query data-origin-distribution-summary [--human]                breakdown of data sources (uploaded vs derived)
    query datasets-created-daily                                    The min/max/average/p95/p99 of total size of datasets created in a single day.
    query disk-usage [--human]                                      Disk usage per object store.
    query errored-jobs <hours> [--details]                          Lists jobs that errored in the last N hours.
    query good-for-pulsar                                           Look for jobs EU would like to send to pulsar
    query group-cpu-seconds [group]                                 Retrieve an approximation of the CPU time in seconds for group(s)
    query group-gpu-time [group]                                    Retrieve an approximation of the GPU time for users
    query groups-list                                               List all groups known to Galaxy
    query hdca-datasets <hdca_id>                                   List of files in a dataset collection
    query hdca-info <hdca_id>                                       Information on a dataset collection
    query history-connections                                       The connections of tools, from output to input, in histories (tool_predictions)
    query history-contents <history_id> [--dataset|--collection]    List datasets and/or collections in a history
    query history-runtime-system-by-tool <history_id>               Sum of runtimes by all jobs in a history, split by tool
    query history-runtime-system <history_id>                       Sum of runtimes by all jobs in a history
    query history-runtime-wallclock <history_id>                    Time as elapsed by a clock on the wall
    query job-history <id>                                          Job state history for a specific job
    query job-info <-|job_id [job_id [...]]>                        Retrieve information about jobs given some job IDs
    query job-inputs <id>                                           Input datasets to a specific job
    query job-outputs <id>                                          Output datasets from a specific job
    query jobs-max-by-cpu-hours                                     Top 10 jobs by CPU hours consumed (requires CGroups metrics)
    query jobs-nonterminal [username|id|email]                      Job info of nonterminal jobs separated by user
    query jobs-per-user <email>                                     Number of jobs run by a specific user
    query jobs-queued                                               How many queued jobs have external cluster IDs
    query jobs-queued-internal-by-handler                           How many queued jobs do not have external IDs, by handler
    query jobs-ready-to-run                                         Find jobs ready to run (Mostly a performance test)
    query largest-collection                                        Returns the size of the single largest collection
    query largest-histories [--human]                               Largest histories in Galaxy
    query latest-users                                              40 recently registered users
    query monthly-cpu-stats [year]                                  CPU years/hours allocated to tools by month
    query monthly-cpu-years                                         CPU years allocated to tools by month
    query monthly-data [year] [--human]                             Number of active users per month, running jobs
    query monthly-gpu-years                                         GPU years allocated to tools by month
    query monthly-jobs [year]                                       Number of jobs run each month
    query monthly-users-active [year]                               Number of active users per month, running jobs
    query monthly-users-registered [year]                           Number of users registered each month
    query old-histories <weeks>                                     Lists histories that haven't been updated (used) for <weeks>
    query pg-cache-hit                                              Check postgres in-memory cache hit ratio
    query pg-index-size [--human]                                   show table and index bloat in your database ordered by most wasteful
    query pg-index-usage                                            calculates your index hit rate (effective databases are at 99% and up)
    query pg-long-running-queries                                   show all queries longer than five minutes by descending duration
    query pg-mandelbrot                                             show the mandlebrot set
    query pg-stat-bgwriter                                          Stats about the behaviour of the bgwriter, checkpoints, buffers, etc.
    query pg-stat-user-tables                                       stats about tables (tuples, index scans, vacuums, analyzes)
    query pg-table-bloat [--human]                                  show table and index bloat in your database ordered by most wasteful
    query pg-table-size [--human]                                   show the size of the tables (excluding indexes), descending by size
    query pg-unused-indexes [--human]                               show unused and almost unused indexes
    query pg-vacuum-stats                                           show dead rows and whether an automatic vacuum is expected to be triggered
    query q <query>                                                 Passes a raw SQL query directly through to the database
    query queue                                                     Brief overview of currently running jobs
    query queue-detail [--all] [--seconds]                          Detailed overview of running and queued jobs
    query queue-detail-by-handler <handler_id>                      List jobs for a specific handler
    query queue-overview [--short-tool-id]                          View used mostly for monitoring
    query queue-time <tool_id>                                      The average/95%/99% a specific tool spends in queue state.
    query recent-jobs <hours>                                       Jobs run in the past <hours> (in any state)
    query runtime-per-user <email>                                  computation time of user (by email)
    query tool-available-metrics <tool_id>                          list all available metrics for a given tool
    query tool-errors [--short-tool-id] [weeks|4]                   Summarize percent of tool runs in error over the past weeks for all tools that have failed (most popular tools first)
    query tool-last-used-date                                       When was the most recent invocation of every tool
    query tool-likely-broken [--short-tool-id] [weeks|4]            Find tools that have been executed in recent weeks that are (or were due to job running) likely substantially broken
    query tool-metrics <tool_id> <metric_id> [--like]               See values of a specific metric
    query tool-new-errors [weeks|4]                                 Summarize percent of tool runs in error over the past weeks for "new tools"
    query tool-popularity [months|24]                               Most run tools by month (tool_predictions)
    query tool-usage [weeks]                                        Counts of tool runs in the past weeks (default = all)
    query total-jobs [year]                                         Total number of jobs run by galaxy instance
    query training-list [--all]                                     List known trainings
    query training-members-remove <training> <username> [YESDOIT]   Remove a user from a training
    query training-members <tr_id>                                  List users in a specific training
    query training-queue <training_id>                              Jobs currently being run by people in a given training
    query ts-repos                                                  Counts of toolshed repositories by toolshed and owner.
    query upload-gb-in-past-hour [hours|1]                          Sum in bytes of files uploaded in the past hour
    query user-cpu-years                                            CPU years allocated to tools by user
    query user-disk-quota                                           Retrieves the 50 users with the largest quotas
    query user-disk-usage [--human]                                 Retrieve an approximation of the disk usage for users
    query user-gpu-years                                            GPU years allocated to tools by user
    query user-history-list <username|id|email> [--size]            Shows the ID of the history, it's size and when it was last updated.
    query user-recent-aggregate-jobs <username|id|email> [days|7]   Show aggregate information for jobs in past N days for user
    query users-count                                               Shows sums of active/external/deleted/purged accounts
    query users-total                                               Total number of Galaxy users (incl deleted, purged, inactive)
    query users-with-oidc                                           How many users logged in with OIDC
    query workers                                                   Retrieve a list of Galaxy worker processes
    query workflow-connections [--all]                              The connections of tools, from output to input, in the latest (or all) versions of user workflows (tool_predictions)
    query workflow-invocation-status                                Report on how many workflows are in new state by handler
    query workflow-invocation-totals                                Report on overall workflow counts, to ensure throughput

All commands can be prefixed with "time" to print execution time to stderr

help / -h / --help : this message. Invoke '--help' on any subcommand for help specific to that subcommand
Tip: Run "gxadmin meta whatsnew" to find out what's new in this release!

## server workflows

([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=server_workflows&type=Code))
gxadmin usage:

DB Queries:
  'query' can be exchanged with 'tsvquery' or 'csvquery' for tab- and comma-separated variants.
  In some cases 'iquery' is supported for InfluxDB compatible output.
  In all cases 'explainquery' will show you the query plan, in case you need to optimise or index data. 'explainjsonquery' is useful with PEV: http://tatiyants.com/pev/

    query aq <table> <column> <-|job_id [job_id [...]]>             Given a list of IDs from a table (e.g. 'job'), access a specific column from that table
    query collection-usage                                          Information about how many collections of various types are used
    query data-origin-distribution [--human]                        data sources (uploaded vs derived)
    query data-origin-distribution-summary [--human]                breakdown of data sources (uploaded vs derived)
    query datasets-created-daily                                    The min/max/average/p95/p99 of total size of datasets created in a single day.
    query disk-usage [--human]                                      Disk usage per object store.
    query errored-jobs <hours> [--details]                          Lists jobs that errored in the last N hours.
    query good-for-pulsar                                           Look for jobs EU would like to send to pulsar
    query group-cpu-seconds [group]                                 Retrieve an approximation of the CPU time in seconds for group(s)
    query group-gpu-time [group]                                    Retrieve an approximation of the GPU time for users
    query groups-list                                               List all groups known to Galaxy
    query hdca-datasets <hdca_id>                                   List of files in a dataset collection
    query hdca-info <hdca_id>                                       Information on a dataset collection
    query history-connections                                       The connections of tools, from output to input, in histories (tool_predictions)
    query history-contents <history_id> [--dataset|--collection]    List datasets and/or collections in a history
    query history-runtime-system-by-tool <history_id>               Sum of runtimes by all jobs in a history, split by tool
    query history-runtime-system <history_id>                       Sum of runtimes by all jobs in a history
    query history-runtime-wallclock <history_id>                    Time as elapsed by a clock on the wall
    query job-history <id>                                          Job state history for a specific job
    query job-info <-|job_id [job_id [...]]>                        Retrieve information about jobs given some job IDs
    query job-inputs <id>                                           Input datasets to a specific job
    query job-outputs <id>                                          Output datasets from a specific job
    query jobs-max-by-cpu-hours                                     Top 10 jobs by CPU hours consumed (requires CGroups metrics)
    query jobs-nonterminal [username|id|email]                      Job info of nonterminal jobs separated by user
    query jobs-per-user <email>                                     Number of jobs run by a specific user
    query jobs-queued                                               How many queued jobs have external cluster IDs
    query jobs-queued-internal-by-handler                           How many queued jobs do not have external IDs, by handler
    query jobs-ready-to-run                                         Find jobs ready to run (Mostly a performance test)
    query largest-collection                                        Returns the size of the single largest collection
    query largest-histories [--human]                               Largest histories in Galaxy
    query latest-users                                              40 recently registered users
    query monthly-cpu-stats [year]                                  CPU years/hours allocated to tools by month
    query monthly-cpu-years                                         CPU years allocated to tools by month
    query monthly-data [year] [--human]                             Number of active users per month, running jobs
    query monthly-gpu-years                                         GPU years allocated to tools by month
    query monthly-jobs [year]                                       Number of jobs run each month
    query monthly-users-active [year]                               Number of active users per month, running jobs
    query monthly-users-registered [year]                           Number of users registered each month
    query old-histories <weeks>                                     Lists histories that haven't been updated (used) for <weeks>
    query pg-cache-hit                                              Check postgres in-memory cache hit ratio
    query pg-index-size [--human]                                   show table and index bloat in your database ordered by most wasteful
    query pg-index-usage                                            calculates your index hit rate (effective databases are at 99% and up)
    query pg-long-running-queries                                   show all queries longer than five minutes by descending duration
    query pg-mandelbrot                                             show the mandlebrot set
    query pg-stat-bgwriter                                          Stats about the behaviour of the bgwriter, checkpoints, buffers, etc.
    query pg-stat-user-tables                                       stats about tables (tuples, index scans, vacuums, analyzes)
    query pg-table-bloat [--human]                                  show table and index bloat in your database ordered by most wasteful
    query pg-table-size [--human]                                   show the size of the tables (excluding indexes), descending by size
    query pg-unused-indexes [--human]                               show unused and almost unused indexes
    query pg-vacuum-stats                                           show dead rows and whether an automatic vacuum is expected to be triggered
    query q <query>                                                 Passes a raw SQL query directly through to the database
    query queue                                                     Brief overview of currently running jobs
    query queue-detail [--all] [--seconds]                          Detailed overview of running and queued jobs
    query queue-detail-by-handler <handler_id>                      List jobs for a specific handler
    query queue-overview [--short-tool-id]                          View used mostly for monitoring
    query queue-time <tool_id>                                      The average/95%/99% a specific tool spends in queue state.
    query recent-jobs <hours>                                       Jobs run in the past <hours> (in any state)
    query runtime-per-user <email>                                  computation time of user (by email)
    query tool-available-metrics <tool_id>                          list all available metrics for a given tool
    query tool-errors [--short-tool-id] [weeks|4]                   Summarize percent of tool runs in error over the past weeks for all tools that have failed (most popular tools first)
    query tool-last-used-date                                       When was the most recent invocation of every tool
    query tool-likely-broken [--short-tool-id] [weeks|4]            Find tools that have been executed in recent weeks that are (or were due to job running) likely substantially broken
    query tool-metrics <tool_id> <metric_id> [--like]               See values of a specific metric
    query tool-new-errors [weeks|4]                                 Summarize percent of tool runs in error over the past weeks for "new tools"
    query tool-popularity [months|24]                               Most run tools by month (tool_predictions)
    query tool-usage [weeks]                                        Counts of tool runs in the past weeks (default = all)
    query total-jobs [year]                                         Total number of jobs run by galaxy instance
    query training-list [--all]                                     List known trainings
    query training-members-remove <training> <username> [YESDOIT]   Remove a user from a training
    query training-members <tr_id>                                  List users in a specific training
    query training-queue <training_id>                              Jobs currently being run by people in a given training
    query ts-repos                                                  Counts of toolshed repositories by toolshed and owner.
    query upload-gb-in-past-hour [hours|1]                          Sum in bytes of files uploaded in the past hour
    query user-cpu-years                                            CPU years allocated to tools by user
    query user-disk-quota                                           Retrieves the 50 users with the largest quotas
    query user-disk-usage [--human]                                 Retrieve an approximation of the disk usage for users
    query user-gpu-years                                            GPU years allocated to tools by user
    query user-history-list <username|id|email> [--size]            Shows the ID of the history, it's size and when it was last updated.
    query user-recent-aggregate-jobs <username|id|email> [days|7]   Show aggregate information for jobs in past N days for user
    query users-count                                               Shows sums of active/external/deleted/purged accounts
    query users-total                                               Total number of Galaxy users (incl deleted, purged, inactive)
    query users-with-oidc                                           How many users logged in with OIDC
    query workers                                                   Retrieve a list of Galaxy worker processes
    query workflow-connections [--all]                              The connections of tools, from output to input, in the latest (or all) versions of user workflows (tool_predictions)
    query workflow-invocation-status                                Report on how many workflows are in new state by handler
    query workflow-invocation-totals                                Report on overall workflow counts, to ensure throughput

All commands can be prefixed with "time" to print execution time to stderr

help / -h / --help : this message. Invoke '--help' on any subcommand for help specific to that subcommand
Tip: Run "gxadmin meta whatsnew" to find out what's new in this release!
