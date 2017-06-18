#!/bin/bash

FIND="find . ( -name .metadata -or -name .project -or -name .classpath -or -name .settings )"

echo "Searching files..."

$FIND | grep -E --color=never '.*'
if [[ $? -ne 0 ]]; then
    echo "No setting files found"
    exit 0
fi

while true; do
    read -p "Delete these files? (y/n) " yn
    case $yn in
        [Yy]) break;;
        [Nn]) exit;;
        *) echo "Please answer y or n.";;
    esac
done

$FIND -print0 | xargs -0 rm -rf