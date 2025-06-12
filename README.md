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

### `VM-Creation-Script.ps1`

This PowerShell script provides an **interactive VM deployment system** for VMware vSphere environments, designed for educational or lab settings where multiple VMs need to be created and assigned to users from Active Directory groups.

**Sanitized for envrionment anonymity**

**Features:**
- Interactive menu-driven configuration for all deployment parameters
- Cluster-aware resource allocation (datastores, networks, resource pools)
- Support for both Windows and Linux VM deployments
- Automated OS customization and network configuration
- User assignment with administrator privileges via PowerShell remoting
- Comprehensive logging of all assignments and operations
- CD/DVD drive configuration for client device access
- Sequential or parallel VM provisioning options

**Key Capabilities:**
- Creates VMs based on AD group membership count
- Assigns individual VMs to users sorted by lastname
- Reserves VM00 for faculty and creates additional IT machine
- Handles Linux deployments with assignment-only logging
- Configures local administrator access for assigned users
- Network adapter management with VMXNET3 drivers

**Prerequisites:**
- VMware PowerCLI module
- Active Directory PowerShell module
- Appropriate vCenter Server permissions
- Domain administrator privileges for user assignment

**Usage:**
```powershell
# Run the script in PowerShell with required modules
.\VM-Creation-Script.ps1
```

**Configuration:**
The script will prompt for all necessary parameters including:
- Active Directory group name
- vCenter cluster and datastore selection
- VM naming prefix and folder location
- Template and customization specifications
- Network and resource pool assignments
- Faculty user ID and log file location

---

### `VM-Late-Adds-Script.ps1`

This PowerShell script provides a **streamlined solution for adding individual students** to existing VM lab environments. It automatically detects the next available VM numbers and creates new VMs for late-enrolling students without disrupting existing assignments.

**Sanitized for envrionment anonymity**

**Features:**
- Intelligent VM numbering that continues from existing deployments
- Manual student User ID collection for precise control
- Automatic detection of highest existing VM numbers in the folder
- Individual VM-to-student mapping and assignment
- Same cluster-aware configuration as the main deployment script
- Comprehensive error handling and logging for each student
- Built-in wait periods for VM readiness before configuration

**Key Capabilities:**
- Scans existing VMs to determine next sequential numbers
- Creates only the exact number of VMs needed for new students
- Maintains consistency with existing naming conventions
- Assigns administrator privileges to both students and faculty
- Handles PowerShell remoting setup for Windows VMs
- Configures network adapters and OS customization specs
- Sets CD/DVD drives to client device mode

**Prerequisites:**
- VMware PowerCLI module
- Active Directory PowerShell module
- Existing VM folder with established naming convention
- Appropriate vCenter Server permissions
- Domain administrator privileges for user assignment

**Usage:**
```powershell
# Run the script in PowerShell with required modules
.\VM-Late-Adds-Script.ps1
```

**Configuration:**
The script will prompt for:
- Faculty User ID and existing VM folder location
- Number of students to add and their individual User IDs
- Same infrastructure selections as main deployment script
- All VMs inherit the same template and network settings

**Workflow:**
1. Analyzes existing VMs to find the highest number
2. Creates new VMs with sequential numbering
3. Applies OS customization and network configuration
4. Assigns individual students to their specific VMs
5. Configures administrator access and logs all assignments

---