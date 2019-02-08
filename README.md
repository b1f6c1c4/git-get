# git-download

:heavy_exclamation_mark:
This project is designed to be bullshit-free,
but unfortunately it's full of bullshit now.
:heavy_exclamation_mark:

```bash
git-download
    [-v|--verbose|-q|--quiet]
    [https://github.com/]<user>/<repo>
    [<branch>|<sha1>]
    [-o <target> [-f|--force] [-F|--rm-rf]]
    [-r|--recursive] [--] [<path>]
```

> Download file/folder from any Git host. Bullshit-free.

## Install

Currently only supports bash.

```bash
wget -qO- https://raw.githubusercontent.com/b1f6c1c4/git-download/master/git-download.sh | sudo tee /usr/bin/git-download > /dev/null && sudo chmod 755 /usr/bin/git-download
```

## License

MIT
