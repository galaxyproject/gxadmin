# Git

1. Please make PRs to the `main` branch
2. When making changes:
	1. Make changes to parts/
	2. Run `make` to build gxadmin and test
	2. Update the changelog for your additions
3. Commit everything except the `gxadmin` file

# Writing Queries

Add your functions to the appropriate file in `parts/2[0-9]*`. The other files are support for gxadmin and probably aren't interesting to you.

Writing a query function is quite easy. We'll look at the following:

```
query_workers() { ## : Retrieve a list of Galaxy worker processes
	handle_help "$@" <<-EOF
		This retrieves a list of Galaxy worker processes.
		This functionality is only available on Galaxy
		20.01 or later.

		server_name         | hostname | pid
		------------------- | -------- | ---
		main.web.1          | server1  | 123
		main.job-handlers.1 | server2  | 456

	EOF

	read -r -d '' QUERY <<-EOF
		SELECT
			server_name,
			hostname,
			pid
		FROM
			worker_process
		WHERE
			pid IS NOT NULL
	EOF
}
```

Here we define a function. For queries in the `parts/22-query.sh` file they **must** begin with `query_`. Anything after `:` in the definition line is used as the function description.

Following that we define some help for the function that will be activated if the user passes the `--help` flag.

After that we create a variable `QUERY` with some content. Easy peasy.

## Argument Parsing

@hexylena has written a [*wonderful argument parser*](https://github.com/hexylena/wap) that is automatically activated when you use `##?` instead of `##`

```
query_stuff() { ##? <tool_id>: Some help
```

When this is provided, the WAP parsers the arguments and automatically exports them. So in your function you can:

1. Access `$arg_tool_id` as if it were already there
2. Be certain that the user has not passed too few or many arguments

Super wonderful!

## View built queries

To see the query gxadmin has built, use `echoquery`, for example:

```
gxadmin echoquery users-total
```

## Tool ID display

Queries that display a `tool_id` column should shorten it via the `tool_id_expr`
helper (defined in `parts/03-query-utils.sh`) rather than selecting the raw
column. This respects the user's `GXADMIN_TOOL_ID_FORMAT` setting (see
README.md → "Tool ID display"):

```
$(tool_id_expr job.tool_id) AS tool_id
```

The format is controlled by the `GXADMIN_TOOL_ID_FORMAT` environment
variable. When grouping, keep the `GROUP BY` on
the raw column (e.g. `GROUP BY job.tool_id`) so distinct tools that shorten to
the same string remain separate rows. Export queries (e.g.
`server workflow-trace-archive-*`) should keep the full tool ID.

# Portability

This is **not** intended to be portable, it is a bash script. There is an assumption you will run it under bash. I *may or may not* accept PRs that make it more portable.

Tabs are used for indentation purposes.
