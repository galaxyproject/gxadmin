local_funcs() {
	if [[ ! -f ${GXADMIN_SITE_SPECIFIC} ]]; then
		error "No local functions are defined in ${GXADMIN_SITE_SPECIFIC}"
		exit 1
	else
		# Load functions
		. ${GXADMIN_SITE_SPECIFIC}
	fi

	group_name="local"
	query_name="$1"; shift

	# Check that FN exists
	fn="${group_name}_${query_name}"
	LC_ALL=C type $fn 2> /dev/null | grep -q 'function'

	if (( $? == 0 )); then
		if [[ -z "${GXADMIN_BUGGER_OFF}" ]] && (( ($RANDOM % 25) == 0 )); then
			warning "Hey! It's great that you're using gxadmin! You should contribute these functions back :) Other people might find these useful, or could learn something from the code you've written, even if you think it is too specific to your site."
		fi

		$fn "$@";

		if [[ "${query_name}" == "query"* ]]; then
			query_tbl "$QUERY"
		fi
	else
		usage ${group_name}
	fi
}
