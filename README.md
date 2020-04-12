# git-get: Blazingly fast `git clone` alternative

[![Test Status](https://travis-ci.com/b1f6c1c4/git-get.svg?branch=master)](https://travis-ci.com/b1f6c1c4/git-get)

## TL;DR

```bash
git-get <url> -t
# is 1x~10000x faster than:
#     git clone <url> repo
#     git -C repo rev-parse HEAD > repo/VERSION
#     rm -rf repo/.git

git-get <url> -o <target> -- <file>
# is 1x~1000000x faster than:
#     git clone <url> repo
#     git -C repo submodule update --init --recursive
#     cp repo/<file> <target> && rm -rf repo

git-get <url> <commit> -- <file>
# is 1x~1000000000x faster than:
#     git clone --mirror <url> repo
#     git -C repo switch --detach <commit>
#     rm -rf repo/.git

git-gets <url> <commit> -P
# is 1x~10000000x faster than:
#     git clone --mirror <url> repo
#     git -C repo switch --detach <commit>
#     git -C repo submodule update --init --recursive

git-gets <url> <commit> -P --flat
# is 1x~10000000x faster than:
#     git clone --mirror <url> repo
#     git -C repo switch --detach <commit>
#     git -C repo submodule update --init --recursive
#     rm -rf repo/**/.git
```

## Why it is so fast?

It leverages `--depth` and `--filter` to save bandwidth.
Only the files you actually want (that commit that file) are downloaded.
No entire development history.
No entire repository folder.
Remember, this applies to both parent repo and all sub repos.

## Usage

The CLI is pretty self-explanatory:

```bash
git-get [-v|--verbose|-q|--quiet]
    <url> | <user>/<repo> [<branch>|<sha1>]
    [-o <target> |--output=<target>] [-f|--force] [-F|--rm-rf]
    [--preserve-git | [-t [--tag-file=VERSION]] [-- <path>]]

git-gets [-v|--verbose|-q|--quiet]
    <url> | <user>/<repo> [<branch>|<sha1>]
    [[-o|--output] <target>] [-F|--rm-rf]
    [--flat [--tag-file=VERSION]] [-P|--parallel] [-c|--confirm]
```

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/b1f6c1c4/git-get/master/git-get | sudo tee /usr/bin/git-get > /dev/null && sudo chmod 755 /usr/bin/git-get
curl -fsSL https://raw.githubusercontent.com/b1f6c1c4/git-get/master/git-gets | sudo tee /usr/bin/git-gets > /dev/null && sudo chmod 755 /usr/bin/git-gets
# Or, locally:
mkdir -p ~/.local/bin/
curl -fsSL https://raw.githubusercontent.com/b1f6c1c4/git-get/master/git-get | tee ~/.local/bin/git-get > /dev/null && sudo chmod 755 ~/.local/bin/git-get
curl -fsSL https://raw.githubusercontent.com/b1f6c1c4/git-get/master/git-gets | tee ~/.local/bin/git-gets > /dev/null && sudo chmod 755 ~/.local/bin/git-gets
```

Upgrading:
```bash
git-get -o- b1f6c1c4/git-get -- git-get | sudo tee /usr/bin/git-get >/dev/null
git-get -o- b1f6c1c4/git-get -- git-gets | sudo tee /usr/bin/git-gets >/dev/null
# Or, locally:
git-get -f -o ~/.local/bin/ b1f6c1c4/git-get -- git-get
git-get -f -o ~/.local/bin/ b1f6c1c4/git-get -- git-gets
```

## Requirements

* git **2.20+**
* bash

## License

MIT
