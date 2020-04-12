# git-get: Download Something from GitHub

[![Test Status](https://travis-ci.com/b1f6c1c4/git-get.svg?branch=master)](https://travis-ci.com/b1f6c1c4/git-get)

## Usage

```bash
git-get <url>
# is 1x~10000x faster than:
#     git clone <url> repo
#     rm -rf repo/.git

git-get <url> -- <file>|<dir>
# is 1x~1000000x faster than:
#     git clone <url> repo
#     git -C repo submodule update --init --recursive
#     mv repo/<file> <file> && rm -rf repo

git-get <url> <commit> -- <file>|<dir>
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

Currently only supports bash.

```bash
wget -qO- https://raw.githubusercontent.com/b1f6c1c4/git-get/master/git-get | sudo tee /usr/bin/git-get > /dev/null && sudo chmod 755 /usr/bin/git-get
wget -qO- https://raw.githubusercontent.com/b1f6c1c4/git-get/master/git-gets | sudo tee /usr/bin/git-gets > /dev/null && sudo chmod 755 /usr/bin/git-gets
# Or, locally:
mkdir -p ~/.local/bin/
wget -qO- https://raw.githubusercontent.com/b1f6c1c4/git-get/master/git-get | tee ~/.local/bin/git-get > /dev/null && sudo chmod 755 ~/.local/bin/git-get
wget -qO- https://raw.githubusercontent.com/b1f6c1c4/git-get/master/git-gets | tee ~/.local/bin/git-gets > /dev/null && sudo chmod 755 ~/.local/bin/git-gets
```

Upgrading:
```bash
git-get -o- b1f6c1c4/git-get -- git-get | sudo tee /usr/bin/git-get
git-get -o- b1f6c1c4/git-get -- git-gets | sudo tee /usr/bin/git-gets
# Or, locally:
git-get -f -o ~/.local/bin/ b1f6c1c4/git-get -- git-get
git-get -f -o ~/.local/bin/ b1f6c1c4/git-get -- git-gets
```

## Requirements

* git **2.20+**
* bash

## License

MIT
