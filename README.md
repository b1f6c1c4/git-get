# `git-get`: Blazingly fast `git clone`

[![Test Status](https://travis-ci.com/b1f6c1c4/git-get.svg?branch=master)](https://travis-ci.com/b1f6c1c4/git-get)

## TL;DR

```bash
git get <url> -t
# is 1x~10000x faster than:
#     git clone <url> repo
#     git -C repo rev-parse HEAD > repo/VERSION
#     rm -rf repo/.git

git get <url> -o <target> -- <file>
# is 1x~1000000x faster than:
#     git clone <url> repo
#     git -C repo submodule update --init --recursive
#     cp repo/<file> <target> && rm -rf repo

git get <url> <commit> -- <file>
# is 1x~1000000000x faster than:
#     git clone --mirror <url> repo
#     git -C repo switch --detach <commit>
#     rm -rf repo/.git

git gets <url> <commit> -P
# is 1x~10000000x faster than:
#     git clone --mirror <url> repo
#     git -C repo switch --detach <commit>
#     git -C repo submodule update --init --recursive

git gets <url> <commit> -P --flat
# is 1x~10000000x faster than:
#     git clone --mirror <url> repo
#     git -C repo switch --detach <commit>
#     git -C repo submodule update --init --recursive
#     rm -rf repo/**/.git
```

## Why we need it, and why is it so fast?

### A brief but lengthened story of `git clone` performance

So many times we want to download something hosted on GitHub.
What we actually want is a complete working copy of the code and configurations,
without any development history or irrelavent informations.
Once upon a time, there were only two ways to retrieve data from git/GitHub:

1. Simply call `git clone`.
Well, by default `git` downloads the entire development history.
Some huge projects can have 100,000 commits, each with 1GiB files.
Even though there are some duplicated files that saves some space,
this is **totally undesirable unless you are one of the developer**.

1. On GitHub, click `Clone or download`/`Download ZIP`.
OK, now we only have what we want downloaded.
But is that complete? What about `git submodule`s?
Some huge projects can have more than 30 nested submodules.
Are you willing to download one by another with your own hands?
This is **only applicable if there is no or very few submodules**.

1. On GitHub, click `Raw` button when displaying a file.
OK, but it only works for a single file.
Are you willing to download one by another with your own hands?
This is **only applicable if you need up to a few files**.

Some time later, `git` has improved.

1. We now have `git clone --depth=1`: to clone the very first commit of a branch.
But some problems also arose:
We cannot get a specific commit buried inside the development history.
This may not be a problem for big matured project where there
people only need to look for its tags and branches.
However, we frequently need to retrieve a specified version of a repo,
especially when we are using `git submodule`.
Long words short, `--depth=1` works well for the parent repo,
but dysfunctions so frequently when working with submodules.

And even later, in 2018, `git` improved again.

1. We now have `git clone --filter tree:0`: to clone commits eagerly but files lazily.
That's a great improvement!
But GitHub hadn't been offering support for `--filter` until 2019.
So, now, we have all the tools necessary to download whatever you what from GitHub!

### Benefits of using `git-get`

1. It leverages both `--depth` and `--filter` to save bandwidth.
Only the files you actually want (that commit that file) are downloaded.
No entire development history.
No entire repository folder.
Remember, this applies to the parent repo as well as all sub repos.
1. It handles `git submodule`s very well.
Just tell `git-get` the path of your file with respect to the parent repo.
`git-get` will recursively scan through the submodule chain and grab the file for you.
1. It handles optional dependencies also pretty well:
Some project specifies optional dependencies as submodules.
If you want to download some submodules but not the others,
just add `-c|--confirm` to `git-gets` and you can
interactively choose which dependency you want to install.

## Usage

The CLI is pretty self-explanatory:

```bash
git get [-v|--verbose|-q|--quiet]
    <url> | <user>/<repo> [<branch>|<sha1>]
    [-o <target> |--output=<target>] [-f|--force] [-F|--rm-rf]
    [--preserve-git | [-t [--tag-file=VERSION]] [-- <path>]]

git gets [-v|--verbose|-q|--quiet]
    <url> | <user>/<repo> [<branch>|<sha1>]
    [[-o|--output] <target>] [-F|--rm-rf]
    [--flat [--tag-file=VERSION]] [-P|--parallel] [-c|--confirm]
```

Some comments:

* `-t|--tag` and `--tag-file`:
Tag file is a file, usually named `VERSION`, that is put
along side with your downloaded file or inside your downloaded directory.
It records the SHA-1 of the commit you downloaded it from.
Without this file and without `.git` repo,
others will lose track of where the code came from.

* `-o|--output=<target>`, `-f|--force` and `-F|--rm-rf`:
If you downloaded a file/directory and `<target>` is a file,
you may override the file with `-f|--force`.
If you downloaded a file and `<target>` is a directory,
the file is put into the directory.
If you downloaded a directory and `<target>` is a directory,
you may override the directory with `-F|--rm-rf`.
In no case will a directory be put into an existing directory.

* `--preserve-git` and `--flat`:
In `git-get`, `.git` is removed by default. You can override this with `--preserve-git`.
In `git-gets`, `.git` is kept by default. You can override this with `--flat`.

## Install

We recommend that you download the two scripts directly:
```bash
curl -fsSL https://raw.githubusercontent.com/b1f6c1c4/git-get/master/git-get | sudo tee /usr/bin/git-get > /dev/null && sudo chmod 755 /usr/bin/git-get
curl -fsSL https://raw.githubusercontent.com/b1f6c1c4/git-get/master/git-gets | sudo tee /usr/bin/git-gets > /dev/null && sudo chmod 755 /usr/bin/git-gets
# Or, locally:
mkdir -p ~/.local/bin/
curl -fsSL https://raw.githubusercontent.com/b1f6c1c4/git-get/master/git-get | tee ~/.local/bin/git-get > /dev/null && sudo chmod 755 ~/.local/bin/git-get
curl -fsSL https://raw.githubusercontent.com/b1f6c1c4/git-get/master/git-gets | tee ~/.local/bin/git-gets > /dev/null && sudo chmod 755 ~/.local/bin/git-gets
```

You DO NOT need to setup `git config alias.get '!git-get'`.
In fact, git is so smart that, as long as `git-get` is in `PATH`, `git <xyz>` will be interpreted as `git-<xyz>`.

Upgrading:
```bash
git-get -o- b1f6c1c4/git-get -- git-get | sudo tee /usr/bin/git-get >/dev/null
git-get -o- b1f6c1c4/git-get -- git-gets | sudo tee /usr/bin/git-gets >/dev/null
# Or, locally:
git-get -f -o ~/.local/bin/ b1f6c1c4/git-get -- git-get
git-get -f -o ~/.local/bin/ b1f6c1c4/git-get -- git-gets
```

## Requirements

* `Linux`
* `git` **2.20+**, the newer the better
* `bash`

## License

MIT
