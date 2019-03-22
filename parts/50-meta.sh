update() { ## update: Update the script
	handle_help "$@" <<-EOF
	EOF

	tmp=$(mktemp);
	curl https://raw.githubusercontent.com/usegalaxy-eu/gxadmin/master/gxadmin > $tmp;
	chmod ugo+x $tmp;
	chmod ugo+r $tmp;
	mv $tmp $0;
	exit 0
}


version() {
	echo 12
}

cmdlist() {
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
