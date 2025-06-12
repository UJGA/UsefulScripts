#————————————————————————————————————————————————————————————————————————————————————————
# VM Creation Script with Interactive Menu - With Cluster-Based Logic and Template Text Input
# SANITIZED VERSION - Remove environment-specific information before sharing
#————————————————————————————————————————————————————————————————————————————————————————

function Show-Menu {
    param (
        [string]$Title,
        [array]$Options
    )
    
    Write-Host "================ $Title ================"
    for ($i = 0; $i -lt $Options.Count; $i++) {
        Write-Host "[$i] $($Options[$i])"
    }
    
    $selection = Read-Host "Please make a selection (0-$($Options.Count - 1))"
    
    if ($selection -match '^\d+$' -and [int]$selection -ge 0 -and [int]$selection -lt $Options.Count) {
        return $Options[[int]$selection]
    } else {
        Write-Host "Invalid selection. Please try again." -ForegroundColor Red
        return Show-Menu -Title $Title -Options $Options
    }
}

function Get-UserInput {
    param (
        [string]$Prompt
    )
    
    $userInput = ""
    while ([string]::IsNullOrWhiteSpace($userInput)) {
        $userInput = Read-Host $Prompt
        if ([string]::IsNullOrWhiteSpace($userInput)) {
            Write-Host "Input cannot be empty. Please try again." -ForegroundColor Red
        }
    }
    return $userInput
}

# Clear screen and show welcome message
Clear-Host
Write-Host "Welcome to the VM Creation Script" -ForegroundColor Green
Write-Host "Please configure the following parameters:" -ForegroundColor Cyan
Write-Host ""

# Get Active Directory group
$ad_group = Get-UserInput -Prompt "Specify the Active Directory group (Ex: CLASS123)"

# Select vCenter Server datastore - This will determine related cluster options
$datastoreOptions = @("Cluster1_vSAN", "Cluster2_vSAN")
$Datastore = Show-Menu -Title "Select vCenter Server datastore" -Options $datastoreOptions

# Set cluster value based on datastore selection
$clusterSelection = if ($Datastore -eq "Cluster1_vSAN") { "Cluster1" } else { "Cluster2" }
Write-Host "Selected cluster: $clusterSelection" -ForegroundColor Cyan

# Get folder to place the VMs
$Folder = Get-UserInput -Prompt "Specify folder to place the VMs"

# Get VM name prefix
$VM_prefix = Get-UserInput -Prompt "Specify the VM name prefix with the - sign (Ex: CLASS123-)"

# Select Resource Pool based on the selected cluster
if ($clusterSelection -eq "Cluster1") {
    $ResourcePoolName = "Classes-Cluster1"
    Write-Host "Resource Pool automatically set to: $ResourcePoolName" -ForegroundColor Cyan
} else {
    $ResourcePoolName = "Classes-Cluster2"
    Write-Host "Resource Pool automatically set to: $ResourcePoolName" -ForegroundColor Cyan
}

# Select VM provisioning type
$provisioningOptions = @("false (sequential)", "true (parallel)")
$provisioningSelection = Show-Menu -Title "Select VM provisioning type" -Options $provisioningOptions
$VM_create_async = $provisioningSelection -eq "true (parallel)"

# Get VM template as direct text input
$VM_from_template = Get-UserInput -Prompt "Specify the VM template name"

# Select VM disk type
$diskTypeOptions = @("Thin", "Thick")
$Typeguestdisk = Show-Menu -Title "Select VM disk type - Usually Thin" -Options $diskTypeOptions

# Select OS Customization Spec
$osCustomOptions = @("Custom - AD,DHCP", "Custom - Server OS", "Custom - Linux", "Custom - DHCP No AD")
$osCustomizationSpecName = Show-Menu -Title "Select OS Customization Spec" -Options $osCustomOptions

# Determine if this is a Linux deployment based on customization spec
$isLinuxDeployment = $osCustomizationSpecName -eq "Custom - Linux"

# Select Network Name based on the selected cluster
Write-Host "`nShowing networks for cluster: $clusterSelection" -ForegroundColor Cyan

if ($clusterSelection -eq "Cluster1") {
    $networkOptions = @(
        "VLAN100__Network_1__Cluster1",
        "VLAN101__Network_2__Cluster1",
        "VLAN102__Network_3__Cluster1",
        "VLAN103__Network_4__Cluster1",
        "VLAN104__Network_5__Cluster1",
        "VLAN105__Network_6__Cluster1"
    )
} else {
    $networkOptions = @(
        "VLAN100__Network_1__Cluster2",
        "VLAN101__Network_2__Cluster2",
        "VLAN102__Network_3__Cluster2",
        "VLAN103__Network_4__Cluster2",
        "VLAN104__Network_5__Cluster2",
        "VLAN105__Network_6__Cluster2"
    )
}

$networkName = Show-Menu -Title "Select Network for $clusterSelection" -Options $networkOptions

# Get Faculty User ID
$faculty = Get-UserInput -Prompt "Specify Faculty User ID for Class"

