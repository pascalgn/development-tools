#!/bin/bash
if [[ "$1" != "-q" && "$1" != "--quiet" ]]; then
    echo "Showing remote refs that have been merged into HEAD ($(git rev-parse --abbrev-ref HEAD)):"
fi
git for-each-ref --merged HEAD \
    --format='%(refname:short)%09%(committername): %(contents:lines=1)' refs/remotes
