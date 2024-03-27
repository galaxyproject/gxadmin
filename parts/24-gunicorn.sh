registered_subcommands="$registered_subcommands	gunicorn"
_gunicorn_short_help="Gunicorn WSGI	statistics"
_gunicorn_long_help="
	Various	commands that contain the gunicorn service,	such as	active users...	Please help	to extend
"

gunicorn_active-users()	{ ## : Shows active	users in last 10 minutes
	handle_help	"$@" <<-EOF
		See	unique sorts IP	adresses from 'GET /history/current_history_json' from last	10 minutes and prints it in	influx line	format
	EOF

	echo "active_users,timespan=last_10_min	users=$(journalctl -u galaxy-gunicorn@*.service	--since	'10	minutes	ago' | \
	grep '/history/current_history_json'  |	awk	'{print	$11}' |	sort -u	| wc -l)"
}

gunicorn_handler-restart() {
	# Retrieve running gunicorn	services matching "galaxy-gunicorn"
	readarray -t gunicorns < <(systemctl list-units	--state=running	| grep galaxy-gunicorn | cut -d	'@'	-f2	| cut -d '.' -f1)

	# Calculate	batch size
	# batch_size=$(( (${#gunicorns[@]} + 1)	/ 2	))
	batch_size=$(( (${#gunicorns[@]} - 1) /	2 +	1))

	# Construct	service	name ranges	for	each batch
	batch1=""
	batch2=""
	for	((i	= 0; i < ${#gunicorns[@]} -	1; i++)); do
		if ((i < batch_size)); then
			batch1+="galaxy-gunicorn@${gunicorns[i]}.service "
		else
			batch2+="galaxy-gunicorn@${gunicorns[i]}.service "
		fi
	done
	# Restart each batch
	if systemctl status	$batch1	| grep "GET" | grep "200" >/dev/null
	then
			echo "First	restarting:	$batch2"
			systemctl restart $batch2
			while true
			do
					if systemctl status	$batch2	| grep "GET" | grep "200" >/dev/null
					then
							break
					else
							sleep 10
					fi
			done
			echo "Now restarting: $batch1"
			systemctl restart $batch1
	fi
}

gunicorn_lastlog(){	## : Fetch the number of seconds since the last	log	message	was	written
	handle_help	"$@" <<-EOF
		Lets you know if any of	your workers or	handlers have maybe	stopped	processing jobs.

		$ gxadmin gunicorn lastlog
			journalctl.lastlog,service=galaxy-gunicorn@0 seconds=0
			journalctl.lastlog,service=galaxy-gunicorn@1 seconds=0
			journalctl.lastlog,service=galaxy-gunicorn@2 seconds=2866

	EOF

	NOW=$(date +%s)

	for	i in {0..10}; do
		lines=$(journalctl -u galaxy-gunicorn@$i -n	1 --no-pager)
		if [[ !	$lines == *"No entries"* ]]; then
			timestamp=$(journalctl -u galaxy-handler@$i	-n 1 --no-pager	| grep -v 'Logs	begin' | awk '{print $1" "$2" "$3}');
			unix=$(date	-d "$timestamp"	+%s)
			date_diff=$((NOW - unix));
			echo "journalctl.lastlog,service=galaxy-handler@$i seconds=$date_diff";
		fi
	done
}

