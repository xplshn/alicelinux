## Install Alice
Here is guide to install Alice Linux into your computer by using chroot method from your existing installed Linux distribution or either from live environment of ALice live or other Linux distributions. Your choice should have all partitioning, filesystem of your choice and extracting tools.

### Get Alice rootfs tarball
Download Alice rootfs tarball from [release](https://codeberg.org/emmett1/alicelinux/releases) page along with its `sha256sum` file.
```
$ curl -O <url>
$ curl -O <url>.sha256sum
```
Verify checksum of Alice rootfs tarball:
```
$ sha256sum -c alicelinux-rootfs-20240525.tar.xz.sha256sum
```
Make sure it prints:
```
alicelinux-rootfs-20240525.tar.xz: OK
```

### Prepare partition and filesystem
Prepare partition and filesystem of your choice. I'm using `ext4` as and example in this guide.
```
# cfdisk /dev/sdX
# mkfs.ext4 /dev/sdXY
```
Mount your created partition somewhere. I'm using `/mnt/alice` for mountpoint.
```
# mkdir /mnt/alice
# mount /dev/sdXY /mnt/alice
```

### Extract Alice rootfs tarball
Extract Alice rootfs into mounted partition.
```
$ tar xvf alicelinux-rootfs-*.tar.xz -C /mnt/alice
```

### Enter chroot
Alright first, chroot into Alice. (change `/mnt/alice` to mountpoint of your choice)
```
# /mnt/alice/usr/bin/apkg-chroot /mnt/alice
```
Further command after this will reflect inside Alice. 

### Clone Alice repos
Fetch Alice packages repositories somewhere. I'm gonna fetch it inside `/var/lib` directory, I like to keep system clean.
```
# cd /var/lib
# git clone --depth=1 https://codeberg.org/emmett1/alicelinux
```
Once we have repos cloned, we gotta configure `apkg`. `apkg` is the Alice's package build system (or the package manager). By default Alice does not provide `apkg` config file (yes `apkg` can works without config file), but we gotta create one. `apkg`'s config file should located at `/etc/apkg.conf` by default. Lets create one. 

### Configure apkg.conf

First we set `CFLAGS` and `CXXFLAGS`. Alice base packages is built using `-O3 -march=x86-64 -pipe`, you can use this or change into what your prefer.
```
# echo 'export CFLAGS="-O3 -march=x86-64 -pipe"' >> /etc/apkg.conf
```
And use whats on `CFLAGS` for `CXXFLAGS`.
```
# echo 'export CXXFLAGS="$CFLAGS"' >> /etc/apkg.conf
```
Next set `MAKEFLAGS`. I will use `6` for my `8 threads` machine.
```
# echo 'export MAKEFLAGS="-j6"' >> /etc/apkg.conf
```
Also I'm gonna set `NINJAJOBS` here, without it, `ninja` gonna use all threads of your machines when compiling.
```
# echo 'export NINJAJOBS="6"' >> /etc/apkg.conf
```
Next we gonna set package's buildscripts path (I will call it `package repos`) so `apkg` can find it. `APKG_REPO` variable can accept multiple value for multiple `package repos`.

Alice provide two (2) `package repos` (at the time of this writing), `core` and `extra`. `core` is all base packages and `extra` is other than base.

First get absolute path of `package repos` where we cloned it. Btw we still inside `/var/lib` directory where we clone the repo.
>NOTE: USE TAB COMPLETION!
```
# realpath alicelinux/repos/core
/var/lib/alicelinux/repos/core
# realpath alicelinux/repos/extra
/var/lib/alicelinux/repos/extra
```
After we got the path of our `package repos`, add it to `APKG_REPO` variable in `/etc/apkg.conf`
```
# echo 'APKG_REPO="/var/lib/alicelinux/repos/core /var/lib/alicelinux/repos/extra"' >> /etc/apkg.conf
```
After we setup our `package repos`, make sure `apkg` can find the packages. We can use `apkg -s <pattern>` for search packages.
```
# apkg -s sway
swayidle
swaybg
swaylock
sway
```
If the output appeared, then we good to go.

Next we gonna setup directory for `packages`, `sources` and `work`. By default these directories is inside package template, but we gonna change to `/var/cache/pkg`, `/var/cache/src` and `/var/cache/work` respectively. But you can change to anywhere you wanna store these files.

First, create the directories:
```
# mkdir -p /var/cache/pkg
# mkdir -p /var/cache/src
# mkdir -p /var/cache/work
```

Then add these path to `/etc/apkg.conf`
```
# echo 'APKG_PACKAGE_DIR=/var/cache/pkg' >> /etc/apkg.conf
# echo 'APKG_SOURCE_DIR=/var/cache/src' >> /etc/apkg.conf
# echo 'APKG_WORK_DIR=/var/cache/work' >> /etc/apkg.conf
```
### Full system upgrade/rebuild
On first install, we should upgrade the system first. 
> Uppercase `U` for system upgrade, lowercase `u` for upgrade package of your choice.
```
# apkg -U
```
If you changed `CFLAGS` and `CXXFLAGS` to other than default, its a good time to make full rebuild first, in this case, you can skip upgrading system because making full rebuild already use latest version in `package repos`. 

> add `-f` flag to force rebuild of existing prebuilt package.
> `apkg -a` is for print all installed packages in system.
```
# apkg -u $(apkg -a)
```
### Install development packages
Before installing any further packages, we need to install development packages.
```
# apkg -I meson cmake pkgconf libtool automake perl
```
### Install kernel
You can configure your own kernel from [kernel.org](https://kernel.org/) or use the one provided by Alice.
> Provided kernel gonna takes a lot of time to compile because its enabled many options

If you wanna use Alice's kernel, just run:
```
# apkg -I linux
```
### Install firmware
if your hardware required firmware install it using:
```
# apkg -I linux-firmware linux-firmware-nvidia
```

### Install bootloader
In this guide i'm gonna use `grub` as the bootloader. Install `grub`
```
# apkg -I grub
```
Then generate grub config:
```
# grub-install /dev/sdX
# grub-mkconfig -o /boot/grub/grub.cfg
```

### Hostname
change `alice` to hostname of your choice.
```
# echo alice > /etc/hostname
```

### Fstab
Change partition and filesystem of your choice below.
```
# echo '/dev/sda1 swap swap defaults 0 1' >> /etc/fstab
# echo '/dev/sda2 / ext4 defaults 0 0' >> /etc/fstab
```
### Enable runit services
Alice use busybox's `runit` as its main service manager. Enable required services:
```
# ln -s /etc/sv/tty1 /var/service
# ln -s /etc/sv/tty2 /var/service
# ln -s /etc/sv/tty3 /var/service
```
I'm enabling 3 `tty` services. `tty` is required, without it you won't be able to login (or run any commands).
> Runit service directory is `/etc/sv`.
> Make symlink `/etc/sv/<service>` to `/var/service` to enable it, remove symlink to disable it.

### Setup user and password
Add your user:
```
# adduser <user>
```
Add your user to `wheel` group:
```
# adduser <user> wheel
```
You might need to add your user to `input` and `video` group to start wayland compositor later, `audio` group to have working audio.
```
# adduser <user> input
# adduser <user> video
# adduser <user> audio
```

### Root password
Set password for `root` user:
```
# passwd
```

### Networking
You might wanna setup networking first before reboot later. Use `wpa_supplicant` and `dhcpcd`.
```
# apkg -I wpa_supplicant dhcpcd
```
Configure your SSID:
```
# wpa_passphrase <YOUR SSID> <ITS PASSWORD> >> /etc/wpa_supplicant
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
Then make symlink your timezone to `/etc/localtime`:
```
# ln -s /usr/share/zoneinfo/Asia/Kuala_Lumpur /etc/localtime
```
Or you can copy instead then uninstall `tzdata` to keep your installed packages minimal.
```
# cp /usr/share/zoneinfo/Asia/Kuala_Lumpur /etc/localtime
# apkg -r tzdata
```

### Reboot then enjoy!
Exit chroot environment and unmount Alice partition then reboot.
```
# exit
# umount /mnt/alice
# reboot
```

## Some important notes
- `Alice` use `spm` and `apkg` as its package manager and package build system, run with `-h` flag to see available option.
- Also extra scripts is provided by name `apkg-<script>` which will be added (or remove) from time to time.
- Use `revdep` to scan broken libraries and binaries after system upgrades and package removal. You can use `revdep -v` to print out missing required libraries, use `apkg -f -u $(revdep)` to scan and rebuild broken packages.
- Run `updateconf` to update config files in `/etc` after package upgrades.
