registered_subcommands="$registered_subcommands meta"
_meta_short_help="meta:   Miscellaneous"


meta_update() { ## : Update the script
	handle_help "$@" <<-EOF
	EOF

	tmp=$(mktemp);
	curl https://raw.githubusercontent.com/usegalaxy-eu/gxadmin/main/gxadmin > "$tmp";
	chmod ugo+rx "$tmp";
	mv "$tmp" "$0";
	exit 0;
}

meta_cmdlist() {
	handle_help "$@" <<-EOF
	EOF

	IFS=$'\n'
	# TOC
	for section in $(locate_cmds_nolocal | correct_cmd | awk '{print $1}' | sort -u); do
		# Progress
		echo $section

		# contents
		echo "# $section"            >  "docs/README.${section}.md"
		echo                         >> "docs/README.${section}.md"
		echo "Command | Description" >> "docs/README.${section}.md"
		echo "------- | -----------" >> "docs/README.${section}.md"
		for command in $(locate_cmds_nolocal | correct_cmd | grep "^$section"); do
			cmd_part="$(echo "$command" | sed 's/:.*//g;s/\s*<.*//g;s/\s*\[.*//')"
			desc_part="$(echo "$command" | sed 's/^[^:]*:\s*//g')"
			key_part="$(echo "$cmd_part" | sed 's/ /-/g')"

			if [[ "$command" != *"Deprecated"* ]]; then
				# Main ToC
				echo "[\`${cmd_part}\`](#${key_part}) | $desc_part" >> "docs/README.${section}.md"
			else
				echo "\`${cmd_part}\` | $desc_part" >> "docs/README.${section}.md"
			fi
		done

		for command in $(locate_cmds_nolocal | correct_cmd | grep "^$section"); do
			cmd_part="$(echo "$command" | sed 's/:.*//g;s/\s*<.*//g;s/\s*\[.*//;s/\s*$//')"
			desc_part="$(echo "$command" | sed 's/^[^:]*:\s*//g;s/\s*$//')"
			key_part="$(echo "$cmd_part" | sed 's/ /-/g')"
			url_part="$(echo "$cmd_part" | sed 's/ /_/g')"

			if [[ "$command" != *"Deprecated"* ]]; then
				# Subsec documentation
				echo                          >> "docs/README.${section}.md"
				echo "## $cmd_part"           >> "docs/README.${section}.md"
				echo                          >> "docs/README.${section}.md"
				echo "([*source*](https://github.com/usegalaxy-eu/gxadmin/search?q=${url_part}&type=Code))" >> "docs/README.${section}.md"
				bash -c "$0 $cmd_part --help" >> "docs/README.${section}.md"
			fi
		done
	done
}

meta_cmdlist2() {
	handle_help "$@" <<-EOF
	EOF

	IFS=$'\n'
	# TOC
	for section in $(locate_cmds_nolocal | correct_cmd | awk '{print $1}' | sort -u); do
		for command in $(locate_cmds_nolocal | correct_cmd | grep "^$section"); do
			echo "$command" | sed 's/:.*//g;s/\s*<.*//g;s/\s*\[.*//;s/\s*$//'
		done
	done
}

