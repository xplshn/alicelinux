+++
date = '2025-01-13T20:01:45'
draft = false
title = 'install'
author = 'xplshn'
+++
## Install Alice
Here is a guide to installing Alice Linux on your computer using the chroot method. You can do this from your existing Linux distribution or from a live environment, such as Alice Live or another Linux distribution. Make sure your chosen environment has the necessary partitioning tools, filesystem tools, and extraction tools.

### Get Alice rootfs tarball
Download the Alice rootfs tarball from the [release](https://codeberg.org/emmett1/alicelinux/releases) page, along with its `sha256sum` file.
```
$ curl -O <url>
$ curl -O <url>.sha256sum
```
Verify the checksum of the Alice rootfs tarball:
```
$ sha256sum -c alicelinux-rootfs-20240525.tar.xz.sha256sum
```
Make sure it prints:
```
alicelinux-rootfs-20240525.tar.xz: OK
```

### Prepare the partition and filesystem
Prepare the partition and filesystem of your choice. In this guide, I will use ext4 as an example.
```
# cfdisk /dev/sdX
# mkfs.ext4 /dev/sdXY
```
Mount your created partition somewhere. In this guide, I will use /mnt/alice as the mount point.
```
# mkdir /mnt/alice
# mount /dev/sdXY /mnt/alice
```

### Extract the Alice rootfs tarball
Extract the Alice rootfs into the mounted partition.
```
$ tar xvf alicelinux-rootfs-*.tar.xz -C /mnt/alice
```

### Enter chroot
First, chroot into Alice. (Replace /mnt/alice with your chosen mount point.)
```
# /mnt/alice/usr/bin/apkg-chroot /mnt/alice
```
Any further commands after this will be executed inside the Alice environment. 

### Clone Alice repos
Fetch the Alice packages repositories somewhere. I'll fetch them inside the /var/lib directory to keep the system clean.
```
# cd /var/lib
# git clone --depth=1 https://codeberg.org/emmett1/alicelinux
```
Once we have the repositories cloned, we need to configure `apkg`. `apkg` is Alice's package build system (or package manager). By default, Alice does not provide an `apkg` config file (yes, `apkg` can work without a config file), but we need to create one. The `apkg` config file should be located at `/etc/apkg.conf` by default. Let's create one. 

### Configure apkg.conf

First, we set `CFLAGS` and `CXXFLAGS`. Alice base packages are built using `-O3 -march=x86-64 -pipe`. You can use these settings or change them to your preference.
```
# echo 'export CFLAGS="-O3 -march=x86-64 -pipe"' >> /etc/apkg.conf
```
And use whats in `CFLAGS` for `CXXFLAGS`.
```
# echo 'export CXXFLAGS="$CFLAGS"' >> /etc/apkg.conf
```
Next set `MAKEFLAGS`. I will use `6` for my `8 threads` machine.
```
# echo 'export MAKEFLAGS="-j6"' >> /etc/apkg.conf
```
I'm also going to set `NINJAJOBS` here. Without it, `ninja` will use all threads of your machine when compiling.
```
# echo 'export NINJAJOBS="6"' >> /etc/apkg.conf
```
Next, we need to set the package's build scripts path (I'll call it `package repos`) so `apkg` can find them. The `APKG_REPO` variable can accept multiple values for multiple `package repos`.

Alice provides four (4) `package repos` (at the time of this writing): `core`, `extra`, `xorg` and `wayland`. `core` contains all base packages, and `extra` includes other packages beyond the base. `xorg` and `wayland` contain packages for gui and their dependencies.

First, get the absolute path of the `package repos` where we cloned them. By the way, we are still inside the `/var/lib` directory where we cloned the repo.
>NOTE: USE TAB COMPLETION!
```
# realpath alicelinux/repos/core
/var/lib/alicelinux/repos/core
# realpath alicelinux/repos/extra
/var/lib/alicelinux/repos/extra
```
After we have the path of our `package repos`, add it to the `APKG_REPO` variable in `/etc/apkg.conf`.
```
# echo 'APKG_REPO="/var/lib/alicelinux/repos/core /var/lib/alicelinux/repos/extra"' >> /etc/apkg.conf
```
>NOTE: All repo paths must be declared in the APKG_REPO variable, seperated by a single space.
 
After setting up our `package repos`, make sure `apkg` can find the packages. We can use `apkg -s <pattern>` to search for packages.
```
# apkg -s sway
swayidle
swaybg
swaylock
sway
```
If the output appears, then we are good to go.

Next, we will set up directories for `packages`, `sources`, and `work`. By default, these directories are inside the package template, but we will change them to `/var/cache/pkg`, `/var/cache/src`, and `/var/cache/work` respectively. You can change these to any location where you want to store these files.

