# git-download

```bash
git-download
    [git@github.com:]<user>/<repo>
    [<branch>|<sha1>]
    [-o <target> [-f|--force] [-F|--rm-rf]]
    [-r|--recursive] [--] [<path>]
```

> Download file/folder from any Git host. Bullshit-free.

## Install

Currently only supports bash.

```bash
wget -qO- https://raw.githubusercontent.com/b1f6c1c4/git-download/master/git-download.sh | sudo bash /dev/stdin b1f6c1c4/git-download git-download.sh -o /usr/bin/git-download -f
```
