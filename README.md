# git-get: Download Something from GitHub

## Usage

```bash
git-get <url>
# Equivalent to:
#     git clone --depth=1 <url>
#     rm -rf git-get/.git

git-get --recursive <url>
# Equivalent to:
#     git clone --depth=1 <url>
#     (cd <repo> && git submodule init --recursive)
#     (cd <repo> && git submodule update --recursive)
#     rm -rf <repo>/**/.git

git-get <url> <branch>
#     Equivalent to:
#     git clone --depth=1 --branch=<branch> <url>
#     rm -rf <repo>/.git

git-get <url> <commit>
# Equivalent to:
#     git clone <url>
#     (cd <repo> && git switch --detach <commit>)
#     rm -rf <repo>/.git
```

```bash
git-get
    [-v|--verbose|-q|--quiet]
    [https://github.com/|git@github.com:]<user>/<repo>
    [<branch>|<sha1>]
    [-o <target> [-f|--force] [-F|--rm-rf]]
    [-r|--recursive] [--] [<path>]
```

## Install

Currently only supports bash.

```bash
wget -qO- https://raw.githubusercontent.com/b1f6c1c4/git-get/master/git-get | sudo tee /usr/bin/git-get > /dev/null && sudo chmod 755 /usr/bin/git-get
# Or, locally:
mkdir -p ~/.local/bin/
wget -qO- https://raw.githubusercontent.com/b1f6c1c4/git-get/master/git-get | tee ~/.local/bin/git-get > /dev/null && sudo chmod 755 ~/.local/bin/git-get
```

## License

MIT
