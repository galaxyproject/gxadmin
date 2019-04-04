query_tbl() {
	psql <<-EOF
	$1
	EOF
}

query_tsv() {
	psql <<-EOF
	COPY ($1) to STDOUT with CSV DELIMITER E'\t'
	EOF
}

query_csv() {
	psql <<-EOF
	COPY ($1) to STDOUT with CSV DELIMITER ','
	EOF
}

query_influx() {
	arr2py=$(cat <<EOF
import sys
query_name = sys.argv[1]
fields = {x.split('=')[0]: int(x.split('=')[1]) for x in sys.argv[2].split(';')}
tags = []
if len(sys.argv) > 3 and len(sys.argv[3]) > 0:
	tags = {x.split('=')[0]: int(x.split('=')[1]) for x in sys.argv[3].split(';')}
for line in sys.stdin.read().split('\n'):
	if len(line) == 0:
		continue
	parsed = line.split(',')
	metric = query_name
	if len(tags):
		tag_data = ['%s="%s"' % (k, parsed[v])  for (k, v) in tags.items()]
		metric += ',' + ','.join(tag_data)
	field_data = ['%s=%s' % (k, parsed[v])  for (k, v) in fields.items()]
	metric += ' ' + ','.join(field_data)
	print(metric)
EOF
)

	psql -c "COPY ($1) to STDOUT with CSV DELIMITER E','"| python -c "$arr2py" "$2" "$3" "$4"
}

gdpr_safe() {
	if [ -z "$GDPR_MODE"  ]; then
		echo "$1"
	else
		# Try and be privacy respecting while generating numbers that can allow
		# linking data across tables if need be?
		echo "substring(md5($1 || now()::date), 0, 12) as ${2:-$1}"
	fi
}
