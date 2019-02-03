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

fetcher()
{
    # $1 = worktree
    # $2 = remote repo
    # $3 = sha1

    if [ ! -z "$VERBOSE" ]; then
        echo "Fetcher:" "$@"
    fi
    F_REPO="$1/.git"
    F_WORK="$1"
    shift
    F_REMO="$1"
    shift
    F_SHA1="$1"
    shift

    REMO_GIT=$(echo "$F_REMO" | sed -E 's_^https://([^/]+)/_git@\1:_')
    if [ ! -z "$VERBOSE" ]; then
        echo "Modified remote:" "$REMO_GIT"
    fi

    if [ ! -z "$LEGACY" ]; then
        if [ ! -d "$F_REPO" ]; then
            mkdir -p "$F_WORK"
            git init "$F_WORK"
        fi
        git --git-dir="$F_REPO" fetch-pack --depth=1 "$REMO_GIT" "$F_SHA1"
        if [ $? -ne 0 ]; then
            exit 2
        fi
    else
        echo "Unfortunately, this feature has not been implemented."
        exit 233 # TODO
    fi
}

WALKER_REPO=
WALKER_WORK=
WALKER_RESULT=
WALKER_TYPE=
WALKER_MODE=
walker()
{
    # $1 = worktree
    # $2 = base sha1
    # $3 = path
    # $4 = sha1
    # $5 = target path

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

    if [ ! -z "$VERBOSE" ]; then
        echo "Walker:" "$@"
    fi
    W_REPO="$1/.git"
    W_WORK="$1"
    shift
    W_BSHA="$1"
    shift
    W_PATH="$1"
    shift
    W_SHA1="$1"
    shift
    W_TARG="$1"
    shift
    FIRST=$(echo "$W_TARG" | sed -E 's_^([^/]*)(/.*)?$_\1_') # TODO: bad regex
    REST=$(echo "$W_TARG" | sed -E 's_^[^/]*(/(.*))?$_\2_') # TODO: bad regex
    if [ -z "$W_PATH" ]; then
        WN_PATH="$FIRST"
    else
        WN_PATH="$W_PATH/$FIRST"
    fi
    LSTREE="$(git --git-dir="$W_REPO" ls-tree "$W_SHA1" -- "$FIRST")"
    if [ $? -ne 0 ]; then
        exit 4
    fi
    set -- $LSTREE
    TYPE=$2
    WN_SHA1=$3
    if [ "$TYPE" = "commit" ]; then
        WN_WORK="$W_WORK/$WN_PATH"
        git --git-dir="$W_REPO" cat-file blob "$W_BSHA:.gitmodules" > "$W_WORK/.gitmodules"
        git config --file="$W_WORK/.gitmodules" --get-regexp 'submodule\..*\.path' > "$WORK_DIR/walker_temp"
        if [ $? -ne 0 ]; then
            echo "Can't clone submodule: .gitmodules not found"
            exit 190
        fi
        NM=$(grep -F ".path $WN_PATH" "$WORK_DIR/walker_temp")
        if [ -z "$NM" ]; then
            echo "Can't clone submodule: submodules not found"
            exit 191
        fi
        NMX=$(echo "$NM" | cut -f2 -d.)
        URL=$(git config --file="$W_WORK/.gitmodules" --get "submodule.$NMX.url")
        if [ ! -z "$VERBOSE" ]; then
            echo "Submodule found:" "$NMX" "$URL"
        fi
        fetcher "$WN_WORK" "$URL" "$WN_SHA1"
        WN_SHA1=$(git --git-dir="$WN_WORK/.git" rev-parse "$WN_SHA1^{tree}")
        if [ $? -ne 0 ]; then
            echo "Can't find tree from commit"
            exit 192
        fi
        if [ -z "$REST" ]; then
            WALKER_WORK="$WN_WORK"
            WALKER_RESULT="$WN_SHA1"
            WALKER_TYPE="tree"
            WALKER_MODE=
            if [ ! -z "$VERBOSE" ]; then
                echo "Walker suceed:" "$WALKER_WORK" "$WALKER_RESULT" "$WALKER_TYPE" "$WALKER_MODE"
            fi
        else
            walker "$WN_WORK" "$WN_SHA1" "." "$WN_SHA1" "$REST"
        fi
    elif [ "$TYPE" = "tree" ]; then
        if [ -z "$REST" ]; then
            WALKER_WORK="$W_WORK"
            WALKER_RESULT="$WN_SHA1"
            WALKER_TYPE="tree"
            WALKER_MODE=
            if [ ! -z "$VERBOSE" ]; then
                echo "Walker suceed:" "$WALKER_WORK" "$WALKER_RESULT" "$WALKER_TYPE" "$WALKER_MODE"
            fi
        else
            walker "$W_WORK" "$W_BSHA" "$WN_PATH" "$WN_SHA1" "$REST"
        fi
    elif [ "$TYPE" = "blob" ]; then
        if [ -z "$REST" ]; then
            WALKER_WORK="$W_WORK"
            WALKER_RESULT="$WN_SHA1"
            WALKER_TYPE="blob"
            WALKER_MODE="$1"
            if [ ! -z "$VERBOSE" ]; then
                echo "Walker suceed:" "$WALKER_WORK" "$WALKER_RESULT" "$WALKER_TYPE" "$WALKER_MODE"
            fi
        else
            echo "$W_SHA1/$FIRST is a file, you can't walk into it"
            exit 17
        fi
    else
        echo "Type $TYPE not supported"
        exit 20
    fi
    WALKER_REPO="$WALKER_WORK/.git"
}

