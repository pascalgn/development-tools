#!/bin/bash

FIND="find . ( -name .metadata -or -name .project -or -name .classpath -or -name .settings )"

echo "Searching files..."

if ! $FIND | grep -E --color=never '.'; then
    echo "No setting files found"
    exit 0
fi

while true; do
    read -r -p "Delete these files? (y/n) " yn
    case $yn in
        [Yy]) break;;
        [Nn]) exit;;
        *) echo "Please answer y or n.";;
    esac
done

$FIND -print0 | xargs -0 rm -rf
