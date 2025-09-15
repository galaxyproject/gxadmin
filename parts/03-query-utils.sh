query_tbl() {
	psql <<-EOF
	$1
	EOF
}

query_tbl_sqlite() {
	echo "$1" | sed "s/AT TIME ZONE 'UTC'//g;s/::text//g" | sqlite3 database/universe.sqlite
}

query_tbl_wrapper() {
	if (( GXADMIN_EXPERIMENT_SQLITE3 == 1 )); then
		query_tbl_sqlite "$1"
	else
		query_tbl "$1"
	fi
}

query_tsv() {
	psql <<-EOF
	COPY ($1) to STDOUT with CSV DELIMITER E'\t'
	EOF
}

query_json() {
	psql <<-EOF
	COPY (
		SELECT array_to_json(array_agg(row_to_json(t)))
		FROM ($1) t
	) to STDOUT with (FORMAT CSV, QUOTE ' ')
	EOF
}

query_tsv_json() {
	psql <<-EOF
	COPY ($1) to STDOUT with (FORMAT CSV, QUOTE ' ')
	EOF
}

query_csv() {
	psql <<-EOF
	COPY ($1) to STDOUT with CSV DELIMITER ','
	EOF
}

query_exp() {
	psql <<-EOF
	EXPLAIN ANALYZE VERBOSE $1
	EOF
}

query_expj() {
	echo "$1"
	echo
	psql -qAt <<-EOF
	EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS, FORMAT JSON) $1
	EOF
}

