look_for() {
	group_name="$1"; shift
	query_name="$1"; shift

	# Check that FN exists
	fn="${group_name}_${query_name}"
	LC_ALL=C type $fn 2> /dev/null | grep -q 'function'

	if (( $? == 0 )); then
		$fn "$@";

		if [[ "${query_name}" == "query"* ]]; then
			query_tbl "$QUERY"
		elif [[ "${query_name}" == "iquery"* ]]; then
			query_influx "$QUERY" "$query_name" "$fields" "$tags" "$timestamp"
		fi
	else
		usage ${group_name}
	fi
}
