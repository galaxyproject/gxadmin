obtain_mutate() {
	query_name="$1"; shift

	fn="mutate_${query_name}"
	LC_ALL=C type "$fn" 2> /dev/null | grep -q 'function'
	ec=$?

	if (( ec == 0 )); then
		$fn "$@";
	else
		export QUERY="ERROR"
	fi
}

mutate() {
	query_type="$1"; shift
	query_name="$1"; shift

	# We do not run this in a subshell because we need to "return" multiple things.
	obtain_mutate "$query_name" "$@"

	# TODO(hxr)
	if [[ "$QUERY" == "ERROR" ]]; then
		error "Error"
		usage mutate
	fi

	if [[ "$FLAVOR" == "tsv" ]]; then
		query_tsv "$QUERY";
	else
		query_tbl "$QUERY";
	fi
}
