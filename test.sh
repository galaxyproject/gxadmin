#!/usr/bin/env bats

@test "Ensure gxadmin exits with zero" {
	run ./gxadmin
	[ "$status" -eq 0 ]
	[ "${lines[0]}" = "gxadmin usage:" ]
}

@test "Ensure help is not too long" {
	out_lines=$(./gxadmin | wc -l)
	[ "$out_lines" -lt 100 ]
}

@test "Version should be returned" {
	out_lines=$(./gxadmin version)
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
