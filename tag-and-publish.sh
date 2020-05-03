#!/bin/sh

main() {
    CURRENT="$(get_current_version)" || exit 1
    echo "Current version: ${CURRENT}"

    if [ "${#}" -ne 1 ]; then
        echo "usage: $0 VERSION" >&2
        exit 1
    fi

    VERSION="${1}"

    if [ -n "$(git status --porcelain)" ]; then
        git status
        exit 1
    fi

    git pull || exit 1

    TAG_NAME_FORMAT="$(get_tag_name_format)" || exit 1
    TAG_MESSAGE_FORMAT="$(get_tag_message_format)" || exit 1

    # shellcheck disable=SC2059
    TAG_NAME="$(printf "${TAG_NAME_FORMAT}" "${VERSION}")" || exit 1

    # shellcheck disable=SC2059
    TAG_MESSAGE="$(printf "${TAG_MESSAGE_FORMAT}" "${VERSION}")" || exit 1

    COMMIT_MESSAGE="Release ${VERSION}"

    echo "Tag name: ${TAG_NAME}"
    echo "Tag message: ${TAG_MESSAGE}"
    echo "Commit message: ${COMMIT_MESSAGE}"

    check_outdated_packages

    ask_confirm "Release?" || exit 1

    commit_new_version "${VERSION}" "${COMMIT_MESSAGE}" || exit 1

    git tag -a -m "${TAG_MESSAGE}" "${TAG_NAME}"

    if ! publish_package "${VERSION}"; then
        git tag -d "${TAG_NAME}"
        git reset --hard HEAD^
        exit 1
    fi

    git push || exit 1
    git push --tags || exit 1

    echo "Version successfully released: ${VERSION}"
}

get_current_version() {
    if [ -f "./package.json" ]; then
        sed -n -E 's/.*"version": "([^"]+)".*/\1/p' package.json
    elif [ -f "./Cargo.toml" ]; then
        sed -n -E 's/^version = "([^"]+)"$/\1/p' Cargo.toml
    elif [ -f "./pom.xml" ]; then
        sed -n -E 's/^ {4}<version>([^"]+)<\/version>$/\1/p' pom.xml
    else
        echo "No packaging file found!" >&2
        exit 1
    fi
}

get_tag_name_format() {
    TAGS="$(git tag)" || return 1
    COUNT="$(echo "${TAGS}" | wc -l)"
    if [ "$(echo "${TAGS}" | grep -cE "^[0-9.]+$")" -eq "${COUNT}" ]; then
        echo "%s"
    elif [ "$(echo "${TAGS}" | grep -cE "^v[0-9.]+$")" -eq "${COUNT}" ]; then
        echo "v%s"
    else
        echo "error: unknown tag name format" >&2
        return 1
    fi
}

get_tag_message_format() {
    T="$(git tag --format='%(contents:subject)')" || return 1
    C="$(echo "${T}" | wc -l)"
    if [ "$(echo "${T}" | grep -cE "^[0-9.]+$")" -eq "${C}" ]; then
        echo "%s"
    elif [ "$(echo "${T}" | grep -cE "^v[0-9.]+$")" -eq "${C}" ]; then
        echo "v%s"
    elif [ "$(echo "${T}" | grep -cE "^Release [0-9.]+$")" -eq "${C}" ]; then
        echo "Release %s"
    else
        echo "error: unknown tag name format" >&2
        return 1
    fi
}

check_outdated_packages() {
    if [ -f "./package.json" ]; then
        yarn outdated
    elif [ -f "./Cargo.toml" ]; then
        cargo update --dry-run
    fi
}

commit_new_version() {
    version="${1}"
    commit_message="${2}"
    if [ -f "./package.json" ]; then
        sed -E "s/\"version\": \"[^\"]+\"/\"version\": \"${version}\"/g" \
            package.json >package.json.new || exit 1
        mv -- package.json.new package.json || exit 1
        git commit -m "${commit_message}" package.json || exit 1
    elif [ -f "./Cargo.toml" ]; then
        sed -E "s/^version = \"[^\"]+\"$/version = \"${version}\"/g" \
            Cargo.toml >Cargo.toml.new || exit 1
        mv -- Cargo.toml.new Cargo.toml || exit 1
        cargo check
        git commit -m "${commit_message}" Cargo.toml Cargo.lock || exit 1
    else
        exit 1
    fi
}

publish_package() {
    version="${1}"
    if [ -f "./package.json" ]; then
        if ! grep -q '"private": true' package.json; then
            if [ -f "${HOME}/.npm/token" ]; then
                NPM_AUTH_TOKEN="$(cat "${HOME}/.npm/token")"
                export NPM_AUTH_TOKEN
            fi

            yarn publish --non-interactive --new-version "${version}" || exit 1
        fi
    elif [ -f "./Cargo.toml" ]; then
        if ! grep -q 'publish = false' Cargo.toml; then
            rm -rf ./target
            cargo publish || exit 1
        fi
    else
        exit 1
    fi
}

ask_confirm() {
    while true; do
        printf "%s " "${1}"
        read -r yn
        case $yn in
        [Yy]) return 0 ;;
        [Nn]) return 1 ;;
        *) echo "Please answer y or n." ;;
        esac
    done
}

main "${@}"
