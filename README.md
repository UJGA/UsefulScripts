# UsefulScripts

A curated collection of scripts designed to automate and streamline setup tasks on the [Framework 13](https://frame.work) laptop. These scripts are tailored for Linux users (particularly Fedora-based distributions) and aim to simplify system configuration, hardware support, and quality-of-life improvements.

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
```
---

### `tidal_import.py`

This script scans a local music folder (e.g. a network share or library inbox), extracts metadata from supported audio files, and attempts to match each track to the TIDAL catalog using the TIDAL API. If a match is found, the track is added to a new playlist in your TIDAL account.

**Features:**
- Supports `.mp3`, `.flac`, and `.m4a` file types
- Uses `mutagen` to extract artist, title, and album metadata
- Matches songs using TIDAL’s API with fuzzy and fallback logic
- Avoids remixes and partial mismatches when possible
- Logs all failures to `failed_tracks.log` for easy review
- Adds matched tracks to a user-owned playlist created at runtime

**Usage:**
```bash
pip install mutagen tidalapi
python tidal_import.py
```
---
