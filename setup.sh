#!/usr/bin/bash

# Preferred keyboard layout
KEYMAP=de-latin1
X11_KEYMAP=( de           # German keyboard layout
             ''           # No model
             ''           # No variant
             compose:prsc # Use print key as compose key
)
# Country to filter pacman mirrors
COUNTRY=Germany
# Time zone
TIMEZONE=Europe/Berlin
# Where to install Arch
DEVICE=/dev/sda
# Size of EFI partition
EFI_PARTITION_SIZE=250M
# What should the cryptdevice be called?
CRYPTSETUP_NAME=cryptoroot
# What should be the name of the volume group?
VG_NAME=system
# What should the name and size of the swap partition be?
LV_SWAP_NAME=swap
LV_SWAP_SIZE=(-L 1G)
# What should the name and size of the root partition be?
LV_ROOT_NAME=root
LV_ROOT_SIZE=(-l 100%FREE)
# What is the name of the new user?
NEW_USER=jonas
GUI_PACKAGES=(
    i3-wm        # The window manager
    i3status     # Status command
    i3lock       # Lock screen
    dmenu        # Application launcher
    xorg-xinit   # Start x.org session with startx
    xorg-server  # The x.org server
    rxvt-unicode # A terminal emulator
    polkit       # PolicyKit to be able to interact with the system ad non-root
    xorg-xrandr  # Graphics configurations
    dunst        # Notification daemon
)
# Which packages do we want to install in the beginning?
WANTED_PACKAGES=(
    # Command line tools
    at
    bash-completion
    convmv
    dos2unix
    dialog
    the_silver_searcher
    tree
    htop
    gtop
    atop
    rsync
    lm_sensors # Requirement for mpd py3status module
    imagemagick
    imagemagick-doc
    inotify-tools
    iotop
    lshw
    lsof
    mediainfo
    moreutils
    mosh
    mtr
    ncdu
    nmap
    openssh
    parallel
    pdfgrep
    powertop
    reptyr
    sshuttle
    tmux
    vim
    vim-spell-de
    vim-spell-en
    vim-spell-es
    w3m
    wget
    whois
    wol
    xdg-utils
    xdotool
    zenity
    zip
    # Daemons an alike
    syncthing
    dnscrypt-proxy
    dnsmasq
    # Publishing
    texlive-most
    biber
    pdf2djvu
    minted
    pandoc
    # Security
    keepass
    nftables
    pwgen
    # Python
    python-pip
    python-virtualenv
    python-pipenv
    python-mpd2       # Requirement for mpd py3status module
    cython
    ipython
    # Programming
    gcc
    graphviz
    strace
    # System maintenance
    baobab
    gdmap
    dstat
    tlp
    x86_energy_perf_policy
    acpi_call
    tpacpi-bat
    arandr
    bumblebee
    bbswitch
    mesa
    nvidia
    nvidia-utils
    # lib32-nvidia-utils
    nvidia-settings
    xf86-video-intel
    # lib32-virtualgl
    dhcpcd
    pacgraph
    pkgfile
    primus
    smartmontools
    testdisk
    xf86-input-libinput
    xorg-xinput
    xorg-xdpyinfo
    xorg-xdriinfo
    xorg-xev
    xorg-xlsatoms
    xorg-xlsclients
    xorg-xprop
    xorg-xvinfo
    xorg-xwininfo
    xorg-xlsfonts
    xorg-xmodmap
    xorg-xrdb
    # Backup
    borg
    # Audio
    alsa-utils
    pulseaudio
    pulseaudio-alsa
    pavucontrol
    pamixer
    chromaprint
    mpd
    ncmpcpp
    picard
    # Smartphone
    android-tools
    android-udev
    # Desktop applications
    firefox
    firefox-i18n-de
    chromium
    evince
    geogebra
    gephi
    gimp
    git
    git-annex
    inkscape
    okular
    openconnect
    pdfpc
    pidgin
    pidgin-libnotify
    pidgin-otr
    rdesktop
    redshift
    smplayer
    sxiv
    thunderbird
    thunderbird-i18n-de
    virtualbox
    virtualbox-guest-iso
    virtualbox-host-dkms
    vlc
    wireshark-gtk
    zathura
    zathura-djvu
    zathura-pdf-mupdf
    zathura-ps
    # Misc
    aspell-de
    aspell-en
    aspell-es
    hunspell-de
    hunspell-en
    hunspell-es
    cups
    cups-pdf
    gutenprint
    macchanger
    # Fonts
    otf-fira-mono
    otf-fira-sans
    otf-font-awesome
    otf-overpass
    ttf-gentium
    ttf-dejavu
    ttf-droid
    ttf-liberation
    ttf-roboto
    ttf-ubuntu-font-family
    ttf-linux-libertine
    noto-fonts
    noto-fonts-emoji
    adobe-source-code-pro-fonts
    adobe-source-sans-pro-fonts
    adobe-source-serif-pro-fonts
    terminus-font
)
AUR_PACKAGES=(
    # Dotfiles manager
    yadm-git
    # Management
    reflector-timer
    # Programming
    git-extras
    pdftk-bin
    # i3
    py3status
    cower-git        # Requirement for one py3status module
    i3ipc-python-git # Requirement for one py3status module
    # Misc
    profile-sync-daemon
    anything-sync-daemon
    storebackup
    nettop
    tiv
    djvu2pdf
    pkg_scripts
    pkgbuild-introspection-git
    virtualbox-ext-oracle
    zotero
    # Python
    pycharm-professional
    dropbox
    dropbox-cli
    # Fonts
    otf-vollkorn
    otf-fira-code
    fontawesome.sty
    powerline-fonts-git
)
PIP_PACKAGES=(
    # To use template files with yadm
    envtpl
)

