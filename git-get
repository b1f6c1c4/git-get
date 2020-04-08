#!/bin/bash

usage()
{
    cat - <<EOF
git-download
    [-v|--verbose|-q|--quiet]
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
        -q|--quiet)
            QUIET=--quiet
            shift
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
trap "{ rm -rf "$WORK_DIR"; }" EXIT

git init $QUIET "$WORK_DIR"
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

git-download-fetcher()
{
    # $1 = verbose
    # $2 = legacy
    # $3 = quiet
    # $4 = worktree
    # $5 = remote repo
    # $6 = sha1

    VREBOSE="$1"
    shift
    if [ ! -z "$VERBOSE" ]; then
        echo "Fetcher:" "$@"
    fi
    LEGACY="$1"
    shift
    QUIET="$1"
    shift
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
            git init $QUIET "$F_WORK"
        fi
        if [ -z "$QUIET" ]; then
            git --git-dir="$F_REPO" fetch-pack --depth=1 "$REMO_GIT" "$F_SHA1"
        else
            git --git-dir="$F_REPO" fetch-pack --quiet --no-progress --depth=1 "$REMO_GIT" "$F_SHA1" > /dev/null
        fi
        if [ $? -ne 0 ]; then
            exit 2
        fi
    else
        echo "Unfortunately, this feature has not been implemented."
        exit 233 # TODO
    fi
}
export -f git-download-fetcher

