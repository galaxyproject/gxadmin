cgi_response() {
	status="$1"; shift;
	format="$1"; shift;
	content="$1"; shift;

	echo "Content-Type: $format"
	echo "Status: $status"
	echo "X-Clacks-Overhead: GNU Simon Gladman (@slugger70)"
	echo
	echo "$content"
	exit 0
}

cgi_error_internal() {
	cgi_response "500 Internal Server Error" "text/plain" ""
}

cgi_bad_request() {
	cgi_response "400 Bad Request" "text/plain" "$1"
}

cgi_redirect() {
	echo "Status: 302 Moved Temporarily"
	echo "X-Clacks-Overhead: GNU Simon Gladman (@slugger70)"
	echo "Content-Type: text/plain"
	echo "Location: $1"
	echo
	echo "Redirect to $1"
	exit 0
}

cgi_ok() {
	content_source="$1"; shift;
	if [[ -n "$1" ]]; then
		format="$1"; shift;
	else
		format="text/plain";
	fi
	
	if [[ "$content_source" == "-" ]]; then
		cgi_response "200 OK" "$format" "$(cat -)"
	else
		cgi_response "200 OK" "$format" "OK"
	fi
}

cgi_parse_query_params(){
	echo
}

cgi_gxadmin_query() {
	submethod=$(echo "$DOCUMENT_URI" | sed 's|/gxadmin/query||;s|^/||g;')
	if [[ -z "$submethod" ]]; then
		cgi_ok - "text/html" <<-HELP
		<html>
			<head><title>gxadmin</title></head>
			<body>
			<h1>gxadmin</h1>
			<h2>Supported Functions</h2>
			<table>
			$($0 query | grep '^   ' | sed 's/^\s*//g' | sed -r 's/\s{3,}/\t/g' | sed 's/</\&lt;/g;s/>/\&gt;/g' | \
				awk -F'\t' '{split($1,a,/ /); print "<tr><td><a href=\"'$PREFIX/gxadmin/query/'"a[2]"\">"$1"</a></td><td>"$2"</td></tr>"}' )
			</table>
			</body>
		</html>
		HELP

		cgi_bad_request "No subcommand specified"
	fi

	format="text/plain"
	query="query"
	if [[ "$QUERY_STRING" == "format=json" ]]; then
		query="jsonquery"
		format="application/json"
	elif [[ "$QUERY_STRING" == "format=csv" ]]; then
		query="csvquery"
		format="text/csv"
	elif [[ "$QUERY_STRING" == "format=tsv" ]]; then
		query="tsvquery"
		format="text/tsv"
	fi

	q="$QUERY_STRING"
	i=0
	while [[ ! -z "$q" ]]; do
		p="${q//&*}"  # get first part of query string
		k="${p//=*}"  # get the key (variable name) from it
		v="${p#*=}"   # get the value from it
		q="${q#$p&*}" # strip first part from query string
		nk=QUERY_$(echo "$k" | tr '[:lower:]' '[:upper:]')

		# If we're overwriting a previously set var, then break, we're
		# done.
		if [[ -n "${!nk}" ]]; then break; fi;

		export ${nk}="${v}"

		# Safety!
		i=$((i + 1))
		if (( i > 4 )); then break; fi;
	done
	unset QUERY_STRING

	export TERM=vt100 # Prevents colours
	# TODO(hexylena) put the arguments in the right order here, and with right --flag= if needed.
	out=$($0 $query $submethod 2>&1)
	ec=$?
	if (( ec > 0 )); then
		cgi_bad_request "$out"
	else
		cgi_ok - "$format" "$out"
	fi
}


# CGI Mode Activate!
if [[ -n "$REQUEST_METHOD" ]] && (( $# == 0 )) ; then
	method=$(echo "$DOCUMENT_URI" | sed 's|/gxadmin||')
	export PGHOST=localhost
	export PGUSER=postgres
	export PGPASSWORD=postgres
	PREFIX=$(echo "$REQUEST_URI" | sed 's|/gxadmin.*||g');

	# Then we're CGI
	if [[ -z "$method" ]]; then
		cgi_ok - "text/html" <<-HELP
		<html>
			<head><title>gxadmin</title></head>
			<body>
			<h1>gxadmin</h1>
			<h2>Supported Functions</h2>
			<ul>
				<li><a href="$PREFIX/gxadmin/query">query</a></li>
			</ul>
			</body>
		</html>
		HELP
	fi

	if [[ "$method" == "/debug" ]]; then
		cgi_ok - "text/plain" <<< $(env | sort | egrep '(REQUEST_|SERVER_|SCRIPT_|CONTENT_|DOCUMENT_|REMOTE_|QUERY_)')
	elif [[ "$method" == "/query"* ]]; then
		cgi_gxadmin_query
	else
		cgi_redirect "/cgi/gxadmin"
	fi

	exit 0
fi
