ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
ln -s /usr/bin/vim /usr/bin/vi 
hwclock --systohc
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=de-latin1" > /etc/vconsole.conf
echo "thinkpad01" > /etc/hostname

cp ./loader.conf /boot/loader/
cp ./arch.conf /boot/loader/entries/
cp ./25-wireless.network /etc/systemd/network/
cp ./20-wired.network /etc/systemd/network/
cp ./wpa_supplicant-wlp3s0.conf /etc/wpa_supplicant/

systemctl enable --now systemd-networkd
systemctl enable --now wpa_supplicant@wlp3s0

ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
systemctl enable --now systemd-resolved


