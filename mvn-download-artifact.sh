#!/bin/bash

OPTIND=1

DEFAULT_URL="https://oss.sonatype.org/content/repositories"

USAGE="usage: $0 [-u <url>] [-r <repository>] <gav>"

url="$DEFAULT_URL"
repository="$HOME/.m2/repository"

while getopts ":u:r:h" opt; do
  case "$opt" in
    u)
        url="$OPTARG"
        ;;
    r)
        repository="$OPTARG"
        ;;
    h)
        echo "$USAGE"
        echo
        echo "  gav       the artifact to download in the format groupId:artifactId:version"
        echo
        echo "  -r <repository>"
        echo "            the location of the local repository (default: ~/.m2/repository)"
        echo "  -u <url>  the URL of the remote repository to download the artifact from"
        echo "            (default: $DEFAULT_URL)"
        exit 0
        ;;
    \?)
        echo "Invalid option: -$OPTARG" >&2
        exit 1
        ;;
    :)
        echo "Option -$OPTARG requires an argument." >&2
        exit 1
        ;;
    esac
done

shift $((OPTIND-1))

id=$1

if [[ -z "$id" ]]; then
  echo "$USAGE"
  exit 1
fi

if [ ! -d "$repository" ]; then
  echo "Repository does not exist: $repository"
  exit 2
fi

gavCount=`echo "$id" | tr -d -c ':' | wc -m`
if [[ $gavCount -eq 2 ]]; then
    groupId=`echo "$id" | cut -d : -f 1`
    artifactId=`echo "$id" | cut -d : -f 2`
    version=`echo "$id" | cut -d : -f 3`
elif [[ $gavCount -eq 3 ]]; then
    groupId=`echo "$id" | cut -d : -f 1`
    artifactId=`echo "$id" | cut -d : -f 2`
    version=`echo "$id" | cut -d : -f 4`
else
    echo "Invalid GAV: $id"
    exit 3
fi

echo "GroupId: $groupId"
echo "ArtifactId: $artifactId"
echo "Version: $version"

exit 3

snapshot=0
baseVersion="$version"

if echo "$version" | grep -q -- "-SNAPSHOT"; then
  snapshot=1
  baseVersion=`echo $version | grep -oP '.+(?=-SNAPSHOT)'`
fi

if [ "$url" == "$DEFAULT_URL" ]; then
  if [[ $snapshot -eq 1 ]]; then
    url="$url/snapshots"
  else
    url="$url/releases"
  fi
fi

groupPath=`echo "$groupId" | sed 's/\./\//g'`
path="$groupPath/$artifactId/$version"

echo "Fetching $groupId:$artifactId:$version"
echo "from $url/$path"

targetDir="$repository/$groupPath/$artifactId/$version"

if [ -d "$targetDir" ]; then
  echo "Target directory already exists: $targetDir" >&2
  exit 100
fi

mkdir -p "$targetDir"

latest="$artifactId-$version"

if [[ $snapshot -eq 1 ]]; then
  metadataFile="$targetDir/maven-metadata.xml"
  if [ ! -f "$metadataFile" ]; then
    echo "Fetching $url/$path/maven-metadata.xml ..."
    curl -o "$metadataFile" -L "$url/$path/maven-metadata.xml" || exit 110
  fi

  metadata=`cat "$metadataFile"`

  ts=`echo $metadata | grep -oP '<timestamp>\K[^<]+'`
  if [ $? -ne 0 ]; then
    exit 105
  fi

  build=`echo $metadata | grep -oP '<buildNumber>\K[^<]+'`
  if [ $? -ne 0 ]; then
    exit 105
  fi

  echo "Latest snapshot version: $baseVersion-$ts-$build"
  latest="$artifactId-$baseVersion-$ts-$build"
fi

echo "Fetching $url/$path ..."
fileUrls=`curl -L "$url/$path" | grep -Eo "$url/$path/${latest}[a-zA-Z0-9.-]+"`
if [ $? -ne 0 ]; then
  exit 110
fi

(cd $targetDir && for fileUrl in $fileUrls; do
  echo "Fetching $fileUrl ..."
  curl -L -O "$fileUrl"
done)

if [[ $snapshot -eq 1 ]]; then
  (cd $targetDir && for fileName in `echo "$artifactId-$baseVersion-*"`; do
    snapshotName=`echo $fileName | sed "s/$ts-$build/SNAPSHOT/g"`
    cp "$fileName" "$snapshotName"
  done)
fi

echo "Downloaded $latest to $targetDir"
