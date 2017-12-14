#!/usr/bin/bash

COUNTRY=Germany
DEVICE=/dev/sda
CRYPTSETUP_NAME=cryptoroot
VG_NAME=system
LV_SWAP_NAME=swap
LV_SWAP_SIZE=(-L 1G)
LV_ROOT_NAME=root
LV_ROOT_SIZE=(-l 100%FREE)
NEW_USER=jonas

comment() {
    echo ">> $(tput setaf 2) $@$(tput sgr0)"
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

# FIRST PART STARTS HERE (Do not remove anything before parenthesis)

comment Load german keyboard layout
run loadkeys de-latin1

comment Test whether we are booted into EFI
run ls --ignore='*' /sys/firmware/efi/efivars

comment Test internet connection
run ping -c 2 archlinux.org

comment Install reflector tool and rate best download mirrors
run pacman --noconfirm -Sy reflector
reflector --country "$COUNTRY" --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

comment Update clock
run timedatectl set-ntp true

comment Show devices and ask which one should be formatted
run fdisk -l
echo "We will install on $(tput bold; tput setaf 1)$DEVICE$(tput sgr0)! This is the last moment to press Ctrl+C."
echo -n "Enter to continue..."
read

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

comment This is the partition setup. Please check.
run gdisk -l "$DEVICE"
echo -n "Enter to continue..."
read

comment Format "${DEVICE}1" with FAT32
mkfs.fat -F32 "${DEVICE}1"

comment Format "${DEVICE}2" with LUKS and open it
run cryptsetup luksFormat "${DEVICE}2"
run cryptsetup open --type luks "${DEVICE}2" "$CRYPTSETUP_NAME"

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
run lvcreate "${LV_SWAP_SIZE[@]}" "$VG_NAME" -n "$LV_SWAP_NAME"
run lvcreate "${LV_ROOT_SIZE[@]}" "$VG_NAME" -n "$LV_ROOT_NAME"

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
run mount -o compress=lzo,discard,noatime,nodiratime,subvol=@ /dev/mapper/"$VG_NAME"-"$LV_ROOT_NAME" /mnt
run mkdir /mnt/home
run mkdir /mnt/.snapshots
run mount -o compress=lzo,discard,noatime,nodiratime,subvol=@home /dev/mapper/"$VG_NAME"-"$LV_ROOT_NAME" /mnt/home
run mount -o compress=lzo,discard,noatime,nodiratime,subvol=@snapshots /dev/mapper/"$VG_NAME"-"$LV_ROOT_NAME" /mnt/.snapshots

comment Exclude some directories from snapshots
run mkdir -p /mnt/var/cache/pacman
run btrfs subvolume create /mnt/var/cache/pacman/pkg
run btrfs subvolume create /mnt/var/log
run btrfs subvolume create /mnt/var/tmp

comment Mount EFI volume
run mkdir -p /mnt/boot/efi
run mount "${DEVICE}1" /mnt/boot/efi

comment Run pacstrap
run pacstrap /mnt base btrfs-progs efibootmgr grub-efi-x86_64

comment Generate /etc/fstab
echo "# $(tput setaf 6)genfstab -U /mnt >> /mnt/etc/fstab$(tput sgr0)"
genfstab -U /mnt >> /mnt/etc/fstab
code=$?
if (( code > 0 ))
then
    fail "The following command executed with error $code:"
    fail "genfstab -U /mnt >> /mnt/etc/fstab"
    exit $code
fi

comment System is set up
sed '/^# FIRST PART STARTS HERE/,/^# FIRST PART ENDS HERE/d' "$0" > /mnt/setup.sh
chmod +x /mnt/setup.sh

comment Please run "arch-chroot /mnt" and then "/setup.sh"
exit 0

# FIRST PART ENDS HERE (Do not remove anything before parenthesis)
comment Running second part of setup inside chroot

comment Patching /etc/mkinitcpio.conf
NEW_HOOKS=$(
sed --silent 's/^HOOKS=(\([^)]\+\))/\1/p' /etc/mkinitcpio.conf \
    | tr ' ' '\n' \
    | sed 's/^\(block\)$/keyboard\nkeymap\n\1/;s/^\(filesystems\)$/encrypt\nlvm2\n\1/;/^keyboard$/d' \
    | tr '\n' ' '
)
sed --in-place 's/^\(HOOKS=(\)[^)]\+/\1'"$NEW_HOOKS"'/;s/^\(BINARIES=(\))/\1\/usr\/bin\/btrfs)/' /etc/mkinitcpio.conf

comment Rebuild initramfs
run mkinitcpio -p linux

comment Find id of installation disk
DISK_ID=$(blkid --output export "${DEVICE}2" | grep --silent 's/^UUID=//p')

comment Edit /etc/default/grub
run sed --in-place 's@^\(GRUB_CMDLINE_LINUX="\)"\+@\1cryptdevice=UUID='"$DISK_ID:$CRYPTSETUP_NAME"':allow-discards"@;' /etc/default/grub
run sed --in-place 's@^\(GRUB_PRELOAD_MODULES="[^"]\+\)"\+@\1 lvm"@;' /etc/default/grub
run sed --in-place 's@^#\(GRUB_ENABLE_CRYPTODISK=\).\+@\1y@;' /etc/default/grub

comment Generate /boot/grub/grub.cfg and install grub
run grub-mkconfig -o /boot/grub/grub.cfg
run grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=grub

comment Set correct time zone and set hardware clock accordingly
run ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
run hwclock --systohc --utc

comment Uncomment a number of locales, generate locales, and set default language
run sed --in-place 's@^#\(\(en_US\|en_GB\|de_DE\|es_ES\|es_NI\)\.UTF-8.*\)@@' /etc/locale.gen
run locale-gen
echo LANG=en_US.UTF-8 >> /etc/locale.conf

comment Set up hostname
echo -n "What should this computer be called? "
read HOSTNAME
echo "$HOSTNAME" > /etc/hostname

comment Update all packages and install some new ones
run pacman --noconfirm -Syu sudo zsh

comment Create user and add to relevant group
run useradd -m -g users -G wheel,rfkill,log -s "$(which zsh)" "$NEW_USER"

comment Set password of new user
run passwd jonas

comment Enable sudo access for group wheel
echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/sudo-for-wheel-group

comment Forget root password
run passwd -l root

comment Basic installation done, execute the following commands to restart "
exit
umount -R /mnt
swapoff -a
reboot"
