## The goal and disclaimer

Install a minimal Systemd/Linux system on a mainstream laptop. These are my notes from 1 Sep 2020, done on Thinkpad T480. 
Follow this guide on your own risk. 

## Preparation

Head to https://wiki.archlinux.org/index.php/Installation_guide and keep it open for further reference. Download and flash the live system image (x86-64). Verify the signature if you want to, then boot your Thinkpad from the USB drive (press Enter when shown Lenovo logo, then F12 for boot menu). You also should disable the "secure boot" feature in the UEFI settings. After the live system boots, you'll see the root prompt. I assume you know how to use the command line.

If you use your native keyboard layout (German in my case), set it up now with the following command:

    loadkeys de-latin1

To connect to your wifi:

    iwctl --passphrase 'xxx_password' station wlan0 connect 'xxx_ssid'

You can test the connection by pinging some internet site

    ping www.archlinux.org

Set up the clock (well, just in case):
	
	timedatectl set-ntp true

The installation environment is now set and ready to go. 

## Partitioning the disk

Partitioning the disk is a common task on all OS'es, yes, even Windows. Though usually it's hidden behind the installer's UI. If you never did it before, please find a tutorial on *fdisk* tool. Do it as many times as you need until you get it right, nothing bad will happen (well, you'll destroy all your data on the disk, but this is what you want anyway). 

    lsblk

This command will list all block devices on your system, ordered as a tree by drives and their partitions. Most likely that will be the internal SSD and the USB drive with the live system. On a modern Thinkpad with a NVMe SSD the internal drive will be probably /dev/nvme0n1. 

    fdisk /dev/nvme0n1

then follow the fdisk's instructions. You need to create in the following order:
1. New GPT table
2. EFI partition (500M), of type EFI
3. Linux swap partition (as much as your RAM, 8G in my case), of type Linux Swap
4. Linux root partition, of type Linux root (x86-64)

The partitions will be then /dev/nvme0n1p1, /dev/nvme0n1p2 and /dev/nvme0n1p3. Now format them to create the file systems: EFI is FAT32, swap is swap, root is Ext4.

    mkfs.fat -F32 /dev/nvme0n1p1
    mkswap /dev/nvme01n1p2
    mkfs.ext4 /dev/nvme0n1p3

Last thing, you have to mount these partitions to their temporary mount points. I'm mounting the EFI partition on /boot, not /efi - that way it's easier to setup the systemd-bootloader. The downside is that your kernel and initrd will land there as well. 

    mount /dev/nvme0n1p3 /mnt
    mkdir /mnt/boot
    mount /dev/nvme0n1p1 /mnt/boot
    swapon /dev/nvme01n1p2

Your Linux base system will be installed to the /mnt directory with the following command:

    pacstrap /mnt base linux linux-firmware intel-ucode wpa_supplicant vim 

If your CPU is AMD, then use amd-ucode instead of intel. If you don't like vim, change it to whatever you feel comfortable with (nano for example)

When the base system is installed to /mnt, generate the fstab config file with the following:

    genfstab -U /mnt >> /mnt/etc/fstab

At this point you can leave the live system and change into into your actual installed one.

## Initial setup 

Change into the installed system:

    arch-chroot /mnt

You'll notice the different prompt. Your former /mnt is now the / (root) directory. 

Now let's set the local time zone and the locale. I want my system in US English using the UTF-8 encoding (which is somewhat standard on Linux). 

    ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
    hwclock --systohc

Edit /etc/locale.gen and uncomment en_US.UTF-8 UTF-8

    vim /etc/locale.gen

Then run:

    locale-gen

Save the settings for the locale and (if needed) the keyboard layout 

    echo "LANG=en_US.UTF-8" > /etc/locale.conf
    echo "KEYMAP=de-latin1" > /etc/vconsole.conf

Set the computer name and configure the localhost networking:

    echo "thinkpad01" > /etc/hostname
    vim /etc/hosts
	--------------------------------------
        127.0.0.1	localhost
        ::1		localhost
        127.0.1.1	thinkpad01.localdomain	thinkpad01