# Paths for which a dedicated folder in the root volume should be created
BTRFS_MOUNTED_SUBVOLUMES=(
    /
    /home
    /var
)
# Paths for which a local subvolume should be created
BTRFS_LOCAL_SUBVOLUMES=(
    # Exclude pacman package cache from snapshots
    /var/cache/pacman/pkg
)
# All subvolumes (out of the above) for which snapper configurations should be created
SNAPPER_SUBVOLUMES=(
    /
    /home
    /var
)

# Global directories for which COW should be disabled
NODATACOW_DIRECTORIES=(
)
# User directories for which COW should be disabled
NODATACOW_USER_DIRECTORIES=(
    Torrents
    "VirtualBox VMs"
)

PRIVATE_PACKAGES=(
    pacman-cache-cleanup-hook
    reflector-timer-config
    dnscrypt-systemd-units
)

if lsusb | grep 'ID 80ee:0021 ' >/dev/null
then
    IS_VIRTUALBOX=true
    IS_REALBOX=false
else
    IS_VIRTUALBOX=false
    IS_REALBOX=true
fi

comment() {
    echo ">> $(tput setaf 2) $@$(tput sgr0)" >&2
}

fail() {
    echo "$(tput bold; tput setaf 5)$@$(tput sgr0)" >&2
}

run() {
    echo "# $(tput setaf 6)$@$(tput sgr0)" >&2
    "$@"
    code=$?
    if (( code > 0 ))
    then
        fail "The following command executed with error $code:"
        fail "$@"
        exit $code
    fi
}

extract-parts() {
    SED_SCRIPT='/^#!\/usr\/bin\/bash/,/^#<<<<CONFIGURATION/p'
    PARTS=
    for PART in "$@"
    do
        SED_SCRIPT="$SED_SCRIPT;"'/^#>>>>PART-'"$PART"'/,/^#<<<<PART-'"$PART"'/p'
        PARTS="$PARTS$PART"
    done
    run sed --silent "$SED_SCRIPT" "$0"
}

