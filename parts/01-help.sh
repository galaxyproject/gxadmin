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
	if [[ $2 == "$1" ]]; then
		cat | grep "^$1 " | sort -k2 | column -s: -t | sed 's/^/    /' | colour_word Deprecated orange | colour_word '(NEW)' green
	else
		cat | grep "^$1 " | sort -k2 | column -s: -t | sed 's/^/    /' | ifmore "$1"
	fi
}

locate_cmds() {
	grep -s -h -o '^[a-z0-9_-]*()\s*{ ## .*' "$0" "$GXADMIN_SITE_SPECIFIC" | grep -v grep | grep -v '| sed' | sort
}

locate_cmds_nolocal() {
	grep -s -h -o '^[a-z0-9_-]*()\s*{ ## .*' "$0" | grep -v grep | grep -v '| sed' | sort
}

correct_cmd() {
	cat | sed 's/_/ /;s/()\s*{ ##//;s/ :/:/'
}

usage(){
	cmds="$(locate_cmds | correct_cmd)"

	cat <<-EOF
		gxadmin usage:

	EOF

	if (( $# == 0  )) || [[ "$1" == "config" ]]; then
		cat <<-EOF
		    config: Access Galaxy configuration and other assorted things
		EOF
	fi

	if (( $# == 0  )) || [[ "$1" == "filter" ]]; then
		cat <<-EOF
		    filter: Some text filtering and processing commands
		EOF
	fi

	if (( $# == 0  )) || [[ "$1" == "galaxy" ]]; then
		cat <<-EOF
		    galaxy: Galaxy Administration
		EOF
	fi


	if (( $# == 0  )) || [[ "$1" == "meta" ]]; then
		cat <<-EOF
		    meta:   Miscellaneous
		EOF
	fi

	if (( $# == 0  )) || [[ "$1" == "mutate" ]]; then
		cat <<-EOF
		    mutate: DB Mutations, CSV/TSV queries are NOT available
		EOF
	fi

	if (( $# == 0  )) || [[ "$1" == "query" ]]; then
		if [[ "$1" == "query" ]]; then
			cat <<-EOF
				DB Queries:
				  'query' can be exchanged with 'tsvquery' or 'csvquery' for tab- and comma-separated variants.
				  In some cases 'iquery' is supported for InfluxDB compatible output.
				  In all cases 'explainquery' will show you the query plan, in case you need to optimise or index data. 'explainjsonquery' is useful with PEV: http://tatiyants.com/pev/
			EOF
		else
			cat <<-EOF
			    query:  DB Queries
			EOF
		fi
	fi

	if (( $# == 0  )) || [[ "$1" == "report" ]]; then
		cat <<-EOF
		    report: Various (rich) reports.  Consider https://github.com/ttscoff/mdless for easier reading in the terminal
		EOF
	fi

	if (( $# == 0  )) || [[ "$1" == "uwsgi" ]]; then
		cat <<-EOF
		    uwsgi:  Galaxy Handler/Zergling management (SystemD only)
		EOF
	fi

	if [[ -f "$GXADMIN_SITE_SPECIFIC" ]]; then
		if (( $# == 0  )) || [[ "$1" == "local" ]]; then
			cat <<-EOF
			    local:  (These can be configured in "$GXADMIN_SITE_SPECIFIC")
			EOF
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
		echo "$cmds" | filter_commands $1 "$1"
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

			key="${mode}"
			if [[ ! -z "${query_name}" ]]; then
				key="${key}_${query_name}"
			fi

			invoke_desc=$(grep -s -h "${key}()\s*{" "$0" "$GXADMIN_SITE_SPECIFIC" | correct_cmd | sed "s/^/gxadmin /g")
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
