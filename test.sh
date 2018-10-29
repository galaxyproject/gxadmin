#!/bin/bash
help_wanted() {
	echo "$@" | grep --quiet -- '--help'
}

usage() {
	echo "Usage: ./$0"
	echo
	if (( $# == 0 )); then
		grep -o '## .*' $0 | grep -v grep | sort | sed 's/^## /  /g' | column -t -s:
	else
		grep -o "## $1.*" $0 | grep -v grep | sort | sed 's/^## /  /g'  | column -t -s:
	fi
	echo
}

cmd=$1;
shift

if [[ $cmd == "a" ]]; then
	subcmd=$1;
	shift

	if [[ $subcmd == "b" ]]; then ## a b: does B thing
		if help_wanted "$@"; then
			cat <<EOF
Hello, world B
EOF
			exit 0
		fi

		echo "a b called"
	elif [[ $subcmd == "c" ]]; then ## a b: does C thing
		if help_wanted "$@"; then
			cat <<EOF
Hello, world C
EOF
			exit 0
		fi

		echo "a c called"
	else
		usage a
	fi
elif [[ $cmd == "bravo" ]]; then ## bravo: does blah
	echo "blah"
elif [[ $cmd == "--help" ]]; then
	usage
	exit 1
else
	usage
	exit 1
fi
