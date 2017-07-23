#!/usr/bin/env python3

import os
import sys
import argparse
import subprocess

def upload(url, repository, filter, dry=False):
    if not url.endswith('/'):
        url += '/'
    root = os.path.abspath(os.path.expanduser(repository))
    filtered = root + os.sep + filter
    if not os.path.isdir(filtered):
        raise Exception('not a directory: %s' % filtered)
    for (dirpath, dirnames, filenames) in os.walk(filtered):
        for filename in filenames:
            if (filename == '_remote.repositories' or filename.endswith('.lastUpdated')
                    or filename.startswith('maven-metadata-')
                    or filename == 'resolver-status.properties'):
                continue
            full_path = dirpath + os.sep + filename
            if not full_path.startswith(root):
                raise Exception('does not start with %s: %s' % (root, full_path))
            path = full_path[len(root)+1:]
            if dry:
                print(path)
            else:
                do_upload(full_path, url + path)

def do_upload(path, url):
    exit_code = subprocess.call(['curl', '--fail', '--upload-file', path, url])
    if exit_code == 0:
        print('Uploaded: %s' % url)

def main():
    parser = argparse.ArgumentParser(prog='mvn-upload-repository')
    parser.add_argument('url', metavar='<url>', help='remote URL')
    parser.add_argument('filter', metavar='<filter>',
            help=('the filter to control which artifacts to upload, '
            'for example com/group/id/artifact-id or com/example'))
    parser.add_argument('-r', '--repository', metavar='<repository>',
            default='~/.m2/repository', help='the local repository')
    parser.add_argument('-n', '--dry', action='store_true', help='dry run')
    args = parser.parse_args()
    upload(args.url, args.repository, args.filter, dry=args.dry)

if __name__ == '__main__':
    main()
