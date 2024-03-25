# Find a python binary, hopefully.
if [[ -z "${GXADMIN_PYTHON}" ]]; then
	if hash python3 2>/dev/null; then
		export GXADMIN_PYTHON=$(command -v python3)
	elif hash python2 >/dev/null; then
		export GXADMIN_PYTHON=$(command -v python2)
	elif hash python >/dev/null; then
		export GXADMIN_PYTHON=$(command -v python)
	else
		warning "Some features require Python support. If you have Python installed somewhere that is not on the path or under a different name, set GXADMIN_PYTHON to the path."
	fi
fi
