assert_restart_lock(){
	if [ -f "$HOME/.restart-lock" ]; then
		echo "A restart lock exists. This means someone is probably already restarting galaxy."
		exit 3
	fi
}

assert_set_env() {
	env_var=$1
	if [[ -z "${!env_var}" ]]; then
		error Please set "\$${env_var}"
		exit 1
	fi
}

wait_for_url() {
	url=$1; shift;

	while [ "$(curl --connect-timeout 5 --silent "$url" | wc -c)" -eq "0" ]; do
		sleep 5;
		echo -n '.'
	done
}

assert_count() {
	if (( $1 != $2 )); then
		error "$3"
		exit 1
	fi
}

assert_count_ge() {
	if (( $1 < $2 )); then
		error "$3"
		exit 1
	fi
}

assert_file() {
	if [[ ! -f "$1" ]]; then
		error "File $1 does not exist"
		exit 1
	fi
}

assert_file_warn() {
	if [[ ! -f "$1" ]]; then
		warning "File $1 does not exist"
	fi
}
