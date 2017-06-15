#!/bin/bash

if [[ "$#" -ne 2 ]]; then
  echo "usage: $0 <repository-url> <pom-file>"
  exit 1
fi

PARSE_POM="mvn-parse-pom"
if [[ -x "./mvn-parse-pom.py" ]]; then
    PARSE_POM="./mvn-parse-pom.py"
fi

REPOSITORY=$1
POM=$2

if [[ ! -e "$POM" ]]; then
    echo "file not found: $POM"
    exit 4
fi

BASEDIR="`dirname \"$POM\"`"
BASENAME="`basename \"$POM\"`"

FILENAME="`$PARSE_POM --format artifact \"$POM\"`"

FILE="$BASEDIR/$FILENAME"
if [[ ! -e "$FILE" ]]; then
    echo "file not found: $FILE"
    exit 4
fi

URLPATH="`$PARSE_POM --format path \"$POM\"`"

FILEURL="$REPOSITORY/$URLPATH/$FILENAME"
POMURL="$REPOSITORY/$URLPATH/$BASENAME"

echo "Uploading to $FILEURL..."
curl --fail --upload-file "$FILE" "$FILEURL" || exit 10

echo "Uploading to $POMURL..."
curl --fail --upload-file "$POM" "$POMURL" || exit 10
