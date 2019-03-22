usage(){
	if (( $# > 0 )); then
		if [[ $1 != "safe" ]] && [[ $1 != "query" ]]; then
			error $@
		fi
	fi
	cmds="$(grep -s -h -o '{ ## .*' $0 $GXADMIN_SITE_SPECIFIC | grep -v grep | grep -v '| sed' | sort | sed 's/^{ ## //g')"

	if [[ $1 == "query" ]]; then
		cat <<-EOF
			gxadmin usage:

			DB Queries:
			'query' can be exchanged with 'tsvquery' or 'csvquery' for tab- and comma-separated variants

			$(echo "$cmds" | grep 'query ' | sort -k2 | column -s: -t | sed 's/^/    /')

			help / -h / --help : this message. Invoke '--help' on any subcommand for help specific to that subcommand
		EOF
	else
		cat <<-EOF
			gxadmin usage:

			DB Queries:
			'query' can be exchanged with 'tsvquery' or 'csvquery' for tab- and comma-separated variants

			$(echo "$cmds" | grep 'query ' | sort -k2 | column -s: -t | sed 's/^/    /')

			DB Queries (Mutations): (csv/tsv queries are not available)

			$(echo "$cmds" | grep 'mutate ' | sort -k2 | column -s: -t | sed 's/^/    /')

			Other:

			$(echo "$cmds" | grep -v 'query ' | grep -v '^zerg' | grep -v '^mutate ' | grep -v '^handler' | grep -v '^local' | column -s: -t | sed 's/^/    /')

			Local: (These can be configured in $GXADMIN_SITE_SPECIFIC)

			$(echo "$cmds" | grep '^local' | column -s: -t | sed 's/^/    /')

			help / -h / --help : this message. Invoke '--help' on any subcommand for help specific to that subcommand
		EOF
	fi
	if [[ $1 == "safe" ]] || [[ $1 == "query" ]]; then
		exit 0;
	fi
	exit 1
}

handle_help() {
	for i in "$@"; do
		if [[ $i = --help || $i = -h ]]; then

			key="${mode}"
			if [[ ! -z "${subfunc}" ]]; then
				key="${key} ${subfunc}"
			fi

			echo "**NAME**"
			echo
			invoke_desc=$(grep -s -h "{ ## ${key}[ :]" $0 $GXADMIN_SITE_SPECIFIC | sed "s/.*## /gxadmin /g")
			short_desc=$(echo $invoke_desc | sed 's/.*://g')
			short_parm=$(echo $invoke_desc | sed 's/:.*//g')
			echo "${key} - ${short_desc}"
			echo
			echo "**SYNOPSIS**"
			echo
			echo $short_parm
			echo
			manual="$(cat -)"
			manual_wc="$(echo $manual | wc -c)"
			if (( manual_wc > 3 )); then
				echo "**NOTES**"
				echo
				echo "$manual"
				echo
			fi
			# exit after printing the documentation!
			exit 42
		fi
	done
}
