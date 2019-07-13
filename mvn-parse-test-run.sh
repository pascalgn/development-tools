#!/bin/sh

LOG_FILE="${1:--}"

echo "Count,Failures,Errors,Skipped,Duration,Test"

PATTERN="Tests run: ([0-9]+), Failures: ([0-9]+), Errors: ([0-9]+), \
Skipped: ([0-9]+), Time elapsed: ([0-9.]+) s - in (.+)"

# shellcheck disable=SC2002
cat "${LOG_FILE}" |
    sed -n -E "s/^.*${PATTERN}\$/\1,\2,\3,\4,\5,\6/p" |
    sort -n -r -t ',' -k 5