# Get Log Directory
$log = Get-UserInput -Prompt "Specify Directory where log should be saved - EX: C:\Scripts\VMCreation\Logs\deployment.txt"

# Show summary of selected options
Write-Host "`n================ Configuration Summary ================" -ForegroundColor Yellow
Write-Host "Cluster: $clusterSelection" -ForegroundColor Cyan
Write-Host "Active Directory Group: $ad_group"
Write-Host "Datastore: $Datastore"
Write-Host "Folder: $Folder"
Write-Host "VM Prefix: $VM_prefix"
Write-Host "Resource Pool: $ResourcePoolName"
Write-Host "VM Create Async: $VM_create_async"
Write-Host "VM Template: $VM_from_template"
Write-Host "Guest Disk Type: $Typeguestdisk"
Write-Host "OS Customization Spec: $osCustomizationSpecName"
Write-Host "Network Name: $networkName"
Write-Host "Faculty User ID: $faculty"
Write-Host "Log Path: $log"
Write-Host "Deployment Type: $(if ($isLinuxDeployment) { 'Linux (Assignment Only)' } else { 'Windows (Full Setup)' })" -ForegroundColor $(if ($isLinuxDeployment) { 'Magenta' } else { 'Cyan' })

# Ask for confirmation to proceed
$proceed = $false
while (!$proceed) {
    $confirm = Read-Host "`nDo you want to proceed with these settings? (Y/N)"
    if ($confirm -eq "Y" -or $confirm -eq "y") {
        $proceed = $true
    } elseif ($confirm -eq "N" -or $confirm -eq "n") {
        Write-Host "Script cancelled by user." -ForegroundColor Red
        exit
    } else {
        Write-Host "Invalid input. Please enter Y or N." -ForegroundColor Red
    }
}

# Continue with the rest of the script
# The variables are now set with user input values
Write-Host "`nProceeding with VM creation..." -ForegroundColor Green

# End of parameter configuration
#————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

#Begin VM Creation

# Prompt for vCenter credentials
$cred = Get-Credential -Message "Enter your vCenter credentials"

# Connect to vCenter - UPDATE THIS WITH YOUR VCENTER SERVER
$vcServer = "your-vcenter-server.domain.com" 

Connect-VIServer -Server $vcServer -Credential $cred

clear-host

# Query Active Directory for the count of users in the specified group
Import-Module ActiveDirectory
$vm_count = (Get-ADGroupMember -Identity $ad_group).Count

$o = Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false

0..$vm_count | ForEach-Object {
    $VM_postfix="{0:D2}" -f $_
    $VM_name= $VM_prefix + $VM_postfix

    write-host "Deployment of VM $VM_name from template $VM_from_template initiated" -foreground green
    $vm = New-VM -RunAsync:$VM_create_async -Name $VM_Name -Template $VM_from_template -ResourcePool $ResourcePoolName -Datastore $Datastore -Location $Folder
}

# For the extra VM
$VM_name= $VM_prefix + "IT"
write-host "Deployment of VM $VM_name from template $VM_from_template initiated" -foreground green
$vm = New-VM -RunAsync:$VM_create_async -Name $VM_Name -Template $VM_from_template -ResourcePool $ResourcePoolName -Datastore $Datastore -Location $Folder

# End of VM Creation section
#————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

$continue = Read-Host "Next step is applying OS Customization and network - Do you want to continue? (y/n)"

if ($continue -ne "y") {
    exit
}

#OS Customization and Network Adapter Creation

# Get all VMs in the specified folder
$vmFolder = Get-Folder -Name $Folder
$vms = Get-VM -Location $vmFolder | Where-Object { $_.Name.StartsWith($VM_prefix) }

foreach ($vm in $vms) {

    # Add a network adapter and connect it at power on
    Write-Host "Adding network adapter to VM $($vm.Name) and connecting it at power on"
    Get-NetworkAdapter -VM $vm | Remove-NetworkAdapter -Confirm:$false # Remove existing network adapters
    New-NetworkAdapter -VM $vm -NetworkName $networkName -StartConnected:$true -Type "VMXNET3" -Confirm:$false

        # Apply OS Customization Spec
        Write-Host "Applying OS Customization Spec to VM $($vm.Name)"
        Set-VM -VM $vm -OSCustomizationSpec $osCustomizationSpecName -Confirm:$false

    # Power on the VM if it's not already running
    if ($vm.PowerState -ne "PoweredOn") {
        Write-Host "Powering on VM $($vm.Name)"
        Start-VM -VM $vm -Confirm:$false
    }
}

#End of OS Customization and Network Adapter Creation
#————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

Write-Host "`n================ Please move the machines in AD and power cycle them if they will be domain joined ================" -ForegroundColor Green
$continue = Read-Host "Next step is assigning the machines - Do you want to continue? (y/n)"

if ($continue -ne "y") {
    exit
}

# Assigning users to VMs

# Sort users by lastname, excluding the faculty member if they are not part of this group
$users = Get-ADGroupMember $ad_group | Get-ADUser | Where-Object {$_.SamAccountName -ne $faculty} | Sort-Object Surname

# Manages loop count, start at 1 for VM01 as VM00 is reserved for faculty
$i = 1

