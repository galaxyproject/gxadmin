#!/usr/bin/env bats
GXADMIN=./.tmpgxadmin

@test "Ensure gxadmin exits with zero" {
	run ${GXADMIN}
	[ "$status" -eq 0 ]
	[ "${lines[0]}" = "gxadmin usage:" ]
}

@test "Ensure help is not too long" {
	out_lines=$(${GXADMIN} | wc -l)
	[ "$out_lines" -lt 100 ]
}

@test "Version should be returned" {
	out_lines=$(${GXADMIN} version)
	[ "$out_lines" -gt 0 ]
}

@test "Ensure no trailing semicolons in queries (fix: remove semicolon from before EOF)" {
	result=$(grep -Pzl '(?s);\n\tEOF' parts/* | wc -l)
	if (( $result > 0 )); then
		grep -Pzl '(?s);\n\t*EOF' parts/*
	fi
	[ "$result" -eq 0 ]
}

@test "Ensure that changes were made to BOTH parts/* and gxadmin (fix: run make)" {
	run diff <(cat gxadmin) <(cat parts/*.sh)
	[ "$status" -eq 0 ]
}

@test "Ensure only using tabs" {
	out_lines=$(egrep '^ +[^\t]' gxadmin | grep -v '%s' | wc -l)
	if (( $out_lines > 2 )); then
		echo "Lines with potential issues. Either fix these or increase the exclusion in the test.sh if it is valid (e.g. inside printf)"
		egrep '^ +[^\t]' parts/* | grep -v %s
	fi
	[ "$out_lines" -lt 3 ]
}

@test "Ensure no shell expansions/vars in changelog (Fix: remove \` and \$ from changelog)" {
	backticks=$(grep -c '`' CHANGELOG.md || true)
	shell=$(grep -c '$' CHANGELOG.md || true)
	both=$(( backticks + shell ))
	[ "$both" -gt 0 ]
}

@test "Ensure no missing help commands" {
	num=$(cat docs/README.* | grep 'gxadmin usage' -c || true)
	[ "$num" -eq 0 ]
}
