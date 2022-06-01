# `git-get`: Blazingly fast, incredibly handy `git clone`

[![Test Status](https://ci.appveyor.com/api/projects/status/32r7s2skrgm9ubva?svg=true)](https://ci.appveyor.com/project/b1f6c1c4/git-get/branch/master)

## TL;DR

- Download a file:
    ```bash
    # Method 1: Paste the original URL into the terminal:
    git get https://github.com/b1f6c1c4/git-get/blob/master/README.md
    # Method 2: Of course, a full URL is acceptable:
    git get git@github.com:b1f6c1c4/git-get -- README.md
    # Method 3a: Type a few words in the terminal:
    git get b1f6c1c4/git-get -- README.md
    # Method 3b: If the above doesn't work because of SSH, use HTTPS:
    git get -H b1f6c1c4/git-get -- README.md
    ```
- Download a folder:
    ```bash
    # The same as before:
    git get https://github.com/b1f6c1c4/git-get/tree/master/tests
    git get b1f6c1c4/git-get -- tests
    # Optionally, you may want a VERSION file to record the commit SHA1:
    git get -t ...
    ```
- Download a repo/branch/tag/commit:
    ```bash
    # Also the same:
    git get https://github.com/b1f6c1c4/git-get
    git get https://github.com/b1f6c1c4/git-get/tree/example-repo2
    git get https://github.com/b1f6c1c4/git-get/commit/2dd50b6
    git get b1f6c1c4/git-get
    git get b1f6c1c4/git-get example-repo2
    git get b1f6c1c4/git-get 2dd50b6
    # You may wonder where did the .git go.
    # We automatically 'rm -rf .git' for you because in 95% of the cases
    # you won't even look at it. But if you really want your .git back:
    git get -x ...
    ```
- Download a file/folder of a branch/tag/commit:
    ```bash
    # Combine what you've learned before:
    git get https://github.com/b1f6c1c4/git-get/blob/example-repo2/file
    git get https://github.com/b1f6c1c4/git-get/tree/example-repo2/dir
    git get b1f6c1c4/git-get example-repo2 -- file
    git get b1f6c1c4/git-get example-repo2 -- dir
    # You *cannot* do -x and -t at the same time:
    # git get -xt ... # Error!!!
    ```
- Download a repo and submodules:
    ```bash
    # Just a tiny tiny change:
    git gets https://github.com/b1f6c1c4/git-get
    git gets b1f6c1c4/git-get
    # If you want it to be even faster:
    git gets -P ...
    # If you want to make changes and push back:
    git gets -x ...
    ```
- You already have a repo, and you want its submodules:
    ```bash
    git gets              # Just give me all
    git gets -c           # Let me choose
    git gets --no-init    # Only those with 'git submodule init ...'
    ```

## Performance

```bash
git get <url> -t
# is 1x~10000x faster than:
#     git clone <url> repo
#     git -C repo rev-parse HEAD > repo/VERSION
#     rm -rf repo/.git

git get <url> -o <output-file> -- <file>
# is 1x~1000000x faster than:
#     git clone <url> repo
#     git -C repo submodule update --init --recursive
#     cp repo/<file> <output-file> && rm -rf repo

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
#     rm -rf repo/**/.git

# If you already have a repo and want to inflate all its submodules:
git gets
# is 1x~10000000x faster than (and 8x shorter to type):
#     git submodule update --init --recursive
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

## Basic Usage

The CLI is pretty self-explanatory:

```bash
# There are multiple ways to specify what you want to download:
<specifier> :=
    <full-url-to-git-location>
    | <user>/<repo> [<branch>|<sha1>]
    | https://github.com/<user>/<repo>/
    | https://github.com/<user>/<repo>/commit/<commitish>
    | https://github.com/<user>/<repo>/tree/<commitish>[/<path>]
    | https://github.com/<user>/<repo>/blob/<commitish>[/<path>]

# Download a single repo (or part of):
git-get [-v|--verbose|-q|--quiet] [-H|--https]
    <specifier> [-o <target>] [-f|--force] [-F|--rm-rf]
    (-x | [-t|--tag] [-- <path>])

# Download a repo and its submodules:
git gets [-v|--verbose|-q|--quiet] [-H|--https] [--no-recursive]
    [-P|--parallel] [-c|--confirm]
    <specifier> [-o <target>] [-F|--rm-rf]
    (-x | [-t|--tag])

# Download submodules of an existing repo:
git gets [-v|--verbose|-q|--quiet] [-H|--https] [--no-recursive]
    [-P|--parallel] [-c|--confirm] [--no-init]
```

Some comments:

* `-H|--https`:
Use HTTPS instead of SSH when accesssing github.com and gist.github.com
in the case when you don't have a ready-to-use SSH set-up.

* `--no-recursive` and `--no-init`:
The former one means that only *top-level* submodules are downloaded.
The latter one means that you need to manually initialize *top-level* submodules.
Both switches apply solely to top-level submodules.
If you don't want to download any submodule, simply use `git get` instead of `git gets`.
Finer control is feasible using `--confirm`.

* `-f|--force` and `-F|--rm-rf`:
Override existing file with `-f|--force`.
Override existing directory with `-F|--rm-rf`.

* `-x`:
`-x` will keep the `.git` so you can make changes.
The repository is NOT 100% the same as a regular `git-clone`'d one.
To take a deeper look at the difference, please read the following reference:
[git partial clone](https://git-scm.com/docs/partial-clone).
You cannot use it together with `-t|--tag`.

* `-t|--tag`:
Instead of keeping a respository, generate a single file called `VERSION`
that contains the SHA-1 of the commit you accessed.
Put it along side with your downloaded file or inside your downloaded directory
so you will know from where the file/dir is obtained.
You cannot use it together with `-x`.

Not all options are shown here.
For additional ones, refer to `man git-get` and `man git-gets`.

## Install and Upgrade

(The upgrading process and install process are identical.)

- Arch Linux

    It's on [AUR](https://aur.archlinux.org/packages/git-get):
    ```bash
    yay install git-get
    rua install git-get
    ...
    ```

- Linux but not Arch Linux

    We recommend that you download the latest release and untar the files:
    ```bash
    # Install git-get(1) globally:
    curl -fsSL https://github.com/b1f6c1c4/git-get/releases/latest/download/git-get.tar.xz | sudo tar -C /usr -xJv
    # Or, locally:
    mkdir -p ~/.local/
    curl -fsSL https://github.com/b1f6c1c4/git-get/releases/latest/download/git-get.tar.xz | tar -C ~/.local/ -xJv
    ```

- MacOS

    ```bash
    # Install dependencies, including realpath(1):
    brew install coreutils
    # Install git-get(1) globally:
    curl -fsSL https://github.com/b1f6c1c4/git-get/releases/latest/download/git-get.tar.xz | sudo tar -C /usr/local -xJv
    # Or, locally:
    mkdir -p ~/.local/bin/
    curl -fsSL https://github.com/b1f6c1c4/git-get/releases/latest/download/git-get.tar.xz | tar -C ~/.local/ -xJv
    ```

- Windows

    Similar as above, but you need to manually download the two files [git-get](https://github.com/b1f6c1c4/git-get/blob/master/git-get) and [git-gets](https://github.com/b1f6c1c4/git-get/blob/master/git-gets) and put it in `PATH`. As for the documentation, you will need to browse it online.

You DO NOT need to setup `git config alias.get '!git-get'`.
In fact, git is so smart that, as long as `git-get` is in `PATH`, `git <xyz>` will be interpreted as `git-<xyz>`.

## Requirements

* `bash`, can be `GNU bash` on Linux / MacOS, or `Git bash` on Windows
* `git` **2.20+**, the newer the better
* `awk`, `sed`, and `grep`
    * On Linux: You should already have them installed.
    * On MacOS: You should already have them installed.
    * On Windows:
        ```bash
        choco install grep awk sed
        ```

## License

MIT
