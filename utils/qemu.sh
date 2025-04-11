#!/bin/sh

PORTSDIR="$(dirname $(dirname $(realpath $0)))"
SCRIPTDIR="$(dirname $(realpath $0))"

[ -f /tmp/qemu-vm.img ] || {
	qemu-img create -f qcow2 /tmp/qemu-vm.img 50G
}

qemu-system-x86_64 -enable-kvm \
        -cpu host \
        -drive file=/tmp/qemu-vm.img,if=virtio \
        -device virtio-rng-pci \
        -m 2G \
        -smp 4 \
        -monitor stdio \
        -name "QEMU" \
        -boot d \
        -cdrom $@

rm -f /tmp/qemu-vm.img

exit 0
