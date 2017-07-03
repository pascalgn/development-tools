#!/usr/bin/env python3

import re
import sys
import json
import signal
import argparse
import datetime

# prevent broken pipe errors:
signal.signal(signal.SIGPIPE, signal.SIG_DFL) 

SEP = '------------------------------------------------------------------------'

TIME_PREFIX = re.compile('^([0-9]+|[0-9]{2}:[0-9]{2}:[0-9]{2}) ')
LINE_LOG_LEVEL = re.compile('^\[(DEBUG|INFO|WARNING|ERROR)\] ?')
LINE_BUILDING_MODULE = re.compile('Building ([a-zA-Z0-9-]+) (.+)')
LINE_PLUGIN = re.compile('--- ([^ ]+) \(([^)]+)\) @ [^ ]+ ---')
LINE_TOTAL_TIME = re.compile('Total time: (.+)')

COLOR_RE = re.compile('\{:color:([a-z]+)\}')
COLORS = { 'red': '\033[31m', 'green': '\033[32m', 'yellow': '\033[33m', 'blue': '\033[34m', 'cyan': '\033[36m', 'gray': '\033[37m', 'default': '\033[0m' }

def parse(log_file, plugin_filter, verbose, output_json):
    builds = []
    with open(log_file, 'r') as f:
        parse_file(f, builds, verbose)
    if plugin_filter != '.*':
        p_re = re.compile(plugin_filter)
        for build in builds:
            for module in build['modules']:
                module['plugins'][:] = [p for p in module['plugins'] if p_re.search(p['plugin'])]
    if output_json:
        print(json.dumps(builds, indent=4, sort_keys=True))
    else:
        tab = '    '
        build_id = 0
        for build in builds:
            build_id += 1
            printc('{:color:green}Build %d{:color:default} (status: %s, started: %s) {:color:yellow}[%s]{:color:default}'
                    % (build_id, build['status'], build['started'], build['time']))
            for module in build['modules']:
                printc('%s{:color:blue}%s{:color:default} (%s) {:color:yellow}[%s]{:color:default}'
                        % (tab, module['id'], module['version'], module['time']))
                for plugin in module['plugins']:
                    printc('%s{:color:cyan}%s{:color:default} (%s) {:color:yellow}[%s]{:color:default}'
                            % (tab * 2, plugin['plugin'], plugin['execution'], plugin['time']))
                    if verbose:
                        for line in plugin['lines']:
                            print('%s%s' % (tab * 3, line))

def parse_file(f, builds, verbose):
    def readline():
        line = f.readline()
        if line:
            m = TIME_PREFIX.match(line)
            if m:
                time = m.group(1)
                line = line[m.end():]
            else:
                time = None
            line = LINE_LOG_LEVEL.sub('', line, 1).rstrip()
            return (time, line)
        else:
            return (None, None)
    s = 'start'
    build = None
    module = None
    plugin = None
    while True:
        time, line = readline()
        if line == None:
            break
        if s == 'start':
            if line == 'Scanning for projects...':
                build = { 'modules': [], 'started': time }
                module = None
                plugin = None
                builds.append(build)
                s = 'build_started'
        elif s == 'build_started':
            if line == 'BUILD SUCCESS' or line == 'BUILD FAILURE':
                build['status'] = 'success'
                readline()
                time, line = readline()
                if line:
                    m = LINE_TOTAL_TIME.match(line)
                    build['time'] = m.group(1)
                    s = 'start'
            m = LINE_PLUGIN.match(line)
            if m:
                if plugin and plugin['started']:
                    plugin['time'] = delta_str(plugin['started'], time)
                plugin = { 'plugin': m.group(1), 'execution': m.group(2),
                        'started': time, 'time': '' }
                if verbose:
                    plugin['lines'] = []
                module['plugins'].append(plugin)
            else:
                m = LINE_BUILDING_MODULE.match(line)
                if m:
                    if module and module['started']:
                        module['time'] = delta_str(module['started'], time)
                    module = { 'id': m.group(1), 'version': m.group(2),
                            'plugins': [], 'started': time, 'time': '' }
                    build['modules'].append(module)
                else:
                    if verbose and plugin and line:
                        plugin['lines'].append(line)

def delta_str(start, end):
    dt_start = to_datetime(start)
    dt_end = to_datetime(end)
    return '%s s' % (dt_end - dt_start).total_seconds()

def to_datetime(s):
    if ':' in s:
        return datetime.datetime.strptime(s, '%H:%M:%S')
    else:
        return datetime.datetime.fromtimestamp(s)

def printc(msg, colors=True):
    def replace_color(m):
        if colors:
            return COLORS[m.group(1)]
        else:
            return ''
    print(COLOR_RE.sub(replace_color, msg))

def main():
    parser = argparse.ArgumentParser(prog='mvn-parse-log')
    parser.add_argument('log_file', metavar='<file>', nargs='?',
            help='the log file to parse (defaults to stdin)', default='-')
    parser.add_argument('-j', '--json', action='store_true', help='output json data')
    parser.add_argument('-p', '--plugins', metavar='<filter>', default='.*',
            help='only display plugins matching the given regular expression')
    parser.add_argument('-v', '--verbose', action='store_true', help='show full log output')
    args = parser.parse_args()
    try:
        parse(args.log_file, args.plugins, args.verbose, args.json)
    except Exception as e:
        print('error while parsing: %s' % e, file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()
