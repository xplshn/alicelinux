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
