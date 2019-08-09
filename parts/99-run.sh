search() { # <term>: Search for a specific command
	if (( $# > 0 )); then
		locate_cmds | correct_cmd | grep $1 | colour_word $1 orange
	else
		locate_cmds | correct_cmd
	fi
}

if (( $# == 0 )); then
	usage
fi

mode="$1"; shift
wrapper=
if [[ "$mode" == time* ]]; then
	wrapper=wrap_time
	mode=${mode:4}
fi

case "$mode" in
	*query ) query "$mode"   "$@" ;;
	config ) $wrapper look_for config "$@" ;;
	filter ) $wrapper look_for filter "$@" ;;
	galaxy ) $wrapper look_for galaxy "$@" ;;
	local  ) $wrapper local_funcs     "$@" ;;
	meta   ) $wrapper look_for meta   "$@" ;;
	mutate ) $wrapper mutate "$mode"  "$@" ;;
	report ) $wrapper look_for report "$@" ;;
	uwsgi  ) $wrapper look_for uwsgi  "$@" ;;
	s      ) search "$@" ;;
	find   ) search "$@" ;;
	search ) search "$@" ;;

	# version commands
	version   ) version ;;
	-v        ) version ;;
	--version ) version ;;
	# help
	help      ) usage;;
	-h        ) usage;;
	--help    ) usage;;
	# anything else
	*         ) usage;;
esac
