#!/usr/bin/bash

CRYPTSETUP_NAME=cryptoroot
VG_NAME=system
LV_SWAP_NAME=swap
LV_SWAP_SIZE=(-L 1G)
LV_ROOT_NAME=root
LV_ROOT_SIZE=(-l 100%FREE)

comment() {
    echo ">> $(tput setaf 2) $@"
}

fail() {
    echo "$(tput bold; tput setaf 5)$@$(tput sgr0)"
}

run() {
    echo "# $(tput setaf 6)$@$(tput sgr0)"
    "$@"
    code=$?
    if (( code > 0 ))
    then
        fail "The following command executed with error $code:"
        fail "$@"
        exit $code
    fi
}

comment Load german keyboard layout
run loadkeys de-latin1

comment Test internet connection
run ping -c 2 archlinux.org

comment Update clock
run timedatectl set-ntp true

comment Show devices and ask which one should be formatted
run fdisk -l
echo -n "Install device? "
read DEVICE
echo "We will install on $(tput bold; tput setaf 1)$DEVICE$(tput sgr0)! This is the last moment to press Ctrl+C."

comment Create partitions for EFI and system
if ! echo 'o
y
n
1

150M
ef00
n
2


8300
w
y' | gdisk "$DEVICE"
then
    fail "Cannot setup device partitions"
    exit 1
fi

comment Format "${DEVICE}2" with LUKS and open it
cryptsetup luksFormat "${DEVICE}2"
cryptsetup open --type luks "${DEVICE}2" "$CRYPTSETUP_NAME"

comment Check whether "$CRYPTSETUP_NAME" is mounted
if ! fdisk -l | grep " /dev/mapper/$CRYPTSETUP_NAME:"
then
    fail "/dev/mapper/$CRYPTSETUP_NAME not found in open disks"
    exit 1
fi

comment Create physical and virtual volumes with lvm
run pvcreate "/dev/mapper/$CRYPTSETUP_NAME"
run vgcreate "$VG_NAME" "/dev/mapper/$CRYPTSETUP_NAME"

comment Create logical volumes with lvm
lvcreate "${LV_SWAP_SIZE[@]}" "$VG_NAME" -n "$LV_SWAP_NAME"
lvcreate "${LV_ROOT_SIZE[@]}" "$VG_NAME" -n "$LV_ROOT_NAME"

comment Create swap and turn it on
run mkswap /dev/mapper/"$VG_NAME"-"$LV_SWAP_NAME"
run swapon -d /dev/mapper/"$VG_NAME"-"$LV_SWAP_NAME"

comment Create BTRFS file system and mount it
run mkfs.btrfs /dev/mapper/"$VG_NAME"-"$LV_ROOT_NAME"
run mount /dev/mapper/"$VG_NAME"-"$LV_ROOT_NAME" /mnt

comment Create subvolumes for /, /home and snapshots
run btrfs subvolume create /mnt/@
run btrfs subvolume create /mnt/@home
run btrfs subvolume create /mnt/@snapshots

comment unmount root filesystem and mount BTRFS subvolumes instead
run umount /mnt
run mount -o compress=lzo,discard,noatime,nodiratime,subvol=@ /dev/mapper/System-root /mnt
run mkdir /mnt/home
run mkdir /mnt/.snapshots
run mount -o compress=lzo,discard,noatime,nodiratime,subvol=@home /dev/mapper/System-root /mnt/home
run mount -o compress=lzo,discard,noatime,nodiratime,subvol=@snapshots /dev/mapper/System-root /mnt/.snapshots

comment Exclude some directories from snapshots
run mkdir -p /mnt/var/cache/pacman
run btrfs subvolume create /mnt/var/cache/pacman/pkg
run btrfs subvolume create /mnt/var/log
run btrfs subvolume create /mnt/var/tmp

comment Mount EFI volume
run mkdir -p /mnt/boot/efi
run mount "${DEVICE}1" /mnt/boot/efi