recurse()
{
    if [ ! -z "$VERBOSE" ]; then
        echo "Recurse:" "$@"
    fi
}

exporter()
{
    # $1: repo
    # $2: work
    # $3: sha1
    # $4: target

    if [ ! -z "$VERBOSE" ]; then
        echo "Exporter:" "$@"
    fi
    E_REPO="$1"
    shift
    E_WORK="$1"
    shift
    E_RESULT="$1"
    shift
    E_OUTPUT="$1"
    shift

    git --git-dir="$E_REPO" --work-tree="$E_WORK" read-tree "$E_RESULT"
    if [ -d "$OUTPUT" ]; then
        if [ ! -z "$FORCE_DIR" ]; then
            rm -rf "$E_OUTPUT"
        else
            echo "Output path is a folder and you try to replace it with a folder; use --rm-rf if that's what you want."
            exit 3
        fi
    elif [ -f "$OUTPUT" ]; then
        if [ ! -z "$FORCE" ]; then
            rm -f "$E_OUTPUT"
        else
            echo "Output path is a file and you try to replace it with a folder; use --force if that's what you want."
            exit 3
        fi
    fi
    git --git-dir="$E_REPO" --work-tree="$E_WORK" checkout-index -f --prefix="result/" -a
    if [ $? -ne 0 ]; then
        exit 4
    fi
    mv "$E_WORK/result" "$E_OUTPUT"
    if [ $? -ne 0 ]; then
        exit 6
    fi
    if [ ! -z "$RECURSIVE" ]; then
        git --git=dir="$E_REPO" ls-tree "$E_RESULT" | grep '^160000 commit ' | xargs -n 1 recurse "$E_WORK" "$E_OUTPUT"
    fi
}

if [ ! -z "$LEGACY" ]; then
    fetcher "$WORK_DIR" "$REPO" "$SHA1"
    walker "$WORK_DIR" "$SHA1" "" "$SHA1" "$DIR"

    if [ ! -z "$VERBOSE" ]; then
        echo "Type:" "$WALKER_TYPE"
    fi

    if [ "$WALKER_TYPE" = "tree" ]; then
        exporter "$WALKER_REPO" "$WALKER_WORK" "$WALKER_RESULT" "$OUTPUT"
    elif [ "$WALKER_TYPE" = "blob" ]; then
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
        git --git-dir="$WALKER_REPO" cat-file blob "$WALKER_RESULT" > "$WALKER_WORK/result"
        if [ $? -ne 0 ]; then
            exit 4
        fi
        if [ "$WALKER_MODE" = "100644" ]; then
            chmod 644 "$WALKER_WORK/result"
        elif [ "$WALKER_MODE" = "100755" ]; then
            chmod 755 "$WALKER_WORK/result"
        else
            echo "Warning: mode not supported: $WALKER_MODE"
        fi
        if [ $? -ne 0 ]; then
            exit 4
        fi
        mv "$WALKER_WORK/result" "$OUTPUT"
        if [ $? -ne 0 ]; then
            exit 4
        fi
    fi
fi