WALKER_REPO=
WALKER_WORK=
WALKER_RESULT=
WALKER_TYPE=
WALKER_MODE=
WALKER_BSHA=
WALKER_PATH=
walker()
{
    # $1 = worktree
    # $2 = base sha1
    # $3 = path
    # $4 = sha1
    # $5 = target path

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
    if [ -z "$W_TARG" ]; then
        LSTREE="040000 tree $W_SHA1 "
    else
        LSTREE="$(git --git-dir="$W_REPO" ls-tree "$W_SHA1" -- "$FIRST")"
    fi
    if [ $? -ne 0 ]; then
        exit 4
    fi
    set -- $LSTREE
    TYPE=$2
    WN_SHA1=$3
    if [ "$TYPE" = "commit" ]; then
        WN_WORK="$W_WORK/$WN_PATH"
        git --git-dir="$W_REPO" cat-file blob "$W_BSHA:.gitmodules" > "$W_WORK/.gitmodules"
        git config --file="$W_WORK/.gitmodules" --get-regexp 'submodule\..*\.path' > "$W_WORK/walker_temp"
        if [ $? -ne 0 ]; then
            echo "Can't clone submodule: .gitmodules not found"
            exit 190
        fi
        NM=$(grep -F ".path $WN_PATH" "$W_WORK/walker_temp")
        if [ -z "$NM" ]; then
            echo "Can't clone submodule: submodules not found"
            exit 191
        fi
        NMX=$(echo "$NM" | cut -f2 -d.)
        URL=$(git config --file="$W_WORK/.gitmodules" --get "submodule.$NMX.url")
        if [ ! -z "$VERBOSE" ]; then
            echo "Submodule found:" "$NMX" "$URL"
        fi
        git-download-fetcher "$VERBOSE" "$LEGACY" "$QUIET" "$WN_WORK" "$URL" "$WN_SHA1"
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
            WALKER_BSHA="$WN_SHA1"
            WALKER_PATH="$WN_PATH"
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
            WALKER_BSHA="$W_BSHA"
            WALKER_PATH="$W_PATH"
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
            WALKER_BSHA="$W_BSHA"
            WALKER_PATH="$W_PATH"
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

git-download-recurse()
{
    # $1: verbose
    # $2: legacy
    # $3: quiet
    # $4: work
    # $5: base sha1
    # $6: path
    # $7: target
    # $8: mode
    # $9: type
    # $a: sha1
    # $b...: path

    VERBOSE="$1"
    shift
    if [ ! -z "$VERBOSE" ]; then
        echo "Recurse:" "$@"
    fi
    LEGACY="$1"
    shift
    QUIET="$1"
    shift
    R_REPO="$1/.git"
    R_WORK="$1"
    shift
    R_BSHA="$1"
    shift
    R_PATH="$1"
    shift
    R_TARGET="$1"
    shift

    if [ -z "$*" ]; then
        return
    fi

    set -- $*
    R_MODE="$1"
    shift
    R_TYPE="$1"
    shift
    R_SHA1="$1"
    shift
    R_NEXT="$*"
    if [ -z "$R_PATH" ]; then
        RN_PATH="$R_NEXT"
    else
        RN_PATH="$R_PATH/$R_NEXT"
    fi
    if [ "$R_TYPE" = "tree" ]; then
        git --git-dir="$R_REPO" ls-tree "$R_SHA1" | grep -v '^100... blob ' | xargs -l bash -c 'git-download-recurse "$@"' "$@" "$VERBOSE" "$LEGACY" "$QUIET" "$R_WORK" "$R_BSHA" "$R_PATH" "$R_TARGET/$R_NEXT"
    elif [ "$R_TYPE" = "commit" ]; then
        RN_WORK="$R_WORK/$R_NEXT"
        RN_TARGET="$R_TARGET/$R_NEXT"
        git --git-dir="$R_REPO" cat-file blob "$R_BSHA:.gitmodules" > "$R_WORK/.gitmodules"
        git config --file="$R_WORK/.gitmodules" --get-regexp 'submodule\..*\.path' > "$R_WORK/walker_temp"
        if [ $? -ne 0 ]; then
            echo "Can't clone submodule: .gitmodules not found"
            exit 290
        fi
        NM=$(grep -F ".path $RN_PATH" "$R_WORK/walker_temp")
        if [ -z "$NM" ]; then
            echo "Can't clone submodule: submodules not found"
            exit 291
        fi
        NMX=$(echo "$NM" | cut -f2 -d.)
        URL=$(git config --file="$R_WORK/.gitmodules" --get "submodule.$NMX.url")
        if [ ! -z "$VERBOSE" ]; then
            echo "Submodule found:" "$NMX" "$URL"
        fi
        git-download-fetcher "$VERBOSE" "$LEGACY" "$QUIET" "$RN_WORK" "$URL" "$R_SHA1"
        RN_SHA1=$(git --git-dir="$RN_WORK/.git" rev-parse "$R_SHA1^{tree}")
        if [ $? -ne 0 ]; then
            echo "Can't find tree from commit"
            exit 292
        fi
        rm -fd "$RN_TARGET"
        if [ $? -ne 0 ]; then
            echo "Can't remove the empty folder"
            exit 293
        fi
        git-download-exporter "$VERBOSE" "$LEGACY" "$QUIET" "YES" "$RN_WORK" "$RN_SHA1" "" "$RN_SHA1" "$RN_TARGET"
    else
        echo "Warning: type $R_TYPE not supported"
    fi
}
export -f git-download-recurse

git-download-exporter()
{
    # $1: verbose
    # $2: legacy
    # $3: quiet
    # $4: recursive
    # $5: work
    # $6: base sha1
    # $7: path
    # $8: sha1
    # $9: target

    VREBOSE="$1"
    shift
    if [ ! -z "$VERBOSE" ]; then
        echo "Exporter:" "$@"
    fi
    LEGACY="$1"
    shift
    QUIET="$1"
    shift
    RECURSIVE="$1"
    shift
    E_WORK="$1"
    E_REPO="$1/.git"
    shift
    E_BSHA="$1"
    shift
    E_PATH="$1"
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
            exit 23
        fi
    elif [ -f "$OUTPUT" ]; then
        if [ ! -z "$FORCE" ]; then
            rm -f "$E_OUTPUT"
        else
            echo "Output path is a file and you try to replace it with a folder; use --force if that's what you want."
            exit 23
        fi
    fi
    git --git-dir="$E_REPO" --work-tree="$E_WORK" checkout-index -f --prefix="result/" -a
    if [ $? -ne 0 ]; then
        exit 24
    fi
    mv "$E_WORK/result" "$E_OUTPUT"
    if [ $? -ne 0 ]; then
        exit 26
    fi
    if [ ! -z "$RECURSIVE" ]; then
        git --git-dir="$E_REPO" ls-tree "$E_RESULT" | grep -v '^100... blob ' | xargs -l bash -c 'git-download-recurse "$@"' "$0" "$VERBOSE" "$LEGACY" "$QUIET" "$E_WORK" "$E_BSHA" "$E_PATH" "$E_OUTPUT"
    fi
}
export -f git-download-exporter

if [ ! -z "$LEGACY" ]; then
    git-download-fetcher "$VERBOSE" "$LEGACY" "$QUIET" "$WORK_DIR" "$REPO" "$SHA1"
    walker "$WORK_DIR" "$SHA1" "" "$SHA1" "$DIR"

    if [ ! -z "$VERBOSE" ]; then
        echo "Type:" "$WALKER_TYPE"
    fi

    if [ "$WALKER_TYPE" = "tree" ]; then
        git-download-exporter "$VERBOSE" "$LEGACY" "$QUIET" "$RECURSIVE" "$WALKER_WORK" "$WALKER_BSHA" "$WALKER_PATH" "$WALKER_RESULT" "$OUTPUT"
    elif [ "$WALKER_TYPE" = "blob" ]; then
        if [ -d "$OUTPUT" ]; then
            if [ ! -z "$FORCE_DIR" ]; then
                rm -rf "$OUTPUT"
            else
                echo "Output path is a folder and you try to replace it with a file; use --rm-rf if that's what you want."
                exit 23
            fi
        elif [ -f "$OUTPUT" ]; then
            if [ ! -z "$FORCE" ]; then
                rm -f "$OUTPUT"
            else
                echo "Output path is a file and you try to replace it with a file; use --force if that's what you want."
                exit 23
            fi
        fi
        git --git-dir="$WALKER_REPO" cat-file blob "$WALKER_RESULT" > "$WALKER_WORK/result"
        if [ $? -ne 0 ]; then
            exit 24
        fi
        if [ "$WALKER_MODE" = "100644" ]; then
            chmod 644 "$WALKER_WORK/result"
        elif [ "$WALKER_MODE" = "100755" ]; then
            chmod 755 "$WALKER_WORK/result"
        else
            echo "Warning: mode not supported: $WALKER_MODE"
        fi
        if [ $? -ne 0 ]; then
            exit 25
        fi
        mv "$WALKER_WORK/result" "$OUTPUT"
        if [ $? -ne 0 ]; then
            exit 26
        fi
    fi
fi
