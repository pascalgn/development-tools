#!/bin/sh

OTHER="$1"

if [ -z "${OTHER}" ]; then
    echo "usage: $0 OTHER" >&2
    exit 1
fi

if [ ! -d "${OTHER}" ]; then
    echo "error: directory not found: ${OTHER}" >&2
    exit 1
fi

DIR="$(basename "${OTHER}")"

if [ -d "${DIR}" ]; then
    echo "error: directory already exists: ${DIR}" >&2
    exit 1
fi

echo "Rewriting history in ${OTHER} ..."

(
    cd "${OTHER}" &&
        git filter-branch --index-filter 'git ls-files -s |
            sed "s,	,&'"${DIR}"'/," |
            GIT_INDEX_FILE=$GIT_INDEX_FILE.new git update-index --index-info &&
            mv $GIT_INDEX_FILE.new $GIT_INDEX_FILE' HEAD
) || exit 1

git fetch "${OTHER}" master:git-import-repository &&
    git checkout git-import-repository &&
    git rebase master &&
    git checkout master &&
    git merge --ff-only git-import-repository &&
    git branch -d git-import-repository ||
    exit 1

echo "Done."
