local_funcs() {
	if [[ ! -f ${GXADMIN_SITE_SPECIFIC} ]]; then
		error "No local functions are defined in ${GXADMIN_SITE_SPECIFIC}"
		exit 1
	else
		. ${GXADMIN_SITE_SPECIFIC}
	fi

	subfunc="$1"; shift
	if [[ ! -n "$subfunc" || $subfunc == "-h" || $subfunc == "--help" || $subfunc == "help" ]]; then
		cmds="$(grep -o '{ ## .*' ${GXADMIN_SITE_SPECIFIC} | grep -v grep | grep -v '| sed' | sort | sed 's/^{ ## //g')"
		cat <<-EOF
			gxadmin local functions usage:

			$(echo "$cmds" | sort -k2 | column -s: -t | sed 's/^/    /')

			help / -h / --help : this message. Invoke '--help' on any subcommand for help specific to that subcommand
		EOF
	else
		if [[ -z "${GXADMIN_BUGGER_OFF}" ]] && (( ($RANDOM % 25) == 0 )); then
			warning "Hey! It's great that you're using gxadmin! You should contribute these functions back :) Other people might find these useful, or could learn something from the code you've written, even if you think it is too specific to your site."
		fi

		local_${subfunc} "$@";
	fi
}
