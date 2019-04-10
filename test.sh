#!/bin/bash

@test "Ensure no trailing semicolons in queries" {
	result=$(grep -Pzl '(?s);\n\tEOF' parts/* | wc -l)
	if (( $result > 0 )); then
		grep -Pzl '(?s);\n\t*EOF' parts/*
	fi
	[ "$result" -eq 0 ]
}
