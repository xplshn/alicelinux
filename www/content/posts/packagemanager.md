+++
date = '2025-01-13T22:50:11'
draft = false
title = 'packagemanager'
author = '[CI]'
+++
PACKAGE MANAGER
===============

In Alice, theres two package manager used, [spm](https://codeberg.org/emmett1/spm) and [autils](https://codeberg.org/emmett1/autils). Why two package manager? `spm` was written for generic package manager for linux distribution. And `autils` is written specifically for `Alice` and required `spm`.

spm
---

`spm` stands for `simple package manager`. It does simple and minimal written in POSIX compliance shell script. It only depends on core utils and tar (or busybox's utils and tar). `spm` only intended for compressing some directory into package, then extract package into system with files being tracked into database. Theres is no build script, recipe or ports in `spm`. You can write your own tools to use with `spm` either like Arch Linux's `makepkg`, CRUX's `pkgmk` or Slackware's `slackbuild` script.

spm - usage
-----------

```
  -a         print all installed packages
  -b <path>  build <path> directory into package
  -h         print this help message
  -i <file>  install <file> package into system
  -l <pkg>   list files installed by <pkg>
  -o <file>  print owner of <file>
  -r <name>  remove installed <name> from system
  -u <pkg>   re-install/upgrade <pkg>
```

- list all install package with version
```
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

- build package from directory
```
(build package)
$ ./configure --prefix=/usr
$ make

(install into fake directory)
$ make DESTDIR=$PWD/fakeroot install

(turn fake directory into package (package.spm))
# spm -b $PWD/fakeroot 

(mv 'package.spm' into correct format (name#version-release.spm))
# mv package.spm pkgname#pkgversion-pkgrelease.spm

(install package into system)
# spm -i pkgname#pkgversion-pkgrelease.spm
```

- install package into system
```
# spm -i pkgname#pkgversion-pkgrelease.spm
[pkgname] Verify package...
[pkgname] Checking for conflicts...
[pkgname] Installing package...
[pkgname] Package 'pkgname#pkgversion-pkgrelease' installed.
```

- list files installed by 'packagename'
```
$ spm -l test
usr/
usr/share/
usr/share/aaa
usr/bin/
usr/bin/aaa
```

- list package owner of a file (can use regex)
```
$ spm -o gcc$
ccache usr/lib/ccache/gcc
gcc usr/bin/gcc
gcc usr/bin/x86_64-pc-linux-musl-gcc
linux lib/modules/6.6.41-Alice/build/scripts/dummy-tools/gcc
```

- upgrade/reinstall installed package
```
# spm -u pkgname#pkgversion-pkgrelease.spm
[pkgname] Verify package...
[pkgname] Checking for conflicts...
[pkgname] Upgrading package...
[pkgname] Package 'pkgname#pkgversion-pkgrelease' upgraded.
```

spm - environment
-----------------

|env|description|
|-|-|
|SPM_ROOT|use custom root location for package installation|
|SPM_FORCEINSTALL|set any value to ignore conflicted files|

You can pass these environment to `spm` command, example:
```
# SPM_ROOT=/mnt/rootfs spm -i pkgname#pkgversion-pkgrelease.spm
# SPM_FORCEINSTALL=1 SPM_ROOT=/mnt/rootfs spm -i pkgname#pkgversion-pkgrelease.spm
```

autils
------

`autils` stands for `alice utilitis`. `autils` contains main package manager (apkg), utilities (apkg-<util>) and <random util script>. `autils` is specifically written to manage `Alice` packages.

apkg
----

`apkg` is a main package manager that can solve dependencies, batch install/upgrade/remove packages, system upgrades, trigger necessary caches, and etc. `apkg` can be run inside or outside package template.

When running outside package template, `apkg` will need 'package names' as arguments, and those 'package names' will search through `APKG_REPO` environment. Example:

```
# apkg testpkg testpkg2 (build testpkg and testpkg2)
# apkg testpkg testpkg2 -i (build and install testpkg and testpkg2)
# apkg -u testpkg testpkg2 (upgrade/reinstall testpkg and testpkg2)
# apkg -f -u testpkg testpkg2 (force rebuild then upgrade/reinstall testpkg and testpkg2)
```

When running inside package template, `apkg` will do operation for current directory package. Example:

```
# cd /path/to/local/testpkg
# apkg (build testpkg)
# apkg -i (build and install testpkg)
# apkg -u (upgrade/reinstall testpkg)
# apkg -u -f (force rebuild then upgrade/reinstall testpkg)

```

apkg - usage
------------

```
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

I won't explain details on every each options here, but I will give quick tips/tricks to use `apkg`

- installing package and its dependencies (mind the uppercase `i`)
```
# apkg -I sway
[...] Solving dependencies...
[...] Installing 3 package(s):  mesa pango sway
[...] Press ENTER to continue operation.
[...] Press Ctrl + C to abort.
```

- search available packages
```
$ apkg -s sway
swaybg
swaylock
sway
swayidle
swayfx
```

- install all package with 'sway' name and its dependencies
```
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

- install package without solving dependencies (mind the lowercase `i` and theres no prompt for this option)
```
# apkg -i wlroots mesa
[...] Package 'wlroots' already installed.
[...] Package 'mesa' already installed.
```

- list all installed packages
```
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

- list all installed packages with filter (will only print installed package contains word filter)
```
$ apkg -a sway
swaybg
swayfx
swayidle
swaylock
```

- list dependencies of a package
```
$ apkg -d sway
wlroots
json-c
pango
```

- list all dependencies tree of package(s)
```
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

- upgrade/reinstall packages
```
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

- full system upgrades (mind uppercase `u` and will prompt first if theres package updates)
```
# apkg -U
[...] Checking for outdated packages...
[...] Solving dependencies...
[...] Upgrading 3 package(s):  initscripts mesa sowm
[...] Press ENTER to continue operation.
[...] Press Ctrl + C to abort.
```

- make full system rebuild in dependencies order (`-f`: force rebuild, `-u`: upgrade/reinstall, `-D`: solve dependency order, `-a`: list all installed package)
```
# apkg -f -u $(apkg -D $(apkg -a))
...
(start rebuilding package here)
...
```

- remove installed packages
```
# apkg -r wlroots pango sway
[...] Package 'wlroots' removed.
[...] Package 'pango' removed.
[...] Package 'sway' removed.

```

- print package path
```
$ apkg -p sway
/home/emmett/codeberg/alicelinux/repos/wayland/sway
```

apkg - environment
------------------

You can pass environment to `apkg` to override defaults and in `/etc/apkg.conf`. Available environment and its default value as follows:

---
|env|default value|description|
|-|-|-|
|APKG_ROOT|/|root for package installation|
|APKG_CONF|/etc/apkg.conf|apkg's config file|
|APKG_REPO| |defaults is empty, template repo path, space separated variable|
|APKG_PACKAGE_DIR|$PWD|prebuilt package directory path|
|APKG_SOURCE_DIR|$PWD|package source directory path|
|APKG_WORK_DIR|$PWD|package working directory path|
|APKG_NOPROMPT| |skip prompt, use any value|

You can add these environment into `apkg` config file.

apkg - config file
------------------

`apkg` can work without its config file by using all default value. Default config path for `apkg` is `/etc/apkg.conf`. You can change config path by append `APKG_CONF` to `apkg`, example:
```
# APKG_CONF=/etc/apkg-local.conf apkg <args>
```

revdep
------

`revdep` is script to find broken packages. Its recomended to run after packages is removed or upgraded.

Usage:
```
(print out broken packages)
$ revdep

(verbosely print missing libraries)
$ revdep -v
```

You can combine with `apkg` to rebuild broken packages, example;
```
# apkg -f -u $(revdep)
```
> NOTE: `revdep` does not solve dependencies, so you might need manually rebuild broken packages instead combine with `apkg`.

updateconf
----------

`updateconf` is script to update configuration files inside `/etc` directory. Its recomended to run after packages upgrades.

apkg-chroot
-----------
Script to entering chroot environment of custom root location.

```
# apkg-chroot <customroot path>
# apkg-chroot <customroot path> <command>
```

apkg-clean
----------
Print out old package and source caches.

Options:
```
  -s  print sources only
  -p  print packages only
```

Usage:
```
(to remove old packages)
# apkg-clean -p | xargs rm

(to remove old sources)
# apkg-clean -s | xargs rm

(to remove both old packages and sources)
# apkg-clean | xargs rm
```

apkg-deps
---------

Script to find runtime linked dependencies of installed package. Its good to use when writing package template.

Usage:
```
$ apkg-deps <pkg>
```

apkg-foreign
------------

Script to list installed package outside package repo.

Usage:
```
(print list foreign packages)
$ apkg-foreign

(remove foreign packages)
# apkg -r $(apkg-foreign)
```

apkg-orphan
-----------

Script to print list package without parent dependencies.

Usage:
```
$ apkg-orphan
```

apkg-redundantdeps
------------------

Script to print package's redundant dependencies. Its good to use when writing package template for minimizing dependencies and speed up `apkg` dependencies solving.

usage:
```
(print package contains redundant dependencies)
$ apkg-redundantdeps

(remove redundant dependencies for depends list)
$ apkg-redundantdeps -f
```
