if (( $# == 0 )); then
	usage
fi

mode="$1"; shift

case "$mode" in
	*query ) query "$mode"   "$@" ;;
	config ) look_for config "$@" ;;
	filter ) look_for filter "$@" ;;
	galaxy ) look_for galaxy "$@" ;;
	local  ) local_funcs     "$@" ;;
	mutate ) mutate "$mode"  "$@" ;;
	uwsgi  ) look_for uwsgi  "$@" ;;
	meta   ) look_for meta   "$@" ;;

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
