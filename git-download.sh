#!/bin/bash

usage()
{
    cat - <<EOF
git-download
    [https://github.com/]<user>/<repo>
    [<branch>|<sha1>]
    [-o <target> [-f|--force] [-F|--rm-rf]]
    [-r|--recursive] [--] [<path>]
EOF
}

POSITIONAL=()
while [ $# -gt 0 ]; do
    key="$1"
    case $key in
        -h|--help)
            usage
            exit
            ;;
        -v|--verbose)
            VERBOSE=YES
            shift
            ;;
        -r|--recursive)
            RECURSIVE=YES
            shift
            ;;
        -f|--force)
            FORCE=YES
            shift
            ;;
        -F|--rm-rf)
            FORCE_DIR=YES
            shift
            ;;
        -o|--output)
            OUTPUT="$2"
            shift
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            POSITIONAL+=("$1")
            shift
            ;;
    esac
done

PATH_POSITIONAL=()
while [ $# -gt 0 ]; do
    PATH_POSITIONAL+=("$1")
    shift
done

set -- "${POSITIONAL[@]}"
set -- "${PATH_POSITIONAL[@]}"

if [ "${#POSITIONAL[@]}" -eq 0 ]; then
    echo "Must specify <user>/<repo>"
    exit 1
fi

REPO=${POSITIONAL[0]}
is_github=$(echo "$REPO" | grep -P "^[^/]+/[^/]+$")
if [ ! -z "$is_github" ]; then
    REPO=https://github.com/$REPO
fi

total=$((${#POSITIONAL[@]} + ${#PATH_POSITIONAL[@]}))
if [ "$total" -gt 3 ] || [ "${#PATH_POSITIONAL[@]}" -gt 1 ]; then
    echo "Too many positional arguments"
    exit 1
fi

if [ "${#PATH_POSITIONAL[@]}" -eq 1 ]; then
    BRANCH="${POSITIONAL[1]}"
    DIR="${PATH_POSITIONAL[0]}"
elif [ "${#POSITIONAL[@]}" -eq 3 ]; then
    BRANCH="${POSITIONAL[1]}"
    DIR="${POSITIONAL[2]}"
else
    MAYBE_BRANCH="${POSITIONAL[1]}"
fi

if [ ! -z "$VERBOSE" ]; then
    echo repo: $REPO
    echo "commit-ish or path:" $MAYBE_BRANCH
    echo commit-ish: $BRANCH
    echo path: $DIR
    [ ! -z "$RECURSIVE" ] && echo recursive
    [ ! -z "$FORCE" ] && echo force
    [ ! -z "$FORCE_DIR" ] && echo force_dir
fi
