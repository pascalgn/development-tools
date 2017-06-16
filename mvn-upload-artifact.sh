#!/bin/bash

if [[ "$#" -lt 2 ]]; then
  echo "usage: $0 <repository-url> <pom-file> [<additional-file>...]"
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

POM_BASEDIR="`dirname \"$POM\"`"
POM_BASENAME="`basename \"$POM\"`"

FILENAME="`$PARSE_POM --format artifact \"$POM\"`"

FILE="$POM_BASEDIR/$FILENAME"
if [[ ! -e "$FILE" ]]; then
    echo "file not found: $FILE"
    exit 4
fi

URLPATH="`$PARSE_POM --format path \"$POM\"`"

FILEURL="$REPOSITORY/$URLPATH/$FILENAME"
POMURL="$REPOSITORY/$URLPATH/$POM_BASENAME"

echo "Uploading to $FILEURL..."
curl --fail --upload-file "$FILE" "$FILEURL" || exit 10

echo "Uploading to $POMURL..."
curl --fail --upload-file "$POM" "$POMURL" || exit 10

# Upload other artifacts:
shift 2
for ARG in $@; do
    ARG_BASENAME="`basename \"$ARG\"`"
    if [[ "$ARG_BASENAME" == "$POM_BASENAME" || "$ARG_BASENAME" == "$FILENAME" ]]; then
        continue
    fi
    ARG_URL="$REPOSITORY/$URLPATH/$ARG_BASENAME"
    echo "Uploading to $ARG_URL..."
    curl --fail --upload-file "$ARG" "$ARG_URL" || exit 11
done
