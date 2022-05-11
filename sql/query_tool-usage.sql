--- ---
--- added_in: 1
--- contributors: hexylena
--- description: Counts of tool runs in the past weeks (default = all)
--- parameters:
--- - name: weeks
---   type: int
---   desc: Number of weeks to search
---   required: false
--- influx:
---   fields: ['count=1']
---   tags: ['tool_id=0']
--- ---
---
---    $ gxadmin tool-usage
---                                    tool_id                                 | count
---    ------------------------------------------------------------------------+--------
---     toolshed.g2.bx.psu.edu/repos/devteam/column_maker/Add_a_column1/1.1.0  | 958154
---     Grouping1                                                              | 638890
---     toolshed.g2.bx.psu.edu/repos/devteam/intersect/gops_intersect_1/1.0.0  | 326959
---     toolshed.g2.bx.psu.edu/repos/devteam/get_flanks/get_flanks1/1.0.0      | 320236
---     addValue                                                               | 313470
---     toolshed.g2.bx.psu.edu/repos/devteam/join/gops_join_1/1.0.0            | 312735
---     upload1                                                                | 103595
---     toolshed.g2.bx.psu.edu/repos/rnateam/graphclust_nspdk/nspdk_sparse/9.2 |  52861
---     Filter1                                                                |  43253


SELECT
	j.tool_id, count(*) AS count
FROM job j

{% if arg_weeks %}
WHERE j.create_time > (now() - '${arg_weeks} weeks'::interval)
{% endif %}

GROUP BY j.tool_id
ORDER BY count DESC
