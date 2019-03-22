obtain_query() {
	query_name="$1"; shift

	# Check that FN exists
	fn="query_${query_name}"
	LC_ALL=C type $fn | grep -q 'function'

	if (( $? == 0 )); then
		$fn "$@";
	else
		export QUERY="ERROR"
	fi
}


query() {
	# do the thing zhu li
	query_type="$1"; shift
	subfunc="$1"; shift

	# We do not run this in a subshell because we need to "return" multiple things.
	obtain_query $subfunc "$@"

	# TODO(hxr)
	#ec=$?
	#if (( ec > 0 )); then
		#echo "$db_query"
		#exit 0
	#fi
	if [[ "$QUERY" == "ERROR" ]]; then
		usage query
	fi

	# Run the queries
	case "$query_type" in
		tsvquery )  query_tsv "$QUERY";;
		csvquery )  query_csv "$QUERY";;
		query    )  query_tbl "$QUERY";;
		iquery   )  query_influx "$QUERY" "$subfunc" "$fields" "$tags";;
		# default
		*        )  usage "Error";;
	esac
}


