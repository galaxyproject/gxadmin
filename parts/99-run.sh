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
	report ) $wrapper look_for report "$@" ;;
	local  ) $wrapper local_funcs     "$@" ;;
	mutate ) $wrapper mutate "$mode"  "$@" ;;
	uwsgi  ) $wrapper look_for uwsgi  "$@" ;;
	meta   ) $wrapper look_for meta   "$@" ;;

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
