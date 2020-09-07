ifmore() {
	q="$(cat)"
	lines=$(echo "$q" | wc -l)
	# 2 more than the head command since we'll 'spend' two for the ... anyway.
	if (( lines > 8 )); then
		echo "$q" | head -n 6
		echo "    ..."
		echo "    run '$0 $1 help' for more"
	else
		echo "$q"
	fi
}

colour_word() {
	word=$1
	color=$2
	if [[ $color == "red" ]]; then
		color_idx=1
	elif [[ $color == "orange" ]]; then
		color_idx=2
	elif [[ $color == "green" ]]; then
		color_idx=4
	fi

	cat | sed "s|${word}|$(tput setab $color_idx)${word}$(tput sgr0)|g"
}

filter_commands() {
	cat | grep "^$1 " | sort -k2 | column -s: -t | sed 's/^/    /' | colour_word Deprecated orange | colour_word '(NEW)' green
}

locate_cmds() {
	grep -s -h -o '^[a-z0-9_-]*()\s*{ ##?\? .*' "$0" "$GXADMIN_SITE_SPECIFIC" | grep -v grep | grep -v '| sed' | sort
}

locate_cmds_nolocal() {
	grep -s -h -o '^[a-z0-9_-]*()\s*{ ##?\? .*' "$0" | grep -v grep | grep -v '| sed' | sort
}

correct_cmd() {
	cat | sed 's/_/ /;s/()\s*{ ##?\?//;s/ :/:/'
}

usage(){
	cat <<-EOF
		gxadmin usage:

	EOF

	if (( $# == 0 )); then
		for x in $registered_subcommands; do
			vn="_${x}_short_help"
			printf "  %10s: %s\n" "${x}" "${!vn}"
		done
	else
		for x in $registered_subcommands; do
			if [[ "$1" == "$x" ]]; then
				vn="_${x}_short_help"
				echo "${!vn}"
				vn="_${x}_long_help"
				echo "${!vn}"
			fi
		done
	fi

	if [[ -f "$GXADMIN_SITE_SPECIFIC" ]]; then
		if (( $# == 0  )) || [[ "$1" == "local" ]]; then
			printf "  %10s: %s\n" "local" "(These can be configured in "$GXADMIN_SITE_SPECIFIC")"
		fi
	else
		cat <<-EOF
			Local-only commands can be configured in $GXADMIN_SITE_SPECIFIC

		EOF
	fi

	if (( $# == 0  )) || [[ "$1" == "search" ]]; then
		cat <<-EOF

			search <term>: Search gxadmin for functions with specific terms
		EOF
	fi

	if (( $# == 1 )); then
		echo
		locate_cmds | correct_cmd | filter_commands "$1"
	fi

	cat <<-EOF

		All commands can be prefixed with "time" to print execution time to stderr

	EOF


	cat <<-EOF
		help / -h / --help : this message. Invoke '--help' on any subcommand for help specific to that subcommand
		Tip: Run "gxadmin meta whatsnew" to find out what's new in this release!
	EOF

	exit 0;
}

handle_help() {
	if [[ ! -z "${GXADMIN_POPCON_ENABLE}" ]]; then
		if [[ "${query_name}" != "user-info" ]]; then
			echo "${mode:-mode} ${query_name:-sf}" >> ~/.gxadmin-popcon.log
		fi
	fi

	for i in "$@"; do
		if [[ "$i" = --help || "$i" = -h ]]; then

			if [[ -n "${query_name}" ]]; then
				key="${query_type}_${query_name}"
			fi

			invoke_desc=$(locate_cmds | grep "${key}()" | correct_cmd | sed "s/^/gxadmin /g")
			short_desc=$(echo "$invoke_desc" | sed 's/.*://g')
			short_parm=$(echo "$invoke_desc" | sed 's/:.*//g')
			echo "${mode} ${query_name} - ${short_desc}"
			echo
			echo "**SYNOPSIS**"
			echo
			echo "    $short_parm"
			echo
			manual="$(cat -)"
			manual_wc="${#manual}"
			if (( manual_wc > 3 )); then
				echo "**NOTES**"
				echo
				echo "$manual"
				echo
			fi
			# exit after printing the documentation!
			exit 0;
		fi
	done
}
