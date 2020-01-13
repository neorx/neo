#!/bin/bash

##
# neo
# ---
# by Francesco Bianco
# bianco@javanile.org
# MIT License
##

set -e

debug=
verbose=
usecache=
registry=https://zionrc.github.io/registry/tag/neo
signature=https://raw.githubusercontent.com/zionrc/neo/master/neo.sig
checksum=$(curl -s "${signature}?ts=$(date +%s)" || true)
hint="try 'neo --help' for more information"
version=5

info () {
    [[ -z ${verbose} ]] || echo -e "\e[33mneo: $1\e[0m"
    return 0
}

error () {
    echo -e "\e[31mneo: $2\e[0m"
    exit $1
}

warning () {
    echo -e "\e[31mneo: $1\e[0m"
    return 0
}

usage () {
    echo "Usage: neo [OPTION]... COMMAND TAG [ARGUMENT]..."
    echo "Run command and tag from public registry https://github.com/zionrc/registry"
    exit 1
}

[[ "$1" == "--help" ]] && usage

while getopts "hcxv" opt &> /dev/null; do
    last=$(( OPTIND-1 ))
    case "${opt}" in
        h) usage ;;
        x) debug=-x ;;
        v) verbose=1 ;;
        c) usecache=1 ;;
        ?) error 2 "illegal option '${!last}', ${hint}." ;;
    esac
done

shift $(( OPTIND-1 ))

[[ -z "$1" ]] && error 2 "requires command and tag, ${hint}."
[[ -z "$2" ]] && error 2 "requires tag, ${hint}."

[[ ${#2} -le 1 ]] && error 2 "tag '${2}' is too short, type at least 2 letters."

info "(checksum) ${checksum}"

if [[ -z "${usecache}" ]]; then
    if [[ -z "${checksum}" ]]; then
        error 3 "you are offline, use '-c' option to run from cache."
    else
        if [[ "$(sha256sum $0)" != "${checksum}  $0" ]]; then
            warning "checksum error, upgrade to latest version."
        fi
    fi
fi

if [[ -f "$2" ]]; then
    script="$2"
    source=$(cat "${script}")
else
    cache="${HOME}/.zionrc_cache/$2"
    info "(cache) ${cache}"

    if [[ -z ${usecache} ]]; then
        page="${registry}/${2:0:1}/${2:1:1}"
        line="$(curl -s "${page}?ts=$(date +%s)" | grep -m1 "^$2 *" || true)"

        if [[ -z "${line}" ]]; then
            error 3 "tag '$2' not found on '${page}' page."
        fi

        file="$(echo ${line} | cut -s -d' ' -f2)"
        hash="$(echo ${line} | cut -s -d' ' -f3)"

        info "curl: ${file}"
        mkdir -p "${HOME}/.zionrc_cache"
        curl -o ${cache} -s "${file}?ts=$(date +%s)" || true

        if [[ "$(sha256sum ${cache})" != "${hash}  ${cache}" ]]; then
            error 3 "tag '$2' checksum error."
        fi
    fi
fi

[[ -f ${cache} ]] || error 3 "cache file '${cache}' not found."

## Prepare script header
header="set -- \"${cache}\" \"$1\""
for arg in "${@:3}"; do header+=" \"${arg}\""; done
info "(header) ${header}"

## Execute script
bash ${debug} - <( echo "${heaeder}"; cat "${cache}" )
