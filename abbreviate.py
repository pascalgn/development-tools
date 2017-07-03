#!/usr/bin/env python3

import os
import sys
import signal
import shutil
import argparse
import subprocess

# prevent broken pipe errors:
signal.signal(signal.SIGPIPE, signal.SIG_DFL) 

DEFAULT_WIDTH = 80

def do_filter(dots, width):
    if width < 0:
        width = 0
    if width == 0:
        try:
            width, height = shutil.get_terminal_size()
        except Exception:
            pass
    if width == 0:
        columns = os.environ.get('COLUMNS')
        if columns:
            try:
                width = int(columns)
            except ValueError:
                pass
    if width == 0:
        width = DEFAULT_WIDTH
        try:
            arr = subprocess.check_output(['stty', 'size'], stderr=subprocess.STDOUT).split()
            print(arr)
            if len(arr) == 2:
                width = int(arr[1])
                if width < 1:
                    width = DEFAULT_WIDTH
        except subprocess.CalledProcessError:
            pass
        except OSError:
            pass
    for line in sys.stdin:
        if len(line) > width:
            if dots:
                sys.stdout.write(line[0:width-3])
                sys.stdout.write('...')
            else:
                sys.stdout.write(line[0:width])
            sys.stdout.write('\n')
        else:
            sys.stdout.write(line)

def main():
    parser = argparse.ArgumentParser(prog='abbreviate',
            description='cut off lines longer than the terminal window')
    parser.add_argument('-d', '--dots', action='store_true',
            help='output three dots at the end of each abbreviated line')
    parser.add_argument('-w', '--width', metavar='<width>', default=0,
            type=int, help='the maximum line width')
    args = parser.parse_args()
    try:
        do_filter(args.dots, args.width)
    except BrokenPipeError:
        pass

if __name__ == '__main__':
    main()
