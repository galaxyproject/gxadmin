# Git

1. Please make PRs to the `master` branch
2. When making changes:
	1. Make changes to parts/
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
