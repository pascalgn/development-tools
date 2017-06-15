#!/usr/bin/env python3

import sys
import argparse
import xml.etree.ElementTree

MAVEN_NS = { 'maven': 'http://maven.apache.org/POM/4.0.0' }

def parse(pom_file, format):
    root = xml.etree.ElementTree.parse(pom_file).getroot()
    def text(name, search_parent=True, default=None):
        elements = root.findall('maven:%s' % name, MAVEN_NS)
        if not elements:
            elements = root.findall(name)
        if not elements and search_parent:
            parent = root.findall('maven:parent', MAVEN_NS)
            if not parent:
                parent = root.findall('parent')
            if parent:
                if len(parent) > 1:
                    raise Exception('more than one element found: parent')
                elements = parent[0].findall('maven:%s' % name, MAVEN_NS)
                if not elements:
                    elements = parent[0].findall(name)
        if elements:
            if len(elements) > 1:
                raise Exception('more than one element found: %s' % name)
            return elements[0].text
        if not default:
            raise Exception('element not found: %s' % name)
        return default
    groupId = text('groupId')
    groupPath = groupId.replace('.', '/')
    artifactId = text('artifactId')
    version = text('version')
    packaging = text('packaging', False, 'jar')
    if format == 'gav':
        print('%s:%s:%s' % (groupId, artifactId, version))
    elif format == 'artifact':
        print('%s-%s.%s' % (artifactId, version, packaging))
    elif format == 'path':
        print('%s/%s/%s' % (groupPath, artifactId, version))
    else:
        raise Exception('unknown format: %s' % format)

def main():
    parser = argparse.ArgumentParser(prog='parse-pom')
    parser.add_argument('pom', metavar='<pom>', nargs='+', help='POM file')
    parser.add_argument('-F', '--format', metavar='<format>', default='gav',
            help='Output format: gav, artifact or path')
    args = parser.parse_args()
    exit_code = 0
    for pom_file in args.pom:
        try:
            parse(pom_file, args.format)
        except Exception as e:
            print('error parsing %s: %s' % (pom_file, e), file=sys.stderr)
    sys.exit(exit_code)

if __name__ == '__main__':
    main()
