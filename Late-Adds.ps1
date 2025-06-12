#————————————————————————————————————————————————————————————————————————————————————————
# VM Creation Script for Late Add Students
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
Write-Host "Welcome to the Late Add Student VM Creation Script" -ForegroundColor Green
Write-Host "Please configure the following parameters:" -ForegroundColor Cyan
Write-Host ""

# Get Faculty User ID
$faculty = Get-UserInput -Prompt "Specify Faculty User ID for Class"

# Get VM name prefix
$VM_prefix = Get-UserInput -Prompt "Specify the VM name prefix with the - sign (Ex: CLASS123-)"

# Get Folder to check for existing VMs
$Folder = Get-UserInput -Prompt "Specify folder containing the existing VMs"

# Get number of students to add
$numStudentsToAdd = 0
$validNumber = $false
while (-not $validNumber) {
    $input = Read-Host "How many students do you need to add?"
    if ($input -match '^\d+$' -and [int]$input -gt 0) {
        $numStudentsToAdd = [int]$input
        $validNumber = $true
    } else {
        Write-Host "Please enter a valid positive number." -ForegroundColor Red
    }
}

# Collect student User IDs
$studentsToAssign = @()
for ($i = 1; $i -le $numStudentsToAdd; $i++) {
    $studentID = Get-UserInput -Prompt "Enter User ID for student $i of $numStudentsToAdd"
    $studentsToAssign += $studentID
}

# Select vCenter Server datastore - This will determine related cluster options
$datastoreOptions = @("Cluster1_vSAN", "Cluster2_vSAN")
$Datastore = Show-Menu -Title "Select vCenter Server datastore" -Options $datastoreOptions

# Set cluster value based on datastore selection
$clusterSelection = if ($Datastore -eq "Cluster1_vSAN") { "Cluster1" } else { "Cluster2" }
Write-Host "Selected cluster: $clusterSelection" -ForegroundColor Cyan

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

# Get Log Directory
$log = Get-UserInput -Prompt "Specify Directory where log should be saved - EX: C:\Scripts\VMCreation\Logs\late-adds.txt"

# Show summary of selected options
Write-Host "`n================ Configuration Summary ================" -ForegroundColor Yellow
Write-Host "Cluster: $clusterSelection" -ForegroundColor Cyan
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
Write-Host "Students to add: $numStudentsToAdd"
Write-Host "Student User IDs: $($studentsToAssign -join ', ')"

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

# Prompt for vCenter credentials
$cred = Get-Credential -Message "Enter your vCenter credentials"

# Connect to vCenter - UPDATE THIS WITH YOUR VCENTER SERVER
$vcServer = "your-vcenter-server.domain.com" 
Connect-VIServer -Server $vcServer -Credential $cred

Clear-Host

# Configure PowerCLI to ignore certificate errors
$o = Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false

# Find the highest VM number in the folder
Write-Host "Determining the next available VM numbers..." -ForegroundColor Cyan
$existingVMs = Get-Folder -Name $Folder | Get-VM | Where-Object { $_.Name -match "$VM_prefix(\d+)$" }
$highestVMNumber = 0

if ($existingVMs) {
    foreach ($vm in $existingVMs) {
        if ($vm.Name -match "$VM_prefix(\d+)$") {
            $vmNumber = [int]$matches[1]
            if ($vmNumber -gt $highestVMNumber) {
                $highestVMNumber = $vmNumber
            }
        }
    }
}

Write-Host "Highest existing VM number found: $highestVMNumber" -ForegroundColor Cyan
$nextVMNumber = $highestVMNumber + 1

# Create the new VMs
$newVMNames = @()
for ($i = 0; $i -lt $numStudentsToAdd; $i++) {
    $VMNumber = "{0:D2}" -f ($nextVMNumber + $i)
    $VM_name = "$VM_prefix$VMNumber"
    $newVMNames += $VM_name
    
    Write-Host "Deployment of VM $VM_name from template $VM_from_template initiated" -ForegroundColor Green
    $vm = New-VM -RunAsync:$VM_create_async -Name $VM_Name -Template $VM_from_template -ResourcePool $ResourcePoolName -Datastore $Datastore -Location $Folder
}

Write-Host "Created the following VMs:" -ForegroundColor Green
$newVMNames | ForEach-Object { Write-Host "- $_" }

# Wait for VM creation to complete if async
if ($VM_create_async) {
    Write-Host "Waiting for VM creation tasks to complete..." -ForegroundColor Yellow
    Get-Task | Where-Object { $_.Name -eq "CloneVM_Task" -and $_.State -eq "Running" } | Wait-Task
}

$continue = Read-Host "Next step is applying OS Customization and network - Do you want to continue? (y/n)"

if ($continue -ne "y") {
    exit
}

# OS Customization and Network Adapter Setup
foreach ($vmName in $newVMNames) {
    $vm = Get-VM -Name $vmName

    # Add a network adapter and connect it at power on
    Write-Host "Adding network adapter to VM $vmName and connecting it at power on"
    Get-NetworkAdapter -VM $vm | Remove-NetworkAdapter -Confirm:$false # Remove existing network adapters
    New-NetworkAdapter -VM $vm -NetworkName $networkName -StartConnected:$true -Type "VMXNET3" -Confirm:$false

    # Apply OS Customization Spec
    Write-Host "Applying OS Customization Spec to VM $vmName"
    Set-VM -VM $vm -OSCustomizationSpec $osCustomizationSpecName -Confirm:$false

    # Power on the VM if it's not already running
    if ($vm.PowerState -ne "PoweredOn") {
        Write-Host "Powering on VM $vmName"
        Start-VM -VM $vm -Confirm:$false
    }
}

