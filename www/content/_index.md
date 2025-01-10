---
title: Home
---

![alicelinux](assets/AliceLinux.png)
![alicelinux](assets/grimshot-240524-234840.png)

**Alice Linux** is my personal daily driver minimal distro that used [musl](https://musl.libc.org/) libc, [busybox](https://www.busybox.net/) as main core utilities, package manager written in POSIX shell script, [Wayland](https://wayland.freedesktop.org/) and/or [Xorg](https://www.x.org/wiki/) as the gui server and trying to be minimal, lightweight and usable as possible.

- no systemd
- no PAM
- no polkit
- musl instead of glibc
- busybox instead of coreutils/util-linux/etc
- busybox's runit instead of systemd/openrc/etc
- libudev-zero instead of udev/eudev
- gettext-tiny instead of gettext
- mandoc instead of man-db
- doas instead of sudo