contains-element () {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

if (( $# > 0 ))
then
    comment "Parameters given to script."
    comment "Will now extract requestes parts ($@) to new file."
    PARTS=$(echo "$@" | tr --delete ' ')
    extract-parts "$@" > "$(dirname "$0")/setup.$PARTS.sh"
    run chmod +x "$(dirname "$0")/setup.$PARTS.sh"
    exit 0
fi

#<<<<CONFIGURATION
#>>>>PART-1

echo "#!/usr/bin/bash

swapoff --all
umount --recursive /mnt
lvremove --force system/root
lvremove --force system/swap
vgremove --force system
pvremove --force /dev/mapper/$CRYPTSETUP_NAME
cryptsetup close /dev/mapper/$CRYPTSETUP_NAME
" > "$(dirname "$0")/remove.sh"
chmod +x "$(dirname "$0")/remove.sh"

comment "Load german keyboard layout"
run loadkeys "$KEYMAP"

comment "Test whether we are booted into EFI"
run ls --ignore='*' /sys/firmware/efi/efivars

comment "Test internet connection"
run ping -c 2 archlinux.org

comment "Install reflector tool and rate best download mirrors"
run pacman --noconfirm --sync --refresh --needed reflector
# Get all mirrors in $COUNTRY synchronized not more than 12 hours ago and sort them by download rate
run reflector --country "$COUNTRY" --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
if $IS_VIRTUALBOX
then
    comment "Set mirror to host"
    HOST_IP=$(ip route | sed --silent 's/.*via \(\S\+\).*/\1/p')
    ( echo "Server = http://$HOST_IP:8080/"; cat /etc/pacman.d/mirrorlist ) > /etc/pacman.d/mirrorlist.tmp
    mv /etc/pacman.d/mirrorlist.tmp /etc/pacman.d/mirrorlist
fi

comment "Update clock"
run timedatectl set-ntp true

comment "Show devices and ask which one should be formatted"
run fdisk -l
echo "We will install on $(tput bold; tput setaf 1)$DEVICE$(tput sgr0)! This is the last moment to press Ctrl+C."
echo -n "Enter to continue..."
read

comment "Create partitions for EFI and system"
# o y: Create a new empty GUID partition table (GPT) and confirm
# n 1 '' $EFI_PARTITION_SIZE ef00: create new partition with id 1, at the beginning, size $EFI_PARTITION_SIZE, and type ef00 (EFI System)
# n 2 '' '' 8300: create new partition with id2, after 1, size rest of the disk, and type 8300 (Linux filesystem)
# w y: Write table to disk and exit
if ! echo 'o
y
n
1

'"$EFI_PARTITION_SIZE"'
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

comment "This is the partition setup. Please check."
run gdisk -l "$DEVICE"
echo -n "Enter to continue..."
read

comment "Format '${DEVICE}1' with FAT32"
mkfs.fat -F32 "${DEVICE}1"

comment "Format '${DEVICE}2' with LUKS and open it"
run cryptsetup luksFormat "${DEVICE}2"
run cryptsetup open --type luks "${DEVICE}2" "$CRYPTSETUP_NAME"

comment "Check whether '$CRYPTSETUP_NAME' is mounted"
if ! fdisk -l | grep " /dev/mapper/$CRYPTSETUP_NAME:"
then
    fail "/dev/mapper/$CRYPTSETUP_NAME not found in open disks"
    exit 1
fi

comment "Create physical and virtual volumes with lvm"
run pvcreate "/dev/mapper/$CRYPTSETUP_NAME"
run vgcreate "$VG_NAME" "/dev/mapper/$CRYPTSETUP_NAME"

comment "Create logical volumes with lvm"
run lvcreate "${LV_SWAP_SIZE[@]}" "$VG_NAME" -n "$LV_SWAP_NAME"
run lvcreate "${LV_ROOT_SIZE[@]}" "$VG_NAME" -n "$LV_ROOT_NAME"

comment "Create swap and turn it on"
run mkswap /dev/mapper/"$VG_NAME"-"$LV_SWAP_NAME"
run swapon -d /dev/mapper/"$VG_NAME"-"$LV_SWAP_NAME"

comment "Create BTRFS file system and mount it"
run mkfs.btrfs /dev/mapper/"$VG_NAME"-"$LV_ROOT_NAME"
run mount /dev/mapper/"$VG_NAME"-"$LV_ROOT_NAME" /mnt

comment "Create subvolumes for ${BTRFS_MOUNTED_SUBVOLUMES[@]} and their respective snapshots (if wanted)"
for BTRFS_SUBVOLUME in "${BTRFS_MOUNTED_SUBVOLUMES[@]}"
do
    BTRFS_SUBVOLUME_PATH="$(realpath --canonicalize-missing "$BTRFS_SUBVOLUME")"
    BTRFS_SUBVOLUME_NAME="${BTRFS_SUBVOLUME_PATH/\//@}"
    BTRFS_SUBVOLUME_NAME="${BTRFS_SUBVOLUME_NAME//\//-}"
    run btrfs subvolume create "/mnt/$BTRFS_SUBVOLUME_NAME"
    if contains-element "$BTRFS_SUBVOLUME" "${SNAPPER_SUBVOLUMES[@]}"
    then
        run btrfs subvolume create "/mnt/${BTRFS_SUBVOLUME_NAME%@}@.snapshots"
    fi
done

comment "unmount root filesystem and mount BTRFS subvolumes instead"
run umount /mnt
for BTRFS_SUBVOLUME in "${BTRFS_MOUNTED_SUBVOLUMES[@]}"
do
    BTRFS_SUBVOLUME_PATH="$(realpath --canonicalize-missing "$BTRFS_SUBVOLUME")"
    BTRFS_SUBVOLUME_NAME="${BTRFS_SUBVOLUME_PATH/\//@}"
    BTRFS_SUBVOLUME_NAME="${BTRFS_SUBVOLUME_NAME//\//-}"
    BTRFS_SUBVOLUME_PATH="$(realpath --canonicalize-missing "/mnt$BTRFS_SUBVOLUME_PATH")"
    run mkdir --parents "$BTRFS_SUBVOLUME_PATH"
    run mount -o compress=lzo,discard,noatime,subvol="$BTRFS_SUBVOLUME_NAME" /dev/mapper/"$VG_NAME"-"$LV_ROOT_NAME" "$BTRFS_SUBVOLUME_PATH"
    if contains-element "$BTRFS_SUBVOLUME" "${SNAPPER_SUBVOLUMES[@]}"
    then
        run mkdir --parents "$BTRFS_SUBVOLUME_PATH/.snapshots"
        run mount -o compress=lzo,discard,noatime,subvol="${BTRFS_SUBVOLUME_NAME%@}@.snapshots" /dev/mapper/"$VG_NAME"-"$LV_ROOT_NAME" "$BTRFS_SUBVOLUME_PATH/.snapshots"
    fi
done

comment "Create local subvolumes for ${BTRFS_LOCAL_SUBVOLUMES[@]}"
for BTRFS_SUBVOLUME in "${BTRFS_LOCAL_SUBVOLUMES[@]}"
do
    BTRFS_SUBVOLUME_PATH="$(realpath --canonicalize-missing "$BTRFS_SUBVOLUME")"
    run mkdir --parents "$(dirname "/mnt$BTRFS_SUBVOLUME_PATH")"
    run btrfs subvolume create "/mnt$BTRFS_SUBVOLUME_PATH"
done

comment "Create folders with a lot of random writes with disabled copy-on-write"
for DIRECTORY in "${NODATACOW_DIRECTORIES[@]}"
do
    run mkdir --parents "$DIRECTORY"
    run chattr +C "$DIRECTORY"
done

comment "Mount EFI volume"
run mkdir -p /mnt/boot/efi
run mount "${DEVICE}1" /mnt/boot/efi

comment "Run pacstrap"
run pacstrap /mnt base btrfs-progs efibootmgr grub-efi-x86_64 wpa_actiond wpa_supplicant

comment "Generate /etc/fstab"
run genfstab -U /mnt >> /mnt/etc/fstab

comment "System is set up"
run extract-parts 2 3 > /mnt/setup.sh
run chmod +x /mnt/setup.sh

comment "Please run the following commands."
comment "\$ arch-chroot /mnt"
comment "\$ /setup.sh"
exit 0

#<<<<PART-1
#>>>>PART-2

comment "Running second part of setup inside chroot"

comment "Install reflector tool and rate best download mirrors"
run pacman --noconfirm --sync --refresh --needed reflector
# Get all mirrors in $COUNTRY synchronized not more than 12 hours ago and sort them by download rate
run reflector --country "$COUNTRY" --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
if $IS_VIRTUALBOX
then
    comment "Set mirror to host"
    HOST_IP=$(ip route | sed --silent 's/.*via \(\S\+\).*/\1/p')
    ( echo "Server = http://$HOST_IP:8080/"; cat /etc/pacman.d/mirrorlist ) > /etc/pacman.d/mirrorlist.tmp
    mv /etc/pacman.d/mirrorlist.tmp /etc/pacman.d/mirrorlist
fi

comment "Patching /etc/mkinitcpio.conf"
# Add/move "keyboard" and "keymap" before "block"
# Add "encrypt" and "lvm2" before "filesystems"
NEW_HOOKS=$(
    sed --silent 's/^HOOKS=(\([^)]\+\))/\1/p' /etc/mkinitcpio.conf \
        | tr ' ' '\n' \
        | sed 's/^\(block\)$/keyboard\nkeymap\n\1/;s/^\(filesystems\)$/encrypt\nlvm2\n\1/;/^\(keyboard\|keymap\|encrypt\|lvm2\)$/d' \
        | tr '\n' ' '
)
# Replace old HOOKS with new ones
# Add btrfs binary to BINARIES to be able to make file system operations before booting
run sed --in-place 's/^\(HOOKS=(\)[^)]\+/\1'"$NEW_HOOKS"'/;s/^\(BINARIES=(\))/\1\/usr\/bin\/btrfs)/' /etc/mkinitcpio.conf

comment "Install linux kernel with ck-patches"
if ! grep 'Include\s*=\s*/etc/pacman\.d/repo-ck' /etc/pacman.conf
then
    echo "
Include = /etc/pacman.d/repo-ck
" | tee -a /etc/pacman.conf
    comment "Receive and sign pacman keys"
    run pacman-key --recv-keys 5EE46C4C
    run pacman-key --lsign-key 5EE46C4C
    if $IS_REALBOX
    then
        echo "[repo-ck]
Server = http://repo-ck.com/$arch
" | tee /etc/pacman.d/repo-ck
    else
        HOST_IP=$(ip route | sed --silent 's/.*via \(\S\+\).*/\1/p')
        echo "[repo-ck]
Server = http://$HOST_IP:8080/
" | tee /etc/pacman.d/repo-ck
    fi
fi
run pacman --noconfirm --sync --refresh --refresh --needed linux-ck-ivybridge linux-ck-ivybridge-headers nvidia-ck-ivybridge

comment "Find uuid of installation disk"
DISK_ID=$(blkid --output export "${DEVICE}2" | sed --silent 's/^UUID=//p')

comment "Edit /etc/default/grub"
# Set cryptdevice to linux command line
run sed --in-place 's@^\(GRUB_CMDLINE_LINUX="\)"\+@\1cryptdevice=UUID='"$DISK_ID:$CRYPTSETUP_NAME"':allow-discards"@;' /etc/default/grub
# Add lvm module to preloaded modules
run sed --in-place 's@^\(GRUB_PRELOAD_MODULES="[^"]\+\)"\+@\1 lvm"@;' /etc/default/grub
# Enable crypto
run sed --in-place 's@^#\?\(GRUB_ENABLE_CRYPTODISK=\).\+@\1y@;' /etc/default/grub
# Set GRUB timeout to 2 seconds
run sed --in-place 's@^#\?\(GRUB_TIMEOUT\)=.\+@\1=2@;' /etc/default/grub

comment "Generate /boot/grub/grub.cfg and install grub"
run grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=arch-grub
run grub-mkconfig -o /boot/grub/grub.cfg

if $IS_VIRTUALBOX
then
    comment "Copy bootloader to location where VirtualBox always finds it"
    mkdir /boot/efi/EFI/BOOT
    cp /boot/efi/EFI/{arch-grub/grubx64.efi,BOOT/bootx64.efi}
fi

comment "Set correct time zone and set hardware clock accordingly"
run ln -sf /usr/share/zoneinfo/"$TIMEZONE" /etc/localtime
run hwclock --systohc --utc

comment "Uncomment a number of locales, generate locales, and set default language"
run sed --in-place 's@^#\(\(en_US\|en_GB\|en_DK\|de_DE\|es_ES\|es_NI\)\.UTF-8.*\)@\1@' /etc/locale.gen
run locale-gen
comment "Set default language to American English"
run echo LANG=en_US.UTF-8 >> /etc/locale.conf
comment "Set time format to display as ISO (YYYY-MM-DD)"
run echo LC_TIME=en_DK.UTF-8 >> /etc/locale.conf

comment "Make keyboard layout persistent"
run echo KEYMAP="$KEYMAP" >> /etc/vconsole.conf

comment "Set up hostname"
echo -n "What should this computer be called? "
read HOSTNAME
run echo "$HOSTNAME" > /etc/hostname

comment "Update all packages and install some new ones"
run pacman --noconfirm --sync --sysupgrade --needed sudo zsh zsh-completions polkit

comment "Create user and add to relevant group"
run useradd -m -g users -G wheel,rfkill,log -s "$(which zsh)" "$NEW_USER"

comment "Set password of new user"
run passwd jonas

comment "Enable sudo access for group wheel"
run echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/sudo-for-wheel-group

comment "Forget root password"
run passwd -l root

comment "Create random key to auto-unlock lvm after already giving the password for GRUB"
run dd bs=512 count=4 if=/dev/urandom of=/crypto_keyfile.bin
run chmod 000 /crypto_keyfile.bin
run chmod 600 /boot/initramfs-linux*

comment "Add keyfile to LUKS"
run cryptsetup luksAddKey "${DEVICE}2" /crypto_keyfile.bin

comment "Add keyfile to /etc/mkinitcpio.conf"
run sed --in-place 's/^\(FILES=(\)/\1\/crypto_keyfile.bin /' /etc/mkinitcpio.conf
comment "Rebuild initramfs"
run mkinitcpio -p linux

SETUP_FILE="$(getent passwd "$NEW_USER" | cut -d: -f6)/setup.sh"
run extract-parts 3 > "$SETUP_FILE"
run chmod +x "$SETUP_FILE"
run chown "$NEW_USER:users" "$SETUP_FILE"

comment "Basic installation done, execute the following commands to restart"
comment "\$ exit"
comment "\$ umount -R /mnt"
comment "\$ swapoff -a"
comment "\$ reboot"
comment "After reboot log in as new user and execute"
comment "\$ ./setup.sh"
exit 0

#<<<<PART-2
#>>>>PART-3
if (( EUID != 0 ))
then
    exec sudo "$0" "$@"
fi

# TODO: First make internet connection work -- for this maybe we also need wifi before?

if ! ping -c 1 archlinux.org
then
    comment "Install ifplugd to automate network access over ethernet"
    for device in $(find /sys/class/net -iname 'en*' -exec basename '{}' ';')
    do
        comment ">> Device $device netctl profile"
        run sed 's/^\(Interface=\)\S*/\1'"$device"'/' /etc/netctl/examples/ethernet-dhcp > "/etc/netctl/$device-dhcp"
        run netctl start "$device-dhcp"
    done
    while ! ping -c 2 archlinux.org
    do
        sleep 1
    done
    run pacman --noconfirm --sync --refresh --needed ifplugd
    for device in $(find /sys/class/net -iname 'en*' -exec basename '{}' ';')
    do
        run netctl stop "$device-dhcp"
        comment ">> Device $device ifplugd services"
        run systemctl enable "netctl-ifplugd@$device"
        run systemctl start "netctl-ifplugd@$device"
    done
fi

if ! pacman -Qi snapper
then
    comment "Install snapper and set up BTRFS snapshots"
    run pacman --noconfirm --sync --needed snapper snap-pac

    for BTRFS_SUBVOLUME in "${SNAPPER_SUBVOLUMES[@]}"
    do
        BTRFS_SUBVOLUME_PATH="$(realpath --canonicalize-missing "$BTRFS_SUBVOLUME")"
        BTRFS_SUBVOLUME_SNAPSHOT_PATH="$(realpath --canonicalize-missing "$BTRFS_SUBVOLUME/.snapshots")"
        if contains-element "$BTRFS_SUBVOLUME" "${BTRFS_MOUNTED_SUBVOLUMES[@]}"
        then
            run umount "${BTRFS_SUBVOLUME_SNAPSHOT_PATH}"
            run rmdir "${BTRFS_SUBVOLUME_SNAPSHOT_PATH}"
        fi
        if [[ "$BTRFS_SUBVOLUME" == "/" ]]
        then
            CONFIG=root
        else
            CONFIG="${BTRFS_SUBVOLUME#/}"
            CONFIG="${CONFIG//\//-}"
        fi
        run snapper --config "$CONFIG" create-config "$BTRFS_SUBVOLUME_PATH"
        if contains-element "$BTRFS_SUBVOLUME" "${BTRFS_MOUNTED_SUBVOLUMES[@]}"
        then
            run mount "${BTRFS_SUBVOLUME_SNAPSHOT_PATH}"
        fi
    done

    run systemctl enable snapper-timeline.timer
    run systemctl start snapper-timeline.timer
    run systemctl enable snapper-cleanup.timer
    run systemctl start snapper-cleanup.timer
fi

comment "Install graphical user interface"
run pacman --noconfirm --sync --needed "${GUI_PACKAGES[@]}"

comment "Install AUR helper"
run pacman --noconfirm --sync --needed base-devel git
if ! pacman -Qi package-query
then
    run sudo -u "$NEW_USER" git clone https://aur.archlinux.org/package-query.git
    cd package-query
    run sudo -u "$NEW_USER" makepkg --syncdeps --install --noconfirm
    cd ..
    run rm -rf package-query
fi
if ! pacman -Qi yaourt
then
    run sudo -u "$NEW_USER" git clone https://aur.archlinux.org/yaourt.git
    cd yaourt
    run sudo -u "$NEW_USER" makepkg --syncdeps --install --noconfirm
    cd ..
    run rm -rf yaourt
fi

comment "Add additional wanted packages"
run pacman --noconfirm --sync --needed "${WANTED_PACKAGES[@]}"

comment "Install Sublime Text 3"
if ! grep 'Include\s*=\s*/etc/pacman\.d/sublime-text' /etc/pacman.conf
then
    echo "
Include = /etc/pacman.d/sublime-text
" | tee -a /etc/pacman.conf
    if $IS_REALBOX
    then
        curl https://download.sublimetext.com/sublimehq-pub.gpg | pacman-key --add -
        run pacman-key --lsign-key 8A8F901A
        echo "[sublime-text]
Server = https://download.sublimetext.com/arch/stable/x86_64
" | tee /etc/pacman.d/sublime-text
    else
        HOST_IP=$(ip route | sed --silent 's/.*via \(\S\+\).*/\1/p')
        curl "http://$HOST_IP:8080/sublimehq-pub.gpg" | pacman-key --add -
        run pacman-key --lsign-key 8A8F901A
        echo "[sublime-text]
Server = http://$HOST_IP:8080/
" | tee /etc/pacman.d/sublime-text
    fi
fi
run pacman --noconfirm --sync --refresh --needed sublime-text

comment "Create folders with a lot of random writes with disabled copy-on-write"
HOME_FOLDER="$(getent passwd "$NEW_USER" | cut -d: -f6)"
for DIRECTORY in "${NODATACOW_USER_DIRECTORIES[@]}"
do
    run sudo -u "$NEW_USER" mkdir --parents "$HOME_FOLDER/$DIRECTORY"
    run sudo -u "$NEW_USER" chattr +C "$HOME_FOLDER/$DIRECTORY"
done

comment "Fetch needed gpg keys from server"
run sudo -u "$NEW_USER" gpg --recv-keys 1D1F0DC78F173680

comment "Add additional packages from AUR"
run sudo -u "$NEW_USER" yaourt --noconfirm --sync --needed "${AUR_PACKAGES[@]}"

comment "Add additional packages from PIP"
run pip install --disable-pip-version-check "${PIP_PACKAGES[@]}"

comment "Install packages from my own package repository"
run sudo -u "$NEW_USER" git clone https://github.com/jonasc/archlinux-pkgbuilds.git
cd archlinux-pkgbuilds
for PACKAGE in "${PRIVATE_PACKAGES[@]}"
do
    cd "$PACKAGE"
    run sudo -u "$NEW_USER" makepkg --syncdeps --install --noconfirm
    cd ..
done
cd ..
run rm -rf archlinux-pkgbuilds

comment "Install my dotfiles"
echo -n "https://<...>/dotfiles.git: "
read HOST_USER
run sudo -u "$NEW_USER" yadm clone "https://$HOST_USER/dotfiles.git"
comment "Configure local yadm class as 'home'"
run sudo -u "$NEW_USER" yadm config local.class home

comment "Set X11 keymap"
localectl set-x11-keymap "${X11_KEYMAP[@]}"

comment "Add user to bumblebee group and enable bumblebee daemon"
run gpasswd -a "$NEW_USER" bumblebee
run systemctl enable bumblebeed.service

comment "Configure dnsmasq to use DNSCrypt"
run sed --in-place 's/^#\(domain-needed\|bogus-priv\|dnssec\|conf-file=.*trust-anchors.conf\|no-resolv\)/\1/' /etc/dnsmasq.conf
run sed --in-place 's/^\(#no-poll\)/\1\n\nserver=127.0.0.1#53531\nserver=127.0.0.1#53532\nserver=127.0.0.1#53533\nserver=127.0.0.1#53534\nserver=127.0.0.1#53535\nserver=127.0.0.1#53536\nserver=127.0.0.1#53537\nserver=127.0.0.1#53538\nserver=127.0.0.1#53539/' /etc/dnsmasq.conf
run systemctl enable dnsmasq
run systemctl start dnsmasq

#<<<<PART-3
