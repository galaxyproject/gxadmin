uwsgi() {
	subfunc="$1"; shift
	case "$subfunc" in
		stats_influx  ) uwsgi_stats_influx "$@";;
	esac
}
