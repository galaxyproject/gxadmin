registered_subcommands="$registered_subcommands gunicorn"
_gunicorn_short_help="Gunicorn WSGI statistics"
_gunicorn_long_help="
	Various commands that contain the gunicorn service, such as active users... Please help to extend
"

gunicorn_active-users() { ## : Shows active users in last 10 minutes
	handle_help "$@" <<-EOF
		See unique sorts IP adresses from 'GET /history/current_history_json' from last 10 minutes and prints it in influx line format
	EOF

	echo "active_users,timespan=last_10_min users=$(journalctl -u galaxy-gunicorn@*.service --since '10 minutes ago' | \
	grep '/history/current_history_json'  | awk '{print $11}' | sort -u | wc -l)"
}

gunicorn_handler-restart() { ## : Restart all handlers
	handle_help "$@" <<-EOF
	EOF

	for i in {0..11}; do
		systemctl restart galaxy-gunicorn@$i
		sleep 4 min
	done
}

gunicorn_lastlog(){ ## : Fetch the number of seconds since the last log message was written
	handle_help "$@" <<-EOF
		Lets you know if any of your workers or handlers have maybe stopped processing jobs.

		$ gxadmin gunicorn lastlog
			journalctl.lastlog,service=galaxy-handler@0 seconds=8
			journalctl.lastlog,service=galaxy-handler@1 seconds=2
			journalctl.lastlog,service=galaxy-handler@2 seconds=186
			journalctl.lastlog,service=galaxy-handler@3 seconds=19
			journalctl.lastlog,service=galaxy-handler@4 seconds=6
			journalctl.lastlog,service=galaxy-handler@5 seconds=80
			journalctl.lastlog,service=galaxy-handler@6 seconds=52
			journalctl.lastlog,service=galaxy-handler@7 seconds=1
			journalctl.lastlog,service=galaxy-handler@8 seconds=79
			journalctl.lastlog,service=galaxy-handler@9 seconds=40
			journalctl.lastlog,service=galaxy-handler@10 seconds=123
			journalctl.lastlog,service=galaxy-handler@11 seconds=13
			journalctl.lastlog,service=galaxy-zergling@0 seconds=0
			journalctl.lastlog,service=galaxy-zergling@1 seconds=0
			journalctl.lastlog,service=galaxy-zergling@2 seconds=2866

	EOF

	NOW=$(date +%s)

	for i in {0..1}; do
		lines=$(journalctl -u galaxy-gunicorn@$i -n 1 --no-pager)
		if [[ ! $lines == *"No entries"* ]]; then
			timestamp=$(journalctl -u galaxy-handler@$i -n 1 --no-pager | grep -v 'Logs begin' | awk '{print $1" "$2" "$3}');
			unix=$(date -d "$timestamp" +%s)
			date_diff=$((NOW - unix));
			echo "journalctl.lastlog,service=galaxy-handler@$i seconds=$date_diff";
		fi
	done
}

