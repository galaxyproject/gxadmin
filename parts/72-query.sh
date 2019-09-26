obtain_query() {
	query_name="$1"; shift

	fn="query_${query_name}"
	LC_ALL=C type "$fn" 2> /dev/null | grep -q 'function'
	ec=$?

	if (( ec == 0 )); then
		$fn "$@";
	else
		export QUERY="ERROR"
	fi
}


query() {
	# do the thing zhu li
	query_type="$1"; shift
	query_name="$1"; shift

	# We do not run this in a subshell because we need to "return" multiple things.
	obtain_query "$query_name" "$@"

	# If query in error, exit.
	if [[ "$QUERY" == "ERROR" ]]; then
		usage query
		exit 1
	fi

	# Run the queries
	case "$query_type" in
		tsvquery         ) $wrapper query_tsv "$QUERY";;
		csvquery         ) $wrapper query_csv "$QUERY";;
		query            ) $wrapper query_tbl "$QUERY";;
		jsonquery        ) $wrapper query_json "$QUERY";;
		iquery           ) $wrapper query_influx "$QUERY" "$query_name" "$fields" "$tags" "$timestamp";;
		explainquery     ) $wrapper query_exp "$QUERY";;
		explainjsonquery ) $wrapper query_expj "$QUERY";;
		echoquery        ) $wrapper query_echo "$QUERY";;
		# default
		*            )  usage "Error";;
	esac
}


