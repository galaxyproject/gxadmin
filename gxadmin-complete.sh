GXADMIN_SITE_SPECIFIC=${GXADMIN_SITE_SPECIFIC:-~/.config/gxadmin-local.sh}
GXADMIN=$(which gxadmin)

_gxadmin() {
	local cur prev opts mprev
	COMPREPLY=()
	cur="${COMP_WORDS[COMP_CWORD]}"
	prev="${COMP_WORDS[COMP_CWORD-1]}"

	local cmds="query tsvquery csvquery iquery config filter galaxy report local mutate uwsgi meta help"
	if [[ $prev == "gxadmin" ]]; then
		COMPREPLY=( $(compgen -W "${cmds}" -- ${cur}) )
		return 0
	fi

	mprev="${prev}"
	if [[ ${prev} == "iquery" ]] || [[ ${prev} == "csvquery" ]] || [[ ${prev} == "tsvquery" ]]; then
		mprev="query"
	fi
	opts="$(grep -s -h -o "^${mprev}_.*##" $GXADMIN $GXADMIN_SITE_SPECIFIC | sed "s/${mprev}_//;s/(.*//")"

	case "${prev}" in
		*query)
			COMPREPLY=( $(compgen -W "$opts" -- ${cur}) )
			return 0
		;;
		config)
			COMPREPLY=( $(compgen -W "$opts" -- ${cur}) )
			return 0
		;;
		filter)
			COMPREPLY=( $(compgen -W "$opts" -- ${cur}) )
			return 0
		;;
		galaxy)
			COMPREPLY=( $(compgen -W "$opts" -- ${cur}) )
			return 0
		;;
		report)
			COMPREPLY=( $(compgen -W "$opts" -- ${cur}) )
			return 0
		;;
		mutate)
			COMPREPLY=( $(compgen -W "$opts" -- ${cur}) )
			return 0
		;;
		uwsgi)
			COMPREPLY=( $(compgen -W "$opts" -- ${cur}) )
			return 0
		;;
		meta)
			COMPREPLY=( $(compgen -W "$opts" -- ${cur}) )
			return 0
		;;
		local)
			COMPREPLY=( $(compgen -W "$opts" -- ${cur}) )
			return 0
		;;
		*)
			COMPREPLY=( $(compgen -W "" -- ${cur}) )
			return 0
		;;
	esac

	COMPREPLY=( $(compgen -W "${cmds}" -- ${cur}) )
	return 0
}

complete -F _gxadmin gxadmin