query_exp_pub() {
	date=$(date --rfc-3339=seconds)
	sql_query="$1"
	explain_json=$(
		psql -qAt <<-EOF
			EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS, FORMAT JSON) $sql_query
		EOF
	)

	if [[ "$explain_json" == "" ]]; then
		exit 1;
	fi

	data=$(jq -n \
		--arg PLAN "$explain_json" \
		--arg TITLE "$USER's gxadmin plan $date" \
		--arg QUERY "$sql_query" \
		'{"title": $ARGS.named.TITLE, "query": $ARGS.named.QUERY, "plan": $ARGS.named.PLAN}')

	echo "⚠️ WARNING ⚠️ "
	echo "We will be sending the data to a PUBLIC service that we do not control!"
	echo "Are you sure you want to do this? And no user IDs or emails are present in the query?"
	echo "[N/y]"
	read -r answer
	if [[ "$answer" != "y" ]]; then
		echo "Aborting"
		exit 1;
	fi
	
	resp=$(curl --silent 'https://explain.dalibo.com/new.json' \
		-X POST \
		-H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:123.0) Gecko/20100101 Firefox/123.0' \
		-H 'Accept: application/json, text/plain, */*' \
		-H 'Accept-Language: en-US,en;q=0.5' -H 'Accept-Encoding: gzip, deflate, br' \
		-H 'Content-Type: application/json;charset=utf-8' \
		-H 'Origin: https://explain.dalibo.com' \
		-H 'DNT: 1' -H 'Connection: keep-alive' \
		-H 'Referer: https://explain.dalibo.com/' \
		-H 'Sec-Fetch-Dest: empty' \
		-H 'Sec-Fetch-Mode: cors' \
		-H 'Sec-Fetch-Site: same-origin' \
		-H 'Pragma: no-cache' \
		-H 'Cache-Control: no-cache' \
		-H 'Accept: application/json' \
		--data-raw "$data")

	echo "Here is the delete key, I haven't found the URL to make it work yet: "
	echo "$resp" | jq .deleteKey
	echo "Here is your nice-to-view plan:"
	echo "$resp" | jq '"https://explain.dalibo.com/plan/" + .id' -r
}

query_echo() {
	echo "$1"
}

query_influx() {
	local query="$1"
	local rename="$2"
	local fields="$3"
	local tags="$4"
	local timestamp="$5"

	if [[ -z "$fields" ]]; then
		exit 0;
	fi

	arr2py=$(cat <<EOF
import sys
query_name = sys.argv[1]
fields = {x.split('=')[0]: int(x.split('=')[1]) for x in sys.argv[2].split(';')}
tags = []
if len(sys.argv) > 3 and len(sys.argv[3]) > 0:
	tags = {x.split('=')[0]: int(x.split('=')[1]) for x in sys.argv[3].split(';')}

timestamp = None
if len(sys.argv) > 4 and sys.argv[4] != '':
	timestamp = int(sys.argv[4])

for line in sys.stdin.read().split('\n'):
	if len(line) == 0:
		continue
	parsed = line.split('\t')
	metric = query_name
	if len(tags):
		tag_data = ['%s=%s' % (k, parsed[v].replace(' ', '\\ ').replace(',', '\\,').replace('=', '\\='))  for (k, v) in tags.items()]
		metric += ',' + ','.join(tag_data)
	field_data = ['%s=%s' % (k, parsed[v])  for (k, v) in fields.items()]
	metric += ' ' + ','.join(field_data)

	if timestamp is not None:
		metric += ' ' + str(parsed[timestamp])
	print(metric)
EOF
)

	psql -c "COPY ($query) to STDOUT with CSV DELIMITER E'\t'"| $GXADMIN_PYTHON -c "$arr2py" "$rename" "$fields" "$tags" "$timestamp"
}

gdpr_safe() {
	local coalesce_to
	if (( $# > 2 )); then
		coalesce_to="$3"
	else
		coalesce_to="__UNKNOWN__"
	fi

	if [[ -z "$GDPR_MODE" ]]; then
		echo "COALESCE($1::text, '$coalesce_to') as $2"
	else
		# Try and be privacy respecting while generating numbers that can allow
		# linking data across tables if need be?
		echo "substring(md5(COALESCE($1::text, '$coalesce_to') || now()::date || '$GDPR_MODE'), 0, 12) as ${2:-$1}"
	fi
}

# Borrowed from https://stackoverflow.com/questions/1527049/how-can-i-join-elements-of-an-array-in-bash
function join_by {
	local d=$1; shift;
	echo -n "$1";
	shift;
	printf "%s" "${@/#/$d}";
}

summary_statistics() {
	local v=$1
	local ishuman=$2

	# TODO: there has got to be a less ugly way to do this
	if (( ishuman == 1 )); then
		human_size="pg_size_pretty("
		human_after=")"
	else
		human_size=""
		human_after=""
	fi

	cat <<-EOF
		${human_size}min($v)${human_after} AS min,
		${human_size}percentile_cont(0.25) WITHIN GROUP (ORDER BY $v) ::bigint${human_after} AS quant_1st,
		${human_size}percentile_cont(0.50) WITHIN GROUP (ORDER BY $v) ::bigint${human_after} AS median,
		${human_size}avg($v)${human_after} AS mean,
		${human_size}percentile_cont(0.75) WITHIN GROUP (ORDER BY $v) ::bigint${human_after} AS quant_3rd,
		${human_size}percentile_cont(0.95) WITHIN GROUP (ORDER BY $v) ::bigint${human_after} AS perc_95,
		${human_size}percentile_cont(0.99) WITHIN GROUP (ORDER BY $v) ::bigint${human_after} AS perc_99,
		${human_size}max($v)${human_after} AS max,
		${human_size}sum($v)${human_after} AS sum,
		${human_size}stddev($v)${human_after} AS stddev
	EOF
}

get_user_filter() {
	echo "(galaxy_user.email = '$1' or galaxy_user.username = '$1' or galaxy_user.id = CAST(REGEXP_REPLACE('$1', '.*\D+.*', '-1') AS INTEGER))"
}

function create_sql_parameters_select() {
	local strSelect = ""

	if [[ -n $arg_arrSelect1 ]]; then
		if [[ $(echo "$arg_arrSelect1" | cut -d';' -f1) == "when" ]]; then
			strSelect+=" WHEN" $(echo "$arg_arrSelect1" | cut -d';' -f2) "THEN" $(echo "$arg_arrSelect1" | cut -d';' -f3)
		else
			strSelect+="ELSE" $(echo "$arg_arrSelect1" | cut -d';' -f3)
		fi
		if [[ $(echo "$arg_arrSelect2" | cut -d';' -f1) == "when" ]]; then
			strSelect+=" WHEN" $(echo "$arg_arrSelect2" | cut -d';' -f2) "THEN" $(echo "$arg_arrSelect2" | cut -d';' -f3)
		else
			strSelect+=" ELSE" $(echo "$arg_arrSelect2" | cut -d';' -f3)
		fi
		if [[ $(echo "$arg_arrSelect3" | cut -d';' -f1) == "when" ]]; then
			strSelect+=" WHEN" $(echo "$arg_arrSelect3" | cut -d';' -f2) "THEN" $(echo "$arg_arrSelect3" | cut -d';' -f3)
		else
			strSelect+=" ELSE" $(echo "$arg_arrSelect3" | cut -d';' -f3)
		fi
		if [[ $(echo "$arg_arrSelect4" | cut -d';' -f1) == "when" ]]; then
			strSelect+=" WHEN" $(echo "$arg_arrSelect4" | cut -d';' -f2) "THEN" $(echo "$arg_arrSelect4" | cut -d';' -f3)
		else
			strSelect+=" ELSE" $(echo "$arg_arrSelect4" | cut -d';' -f3)
		fi
		if [[ $(echo "$arg_arrSelect5" | cut -d';' -f1) == "when" ]]; then
			strSelect+=" WHEN" $(echo "$arg_arrSelect5" | cut -d';' -f2) "THEN" $(echo "$arg_arrSelect5" | cut -d';' -f3)
		else
			strSelect+=" ELSE" $(echo "$arg_arrSelect5" | cut -d';' -f3)
		fi

		strSelect="CASE" $strSelect "END"
	fi

    return $strSelect;
}

function create_sql_parameters_where() {
	local strWhere = ""

	if [[ -n $arg_arrWhere1 ]]; then
		if [[ $(echo "$arg_arrWhere1" | cut -d';' -f1) == "when" ]]; then
			strWhere+=" WHEN" $(echo "$arg_arrWhere1" | cut -d';' -f2) "THEN" $(echo "$arg_arrWhere1" | cut -d';' -f3)
		else
			strWhere+="ELSE" $(echo "$arg_arrWhere1" | cut -d';' -f3)
		fi
		if [[ $(echo "$arg_arrWhere2" | cut -d';' -f1) == "when" ]]; then
			strWhere+=" WHEN" $(echo "$arg_arrWhere2" | cut -d';' -f2) "THEN" $(echo "$arg_arrWhere2" | cut -d';' -f3)
		else
			strWhere+=" ELSE" $(echo "$arg_arrWhere2" | cut -d';' -f3)
		fi
		if [[ $(echo "$arg_arrWhere3" | cut -d';' -f1) == "when" ]]; then
			strWhere+=" WHEN" $(echo "$arg_arrWhere3" | cut -d';' -f2) "THEN" $(echo "$arg_arrWhere3" | cut -d';' -f3)
		else
			strWhere+=" ELSE" $(echo "$arg_arrWhere3" | cut -d';' -f3)
		fi
		if [[ $(echo "$arg_arrWhere4" | cut -d';' -f1) == "when" ]]; then
			strWhere+=" WHEN" $(echo "$arg_arrWhere4" | cut -d';' -f2) "THEN" $(echo "$arg_arrWhere4" | cut -d';' -f3)
		else
			strWhere+=" ELSE" $(echo "$arg_arrWhere4" | cut -d';' -f3)
		fi
		if [[ $(echo "$arg_arrWhere5" | cut -d';' -f1) == "when" ]]; then
			strWhere+=" WHEN" $(echo "$arg_arrWhere5" | cut -d';' -f2) "THEN" $(echo "$arg_arrWhere5" | cut -d';' -f3)
		else
			strWhere+=" ELSE" $(echo "$arg_arrWhere5" | cut -d';' -f3)
		fi

		strWhere="CASE" $strWhere "END"
	fi
	
    return $strWhere;
}
