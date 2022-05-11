#!/usr/bin/env python
import glob
import yaml
import re


def parse(lines):
    lines = lines[1:] # Strip off first meta.
    sql = [line.rstrip() for line in lines if not line.startswith('---')]

    meta = yaml.safe_load(''.join([line.lstrip('-').lstrip() for line in lines[0:lines.index('--- ---\n')]]))

    helptext = [
        line.lstrip('-')[1:].rstrip()
        for line in lines[lines.index('--- ---\n') + 1:]
        if line.startswith('---')
    ]

    # If username and email are in there, we have some special lines to add to our query.

    return [meta, helptext, sql]


def indent(lines, count=1):
    yield from [
        ('\t' * count) + line
        for line in lines
    ]

def convert(lines, filename):
    meta, helptext, sql = parse(lines)

    output = ['handle_help "$@" <<-EOF']
    output.extend(list(indent(helptext)))
    output.append('EOF')
    output.append('')

    # Not sure this will work in group by/etc.
    if '$username' in ''.join(sql):
        output.append('username=$(gdpr_safe galaxy_user.username username)')
    if '$email' in ''.join(sql):
        output.append('email=$(gdpr_safe galaxy_user.email email)')
    output.append('')

    output.append("read -r -d '' QUERY <<-EOF")
    output.extend(indent(sql))
    output.append('EOF')
    # __import__('pprint').pprint(output)
    wrapper = [
        filename + '() { ##? : ' + meta['description']
    ] + list(indent(output)) + ['}']
    return '\n'.join(wrapper)


with open('parts/22-query-AUTO.sh', 'w') as query:
    for fn in glob.glob("sql/query*.sql"):
        with open(fn, 'r') as handle:
            result = convert(handle.readlines(), fn.split('/')[1][:-4])
            print(result)
            query.write(result)
