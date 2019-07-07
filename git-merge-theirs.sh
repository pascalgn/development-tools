#!/bin/bash
for ARG in "$@"; do :; done
THEIR_COMMIT=$ARG
exec git read-tree --reset -u "$THEIR_COMMIT"