if ($isLinuxDeployment) {
    # Linux deployment - Just log assignments without connecting to machines
    Write-Host "`n================ Linux Deployment - Logging Assignments Only ================" -ForegroundColor Magenta
    
    # Special handling for VM00, assigned to faculty
    $m = "$VM_prefix" + "00"
    Write-Host "$m - assigned to faculty $faculty" -ForegroundColor Green
    Add-Content $log @("$m - assigned to faculty $faculty")
    
    # Running the assignment logging for students
    foreach ($n in $users) {
        $VMNumber = "{0:D2}" -f $i  # Pads with leading zero
        $m = "$VM_prefix$VMNumber"
        
        $user = Get-ADUser -Identity $n.SamAccountName
        $UserID = $user.SamAccountName
        
        Write-Host "$m - assigned to $UserID" -ForegroundColor Green
        Add-Content $log @("$m - assigned to $UserID")
        
        $i++
    }
    
    # Handle the IT machine
    $m = "$VM_prefix" + "IT"
    Write-Host "$m - assigned to IT" -ForegroundColor Green
    Add-Content $log @("$m - assigned to IT")
    
    Write-Host "`nLinux assignment logging completed. Students will use shared 'student' account on their assigned machines." -ForegroundColor Yellow
    
} else {
    # Windows deployment - Full PowerShell remoting setup
    Write-Host "`n================ Windows Deployment - Full Setup ================" -ForegroundColor Cyan
    
    # Special handling for VM00, assigned to faculty
    $m = "$VM_prefix" + "00"

    if (Test-Connection -ComputerName $m -Count 1 -Quiet) {
        $s = New-PSSession -ComputerName $m -ErrorAction SilentlyContinue
        if ($s) {
            Add-Content $log @("$m assigned to faculty $faculty")
            $isAdmin = Invoke-Command -Session $s -ScriptBlock { net localgroup administrators | Select-String $Using:faculty }
            if (-not $isAdmin) {
                Invoke-Command -Session $s -ScriptBlock { net localgroup administrators /add DOMAIN\$Using:faculty }
            }
            Remove-PSSession $s
        } else {
            Write-Host "Failed to create session to $m"
            Add-Content $log @("$m - FAILED to create session for faculty")
        }
    } else {
        Write-Host "$m is not reachable via ping."
        Add-Content $log @("$m - Unreachable for faculty")
    }

    # Running the script for students
    foreach ($n in $users) {
        $VMNumber = "{0:D2}" -f $i  # Pads with leading zero
        $m = "$VM_prefix$VMNumber"

        Write-Host "Processing $m"

        if (-not (Test-Connection -ComputerName $m -Count 1 -Quiet)) {
            Write-Host "$m is not reachable via ping."
            Add-Content $log @("$m - Unreachable")
            $i++
            continue
        }

        $s = New-PSSession -ComputerName $m -ErrorAction SilentlyContinue
        if (-not $s) {
            Write-Host "Failed to create session to $m"
            Add-Content $log @("$m - FAILED to create session")
            $i++
            continue
        }

        $user = Get-ADUser -Identity $n.SamAccountName
        $UserID = $user.SamAccountName

        Add-Content $log @("$m assigned to $($user.Name)")

        # Check and add user if not already an admin
        $isUserAdmin = Invoke-Command -Session $s -ScriptBlock { net localgroup administrators | Select-String $Using:UserID }
        if (-not $isUserAdmin) {
            Invoke-Command -Session $s -ScriptBlock { net localgroup administrators /add DOMAIN\$Using:UserID }
        }

        # Check and add faculty if not already an admin, applies to all VMs
        $isFacultyAdmin = Invoke-Command -Session $s -ScriptBlock { net localgroup administrators | Select-String $Using:faculty }
        if (-not $isFacultyAdmin) {
            Invoke-Command -Session $s -ScriptBlock { net localgroup administrators /add DOMAIN\$Using:faculty }
        }

        Remove-PSSession $s
        $i++
    }
}

#Set Client Device for CD/DVD Drive

$vms = Get-Folder -Name $Folder -Type VM | Get-VM -Recurse
foreach ($vm in $vms) {
    $cdrom = Get-CDDrive -VM $vm | Where-Object { $_.Name -eq "CD/DVD drive 1" }
    
    # Check if the CD/DVD drive exists and is not already set to Client Device
    if ($cdrom -and $cdrom.ConnectionState.Connected -eq $true -and $cdrom.ConnectionType.ToString() -ne "Client") {
        try {
            Set-CDDrive -CD $cdrom -NoMedia -Confirm:$false
            Write-Host "Changed CD/DVD drive for VM $($vm.Name) to Client Device"
        } catch {
            Write-Host "Error changing CD/DVD drive for VM $($vm.Name): $($_.Exception.Message)"
        }
    } else {
        if (-not $cdrom) {
            Write-Host "Skipping VM $($vm.Name): CD/DVD drive 1 not found"
        } else {
            Write-Host "Skipping VM $($vm.Name): CD/DVD drive already set to Client Device or not connected"
        }
    }
}