#!/bin/bash
set -e

echo "==> Creating /etc/systemd/sleep.conf if it doesn't exist..."
sudo touch /etc/systemd/sleep.conf

echo "==> Installing required packages..."
sudo dnf install -y audit policycoreutils-python-utils libnotify unzip wget python3-gobject polkit

echo "==> Adding HibernateDelaySec to /etc/systemd/sleep.conf..."
sudo sed -i '/^\[Sleep\]/d' /etc/systemd/sleep.conf
echo -e "[Sleep]\nHibernateDelaySec=600" | sudo tee -a /etc/systemd/sleep.conf

echo "==> Updating /etc/systemd/logind.conf to configure lid close behavior..."
sudo sed -i '/^\[Login\]/d' /etc/systemd/logind.conf
echo -e "[Login]\nHandleLidSwitch=suspend" | sudo tee -a /etc/systemd/logind.conf

echo "==> Downloading Hibernate GNOME Extension..."
wget -q https://github.com/ctsdownloads/gnome-shell-extension-hibernate-status/archive/refs/heads/master.zip -O /tmp/hibernate-extension.zip

echo "==> Unzipping extension..."
unzip -oq /tmp/hibernate-extension.zip -d /tmp/hibernate-extension

EXT_SRC="/tmp/hibernate-extension/gnome-shell-extension-hibernate-status-master"
EXT_UUID="hibernate-status@ctsdownloads"
EXT_DEST="$HOME/.local/share/gnome-shell/extensions/$EXT_UUID"

echo "==> Installing GNOME extension to $EXT_DEST..."
mkdir -p "$EXT_DEST"
cp -r "$EXT_SRC"/* "$EXT_DEST"

echo "==> Enabling GNOME extension..."
gnome-extensions enable "$EXT_UUID" || echo "Please enable manually if this fails."

echo "==> Checking installed dependencies..."
rpm -q python3-gobject polkit || echo "Some dependencies may not be properly installed."

echo "==> Checking GNOME extension install..."
gnome-extensions list | grep "$EXT_UUID" || echo "Extension not found in list."

echo "==> Checking SELinux policy enforcement..."
sudo setenforce 0
sudo ausearch -m avc -ts recent | audit2allow -M hibernate_policy || echo "No AVC messages found to build policy."
sudo semodule -i hibernate_policy.pp 2>/dev/null || echo "No policy applied or file not created."
sudo setenforce 1

echo "==> Setup complete. Please reboot your system to apply all changes."
