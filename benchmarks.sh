f=benchmarks/benchmarks.py

# If sqlfmt fails: https://github.com/mjibson/sqlfmt/releases/tag/v0.4.0

echo "import subprocess"
echo
echo
echo "class GxadminSuite:"

for cmd in $(./gxadmin meta cmdlist2 | grep ^query | sed 's/^query //' | grep -v '^q$' | grep -v '^aq$'); do
	safe=$(echo "$cmd" | sed 's/[^a-z0-9_]/_/g')
	echo "    def time_query_${safe}(self):"
	echo "        query = \"\"\""
	./gxadmin echoquery $cmd | sqlfmt | sed 's/^/            /'
	echo "        \"\"\""
	echo "        query = subprocess.check_output(["
	echo "            '${PWD}/gxadmin',"
	echo "            'query',"
	echo "            '$cmd',"
	echo "        ])"
done
