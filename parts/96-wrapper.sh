wrap_time() {
	local TIMEFORMAT="Time to execute $1: %R seconds"
	time "$@"
}
