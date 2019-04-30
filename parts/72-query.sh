obtain_query() {
	query_name="$1"; shift

	fn="query_${query_name}"
	LC_ALL=C type $fn 2> /dev/null | grep -q 'function'

	if (( $? == 0 )); then
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
	obtain_query $query_name "$@"

	# If query in error, exit.
	if [[ "$QUERY" == "ERROR" ]]; then
		usage query
		exit 1
	fi

	# Run the queries
	case "$query_type" in
		tsvquery         ) query_tsv "$QUERY";;
		csvquery         ) query_csv "$QUERY";;
		query            ) query_tbl "$QUERY";;
		iquery           ) query_influx "$QUERY" "$query_name" "$fields" "$tags" "$timestamp";;
		explainquery     ) query_exp "$QUERY";;
		explainjsonquery ) query_expj "$QUERY";;
		# default
		*            )  usage "Error";;
	esac
}


