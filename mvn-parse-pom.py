#!/usr/bin/env python3

import argparse
import xml.etree.ElementTree

MAVEN_NS = { 'maven': 'http://maven.apache.org/POM/4.0.0' }

def parse(pom_file, format):
    root = xml.etree.ElementTree.parse(pom_file).getroot()
    def text(name, default=None):
        elements = root.findall('maven:%s' % name, MAVEN_NS)
        if elements:
            if len(elements) > 1:
                raise Exception('more than one element found: %s' % name)
            return elements[0].text
        return default
    groupId = text('groupId')
    groupPath = groupId.replace('.', '/')
    artifactId = text('artifactId')
    version = text('version')
    packaging = text('packaging', 'jar')
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
    for pom_file in args.pom:
        parse(pom_file, args.format)

if __name__ == '__main__':
    main()
