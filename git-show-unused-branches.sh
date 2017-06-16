#!/bin/bash
if [[ "$1" != "-q" && "$1" != "--quiet" ]]; then
    echo "Showing all remote refs, sorted by last commit date:"
fi
git for-each-ref --sort=committerdate \
    --format='%(committerdate:relative)%09%(committername)%09%(refname:short)' refs/remotes