Write-Host "`n================ Please move the machines in AD and power cycle them if they will be domain joined ================" -ForegroundColor Green
$continue = Read-Host "Next step is assigning the machines to students - Do you want to continue? (y/n)"

if ($continue -ne "y") {
    exit
}

# Import Active Directory module
Import-Module ActiveDirectory

# Create a mapping of students to VMs
$studentVMMapping = @{}
for ($i = 0; $i -lt [Math]::Min($studentsToAssign.Count, $newVMNames.Count); $i++) {
    $studentVMMapping[$studentsToAssign[$i]] = $newVMNames[$i]
}

# Wait for VMs to be ready
Write-Host "Waiting for VMs to be ready for connections..."
$waitTime = 180
Write-Host "Will attempt connections in $waitTime seconds..."
Start-Sleep -Seconds $waitTime

# Assign students to their VMs
foreach ($studentID in $studentsToAssign) {
    if (-not $studentVMMapping.ContainsKey($studentID)) {
        Write-Host "No VM assigned for student $studentID" -ForegroundColor Yellow
        continue
    }
    
    $vmName = $studentVMMapping[$studentID]
    Write-Host "Processing $vmName for student $studentID" -ForegroundColor Cyan
    
    if (-not (Test-Connection -ComputerName $vmName -Count 1 -Quiet)) {
        Write-Host "$vmName is not reachable via ping." -ForegroundColor Red
        Add-Content $log @("$vmName - Unreachable")
        continue
    }
    
    $session = New-PSSession -ComputerName $vmName -ErrorAction SilentlyContinue
    if (-not $session) {
        Write-Host "Failed to create session to $vmName" -ForegroundColor Red
        Add-Content $log @("$vmName - FAILED to create session")
        continue
    }
    
    try {
        # Get student name from AD
        $user = Get-ADUser -Identity $studentID
        $studentName = $user.Name
        
        Add-Content $log @("$vmName assigned to $studentName")
        
        # Add student to administrators group
        $isUserAdmin = Invoke-Command -Session $session -ScriptBlock { 
            net localgroup administrators | Select-String $Using:studentID 
        }
        
        if (-not $isUserAdmin) {
            Write-Host "Adding $studentID to administrators group on $vmName" -ForegroundColor Green
            Invoke-Command -Session $session -ScriptBlock { 
                net localgroup administrators /add DOMAIN\$Using:studentID 
            }
        }
        
        # Add faculty to administrators group
        $isFacultyAdmin = Invoke-Command -Session $session -ScriptBlock { 
            net localgroup administrators | Select-String $Using:faculty 
        }
        
        if (-not $isFacultyAdmin) {
            Write-Host "Adding faculty $faculty to administrators group on $vmName" -ForegroundColor Green
            Invoke-Command -Session $session -ScriptBlock { 
                net localgroup administrators /add DOMAIN\$Using:faculty 
            }
        }
    }
    catch {
        Write-Host "Error processing ${vmName}: $($_.Exception.Message)" -ForegroundColor Red
        Add-Content $log @("$vmName - ERROR: $($_.Exception.Message)")
    }
    finally {
        if ($session) {
            Remove-PSSession $session
        }
    }
}

# Set CD/DVD drives to Client Device
Write-Host "Setting CD/DVD drives to Client Device for new VMs..." -ForegroundColor Cyan
foreach ($vmName in $newVMNames) {
    $vm = Get-VM -Name $vmName
    $cdrom = Get-CDDrive -VM $vm | Where-Object { $_.Name -eq "CD/DVD drive 1" }
    
    if ($cdrom -and $cdrom.ConnectionState.Connected -eq $true -and $cdrom.ConnectionType.ToString() -ne "Client") {
        try {
            Set-CDDrive -CD $cdrom -NoMedia -Confirm:$false
            Write-Host "Changed CD/DVD drive for VM $vmName to Client Device" -ForegroundColor Green
        } catch {
            Write-Host "Error changing CD/DVD drive for VM ${vmName}: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        if (-not $cdrom) {
            Write-Host "Skipping VM ${vmName}: CD/DVD drive 1 not found" -ForegroundColor Yellow
        } else {
            Write-Host "Skipping VM ${vmName}: CD/DVD drive already set to Client Device or not connected" -ForegroundColor Yellow
        }
    }
}

Write-Host "`n================ Late Add Student VM Creation Complete ================" -ForegroundColor Green
Write-Host "Created and assigned the following VMs:" -ForegroundColor Cyan
foreach ($studentID in $studentsToAssign) {
    if ($studentVMMapping.ContainsKey($studentID)) {
        $user = Get-ADUser -Identity $studentID
        Write-Host "$($studentVMMapping[$studentID]) -> $($user.Name) ($studentID)" -ForegroundColor Cyan
    }
}

Disconnect-VIServer -Server $vcServer -Confirm:$false