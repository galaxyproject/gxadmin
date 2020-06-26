meta_complete-bash() { ## : export bash autocompletion
	handle_help "$@" <<-EOF
		Produces the bash autocompletion for gxadmin

		Write the output of this somewhere useful, and source it in your bash profile.

		    $ gxadmin meta bash-complete > ~/.cache/gxadmin-autocomplete.sh
			$ . ~/.cache/gxadmin-autocomplete.sh
			$ gxadmin<TAB>
	EOF

	IFS=$'\n'
	commands=$(locate_cmds_nolocal | correct_cmd | sed 's/://g')

	leading=$(echo "$commands" | awk '{print $1}' | sort -u | paste -s -d' ')
	subcommands=""
	for cmd in $(echo "$commands" | awk '{print $1}' | sort -u); do
		subcmds=$(echo "$commands" | awk '($1 == "'"$cmd"'"){ print $2 }' | sort -u | paste -s -d' ')
		if (( ${#subcmds} > 0 )); then
			subcommands="${subcommands}\n\n\t\t$cmd)\n\t\t\tCOMPREPLY=( \$(compgen -W \"${subcmds}\" \${cur}) )\n\t\t\treturn 0\n\t\t;;"
		fi
	done;
	# Fix newlines
	subcommands="$(echo -e "$subcommands")"

	# Template
BASH_COMPLETION_TEMPLATE=$(cat <<EOF
_gxadmin() {
	local cur prev opts
	COMPREPLY=()
	cur="\${COMP_WORDS[COMP_CWORD]}"
	prev="\${COMP_WORDS[COMP_CWORD-1]}"

	local -r cmds="%s"

	case "\${prev}" in
		%s
	esac

	COMPREPLY=( \$(compgen -W "\${cmds}" -- \${cur}) )
	return 0
}

complete -F _gxadmin gxadmin
EOF
)

	# shellcheck disable=SC2059
	printf "${BASH_COMPLETION_TEMPLATE}\n" "$leading" "$subcommands"
}
