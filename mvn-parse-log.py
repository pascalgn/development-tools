#!/usr/bin/env python3

import re
import sys
import json
import argparse

SEP = '------------------------------------------------------------------------'

LINE_LOG_LEVEL = re.compile('^\[(DEBUG|INFO|WARNING|ERROR)\] ?')
LINE_BUILDING_MODULE = re.compile('Building ([^ ]+) (.+)')
LINE_PLUGIN = re.compile('--- ([^ ]+) \(([^)]+)\) @ [^ ]+ ---')
LINE_TOTAL_TIME = re.compile('Total time: (.+)')

def parse(log_file):
    builds = []
    with open(log_file, 'r') as f:
        parse_file(f, builds)
    print(json.dumps(builds, indent=4, sort_keys=True))

def parse_file(f, builds):
    def readline():
        line = f.readline()
        return LINE_LOG_LEVEL.sub('', line, 1).rstrip() if line else None
    s = 'start'
    while True:
        line = readline()
        if line == None:
            break
        if s == 'start':
            if line == 'Scanning for projects...':
                build = { 'modules': [] }
                builds.append(build)
                s = 'build_started'
        elif s == 'build_started':
            if line == 'BUILD SUCCESS' or line == 'BUILD FAILURE':
                build['status'] = 'success'
                readline()
                line = readline()
                m = LINE_TOTAL_TIME.match(line)
                build['total_time'] = m.group(1)
                s = 'start'
            m = LINE_PLUGIN.match(line)
            if m:
                plugin = { 'plugin': m.group(1), 'execution': m.group(2) }
                module['plugins'].append(plugin)
            else:
                m = LINE_BUILDING_MODULE.match(line)
                if m:
                    module = { 'id': m.group(1), 'version': m.group(2), 'plugins': [] }
                    build['modules'].append(module)

def main():
    parser = argparse.ArgumentParser(prog='mvn-parse-log')
    parser.add_argument('log_file', metavar='<file>', nargs='?',
            help='the log file to parse (defaults to stdin)', default='-')
    args = parser.parse_args()
    try:
        parse(args.log_file)
    except Exception as e:
        print('error while parsing: %s' % e, file=sys.stderr)
        raise e
        #sys.exit(1)

if __name__ == '__main__':
    main()
