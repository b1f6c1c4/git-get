#!/bin/bash

usage()
{
    cat - <<EOF
git-download
    [git@github.com:]<user>/<repo>
    [<branch>|<sha1>]
    [-o <target> [-f|--force] [-F|--rm-rf]]
    [--[no-]legacy]
    [--] [<path>]
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
        --legacy)
            LEGACY=YES
            shift
            ;;
        --no-legacy)
            LEGACY=NO
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

if [ "${#POSITIONAL[@]}" -eq 0 ]; then
    echo "Must specify <user>/<repo>"
    exit 1
fi

REPO=$(echo "${POSITIONAL[0]}" | sed -E 's_^[^/]+/[^/]+$_git@github.com:\0_')

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
    is_sha1=$(echo "$MAYBE_BRANCH" | grep -P "^[0-9a-fA-F]{40}$")
    if [ ! -z "$is_sha1" ]; then
        BRANCH="$MAYBE_BRANCH"
        MAYBE_BRANCH=
    fi
fi

if [ -z "$BRANCH" ] && [ -z "$MAYBE_BRANCH" ]; then
    BRANCH="HEAD"
fi

which git >/dev/null
if [ $? -ne 0 ]; then
    echo "Git not found"
    exit 66
fi

WORK_DIR=$(mktemp -d)
REPO_DIR="$WORK_DIR/.git"
trap "{ rm -rf "$WORK_DIR"; }" EXIT

git init "$WORK_DIR"
git --git-dir="$REPO_DIR" remote add origin "$REPO"
if [ ! -z "$VERBOSE" ]; then
    echo "Remote:" "$REPO"
fi

if [ ! -z $MAYBE_BRANCH ]; then
    SHA1=$(git --git-dir="$REPO_DIR" ls-remote origin $MAYBE_BRANCH)
    if [ -z "$SHA1" ]; then
        BRANCH="HEAD"
        DIR="$MAYBE_BRANCH"
        SHA1=$(git --git-dir="$REPO_DIR" ls-remote origin $BRANCH)
    fi
else
    SHA1=$(git --git-dir="$REPO_DIR" ls-remote origin $BRANCH)
fi

if [ -z "$SHA1" ]; then
    echo "Reference $BRANCH not found in $REPO"
    exit 2
fi

set -- $SHA1
SHA1=$1

if [ ! -z "$VERBOSE" ]; then
    echo "Retrived SHA1:" $SHA1
fi

if [ -z "$OUTPUT" ]; then
    OUTPUT="./"
fi
IS_FINAL=$(echo "$OUTPUT" | grep '/$')
if [ ! -z "$IS_FINAL" ]; then
    if [ -z "$DIR" ]; then
        OUTPUT="$OUTPUT$(basename "$REPO")"
    else
        OUTPUT="$OUTPUT$(basename "$DIR")"
    fi
fi

if [ ! -z "$VERBOSE" ]; then
    echo "Output directory:" "$OUTPUT"
fi

GIT_VERSION=$(git --version | grep -P '^git version (2\.1[8-9]|2\.[2-9][0-9]|2\.[0-9][0-9][0-9]+|[3-9]\.[0-9]+|[1-9][0-9]+\.[0-9]+)(\.[0-9]+)?$')
if [ -z "$GIT_VERSION" ]; then
    echo "[31m$(git --version) is too old, please use 2.18+[0m"
    if [ "$LEGACY" = "NO" ]; then
        exit 18
    fi
    echo "fallback to legacy mode"
    LEGACY=YES
fi
if [ "$LEGACY" = "NO" ]; then
    echo "Unfortunately, this feature has not been implemented."
    exit 233 # TODO
    LEGACY=
fi

LEGACY=YES # TODO

if [ ! -z "$LEGACY" ]; then
    git --git-dir="$REPO_DIR" fetch-pack --depth=1 "$REPO" "$SHA1"
    if [ $? -ne 0 ]; then
        exit 2
    fi

    if [ -z "$DIR" ]; then
        TYPE=tree
    else
        TYPE=$(git --git-dir="$REPO_DIR" cat-file -t "$SHA1:$DIR")
        if [ $? -ne 0 ]; then
            exit 4
        fi
    fi
    if [ ! -z "$VERBOSE" ]; then
        echo "Type:" $TYPE
    fi

    git --git-dir="$REPO_DIR" --work-tree="$WORK_DIR" read-tree "$SHA1"

    if [ "$TYPE" = "tree" ]; then
        if [ -d "$OUTPUT" ]; then
            if [ ! -z "$FORCE_DIR" ]; then
                rm -rf "$OUTPUT"
            else
                echo "Output path is a folder and you try to replace it with a folder; use --rm-rf if that's what you want."
                exit 3
            fi
        elif [ -f "$OUTPUT" ]; then
            if [ ! -z "$FORCE" ]; then
                rm -f "$OUTPUT"
            else
                echo "Output path is a file and you try to replace it with a folder; use --force if that's what you want."
                exit 3
            fi
        fi
        if [ -z "$DIR" ]; then
            git --git-dir="$REPO_DIR" --work-tree="$WORK_DIR" checkout-index -f --prefix="result/" -- "$DIR"
        else
            git --git-dir="$REPO_DIR" --work-tree="$WORK_DIR" checkout-index -f --prefix="result/" -a
        fi
        if [ $? -ne 0 ]; then
            exit 4
        fi
        mv "$WORK_DIR/result/$DIR" "$OUTPUT"
        if [ $? -ne 0 ]; then
            exit 6
        fi
    elif [ "$TYPE" = "blob" ]; then
        if [ -d "$OUTPUT" ]; then
            if [ ! -z "$FORCE_DIR" ]; then
                rm -rf "$OUTPUT"
            else
                echo "Output path is a folder and you try to replace it with a file; use --rm-rf if that's what you want."
                exit 3
            fi
        elif [ -f "$OUTPUT" ]; then
            if [ ! -z "$FORCE" ]; then
                rm -f "$OUTPUT"
            else
                echo "Output path is a file and you try to replace it with a file; use --force if that's what you want."
                exit 3
            fi
        fi
        git --git-dir="$REPO_DIR" --work-tree="$WORK_DIR" checkout-index -f --prefix="result/" -- "$DIR"
        if [ $? -ne 0 ]; then
            exit 4
        fi
        mv "$WORK_DIR/result/$DIR" "$OUTPUT"
        if [ $? -ne 0 ]; then
            exit 4
        fi
    elif [ "$TYPE" = "commit" ]; then
        echo "TODO: recursive"
        exit 255
    fi
fi