meta_slurp-current() { ## [--date] [slurp-name [2nd-slurp-name [...]]]: Executes what used to be "Galaxy Slurp"
	handle_help "$@" <<-EOF
		Obtain influx compatible metrics regarding the current state of the
		server. UseGalaxy.EU uses this to display things like "Current user
		count" and "Current dataset size/distribution/etc."

		It is expected that you are passing this straight to telegraf, there is
		no non-influx output supported currently.

		Supplying --date will include the current timestamp at the end of the
		line, making it compatible for "gxadmin meta influx-post" usage

		You can add your own functions which are included in this output, using
		the \$GXADMIN_SITE_SPECIFIC file. They must start with the prefix
		"server_", e.g. "server_mymetric".

		    $ gxadmin meta slurp-current
		    server-allocated-cpu,job_runner_name=condor cpu_years=102.00
		    server-allocated-cpu,job_runner_name=local cpu_years=1346.00
		    server-datasets,deleted=f,object_store_id=,state=error,purged=f count=37,size=29895528
		    server-datasets,deleted=f,object_store_id=,state=ok,purged=f count=72,size=76739510
		    server-datasets,deleted=f,object_store_id=,state=discarded,purged=f count=2,size=0
		    server-hda,deleted=f,extension=gff3 max=2682565,sum=2682565,avg=2682565,min=2682565
		    server-hda,deleted=t,extension=tabular max=468549,sum=597843,avg=22142,min=2
		    server-hda,deleted=f,extension=fastqsanger max=3,sum=3,avg=3,min=3
		    server-hda,deleted=f,extension=tabular max=2819293,sum=3270268,avg=155727,min=3
		    server-hda,deleted=f,extension=png max=800459,sum=7047695,avg=503407,min=142863
		    server-hda,deleted=t,extension=auto max=9571,sum=9571,avg=9571,min=9571
		    server-hda,deleted=t,extension=data max=2,sum=2,avg=2,min=2
		    server-hda,deleted=t,extension=txt max=5023,sum=5039,avg=2520,min=16
		    server-hda,deleted=t,extension=bigwig max=2972569,sum=5857063,avg=1464266,min=0
		    server-hda,deleted=t,extension=tar.gz max=209034,sum=1318690,avg=188384,min=91580
		    server-hda,deleted=f,extension=vcf_bgzip max=3965889,sum=3965889,avg=3965889,min=3965889
		    server-hda,deleted=t,extension=png max=2969711,sum=6584812,avg=1097469,min=183
		    server-hda,deleted=f,extension=txt max=9584828,sum=132124407,avg=4556014,min=0
		    server-hda,deleted=f,extension=bigwig max=14722,sum=17407,avg=8704,min=2685
		    server-hda,deleted=f,extension=tar.gz max=209025,sum=390421,avg=195211,min=181396
		    server-histories,importable=f,deleted=f,genome_build=?,published=f,importing=f,purged=f count=14
		    server-jobs,state=ok,destination_id=slurm_singularity,job_runner_name=local count=26
		    server-jobs,state=error,destination_id=condor_resub,job_runner_name=condor count=1
		    server-jobs,state=deleted,destination_id=local,job_runner_name=local count=1
		    server-jobs,state=error,destination_id=condor,job_runner_name=condor count=8
		    server-jobs,state=ok,destination_id=local,job_runner_name=local count=13
		    server-jobs,state=ok,destination_id=condor,job_runner_name=condor count=2
		    server-jobs,state=error,destination_id=local,job_runner_name=local count=3
		    server-users,active=t,deleted=f,external=f,purged=f count=3
		    server-workflows,deleted=f,importable=f,published=f count=3
	EOF

	append=""
	if [[ $1 == "--date" ]]; then
		append=" "$(date +%s%N)
		shift;
	fi

	specific_slurp=($@)

	# shellcheck disable=SC2013
	for func in $(grep -s -h -o '^server_[a-z-]*' "$0" "$GXADMIN_SITE_SPECIFIC" | sort | sed 's/server_//g'); do
		# To allow only slurping the one that was requested, if this was done.
		if (( ${#specific_slurp[@]} > 0 )); then
			if [[ ! "${specific_slurp[*]}" =~ "${func}"  ]]; then
				continue
			fi
		fi

		obtain_func "server" "$func"
		$wrapper query_influx "$QUERY" "$query_name" "$fields" "$tags" | sed "s/$/$append/"
	done
}

meta_slurp-upto() { ## <yyyy-mm-dd> [slurp-name [2nd-slurp-name [...]]]: Slurps data up to a specific date.
	handle_help "$@" <<-EOF
		Obtain influx compatible metrics regarding the summed state of the
		server up to a specific date. UseGalaxy.EU uses this to display things
		like charts of "how many users were registered as of date X".

		This calls all of the same functions as 'gxadmin meta slurp-current',
		but with date filters for the entries' creation times.
	EOF

	date=$1; shift
	specific_slurp=($@)

	# shellcheck disable=SC2013
	for func in $(grep -s -h -o '^server_[a-z-]*' "$0" "$GXADMIN_SITE_SPECIFIC" | sort | sed 's/server_//g'); do
		# To allow only slurping the one that was requested, if this was done.
		if (( ${#specific_slurp[@]} > 0 )); then
			if [[ ! "${specific_slurp[*]}" =~ "${func}"  ]]; then
				continue
			fi
		fi

		obtain_func server "$func" "$date" "<="
		$wrapper query_influx "$QUERY" "$query_name.upto" "$fields" "$tags" | \
			sed "s/$/ $(date -d "$date" +%s%N)/"
	done
}

meta_slurp-day() { ## <yyyy-mm-dd> [slurp-name [2nd-slurp-name [...]]]: Slurps data on a specific date.
	handle_help "$@" <<-EOF
		Obtain influx compatible metrics regarding the state of the
		server on a specific date. UseGalaxy.EU uses this to display things
		like charts of "how many users were registered as of date X". You can
		backfill data from your server by running a for loop like:

		    #!/bin/bash
		    for i in range {1..365}; do
		        gxadmin meta slurp-day \$(date -d "$i days ago" "+%Y-%m-%d") | <get into influx somehow>
		    done

		It is expected that you are passing this straight to telegraf, there is
		no non-influx output supported currently.

		This calls all of the same functions as 'gxadmin meta slurp-current',
		but with date filters for the entries' creation times.

		You can add your own functions which are included in this output, using
		the \$GXADMIN_SITE_SPECIFIC file. They must start with the prefix
		"server_", e.g. "server_mymetric". They should include a date filter as
		well, or the metrics reported here will be less useful.

		    $ gxadmin meta slurp-day 2019-01-01
		    server-allocated-cpu.daily,job_runner_name=condor cpu_years=102.00
		    server-datasets.daily,deleted=f,object_store_id=,state=error,purged=f count=37,size=29895528
		    server-datasets.daily,deleted=f,object_store_id=,state=ok,purged=f count=72,size=76739510
		    server-datasets.daily,deleted=f,object_store_id=,state=discarded,purged=f count=2,size=0
		    server-hda.daily,deleted=t,extension=data max=2,sum=2,avg=2,min=2
		    server-hda.daily,deleted=t,extension=txt max=5023,sum=5039,avg=2520,min=16
		    server-hda.daily,deleted=f,extension=fastqsanger max=3,sum=3,avg=3,min=3
		    server-hda.daily,deleted=f,extension=tabular max=3,sum=51,avg=3,min=3
		    server-hda.daily,deleted=t,extension=tabular max=468549,sum=552788,avg=21261,min=2
		    server-histories.daily,importable=f,deleted=f,genome_build=?,published=f,importing=f,purged=f count=5
		    server-jobs.daily,state=error,destination_id=condor,job_runner_name=condor count=8
		    server-jobs.daily,state=error,destination_id=condor_resub,job_runner_name=condor count=1
		    server-jobs.daily,state=error,destination_id=condor_a,job_runner_name=condor count=11
		    server-jobs.daily,state=ok,destination_id=condor,job_runner_name=condor count=2
		    server-jobs.daily,state=ok,destination_id=condor_a,job_runner_name=condor count=23
		    server-users.daily,active=t,deleted=f,external=f,purged=f count=1
		    server-workflows.daily,deleted=f,importable=f,published=f count=1

	EOF

	date=$1; shift;
	specific_slurp=($@)

	# shellcheck disable=SC2013
	for func in $(grep -s -h -o '^server_[a-z-]*' "$0" "$GXADMIN_SITE_SPECIFIC" | sort | sed 's/server_//g'); do
		# To allow only slurping the one that was requested, if this was done.
		if (( ${#specific_slurp[@]} > 0 )); then
			if [[ ! "${specific_slurp[*]}" =~ "${func}"  ]]; then
				continue
			fi
		fi

		obtain_func server "$func" "$date"
		$wrapper query_influx "$QUERY" "$query_name.daily" "$fields" "$tags" | \
			sed "s/$/ $(date -d "$date" +%s%N)/"
	done
}

meta_slurp-initial() { ## <yyyy-mm-dd> <yyyy-mm-dd> [slurp-name [2nd-slurp-name [...]]]: Slurps data starting at the first date until the second date.
	handle_help "$@" <<-EOF
		Obtains influx compatible metrics between dates and posts this to Influx.
		This function calls 'gxadmin meta slurp-upto' and 'gxadmin meta slurp-day'.

		It requires a start and end date. Allows to run specific slurp queries.
	EOF

	# Variables
	begindate=$1; shift
	enddate=$1; shift
	specific_slurp=($@)
	specific_slurp_string=""
	if (( ${#specific_slurp[@]} > 0 )); then
		for specificslurppiece in "${specific_slurp[@]}"; do
			if (( ${#specific_slurp_string} == 0 )); then
				specific_slurp_string="$specificslurppiece"
			else
				specific_slurp_string="$specific_slurp_string $specificslurppiece"
			fi
		done
	fi

	tmpfile=/tmp/gxadmin-meta-slurp-initial-$(date +%s)

	# Create temporary file
	echo "" > $tmpfile

	# Validate environment
	assert_set_env INFLUX_DB
	assert_set_env INFLUX_URL
	assert_set_env INFLUX_PASS
	assert_set_env INFLUX_USER

	# Loop for the data
	d=$begindate
	while [ "$d" != $enddate ]; do
		echo "Slurping for $d"
		# Slurp the data
		meta_slurp-upto $d $specific_slurp_string > $tmpfile
		meta_slurp-day $d $specific_slurp_string >> $tmpfile

		# Post to influxdb
		meta_influx-post $INFLUX_DB $tmpfile

		d=$(date -I -d "$d + 1 day")
	done

	rm $tmpfile
}

meta_error() {
	error "$@"
}

meta_warning() {
	warning "$@"
}

meta_success() {
	success "$@"
}


meta_influx-post() { ## <db> <file>: Post contents of file (in influx line protocol) to influx
	handle_help "$@" <<-EOF
		Post data to InfluxDB. Must be [influx line protocol formatted](https://docs.influxdata.com/influxdb/v1.7/write_protocols/line_protocol_tutorial/)

		Posting data from a file:

		    $ gxadmin meta influx-post galaxy file.inflx

		Posting data from the output of a command

		    $ gxadmin meta influx-post galaxy <(echo "weather,location=us-midwest temperature=\$RANDOM \$(date +%s%N)")

		Posting data from the output of a gxadmin command

		    $ gxadmin meta influx-post galaxy <(gxadmin meta slurp-current --date)

		**WARNING**

		!> If you are sending a LOT of data points, consider splitting
		!> them. Influx recommends 5-10k lines:
		!>
		!>     $ split --lines=5000 data.iflx PREFIX
		!>     $ for file in PREFIX*; do gxadmin meta influx-post galaxy $file; done
	EOF

	assert_set_env INFLUX_URL
	assert_set_env INFLUX_PASS
	assert_set_env INFLUX_USER

	assert_count_ge $# 2 "Must supply DB and then data file path"
	DB="$1"
	FILE="$2"

	# If the user is reading the output of a command then it'll be a transient
	# FD and might fail this check? Or it has for me. So if proc is in there,
	# don't bother asserting that it exists.
	if [[ "$FILE" != "/proc/"* ]]; then
		assert_file "$FILE"
	fi

	curl --silent -XPOST "${INFLUX_URL}/write?db=${DB}&u=${INFLUX_USER}&p=${INFLUX_PASS}" --data-binary @"${FILE}"
}

meta_influx-query() { ## <db> "<query>": Query an influx DB
	handle_help "$@" <<-EOF
		Query an InfluxDB

		Query percentage of memory used over last hour.

		    $ gxadmin meta influx-query galaxy "select mean(used_percent) from mem where host='X' AND time > now() - 1h group by time(10m)" | \\
		        jq '.results[0].series[0].values[] | @tsv' -r
		    2019-04-26T09:30:00Z    64.83119975586277
		    2019-04-26T09:40:00Z    64.58284600472675
		    2019-04-26T09:50:00Z    64.62714491344244
		    2019-04-26T10:00:00Z    64.62339148181154
		    2019-04-26T10:10:00Z    63.95268353798708
		    2019-04-26T10:20:00Z    64.66849537282599
		    2019-04-26T10:30:00Z    65.06069941790024
	EOF

	assert_set_env INFLUX_URL
	assert_set_env INFLUX_PASS
	assert_set_env INFLUX_USER

	assert_count_ge $# 2 "Must supply DB and then query"
	DB="$1"
	QUERY="$2"

	curl --silent "${INFLUX_URL}/query?db=${DB}&u=${INFLUX_USER}&p=${INFLUX_PASS}" --data-urlencode "q=${QUERY}"
}

meta_iquery-grt-export() { ## : Export data from a GRT database for sending to influx
	handle_help "$@" <<-EOF
		**WARNING**:

		!> GRT database specific query, will not work with a galaxy database!
	EOF

	fields="count=4"
	timestamp="3"
	tags="tool_id=0;tool_version=1;instance=2"

	read -r -d '' QUERY <<-EOF
		SELECT
			api_job.tool_id,
			api_job.tool_version,
			api_galaxyinstance.title,
			extract(epoch from date_trunc('week', api_job.create_time)) || '000000000' as date,
			count(*)
		FROM
			api_job, api_galaxyinstance
		WHERE
			api_job.instance_id = api_galaxyinstance.id
		GROUP BY
			api_job.tool_id,
			api_job.tool_version,
			api_galaxyinstance.title,
			date
	EOF
}

meta_whatsnew() { ## : What's new in this version of gxadmin
	handle_help "$@" <<-EOF
		Informs users of what's new in the changelog since their version
	EOF

	current_version=$(version)
	prev_version=$(( current_version - 1 ))
	#sed -n '1,/^# 12/d;/^# 11/q;p'
	echo "$CHANGELOG" | sed -n "/^# ${prev_version}/q;p"
}

meta_export-grafana-dashboards() { ## [grafana_db|/var/lib/grafana/grafana.db]: Export all dashboards from a Grafana database to CWD and commit them to git.
	handle_help "$@" <<-EOF
		Given a grafana database, use sqlite3 to access all of the dashboards within, and then write them out to the current working directly. Next, commit them and update a README.

		This script forms the basis of https://github.com/usegalaxy-eu/grafana-dashboards

		**WARNING**

		!> This script will silently remove all json files from CWD
		!> as a first step. Additionally it will commit and push at the end, so it
		!> should be run in a directory that has a git repo initialised, where you
		!> are not concerned about accidentally pushing to wrong remote.
	EOF

	db_path=${1:-/var/lib/grafana/grafana.db}

	rm -f *.json
	sqlite3 --csv -separator "$(printf '\t')" $db_path \
		'select title,data from dashboard;' | \
		awk -F'\t' '{gsub("\"", "", $1); print $2 > $1".json" }'

	for i in *.json; do
		q=$(mktemp)
		cat "$i" | sed 's/^"//;s/"$//g;s/""/"/g' | jq -S . > "$q"
		mv "$q" "$i";

		lines=$(wc -l "$i" | awk '{print $1}')
		if (( lines < 10 )); then
			rm "$i"
		fi
	done;


	cat > README.md <<-EOF
	# Grafana Dashbaords

	Name | Tags | Version | Live | JSON
	--- | --- | --- | --- | ---
	EOF

	sqlite3 --csv -separator "$(printf '\t')" $db_path \
		'SELECT title,uid,title,version,GROUP_CONCAT(dashboard_tag.term) FROM dashboard left outer join dashboard_tag on dashboard.id = dashboard_tag.dashboard_id WHERE dashboard.is_folder = 0 GROUP BY title, uid, title order by title asc' | \
		awk -F'\t' '{gsub("\"", "", $1); gsub("\"", "", $3); gsub(" ", "%20", $3); print $1" | "$5" | "$4" | [Live](https://stats.galaxyproject.eu/d/"$2") | [File](./"$3".json)"}' \
		>> README.md

	git add *.json README.md
	git commit -a -m "Automated commit for $(date)"
	git push --quiet
}


meta_gxadmin-as-a-service() { ## [port|8080] : A totally ridiculous hack. NOT SAFE :)
	handle_help "$@" <<-EOF
		Run gxadmin as a service, specifically the query portion of the API!

		    $ curl localhost:8080/ts-repos
		    [{"tool_shed":"toolshed.g2.bx.psu.edu","owner":"bgruening","count":1},{"tool_shed":"toolshed.g2.bx.psu.edu","owner":"iuc","count":2}]
		    $ curl localhost:8080/latest-users
		    [{"id":3,"create_time":"2019-03-07T13:06:37.945403+00:00","disk_usage":null,"username":"beverly","email":"b@example.com","groups":"","active":true},{"id":2,"create_time":"2019-03-07T13:06:23.369201+00:00","disk_usage":"826  bytes","username":"alice","email":"a@example.com","groups":"","active":true},{"id":1,"create_time":"2018-11-19T14:54:30.969713+00:00","disk_usage":"869  MB","username":"helena","email":"hxr@local.host","groups":"training-asdf  training-hogeschool","active":true}]
		    $ curl --silent http://localhost:8081/user-history-list/helena | jq '.[0]'
		    {
		        "ID": 74,
		        "Name": "Unnamed  history",
		        "Last  Updated": "2020-05-19T14:00:37.066429",
		        "Size": "961  kB"
		    }

		Multiple arguments can be separated by %20 or +

		I found https://github.com/izabera/ynaas which contained a very nice, simple bash webservice and so I learnt from that and turned gxadmin into a self-running webservice. jsonquery was already in gxadmin, so it was a short jump to this idea. This is for fun only!! Use at your own risk.

		If you're legitimately considering doing this (please, do not), then just use https://github.com/PostgREST/postgrest which is a much safer and more reliable solution.

		**WARNING**

		!> This is totally ridiculous and no one should ever do this. I thought
		!> it was fun, so, I added it. PLEASE DO NOT RUN IN PRODUCTION.
	EOF

	port=8080
	if (( $# == 1 )); then
		port="$1"
	fi

	ncat -e "$0 meta gaas" -kl $port
}

meta_gaas() {
	IFS=$' \t\n\r'

	while read -r header value; do
		[[ $header = GET ]] && request=GET && query=$value
		[[ $header = HEAD ]] && request=HEAD
		[[ $header ]] || break
	done

	warning "[$(date --rfc-3339=seconds)] $request $query"

	case $request in
		GET)
			# This is probably horribly unsafe. It could be cool to fix it...
			command="$(echo "$query" | grep -e '^[.A-Za-z/%+0-9-]*' -o | sed 's|^\/||g' | sed 's|%20| |g;s|+| |g')"
			echo "$command" | fgrep --quiet "/"
			ec=$?

			if (( ec > 0 )); then
				cmd="$(echo "$command" | sed 's|/.*||g')"
				args=""
			else
				cmd="$(echo "$command" | sed 's|/.*||g')"
				args="$(echo "$command" | sed 's|.*/||g')"
			fi
			warning "c $command c $cmd a $args"

			if [[ "$cmd" != "" ]]; then
				if [[ "$cmd" == "favicon.ico" ]]; then
					echo "HTTP/1.1 200 OK"
					echo "content-type: image/x-icon"
					echo
					#convert -size 64x64 canvas:khaki ico:-
					convert \( xc:red xc:blue +append \) \
						\( xc:yellow xc:cyan +append \) -append \
						-filter triangle -resize 32x32\! ico:-
					exit
				fi

				fn="query_${cmd}"
				LC_ALL=C type "$fn" 2> /dev/null | grep -q 'function'
				ec=$?

				if (( ec != 0 )); then
					printf "HTTP/1.1 404 Command Not Found\r\n\r\nCommand Not Found"
					exit
				fi
				warning "Running $0 jsonquery $cmd | $args"
				output="$(bash $0 jsonquery $cmd $args)"
				ec=$?
				warning "ec $ec"

				if (( ec > 0 )); then
					echo "HTTP/1.1 500 Internal Server Error"
					echo "content-type: text/html"
					echo
					echo "Error."
					exit
				else
					echo "HTTP/1.1 200 OK"
					echo "content-type: application/json; charset=utf-8"
					echo
					if [[ "$output" != "" ]]; then
						echo "$output"
					else
						echo "[]"
					fi
					exit
				fi
			else
				echo "HTTP/1.1 200 OK"
				echo "content-type: text/html; charset=utf-8"
				echo
				echo "<html><head></head><body style='font-family:monospace;white-space:pre;'>"
				usage query | sed 's/</\&lt;/g;s/>/\&gt;/g' | sed -r 's|query ([^ ]*)|<a href="\1">\1</a>|g' | perl -p -e 's/\n/<br>/'
				echo "</body></html>"
				exit
			fi
			;;
		HEAD)
			printf 'HTTP/1.1 200 OK\r\n\r\n'
			exit
			;;
		*)
			printf 'HTTP/1.1 404 Not Found\r\n\r\nOnly GET requests are supported. Try <a href="/latest-users">/latest-users</a>'
			exit
			;;
	esac
}
