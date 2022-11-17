# shellcheck disable=SC2001
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
	grep -s -h -o "${fn}()\s*{ ##?\? .*" "$0" | grep -F --quiet -o '##?'
	# Nothing needs to be done, just let that function handle and auto-parse
	# and auto-export
	enable_wap=$?
	if (( enable_wap == 0 )); then
		signature=$(wap_fn_signature "$fn")
		wonderful_argument_parser "$(wap_fn_signature "$fn")" "$@"
	fi

	if (( ec == 0 )); then
		$fn "$@";
	else
		export QUERY="ERROR"
	fi
}

wap_fn_signature() {
	grep "${1}()" "$0" | sed "s/.*##? //g;s/: .*//"
}

wap_debug_args() {
	for x in $(compgen -v | grep ^arg_ | sort); do
		echo "${x} = ${!x}"
	done
}

wonderful_argument_parser() {
	# from the top, parse the signature
	# shellcheck disable=SC2206
	signature=($1);
	# make it drop, so we can parse the rest
	shift;
	declare -a parsed_keys
	declare -a parsed_vals
	declare -a positional_args
	declare -a optional_flag_args
	declare -a optional_args
	declare -a args
	positional_index=0
	optional_index=0

	signature+=('[--help]') # This is always available

	for x in "$@"; do
		args+=("$x");
		shift;
	done

	debug "Signature: ${signature[*]}"
	for arg in "${signature[@]}"; do
		if [[ "$arg" == '<'* ]]; then
			# This is a required argument
			positional_args+=("$(echo "$arg" | sed 's/^<//;s/>$//')")
		elif [[ "$arg" == '[--'* ]]; then
			# This is an optional argument
			optional_flag_args+=("$(echo "$arg" | sed 's/^\[//;s/\]$//')")
		elif [[ "$arg" == '['* ]]; then
			# This is an optional argument
			optional_args+=("$(echo "$arg" | sed 's/^\[//;s/\]$//')")
		else
			# This is an error
			error "ERROR!!! Bad argument specification: $arg"
		fi
	done

	# Size of the arrays
	positional_count=${#positional_args[@]}
	optional_count=${#optional_args[@]}

	if (( WAP_DEBUG == 1 )); then
		debug Positional args
		for arg in "${positional_args[@]}"; do debug "  $arg"; done;
		debug Optional args
		for arg in "${optional_args[@]}"; do debug "  $arg"; done;
		debug Optional flag args
		for arg in "${optional_flag_args[@]}"; do debug "  $arg"; done;
	fi

	# If the help flag is in there, we can short-circuit
	if [[ "$x" == "--help" ]] || [[ "$x" == "-h" ]]; then
		WAP_HELP=1
		WAP_HELP_POSITIONAL=
		for arg in "${positional_args[@]}"; do WAP_HELP_POSITIONAL="$WAP_HELP_POSITIONAL\n\t<$arg>"; done;
		WAP_HELP_OPTIONAL_FLAGS=
		for arg in "${optional_flag_args[@]}"; do WAP_HELP_OPTIONAL_FLAGS="$WAP_HELP_OPTIONAL_FLAGS\n\t[$arg]"; done;
		WAP_HELP_OPTIONAL=
		for arg in "${optional_args[@]}"; do WAP_HELP_OPTIONAL="$WAP_HELP_OPTIONAL\n\t[$arg]"; done;
		return
	fi

	offset=0

	# For every optional flag argument with a default value, we should set that.
	for arg in "${optional_flag_args[@]}"; do
		# Two types of args: with, without values
		if [[ "$arg" == "--"*'='* ]]; then
			key=$(echo "$arg" | sed 's/--//g;s/=.*//g')
			val=$(echo "$arg" | sed 's/--//g;s/.*=//g')

			# If it has <desc> then it's just a description, not a default.
			if [[ "$val" != '<'*'>' ]]; then
				parsed_keys+=("${key}")
				parsed_vals+=("${val}")
			fi
		fi
	done

	while true; do
		# Get the first bit of content from the arguments
		a_cur=${args[$offset]}
		if [[ "$a_cur" == "" ]]; then
			break
		fi

		if [[ "$a_cur" == "--"* ]]; then
			# This is a flag. So find the matching flag definition.
			for arg in "${optional_flag_args[@]}"; do
				# Two types of args: with, without values
				if [[ "$arg" == *'='* ]]; then
					# This has another argument.
					# So we need to pop something else.
					# And increment offset so we don't re-process it
					valueless_arg=$(echo "$arg" | sed 's/=.*//')
					valueless_acr=$(echo "$a_cur" | sed 's/=.*//')

					if [[ "$valueless_arg" == "$valueless_acr" ]]; then
						#echo "HI: a_cur=${a_cur} arg=${arg} valueless_arg=${valueless_arg} valueless_acr=${valueless_acr}"
						if [[ "${a_cur}" == "${valueless_acr}"'='* ]]; then
							val="$(echo "${a_cur}" | sed 's/.*=//g')"
						else
							val="${args[$offset+1]}"
							offset=$(( offset + 1 ))
						fi

						k="$(echo "$valueless_acr" | sed 's/^--//;s/-/_/g')"
						parsed_keys+=("${k}")
						parsed_vals+=("$val")

						debug "Parsed ${k} = ${val}"
					fi
				else
					# This is just a flag
					if [[ "$arg" == "$a_cur" ]]; then
						k="$(echo "$a_cur" | sed 's/^--//;s/-/_/g')"
						parsed_keys+=("${k}")
						parsed_vals+=(1)

						debug "Parsed ${k} = 1"
					fi
				fi
			done
		else
			# This is a non-flag, so maybe a positional, maybe an optional argument.
			# So we need to find the Nth positional (via positional_index)
			if (( (positional_index + optional_index) >= (positional_count + optional_count) )); then
				error "Error: more positional arguments than should be possible"
				exit 1;
			fi

			if (( positional_index < positional_count )); then
				key_fixed=$(echo "${positional_args[$positional_index]}" | sed 's/|.*//g')
				parsed_keys+=("$key_fixed")
				parsed_vals+=("${a_cur}")
				positional_index=$((positional_index + 1))
			else
				# We're past the positional and into the optional
				k="${optional_args[$optional_index]}"
				if [[ "$k" == *'='* ]]; then
					# Here there is a default supplied.
					#k="${k//=.*//}"
					k=$(echo "$k" | sed 's/=.*//g')
				fi

				parsed_keys+=("$(echo "$k" | sed 's/|.*//g')")
				parsed_vals+=("${a_cur}")
				optional_index=$(( optional_index + 1 ))
			fi
			debug "Parsed ${parsed_keys[*]} = ${parsed_vals[*]}"
		fi
		offset=$(( offset + 1 ))
	done

	# Set all default optional args, if they aren't set
	if (( optional_index < optional_count )); then
		for i in $(seq $optional_index $((optional_count - 1)) ); do
			if [[ "${optional_args[$i]}" == *'='* ]]; then
				parsed_keys+=("$(echo "$optional_args" | sed 's/=.*//g')")
				parsed_vals+=("$(echo "$optional_args" | sed 's/.*=//g')")
			fi
		done
	fi

	if (( positional_index < positional_count )); then
		for i in $(seq $positional_index $(( positional_count - 1 )) ); do
			error "Required argument <${positional_args[$i]}> is missing"
		done
		exit 1;
	fi

	size=${#parsed_keys[@]}
	for i in $(seq 0 $((size - 1))); do
		debug "$(printf "SETTING\t%10s=%-10s\n" "${parsed_keys[$i]}" "${parsed_vals[$i]}")"
		# shellcheck disable=SC2086
		export arg_${parsed_keys[$i]}="${parsed_vals[$i]}"
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
		didyoumean "${query_type}" "${query_name}"
	fi

	# Set the application name to something useful. (Makes it easier to figure
	# out which gxadmin command is hogging resources, etc.)
	export PGAPPNAME=gxadmin.${query_type}.${query_name}

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
	elif [[ $query_type == "galaxy" ]]; then
		obtain_func "$query_type" "$query_name" "$@"

		if [[ "${query_name}" == "query"* ]]; then
			query_tbl "$QUERY"
		elif [[ "${query_name}" == "iquery"* ]]; then
			query_influx "$QUERY" "$query_name" "$fields" "$tags" "$timestamp"
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
