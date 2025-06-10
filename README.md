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

---

### `tidal_import.py`

This script scans a local music folder (e.g. network share or library inbox), extracts metadata from supported audio files (`.mp3`, `.flac`, `.m4a`), and attempts to match each track to the TIDAL catalog using the TIDAL API. If a match is found, the track is added to a new playlist in your TIDAL account.

**Features:**

* Supports `.mp3`, `.flac`, and `.m4a` file types
* Reads metadata using `mutagen` for artist/title/album info
* Matches songs using TIDAL’s search API with multiple fallback strategies
* Skips remixes and handles fuzzy matching
* Logs failures to `failed_tracks.log` for review
* Adds all matches to a user-owned TIDAL playlist (created on the fly)

**Usage:**

```bash
pip install mutagen tidalapi
python tidal_import.py
```

**Configuration:**
Edit the variables at the top of the script to specify:

* The target music folder (e.g. network share path)
* Playlist name and description
* Delay between TIDAL requests to avoid throttling
* File types to process

> Ideal for automating the import of newly downloaded or ripped music into your TIDAL library.

---
