usage(){
	cmds="$(grep -s -h -o '{ ## .*' $0 $GXADMIN_SITE_SPECIFIC | grep -v grep | grep -v '| sed' | sort | sed 's/^{ ## //g')"

	cat <<-EOF
		gxadmin usage:

	EOF

	if (( $# == 0  )) || [[ $1 == "config" ]]; then
		cat <<-EOF
			Configuration:

			$(echo "$cmds" | grep 'config ' | sort -k2 | column -s: -t | sed 's/^/    /')

		EOF
	fi

	if (( $# == 0  )) || [[ $1 == "filter" ]]; then
		cat <<-EOF
			Filters:

			$(echo "$cmds" | grep 'filter ' | sort -k2 | column -s: -t | sed 's/^/    /')

		EOF
	fi

	if (( $# == 0  )) || [[ $1 == "galaxy" ]]; then
		cat <<-EOF
			Galaxy Administration:

			$(echo "$cmds" | grep 'galaxy ' | sort -k2 | column -s: -t | sed 's/^/    /')

		EOF
	fi

	if (( $# == 0  )) || [[ $1 == "galaxy" ]]; then
		cat <<-EOF
			uwsgi:

			$(echo "$cmds" | grep 'uwsgi ' | sort -k2 | column -s: -t | sed 's/^/    /')

		EOF
	fi


	if (( $# == 0  )) || [[ $1 == "query" ]]; then
		cat <<-EOF
			DB Queries:
			'query' can be exchanged with 'tsvquery' or 'csvquery' for tab- and comma-separated variants

			$(echo "$cmds" | grep 'query ' | sort -k2 | column -s: -t | sed 's/^/    /')

		EOF
	fi

	if (( $# == 0  )) || [[ $1 == "mutate" ]]; then
		cat <<-EOF
			DB Mutations: (csv/tsv queries are NOT available)

			$(echo "$cmds" | grep 'mutate ' | sort -k2 | column -s: -t | sed 's/^/    /')

		EOF
	fi

	if (( $# == 0  )) || [[ $1 == "local" ]]; then
		cat <<-EOF
			Local: (These can be configured in $GXADMIN_SITE_SPECIFIC)

			$(echo "$cmds" | grep '^local' | column -s: -t | sed 's/^/    /')

		EOF
	fi

	if (( $# == 0  )) || [[ $1 == "meta" ]]; then
		cat <<-EOF
			Meta:

			$(echo "$cmds" | grep '^meta ' | column -s: -t | sed 's/^/    /')

		EOF
	fi


	cat <<-EOF
		help / -h / --help : this message. Invoke '--help' on any subcommand for help specific to that subcommand
	EOF

	echo $# $1 $2

	exit 0;
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
