#!/bin/sh

LIVEUSER=live
PASSWORD=live
LIVEHOSTNAME=alicelive

adduser -D $LIVEUSER
for g in users wheel audio video input; do
	addgroup $LIVEUSER $g
done

passwd -d $LIVEUSER >/dev/null 2>&1
passwd -d root >/dev/null 2>&1

echo "root:root" | chpasswd -c SHA512
echo "$LIVEUSER:$PASSWORD" | chpasswd -c SHA512

for sv in tty1 tty2 tty3 seatd; do
	[ -d /etc/sv/$sv ] && ln -s /etc/sv/$sv /var/service
done

echo $LIVEHOSTNAME > /etc/hostname

if [ -f /etc/doas.conf ]; then
	echo "permit nopass $LIVEUSER" >> /etc/doas.conf
fi

cat <<'EOF' > /etc/skel/.profile
if [ -z "$XDG_RUNTIME_DIR" ]; then
        XDG_RUNTIME_DIR="/tmp/$(id -u)-runtime-dir"
        mkdir -pm 0700 "$XDG_RUNTIME_DIR"
        export XDG_RUNTIME_DIR
fi
EOF

cat <<'EOF' > /etc/issue
Alice Linux \r (\l)

Project page : https://codeberg.org/emmett1/alicelinux

user login   : live
user password: live

root login   : root
root password: root

run 'sway' after login to start gui

Some default sway keybindsym reminder:

   Super + Enter       : foot terminal
   Super + d           : menu launcher
   Super + Shift + q   : quit program
   Super + Shift + e   : exit sway
   
run 'doas poweroff' to poweroff live system

EOF