First, create the directories:
```
# mkdir -p /var/cache/pkg
# mkdir -p /var/cache/src
# mkdir -p /var/cache/work
```

Then add these paths to `/etc/apkg.conf`.
```
# echo 'APKG_PACKAGE_DIR=/var/cache/pkg' >> /etc/apkg.conf
# echo 'APKG_SOURCE_DIR=/var/cache/src' >> /etc/apkg.conf
# echo 'APKG_WORK_DIR=/var/cache/work' >> /etc/apkg.conf
```
### Full system upgrade/rebuild
On the first install, we should upgrade the system first.
> Use uppercase `U` for a system upgrade, and lowercase `u` to upgrade a specific package of your choice.
```
# apkg -U
```
If you changed `CFLAGS` and `CXXFLAGS` to something other than the default, it's a good time to perform a full rebuild first. In this case, you can skip upgrading the system because performing a full rebuild will already use the latest version in `package repos`.

> Add the `-f` flag to force rebuild of existing prebuilt package.
> `apkg -a` prints all installed packages on the system.
```
# apkg -u $(apkg -a)
```
### Install development packages
Before installing any additional packages, we need to install development packages.
```
# apkg -I meson cmake pkgconf libtool automake perl
```
### Install kernel
You can configure your own kernel from [kernel.org](https://kernel.org/) or use the one provided by Alice.
> The provided kernel will take a lot of time to compile because many options are enabled.

If you want to use Alice's kernel, just run:
```
# apkg -I linux
```
### Install firmware
If your hardware requires firmware, install it using:
```
# apkg -I linux-firmware linux-firmware-nvidia
```

### Install bootloader
In this guide, I'm going to use `grub` as the bootloader. Install `grub`:
```
# apkg -I grub
```
Then generate grub config:
```
# grub-install /dev/sdX
# grub-mkconfig -o /boot/grub/grub.cfg
```

### Hostname
Change `alice` to the hostname of your choice.
```
# echo alice > /etc/hostname
```

### Fstab
Change the partition and filesystem of your choice below:
```
# echo '/dev/sda1 swap swap defaults 0 1' >> /etc/fstab
# echo '/dev/sda2 / ext4 defaults 0 0' >> /etc/fstab
```
### Enable runit services
Alice uses busybox's `runit` as its main service manager. Enable the required services:
```
# ln -s /etc/sv/tty1 /var/service
# ln -s /etc/sv/tty2 /var/service
# ln -s /etc/sv/tty3 /var/service
```
I'm enabling 3 `tty` services. `tty` is required; without it, you won't be able to log in (or run any commands).
> The runit service directory is `/etc/sv`.
> Create a symlink from `/etc/sv/<service>` to `/var/service` to enable it; remove the symlink to disable it.

### Setup user and password
Add your user:
```
# adduser <user>
```
Add your user to the `wheel` group:
```
# adduser <user> wheel
```
You might need to add your user to the `input` and `video` groups to start the Wayland compositor later, and the `audio` group to have working audio:
```
# adduser <user> input
# adduser <user> video
# adduser <user> audio
```

### Root password
Set the password for the `root` user:
```
# passwd
```

### Networking
You might want to set up networking before rebooting. Use `wpa_supplicant` and `dhcpcd`.
```
# apkg -I wpa_supplicant dhcpcd
```
Configure your SSID:
```
# wpa_passphrase <YOUR SSID> <ITS PASSWORD> >> /etc/wpa_supplicant.conf
```
Enable the service:
```
# ln -s /etc/sv/wpa_supplicant /var/service
# ln -s /etc/sv/dhcpcd /var/service
```

### Timezone
Install `tzdata`:
```
# apkg -I tzdata
```
Then create a symlink for your timezone to `/etc/localtime`:
```
# ln -s /usr/share/zoneinfo/Asia/Kuala_Lumpur /etc/localtime
```
Alternatively, you can copy it and then uninstall `tzdata` to keep your installed packages minimal:
```
# cp /usr/share/zoneinfo/Asia/Kuala_Lumpur /etc/localtime
# apkg -r tzdata
```

### Reboot and enjoy!
Exit the chroot environment and unmount the Alice partition, then reboot:
```
# exit
# umount /mnt/alice
# reboot
```

## Some important notes
- `Alice` uses `spm` and `apkg` as its package manager and package build system. Run with the `-h` flag to see available options.
- Additional scripts are provided with the name `apkg-<script>` which will be added (or removed) from time to time.
- Use `revdep` to scan for broken libraries and binaries after system upgrades and package removals. You can use `revdep -v` to print out missing required libraries, and use `apkg -f -u $(revdep)` to scan and rebuild broken packages.
- Run `updateconf` to update config files in `/etc` after package upgrades.
