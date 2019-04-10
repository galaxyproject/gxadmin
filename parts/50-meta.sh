meta_update() { ## meta update: Update the script
	handle_help "$@" <<-EOF
	EOF

	tmp=$(mktemp);
	curl https://raw.githubusercontent.com/usegalaxy-eu/gxadmin/master/gxadmin > $tmp;
	chmod ugo+rx $tmp;
	mv $tmp $0;
	exit 0;
}

meta_cmdlist() {
	handle_help "$@" <<-EOF
	EOF

	IFS=$'\n'
	# TOC
	echo "## Commands"
	echo
	echo "Command | Description"
	echo "------- | -----------"
	for command in $(grep -o '{ ## .*' $0 | grep -v grep | grep -v '| sed' | sort | sed 's/^{ ## //g'); do
		cmd_part="$(echo $command | sed 's/:.*//g;s/\s*<.*//g;s/\s*\[.*//')"
		desc_part="$(echo $command | sed 's/^[^:]*:\s*//g')"
		key_part="$(echo $cmd_part | sed 's/ /-/g')"
		echo "[\`${cmd_part}\`](#${key_part}) | $desc_part"
	done
	echo

	# Now for sections
	for command in $(grep -o '{ ## .*' $0 | grep -v grep | grep -v '| sed' | sort | sed 's/^{ ## //g'); do
		cmd_part="$(echo $command | sed 's/:.*//g;s/\s*<.*//g;s/\s*\[.*//')"
		echo
		echo "### $cmd_part"
		echo
		bash -c "$0 $cmd_part --help"
	done
}

meta_slurp-current() { ## meta slurp-current: Executes what used to be "Galaxy Slurp"
	handle_help "$@" <<-EOF
	EOF

	$0 iquery server-workflow-invocations
}

meta_error() {
	error "$@"
}

meta_warning() {
	warning "$@"
}

meta_success() {
	success "$@"
}
