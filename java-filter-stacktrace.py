#!/usr/bin/env python3

import re
import sys
import argparse

LINE_EXCEPTION = re.compile('^([a-zA-Z0-9_.]+Exception:?)(.*)$')
LINE_STACK_ELEMENT = re.compile('^(        at )([a-z0-9_.]+)([A-Z][a-zA-Z0-9_.]*)(.*)$')
LINE_CAUSE = re.compile('^([cC]aused by: [a-zA-Z0-9_.]+:?)(.*)$')

COLOR_RE = re.compile('\{:color:([a-z]+)\}')
COLORS = { 'red': '\033[31m', 'green': '\033[32m', 'yellow': '\033[33m', 'blue': '\033[34m', 'cyan': '\033[36m', 'gray': '\033[37m', 'default': '\033[0m' }

def do_filter(input_file, packages):
    if input_file == '-':
        do_filter_input(sys.stdin, packages)
    else:
        with open(input_file, 'r') as f:
            do_filter_input(f, packages)

def do_filter_input(f, packages, colors=True):
    filtered = 0
    def print_filtered():
        nonlocal filtered
        if filtered == 1:
            printc('        {:color:default}(1 line filtered){:color:default}' % filtered)
        elif filtered > 1:
            printc('        {:color:default}(%d lines filtered){:color:default}' % filtered)
        filtered = 0
    while True:
        line = f.readline()
        if not line:
            break
        line = line.rstrip()
        m = LINE_STACK_ELEMENT.search(line)
        if m:
            found = False
            for pkg in packages:
                if m.group(2).startswith(pkg):
                    found = True
                    break
            if found:
                print_filtered()
                printc('%s{:color:cyan}%s{:color:blue}%s{:color:default}%s' % (m.group(1), m.group(2), m.group(3), m.group(4)))
            else:
                filtered += 1
        else:
            print_filtered()
            m = LINE_CAUSE.match(line)
            if not m:
                m = LINE_EXCEPTION.match(line)
            if m:
                printc('{:color:red}%s{:color:default}%s' % (m.group(1), m.group(2)))
            else:
                print(line)
    print_filtered()

def printc(msg, colors=True):
    def replace_color(m):
        if colors:
            return COLORS[m.group(1)]
        else:
            return ''
    print(COLOR_RE.sub(replace_color, msg))

def main():
    parser = argparse.ArgumentParser(prog='java-filter-stacktrace')
    parser.add_argument('input_file', metavar='<file>', nargs='?',
            help='the file to filter (defaults to stdin)', default='-')
    parser.add_argument('packages', metavar='<package>', nargs='+',
            help='packages to filter')
    args = parser.parse_args()
    do_filter(args.input_file, args.packages)

if __name__ == '__main__':
    main()
