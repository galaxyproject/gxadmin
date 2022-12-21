registered_subcommands="$registered_subcommands gunicorn"
_gunicorn_short_help="Gunicorn WSGI statistics"
_gunicorn_long_help="
	Various commands that contain the gunicorn service, such as active users... Please help to extend
"

gunicorn_active-users() { ## : Shows active users in last 10 minutes
	handle_help "$@" <<-EOF
		Extract a count of unique IP adresses from 'GET /history/current_history_json' from last 10 minutes and prints it in influx line format
	EOF

	echo "active_users,timespan=last_10_min users=$(journalctl -u galaxy-gunicorn@*.service --since '10 minutes ago' | \
	grep '/history/current_history_json'  | awk '{print $11}' | sort -u | wc -l)"
}
