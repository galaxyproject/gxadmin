obtain_func() {
	category="$1"; shift
	query_name="$1"; shift

	fn="${category}_${query_name}"
	LC_ALL=C type "$fn" 2> /dev/null | grep -q 'function'
	ec=$?

	if (( ec == 0 )); then
		$fn "$@";
	else
		export QUERY="ERROR"
	fi
}


look_for() {
	query_type="$1"; shift
	group_name="$1"; shift
	query_name="$1"; shift

	# query_type group_name query_name
	# query      tsvquery   users-total
	# galaxy     none       somethingelse
	#echo "HIII $query_type $group_name $query_name"

	if [[ $query_type == "local" ]]; then
		if [[ ! -f ${GXADMIN_SITE_SPECIFIC} ]]; then
			error "No local functions are defined in ${GXADMIN_SITE_SPECIFIC}"
			exit 1
		else
			# Load functions
			# shellcheck disable=SC1090
			. "${GXADMIN_SITE_SPECIFIC}"
		fi
	fi

	# Check that FN exists
	fn="${query_type}_${query_name}"
	LC_ALL=C type "$fn" 2> /dev/null | grep -q 'function'
	ec=$?

	if (( ec != 0 )); then
		error "Unknown command"
		usage "${query_type}"
	fi

	if [[ $query_type == "query" ]]; then
		obtain_func query "$query_name" "$@"

		# If query in error, exit.
		if [[ "$QUERY" == "ERROR" ]]; then
			error "Error"
			usage query
		fi

		# Run the queries
		case "$group_name" in
			tsvquery         ) query_tsv "$QUERY";;
			csvquery         ) query_csv "$QUERY";;
			query            ) query_tbl "$QUERY";;
			jsonquery        ) query_json "$QUERY";;
			iquery           ) query_influx "$QUERY" "$query_name" "$fields" "$tags" "$timestamp";;
			explainquery     ) query_exp "$QUERY";;
			explainjsonquery ) query_expj "$QUERY";;
			echoquery        ) query_echo "$QUERY";;
			# default
			*                )  usage "Error";;
		esac
	elif [[ $query_type == "mutate" ]]; then
		obtain_func mutate "$query_name" "$@"

		# If query in error, exit.
		if [[ "$QUERY" == "ERROR" ]]; then
			error "Error"
			usage mutate
		fi

		# Run the queries
		if [[ "$FLAVOR" == "tsv" ]]; then
			query_tsv "$QUERY";
		else
			query_tbl "$QUERY";
		fi
	elif [[ $query_type == "local" ]]; then
		if [[ -z "${GXADMIN_BUGGER_OFF}" ]] && (( (RANDOM % 25) == 0 )); then
			warning "Hey! It's great that you're using gxadmin! You should contribute these functions back :) Other people might find these useful, or could learn something from the code you've written, even if you think it is too specific to your site."
		fi

		$fn "$@";

		if [[ "${query_name}" == "query"* ]]; then
			query_tbl "$QUERY"
		fi
	else
		$fn "$@";

		if [[ "${query_name}" == "query"* ]]; then
			query_tbl "$QUERY"
		elif [[ "${query_name}" == "iquery"* ]]; then
			query_influx "$QUERY" "$query_name" "$fields" "$tags" "$timestamp"
		fi
	fi
}
