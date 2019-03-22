filter() {
	subfunc="$1"; shift
	case "$subfunc" in
		hexdecode  ) hexdecode "$@" ;;
		pg2md      ) pg2md     "$@" ;;
	esac
}
