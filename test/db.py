#!/usr/bin/env python
import difflib
import subprocess

def enumerateCommands():
    cmds = subprocess.check_output(['./gxadmin', 'meta', 'cmdlist2']).decode().strip().split('\n')
    for c in cmds:
        yield c.split(' ')


def identifyTestCases(helptext):
    inCase = False
    current = []
    cases = []
    helptext = helptext.decode()
    for line in helptext.split('\n'):
        if line.startswith('    $ gxadmin'):
            if current:
                cases.append({
                    'cmd': current[0].lstrip().lstrip('$').lstrip(),
                    'out': '\n'.join([x[4:] for x in current[1:]])
                })
            current = []
            inCase = True

        if line.startswith('    '):
            if inCase:
                current.append(line)
            else:
                inCase = False

    if current:
        cases.append({
            'cmd': current[0].lstrip().lstrip('$').lstrip(),
            'out': '\n'.join([x[4:] for x in current[1:]])
        })

    return cases


def filterCases(cases):
    for c in cases:
        if c['cmd'].startswith('gxadmin'):
            yield c


def r(s):
    return [x.rstrip() for x in s.split('\n')]


def runCases(cases):
    for c in cases:
        print(f'\033[1mRunning: {c["cmd"]}\033[0m')
        o = subprocess.check_output(('./' + c['cmd']).split(' ')).decode().rstrip()
        # print('===' * 10)
        # print(o)
        # print('===' * 10)
        # print(c['out'])
        # print('===' * 10)
        w = difflib.SequenceMatcher(a=o, b=c['out'])
        if w.ratio() > 0.95:
            print("PASS")
            yield 0
        else:
            print("FAIL")
            yield 1

        # for x in difflib.unified_diff(r(o), r(c['out'])):
            # print(x)


results = []
for cmd in enumerateCommands():
    c = ['./gxadmin', *cmd, '--help']
    if cmd[0] == 'query':
        output = subprocess.check_output(c)
        cases = identifyTestCases(output)
        cases = filterCases(cases)
        results += runCases(cases)

print(f'Passing: {len(results) - sum(results)} / {len(results)}')
