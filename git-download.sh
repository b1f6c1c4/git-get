#!/bin/bash

usage()
{
    cat - <<EOF
git-download
    [https://github.com/]<user>/<repo>
    [<branch>|<sha1>]
    [-o <target> [-f|--force] [-F|--rm-rf]]
    [--[no-]legacy]
    [-r|--recursive] [--] [<path>]
EOF
}

POSITIONAL=()
while [ $# -gt 0 ]; do
    key="$1"
    case "$key" in
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
# trap "{ rm -rf "$WORK_DIR"; }" EXIT

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

WALKER_REPO=
WALKER_RESULT=
WALKER_TYPE=
WALKER_MODE=
walker()
{
    # $1 = worktree
    # $2 = base sha1
    # $3 = sha1
    # $4 = target path

    # if [ -z "$2" ]; then
    #     TYPE=$(git --git-dir="$REPO_DIR" cat-file -t "$1")
    #     if [ $? -ne 0 ]; then
    #         exit 4
    #     fi
    #     if [ "$TYPE" = "commit" ]; then
    #         exit 233 # TODO
    #     fi
    #     echo "$TYPE"
    #     return
    # fi

    W_REPO=$1.git
    W_WORK=$1
    W_BSHA=$2
    W_SHA1=$3
    W_TARG=$4
    echo in walker "$1" "$2" "$3" "$4"
    FIRST=$(echo "$W_TARG" | sed -E 's_^([^/]*)(/.*)?$_\1_')
    REST=$(echo "$W_TARG" | sed -E 's_^[^/]*(/(.*))?$_\2_')
    LSTREE="$(git --git-dir="$W_REPO" ls-tree "$W_SHA1" -- "$FIRST")"
    if [ $? -ne 0 ]; then
        exit 4
    fi
    set -- $LSTREE
    TYPE=$2
    WN_SHA1=$3
    if [ "$TYPE" = "commit" ]; then
        git --git-dir="$W_REPO" cat-file blob "$W_BSHA:.gitmodule" > "$WORK_DIR/walker_temp"
        if [ $? -ne 0 ]; then
            echo "Can't clone submodule: .gitmodule not found"
            exit 190
        fi
        ID=$(grep -nF "$WN_SHA1" "$WORK_DIR/walker_temp" | cut -f1 -d:)
        if [ -z "$ID" ]; then
            echo "Can't clone submodule: submodule not found"
            exit 191
        fi
        URL=$(awk "FNR == $ID { print \$1; }" "$WORK_DIR/walker_temp")
        if [ ! "$URL" = "URL" ]; then
            echo "Can't clone submodule: url not found"
            exit 192
        fi
        URL=$(awk "FNR == $ID { print \$3; }" "$WORK_DIR/walker_temp")
        # TODO
    elif [ "$TYPE" = "tree" ]; then
        if [ -z $REST ]; then
            WALKER_REPO="$W_REPO"
            WALKER_RESULT="$WN_SHA1"
            WALKER_TYPE="tree"
            WALKER_MODE=
            # TODO
        else
            walker "$W_WORK" "$W_BSHA" "$WN_SHA1" "$REST"
        fi
    elif [ "$TYPE" = "blob" ]; then
        if [ -z $REST ]; then
            WALKER_REPO="$W_REPO"
            WALKER_RESULT="$WN_SHA1"
            WALKER_TYPE="blob"
            WALKER_MODE="$1"
        else
            echo "$W_SHA1/$FIRST is a file, you can't walk into it"
            exit 17
        fi
    else
        echo "Type $TYPE not supported"
        exit 20
    fi
}

if [ ! -z "$LEGACY" ]; then
    git --git-dir="$REPO_DIR" fetch-pack --depth=1 "$REPO" "$SHA1"
    if [ $? -ne 0 ]; then
        exit 2
    fi

    echo "walker: $(walker "$SHA1" "." "$DIR")"

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
