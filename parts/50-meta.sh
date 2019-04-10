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
	for section in $(grep -o '{ ## .*' $0 | grep -v grep | grep -v '| sed' | awk '{print $3}' | sort -u); do
		echo "# $section" > docs/README.${section}.md

		echo "### $section"
		echo
		echo "Command | Description"
		echo "------- | -----------"
		for command in $(grep -o '{ ## .*' $0 | grep -v grep | grep -v '| sed' | sort | sed 's/^{ ## //g' | grep "^$section"); do
			cmd_part="$(echo $command | sed 's/:.*//g;s/\s*<.*//g;s/\s*\[.*//')"
			desc_part="$(echo $command | sed 's/^[^:]*:\s*//g')"
			key_part="$(echo $cmd_part | sed 's/ /-/g')"

			if [[ "$command" != *"Deprecated"* ]]; then
				# Main ToC
				echo "[\`${cmd_part}\`](docs/README.${section}.md#${key_part}) | $desc_part"

				# Subsec documentation
				echo                          >> docs/README.${section}.md
				echo "### $cmd_part"          >> docs/README.${section}.md
				echo                          >> docs/README.${section}.md
				bash -c "$0 $cmd_part --help" >> docs/README.${section}.md
			else
				echo "\`${cmd_part}\` | $desc_part"
			fi
		done
		echo
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
