# UsefulScripts

A curated collection of scripts designed to automate and streamline setup tasks on the [Framework 13](https://frame.work) laptop. These scripts are tailored for my use cases and aim to simplify system configuration, hardware support, and quality-of-life improvements.

---

## Included Scripts

### `Fedora-Hibernate.sh`

This script automates the full manual setup process for enabling **hibernate on Fedora** using a swap partition. It follows Framework's community-recommended approach, including GNOME Shell integration.

**Features:**
- Installs required packages for hibernation
- Configures `/etc/systemd/sleep.conf` and `/etc/systemd/logind.conf`
- Installs and enables the GNOME Hibernate extension
- Optionally handles SELinux policy creation if necessary

**Usage:**
```bash
chmod +x Fedora-Hibernate.sh
./Fedora-Hibernate.sh
