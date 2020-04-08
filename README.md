# git-get: Download Something from GitHub

## Usage

```bash
git-get <url>
# Equivalent to:
#     git clone --depth=1 <url> && cd <repo>
#     rm -rf .git

git-get <url> -- <file>|<dir>
# Equivalent to:
#     git clone --depth=1 <url>
#     mv <repo>/<file> <file> && rm -rf <repo>
# ... and is 1x~10000x faster

git-get <url> <commit> -- <file>|<dir>
# Equivalent to:
#     git clone <url> && cd <repo>
#     (cd <repo> && git fetch --all && git switch --detach <commit>)
#     rm -rf <repo>/.git
# ... and is 1x~1000000000x faster

git-get --recursive <url>
# Equivalent to:
#     git clone --depth=1 <url> && cd <repo>
#     git submodule init --recursive
#     git submodule update --recursive
#     rm -rf **/.git
# ... and is 1x~10000000x faster
```

```bash
git-get
    [-v|--verbose|-q|--quiet]
    <url> | <user>/<repo>
    [<branch>|<sha1>]
    [-o <target>] [-f|--force] [-F|--rm-rf]
    [-t [--tag-file=VERSION]]
    [-r|--recursive] [-j<N>] [-- <path>]
```

## Install

Currently only supports bash.

First time installation (bootstrapping):
```bash
wget -qO- https://raw.githubusercontent.com/b1f6c1c4/git-get/master/git-get | sudo tee /usr/bin/git-get > /dev/null && sudo chmod 755 /usr/bin/git-get
# Or, locally:
mkdir -p ~/.local/bin/
wget -qO- https://raw.githubusercontent.com/b1f6c1c4/git-get/master/git-get | tee ~/.local/bin/git-get > /dev/null && sudo chmod 755 ~/.local/bin/git-get
```

Upgrading:
```bash
git-get -o- b1f6c1c4/git-get git-get | sudo tee /usr/bin/git-get
# Or, locally:
git-get -f -o ~/.local/bin/ b1f6c1c4/git-get git-get
```

## License

MIT
