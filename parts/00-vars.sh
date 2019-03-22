GXADMIN_SITE_SPECIFIC=${GXADMIN_SITE_SPECIFIC:-~/.config/gxadmin-local.sh}

hexdecodelines=$(cat <<EOF
import sys
import re
import binascii
query = re.compile(r'^(.*)\\\\x([0-9a-f]+)(.*)$')
for line in sys.stdin:
	out = '%s' % line.replace('\\\\\\\\', '\\\\')
	while True:
		m = query.match(out)
		if m:
			out = m.groups()[0]
			out += binascii.unhexlify(m.groups()[1])
			out += m.groups()[2] + '\\n'
		else:
			break
	sys.stdout.write(out)
EOF
)
