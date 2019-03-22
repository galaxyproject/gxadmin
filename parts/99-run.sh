if (( $# == 0 )); then
	usage safe
fi

mode="$1"; shift

case "$mode" in
	validate                       ) validate          "$@" ;;
	cleanup                        ) cleanup           "$@" ;;
	migrate-tool-install-to-sqlite ) migrate_to_sqlite "$@" ;;
	dump-config                    ) dump_config       "$@" ;;
	update                         ) update            "$@" ;;
	uwsgi                          ) uwsgi             "$@" ;;
	filter                         ) filter            "$@" ;;
	mutate                         ) mutate "$mode"    "$@" ;;
	local                          ) local_funcs       "$@" ;;
	*query                         ) query "$mode"     "$@" ;;

	# Generate for readme:
	cmdlist   ) cmdlist ;;
	completion ) completion;;
	# version commands
	version   ) version ;;
	-v        ) version ;;
	--version ) version ;;
	# help
	help      ) usage safe ;;
	-h        ) usage safe ;;
	--help    ) usage safe ;;
	# anything else
	*         ) usage safe;;
esac
