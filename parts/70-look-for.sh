obtain_func() {
	category="$1"; shift
	query_name="$1"; shift

	if [[ "$category" != "" ]]; then
		category="${category}_"
	fi

	fn="${category}${query_name}"
	LC_ALL=C type "$fn" 2> /dev/null | grep -q 'function'
	ec=$?

	# ##? enables fancy argument parsing.
	# Nothing needs to be done, just let that function handle and auto-parse
	# and auto-export
	wonderful_argument_parsing "$fn" "$@"

	if (( ec == 0 )); then
		$fn "$@";
	else
		export QUERY="ERROR"
	fi
}

wonderful_argument_parsing() {
	fn=$1; shift;
	declare -a parsed_keys
	declare -a parsed_vals
	declare -a positional_args
	declare -a flag_args
	declare -a args
	positional_index=0

	# shellcheck disable=SC2207
	signature=($(grep -s -h -o "${fn}()\s*{ ##?\? .*" "$0" | sed 's/.*##?//g;s/: .*//g;'))

	# shellcheck disable=SC2068
	for x in $@; do
		args+=("$x");
		shift;
	done

	for arg in "${signature[@]}"; do
		if [[ "$arg" == '<'* ]]; then
			# This is a required argument
			positional_args+=("$(echo "$arg" | sed 's/^<//;s/>$//')")
		elif [[ "$arg" == '['* ]]; then
			# This is an optional argument
			flag_args+=("$arg")
		else
			# This is an error
			echo "ERROR!!! Bad argument specification: $arg"
		fi
	done

	# Size of the arrays
	positional_count=${#positional_args[@]}

	offset=0
	while true; do
		# Get the first bit of content from the arguments
		a_cur=${args[$offset]}
		if [[ "$a_cur" == "" ]]; then
			break
		fi

		if [[ "$a_cur" == "--"* ]]; then
			# This is a flag. So find the matching flag definition.
			for arg in "${flag_args[@]}"; do
				# Two types of args: with, without values
				if [[ "$arg" == "[--"* ]]; then
					if [[ "$arg" == *'|'* ]]; then
						# This has another argument.
						# So we need to pop something else.
						# And increment offset so we don't re-process it
						if [[ "$arg" == '['$a_cur'|'* ]]; then
							val="${args[$offset+1]}"
							offset=$(( offset + 1 ))
							parsed_keys+=("${a_cur/--/}")
							parsed_vals+=("$val")
						fi
					else
						# This is just a flag
						if [[ "$arg" == '['$a_cur']' ]]; then
							parsed_keys+=("${a_cur/--/}")
							parsed_vals+=(1)
						fi
					fi
				fi
			done
		else
			# This is a non-flag, so a positional argument.
			# So we need to find the Nth positional (via positional_index)
			if (( positional_index >=  positional_count)); then
				error "Error: more positional arguments than should be possible"
				exit 1;
			fi

			parsed_keys+=("${positional_args[$positional_index]}")
			parsed_vals+=("${a_cur}")
			positional_index=$((positional_index + 1))
		fi
		offset=$(( offset + 1 ))
	done

	if (( positional_index < positional_count )); then
		error "More positional arguments are required"
		exit 1;
	fi

	# size
	size=${#parsed_keys[@]}
	for i in $(seq 0 $((size - 1))); do
		#printf "\t%10s=%-10s\n" "${parsed_keys[$i]}" "${parsed_vals[$i]}"
		export arg_${parsed_keys[$i]}=${parsed_vals[$i]}
	done
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
		obtain_func "$query_type" "$query_name" "$@"

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
	elif [[ $query_type == "server" ]]; then
		obtain_func "$query_type" "$query_name" "$@"
		# If query in error, exit.
		if [[ "$QUERY" == "ERROR" ]]; then
			error "Error"
			usage server
		fi

		# Run the queries
		case "$group_name" in
			tsvserver         ) query_tsv "$QUERY";;
			csvserver         ) query_csv "$QUERY";;
			server            ) query_tbl "$QUERY";;
			jsonserver        ) query_json "$QUERY";;
			iserver           ) query_influx "$QUERY" "$query_name" "$fields" "$tags" "$timestamp";;
			explainserver     ) query_exp "$QUERY";;
			explainjsonserver ) query_expj "$QUERY";;
			echoserver        ) query_echo "$QUERY";;
			# default
			*                )  usage "Error";;
		esac

	elif [[ $query_type == "mutate" ]]; then
		obtain_func "$query_type" "$query_name" "$@"
		# If query in error, exit.
		if [[ "$QUERY" == "ERROR" ]]; then
			error "Error"
			usage mutate
		fi

		# Run the queries
		case "$group_name" in
			mutate            ) query_tbl "$QUERY";;
			explainmutate     ) query_exp "$QUERY";;
			explainjsonmutate ) query_expj "$QUERY";;
			echomutate        ) query_echo "$QUERY";;
			# default
			*                 )  usage "Error";;
		esac

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
