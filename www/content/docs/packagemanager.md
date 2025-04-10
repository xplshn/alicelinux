+++
date = '2025-04-10T04:21:46'
draft = false
title = 'packagemanager.md'
[params.author]
  name = '󰬭 [CI] '
  email = 'action@github.com'
+++
# Package Manager

In Alice, there are two package managers used: [spm](https://codeberg.org/emmett1/spm) and [autils](https://codeberg.org/emmett1/autils). Why two package managers? `spm` was written as a generic package manager for Linux distributions. `autils` is written specifically for `Alice` and requires `spm`.

## spm

`spm` stands for `simple package manager`. It is simple and minimal, written in POSIX-compliant shell script. It only depends on core utils and tar (or busybox's utils and tar). `spm` is intended for compressing a directory into a package and then extracting the package into the system with files being tracked into a database. There is no build script, recipe, or ports in `spm`. You can write your own tools to use with `spm`, similar to Arch Linux's `makepkg`, CRUX's `pkgmk`, or Slackware's `slackbuild` script.

### spm - usage

List `spm` usage:

```sh
-a         print all installed packages
-b <path>  build <path> directory into package
-h         print this help message
-i <file>  install <file> package into system
-l <pkg>   list files installed by <pkg>
-o <file>  print owner of <file>
-r <name>  remove installed <name> from system
-u <pkg>   re-install/upgrade <pkg>
```

List all installed packages with version:

```sh
$ spm -a
...
neofetch 7.1.0-1
nettle 3.10-1
nghttp2 1.62.1-1
ninja 1.12.1-1
nodejs 22.5.1-1
nspr 4.35-1
nss 3.102.1-1
nsxiv 32-1
...
```

Build package from directory:

```sh
# (build package)
$ ./configure --prefix=/usr
$ make

# (install into fake directory)
$ make DESTDIR=$PWD/fakeroot install

# (turn fake directory into package (package.spm))
# spm -b $PWD/fakeroot

# (mv 'package.spm' into correct format (name#version-release.spm))
# mv package.spm pkgname#pkgversion-pkgrelease.spm

# (install package into system)
# spm -i pkgname#pkgversion-pkgrelease.spm
```

Install package into system:

```sh
# spm -i pkgname#pkgversion-pkgrelease.spm
[pkgname] Verify package...
[pkgname] Checking for conflicts...
[pkgname] Installing package...
[pkgname] Package 'pkgname#pkgversion-pkgrelease' installed.
```

List files installed by 'packagename':

```sh
$ spm -l test
usr/
usr/share/
usr/share/aaa
usr/bin/
usr/bin/aaa
```

List package owner of a file (can use regex):

```sh
$ spm -o gcc$
ccache usr/lib/ccache/gcc
gcc usr/bin/gcc
gcc usr/bin/x86_64-pc-linux-musl-gcc
linux lib/modules/6.6.41-Alice/build/scripts/dummy-tools/gcc
```

Upgrade/reinstall installed package:

```sh
# spm -u pkgname#pkgversion-pkgrelease.spm
[pkgname] Verify package...
[pkgname] Checking for conflicts...
[pkgname] Upgrading package...
[pkgname] Package 'pkgname#pkgversion-pkgrelease' upgraded.
```

### spm - environment

| env              | description                               |
|------------------|-------------------------------------------|
| SPM_ROOT         | use custom root location for package installation |
| SPM_FORCEINSTALL | set any value to ignore conflicted files |

You can pass these environment variables to the `spm` command, for example:

```sh
# SPM_ROOT=/mnt/rootfs spm -i pkgname#pkgversion-pkgrelease.spm
# SPM_FORCEINSTALL=1 SPM_ROOT=/mnt/rootfs spm -i pkgname#pkgversion-pkgrelease.spm
```

## autils

`autils` stands for `alice utilities`. `autils` contains the main package manager (apkg), utilities (apkg-<util>), and various utility scripts. `autils` is specifically written to manage `Alice` packages.

### apkg

`apkg` is the main package manager that can solve dependencies, batch install/upgrade/remove packages, perform system upgrades, trigger necessary caches, and more. `apkg` can be run inside or outside a package template.

When running outside a package template, `apkg` will need 'package names' as arguments, and those 'package names' will be searched through the `APKG_REPO` environment variable. Example:

```sh
# apkg testpkg testpkg2 (build testpkg and testpkg2)
# apkg testpkg testpkg2 -i (build and install testpkg and testpkg2)
# apkg -u testpkg testpkg2 (upgrade/reinstall testpkg and testpkg2)
# apkg -f -u testpkg testpkg2 (force rebuild then upgrade/reinstall testpkg and testpkg2)
```

When running inside a package template, `apkg` will perform the operation for the current directory's package. Example:

```sh
# cd /path/to/local/testpkg
# apkg (build testpkg)
# apkg -i (build and install testpkg)
# apkg -u (upgrade/reinstall testpkg)
# apkg -u -f (force rebuild then upgrade/reinstall testpkg)
```

### apkg - usage

```sh
-i <pkg(s)>  install package(s)
-I <pkg(s)>  install packages(s) with dependencies
-d <pkg>     list <pkg> dependencies
-D <pkg(s)>  list all dependencies
-j <pkg>     list all dependents
-u <pkg(s)>  upgrade package(s)
-t [pkg(s)]  trigger system cache/db updates
-U           update system
-f           force rebuild
-o <pkg(s)>  download source
-p <pkg>     print package path
-s <pattern> search packages
-h           print this help message
```

I won't explain the details of every option here, but I will give some quick tips/tricks to use `apkg`.

Install a package and its dependencies (mind the uppercase `I`):

```sh
# apkg -I sway
[...] Solving dependencies...
[...] Installing 3 package(s):  mesa pango sway
[...] Press ENTER to continue operation.
[...] Press Ctrl + C to abort.
```

Search available packages:

```sh
$ apkg -s sway
swaybg
swaylock
sway
swayidle
swayfx
```

Install all packages with 'sway' in their name and their dependencies:

```sh
# apkg -I $(apkg -s sway)
...
[...] Package 'mesa' is installed
[...] Package 'swaybg' is installed
[...] Package 'swaylock' is installed
[...] Package 'swayidle' is installed
[...] Package 'swayfx' is installed
[...] Solving dependencies...
[...] Installing 2 package(s):  pango sway
[...] Press ENTER to continue operation.
[...] Press Ctrl + C to abort.
```

Install a package without solving dependencies (mind the lowercase `i` and there is no prompt for this option):

```sh
# apkg -i wlroots mesa
[...] Package 'wlroots' already installed.
[...] Package 'mesa' already installed.
```

List all installed packages:

```sh
$ apkg -a
...
qemu
ranger
rdfind
readline
rsync
rtorrent
rust
...
```

List all installed packages with a filter (will only print installed packages containing the word filter):

```sh
$ apkg -a sway
swaybg
swayfx
swayidle
swaylock
```

List dependencies of a package:

```sh
$ apkg -d sway
wlroots
json-c
pango
```

List all dependencies tree of package(s):

```sh
$ apkg -D sway dwm
...
wayland
wayland-protocols
xkeyboard-config
xcb-proto
xorgproto
util-macros
...
```

Upgrade/reinstall package(s):

```sh
# apkg -u wlroots cwm pango
[wlroots] Verify package...
[wlroots] Checking for conflicts...
[wlroots] Upgrading package...
[wlroots] Package 'wlroots#0.17.4-1' upgraded.
[cwm] Verify package...
[cwm] Checking for conflicts...
[cwm] Upgrading package...
[cwm] Package 'cwm#7.4-1' upgraded.
[pango] Verify package...
[pango] Checking for conflicts...
[pango] Upgrading package...
[pango] Package 'pango#1.54.0-1' upgraded.
```

Full system upgrade (mind uppercase `U` and will prompt first if there are package updates):

```sh
# apkg -U
[...] Checking for outdated packages...
[...] Solving dependencies...
[...] Upgrading 3 package(s):  initscripts mesa sowm
[...] Press ENTER to continue operation.
[...] Press Ctrl + C to abort.
```

Make a full system rebuild in dependencies order (`-f`: force rebuild, `-u`: upgrade/reinstall, `-D`: solve dependency order, `-a`: list all installed package(s)):

```sh
# apkg -f -u $(apkg -D $(apkg -a))
...
(start rebuilding packages in dependencies order here)
...
```

Remove installed packages:

```sh
# apkg -r wlroots pango sway
[...] Package 'wlroots' removed.
[...] Package 'pango' removed.
[...] Package 'sway' removed.
```

Print package path:

```sh
$ apkg -p sway
/home/emmett/codeberg/alicelinux/repos/wayland/sway
```

### apkg - environment

You can pass environment variables to `apkg` to override defaults and in `/etc/apkg.conf`. Available environment variables and their default values are as follows:

| env                | default value | description                                   |
|--------------------|---------------|-----------------------------------------------|
| APKG_ROOT          | /             | root for package installation                |
| APKG_CONF          | /etc/apkg.conf| apkg's config file                           |
| APKG_REPO          |               | defaults is empty, template repo path, space separated variable |
| APKG_PACKAGE_DIR   | $PWD          | prebuilt package directory path              |
| APKG_SOURCE_DIR    | $PWD          | package source directory path                |
| APKG_WORK_DIR      | $PWD          | package working directory path               |
| APKG_NOPROMPT      |               | skip prompt, use any value                   |

You can add these environment variables into the `apkg` config file.

### /etc/apkg.conf

`apkg` can work without its config file by using all default values. The default config path for `apkg` is `/etc/apkg.conf`. You can override the config path by appending `APKG_CONF` to `apkg`, for example:

```sh
# APKG_CONF=/etc/apkg-local.conf apkg <args>
```

### revdep

`revdep` is a script to find broken packages. It is recommended to run it after packages are removed or upgraded.

Usage:

```sh
# (print out broken packages)
$ revdep

# (verbosely print missing libraries)
$ revdep -v
```

You can combine it with `apkg` to rebuild broken packages, for example:

```sh
# apkg -f -u $(revdep)
```

> NOTE: `revdep` does not solve dependencies, so you might need to manually rebuild broken packages instead of combining it with `apkg`.

### updateconf

`updateconf` is a script to update configuration files inside the `/etc` directory. It is recommended to run it after package upgrades.

### apkg-chroot

Script to enter the chroot environment of a custom root location.

```sh
# apkg-chroot <customroot path>
# apkg-chroot <customroot path> <command>
```

### apkg-clean

Print out old package and source caches.

Options:

```sh
-s  print sources only
-p  print packages only
```

Usage:

```sh
# (to remove old packages)
# apkg-clean -p | xargs rm

# (to remove old sources)
# apkg-clean -s | xargs rm

# (to remove both old packages and sources)
# apkg-clean | xargs rm
```

### apkg-deps

Script to find runtime linked dependencies of an installed package. It is good for figuring out dependencies when writing a package template.

Usage:

```sh
$ apkg-deps <pkg>
```

### apkg-foreign

Script to list installed packages outside the package repo.

Usage:

```sh
# (print list of foreign packages)
$ apkg-foreign

# (remove foreign packages)
# apkg -r $(apkg-foreign)
```

### apkg-orphan

Script to print a list of packages without parent dependencies.

Usage:

```sh
$ apkg-orphan
```

### apkg-redundantdeps

Script to print a package's redundant dependencies. It is good to use when writing a package template for minimizing dependencies and speeding up `apkg` dependencies solving.

Usage:

```sh
# (print packages containing redundant dependencies)
$ apkg-redundantdeps

# (remove redundant dependencies for depends list)
$ apkg-redundantdeps -f
```