Set password for the *root* user

    passwd  


## Making it bootable

Create a ramdisk image needed for the boot routine:

    mkinitcpio -P

Now let's install and configure the systemd's own bootloader:

    bootctl install
    vim /boot/loader/loader.conf
	--------------------------------------
        default  arch.conf
        timeout  3
        console-mode keep

    vim /boot/loader/entries/arch.conf
	--------------------------------------
        title   Arch Linux
        linux   /vmlinuz-linux
        initrd  /intel-ucode.img
        initrd  /initramfs-linux.img
        options root=/dev/nvme0n1p3 rw

Remember, it's amd-ucode if your CPU is AMD. Also make sure you've put the right device as your root partition. 

Run following to check for the errors:

    bootctl list  

If everything looks okay, you can exit the chroot-environment, unmount the /mnt, remove the USB-disk and reboot:

    exit
    umount -R /mnt
    reboot

## Setting up networking

If you've done it well, the system will boot up to the login prompt. Login as *root* with the password you've set by the passwd command.

Now let's configure networking with systemd-networkd. First, run the following command to see the available network interfaces:

    networkctl list 

there will be wired adapter with the name beginning with "en", and a wireless with a name beginning with "wl". On my computer it's wlp3s0. I bet you're using a router with wifi. Then create following files:

    vim /etc/systemd/network/25-wireless.network
	--------------------------------------------
        [Match]
        Name=wl*
        
        [Network]
        DHCP=yes
        
        [DHCP]
        RouteMetric=20

    vim /etc/systemd/network/20-wired.network
	--------------------------------------
        [Match]
        Name=en*
        
        [Network]
        DHCP=yes
        
        [DHCP]
        RouteMetric=10

    vim /etc/wpa_supplicant/wpa_supplicant-wlp3s0.conf
	--------------------------------------
        ctrl_interface=/run/wpa_supplicant
        update_config=1
        eapol_version=1
        ap_scan=1
        fast_reauth=1
        
        network={
            ssid="xxx_ssid"
            psk="xxx_password"
        }

Put in you actual SSID and password for the wifi. If you use multiple networks, just add additional network-blocks.

Now enable and start the services:

    systemctl enable systemd-networkd
    systemctl enable wpa_supplicant@wlp3s0
    systemctl start systemd-networkd
    systemctl start wpa_supplicant@wlp3s0

Run following to check the results:

    networkctl list 

The last thing is to make the name resolution work:

    ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
    systemctl enable systemd-resolved
    systemctl start systemd-resolved

To test the networking, ping some internet site:

    ping www.archlinux.org

## Setting up the actual user

Let's set up the actual user you'll be working under. The following commands will create a user *alex* (you're free to chose your own name of course ;) ), add it to the group *wheel* and set its password:

    useradd -m -G wheel alex
    passwd alex

Now install sudo and enable the user for it

    pacman -S sudo
    ln -s /usr/bin/vim /usr/bin/vi 
    visudo 

When the editor opens, uncomment the line "%wheel ALL=(ALL) ALL", making sudo available to the *wheel* group.
Now exit the root shell and login as the new user.

## Setting up the user's environment

Now let's set up the graphical UI and make the environment comfortable. I keep my dotfiles on Github and simply dump them directly into my home directory. You can use them as well:

    sudo pacman -S git
    cd ~
    git init
    git remote add origin https://github.com/asustavov/minimalarch.git
    git fetch
    git checkout -f master

Make your text console more usable:

    sudo pacman -S man-db bash-completion

The additional packages you'll require for setting up the graphical system on Wayland:

    sudo pacman -S sway bemenu ttf-font-awesome acpi termite

When asked for options, choose fonts: ttf-droid, opengl driver: mesa, bemenu: wlroots. 

Install more the sound goodness:

    sudo pacman -S pulseaudio pulseaudio-alsa pavucontrol
    pulseaudio --daemonize

PS. From a comment on Reddit:

There are equivalents for selecting timezones and utc hardware clock using timedatectl. You can use machinectl to see the hostname, and pulseaudio comes with a systemd service systemctl --user enable --now pulseaudio.
