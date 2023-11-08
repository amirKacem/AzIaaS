#For nested virtualization for a Hyper-V VM
Set-VMProcessor -VMName 2019OnDemand -ExposeVirtualizationExtensions $true -Verbose
Get-VM 2019OnDemand | Set-VMNetworkAdapter -MacAddressSpoofing On -Verbose


#region  setup networking with Nating in an Azure VM that has nested virtualization enabled  [https://www.vembu.com/blog/running-hyper-v-in-azure-nested-virtualization/]

Install-WindowsFeature -Name Hyper-V -IncludeAllSubFeature -IncludeManagementTools -Restart -Verbose

New-VMSwitch -Name "InternalNATSwitch" -SwitchType Internal -Verbose

Get-NetAdapter -Verbose   #mark the Index of the Hyper-V adapter
Rename-NetAdapter -Name Ethernet -NewName IntConnection -Verbose
Get-NetIPAddress|ft

New-NetIPAddress -IPAddress 192.168.0.1 -PrefixLength 24 -InterfaceIndex 13 -Verbose #Index should be the same as that of the hyper-V adapter

New-NetNat -Name InternalNat -InternalIPInterfaceAddressPrefix 192.168.0.0/24 -Verbose  #Will make you lose RDP connection on an AzVM

#Change VM's NIC's IP to be in the same subnet as the switch
Get-NetIPConfiguration
Get-NetAdapter
Get-NetAdapterHardwareInfo #shows nothing on a VM
Get-NetAdapter | ft Name, DriverFileName, DriverData, DriverDescription

New-NetIPAddress -InterfaceIndex 4 -IPAddress 192.168.0.2 -PrefixLength 24 -DefaultGateway 192.168.0.1
ping 8.8.8.8  #worked
Set-DnsClientServerAddress -InterfaceIndex 2 -ServerAddresses 8.8.8.8
ping google.com  #worked




#endregion



#region v2:For Win11 client. Should work above Dv3 and Ev3
Import-Module DISM -UseWindowsPowerShell
Enable-WindowsOptionalFeature -Online -FeatureName NetFx3
Get-WindowsOptionalFeature -Online -FeatureName *hy*|FT
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -Verbose #Enable Hyper-V using PowerShell  on Windows 11
#Restart
Get-WindowsOptionalFeature -Online -FeatureName *hy*|FT
#endregion


#Get name of the HyperV host from VM
(get-item "HKLM:\SOFTWARE\Microsoft\Virtual Machine\Guest\Parameters").GetValue("PhysicalHostName")
(get-item "HKLM:\SOFTWARE\Microsoft\Virtual Machine\Guest\Parameters").GetValue("VirtualMachineName")


(get-item "HKLM:\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Azure").GetValue("VmId")  #Get the Azure VM id from within the OS
(get-item "HKLM:\HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\HealthService\Parameters").GetValue("Azure Resource Id")  #Get the Azure VM resource id from within the OS


#region  Nested virtualization setup in an Azure VM| MS script
Param([Parameter(Mandatory=$false)][string]$gen)

. .\src\windows\common\setup\init.ps1

Log-Info 'Running Script Enable-NestedHyperV'

$scriptStartTime = get-date -f yyyyMMddHHmmss
$scriptPath = split-path -path $MyInvocation.MyCommand.Path -parent
$scriptName = (split-path -path $MyInvocation.MyCommand.Path -leaf).Split('.')[0]

$logFile = "$env:PUBLIC\Desktop\$($scriptName).log"
$scriptStartTime | out-file -FilePath $logFile -Append

$nestedGuestVmName = 'ProblemVM'
$batchFile = "$env:allusersprofile\Microsoft\Windows\Start Menu\Programs\StartUp\RunHyperVManagerAndVMConnect.cmd"
$batchFileContents = @"
start $env:windir\System32\mmc.exe $env:windir\System32\virtmgmt.msc
start $env:windir\System32\vmconnect.exe localhost $nestedGuestVmName
"@

$features = get-windowsfeature -ErrorAction Stop
$hyperv = $features | where Name -eq 'Hyper-V'
$hypervTools = $features | where Name -eq 'Hyper-V-Tools'
$hypervPowerShell = $features | where Name -eq 'Hyper-V-Powershell'
$dhcp = $features | where Name -eq 'DHCP'
$rsatDhcp = $features | where Name -eq 'RSAT-DHCP'

if ($hyperv.Installed -and $hypervTools.Installed -and $hypervPowerShell.Installed)
{
    Log-Info 'START: Creating nested guest VM' | out-file -FilePath $logFile -Append
    # Sets "Do not start Server Manager automatically at logon"
    $return = New-ItemProperty -Path HKLM:\Software\Microsoft\ServerManager -Name DoNotOpenServerManagerAtLogon -PropertyType DWORD -Value 1 -force -ErrorAction SilentlyContinue
    $return = New-ItemProperty -Path HKLM:\Software\Microsoft\ServerManager\Oobe -Name DoNotOpenInitialConfigurationTasksAtLogon -PropertyType DWORD -Value 1 -force -ErrorAction SilentlyContinue

    try {

        # Configure NAT so nested guest has external network connectivity
        # See also https://docs.microsoft.com/en-us/virtualization/hyper-v-on-windows/user-guide/nested-virtualization#networking-options
        $switch = Get-VMSwitch -Name Internal -SwitchType Internal -ErrorAction SilentlyContinue | select -first 1
        if (!$switch)
        {
            $switch = New-VMSwitch -Name Internal -SwitchType Internal -ErrorAction Stop
            Log-Info 'New VMSwitch Successfully created' | out-file -FilePath $logFile -Append
        }
        $adapter = Get-NetAdapter -Name 'vEthernet (Internal)' -ErrorAction Stop

        $ip = get-netipaddress -IPAddress 192.168.0.1 -ErrorAction SilentlyContinue | select -first 1
        if (!$ip)
        {
            $return = New-NetIPAddress -IPAddress 192.168.0.1 -PrefixLength 24 -InterfaceIndex $adapter.ifIndex -ErrorAction Stop
            Log-Info 'New NetIPAddress Successfully created' | out-file -FilePath $logFile -Append
        }

        $nat = Get-NetNat -Name InternalNAT -ErrorAction SilentlyContinue | select -first 1
        if (!$nat)
        {
            $return = New-NetNat -Name InternalNAT -InternalIPInterfaceAddressPrefix 192.168.0.0/24 -ErrorAction Stop
            Log-Info 'New NetNat Successfully created' | out-file -FilePath $logFile -Append
        }

        # Configure DHCP server service so nested guest can get an IP from DHCP and will use 168.63.129.16 for DNS and 192.168.0.1 as default gateway
        if ($dhcp.Installed -eq $false -or $rsatDhcp.Installed -eq $false)
        {
            $return = Install-WindowsFeature -Name DHCP -IncludeManagementTools -ErrorAction Stop
            Log-Info 'New NetIPAddress Successfully created' | out-file -FilePath $logFile -Append
        }
        $scope = Get-DhcpServerv4Scope -ErrorAction SilentlyContinue | where Name -eq Scope1 | select -first 1
        if (!$scope)
        {
            $return = Add-DhcpServerV4Scope -Name Scope1 -StartRange 192.168.0.100 -EndRange 192.168.0.200 -SubnetMask 255.255.255.0 -ErrorAction Stop
        }
        $return = Set-DhcpServerv4OptionValue -DnsServer 168.63.129.16 -Router 192.168.0.1 -ErrorAction Stop

        # Create the nested guest VM
        if (!$gen -or ($gen -eq 1)) {
            Log-Info 'Creating Gen1 VM with 4GB memory' | Out-File -FilePath $logFile -Append
            $return = New-VM -Name $nestedGuestVmName -MemoryStartupBytes 4GB -NoVHD -BootDevice IDE -Generation 1 -ErrorAction Stop
        }
        else {
            Log-Info "Creating Gen$($gen) VM with 4GB memory" | Out-File -FilePath $logFile -Append
            $return = New-VM -Name $nestedGuestVmName -MemoryStartupBytes 4GB -NoVHD -Generation $gen -ErrorAction Stop
        }
        $return = set-vm -name $nestedGuestVmName -ProcessorCount 2 -CheckpointType Disabled -ErrorAction Stop
        $disk = get-disk -ErrorAction Stop | where {$_.FriendlyName -eq 'Msft Virtual Disk'}
        $return = $disk | set-disk -IsOffline $true -ErrorAction Stop

        if (!$gen -or ($gen -eq 1)) {
            Log-Info "Gen1: Adding hard drive to IDE controller" | Out-File -FilePath $logFile -Append
            $return = $disk | Add-VMHardDiskDrive -VMName $nestedGuestVmName -ErrorAction Stop
        }
        else {
            Log-Info "Gen$($gen): Adding hard drive to SCSI controller" | Out-File -FilePath $logFile -Append
            $return = $disk | Add-VMHardDiskDrive -VMName $nestedGuestVmName -ControllerType SCSI -ControllerNumber 0 -ErrorAction Stop
            Log-Info "Gen$($gen): Modifying firmware boot order (we do not need to network boot)" | Out-File -FilePath $logFile -Append
            $return = Set-VMFirmware $nestedGuestVmName -FirstBootDevice ((Get-VMFirmware $nestedGuestVmName).BootOrder | Where-Object { $_.BootType -eq "Drive" })[0]
        }

        $return = $switch | Connect-VMNetworkAdapter -VMName $nestedGuestVmName -ErrorAction Stop
        $return = start-vm -Name $nestedGuestVmName -ErrorAction Stop
        $nestedGuestVmState = (get-vm -Name $nestedGuestVmName -ErrorAction Stop).State

        # Create a batch file in the all users startup folder so both Hyper-V Manager and VMConnect run automatically at logon.
        $return = $batchFileContents | out-file -FilePath $batchFile -Force -Encoding Default
        $return = copy-item -path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Administrative Tools\Hyper-V Manager.lnk" -Destination "C:\Users\Public\Desktop"
        # Suppress the prompt for "Do you want to allow your PC to be discoverable by other PCs and devices on this network"
        $return = new-item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Network\NewNetworkWindowOff" -Force
        "END: Creating nested guest VM" | out-file -FilePath $logFile -Append
    }
    catch {
        throw $_
        return $STATUS_ERROR
    }

    # Returns the nested guest VM status to the calling script - "Running" if all went well.
    $nestedGuestVmState
}
else
{
    "START: Installing Hyper-V" | out-file -FilePath $logFile -Append
    try {
        # Install Hyper-V role. The required restart is handled in the calling script, not this script, to make sure that this script cleanly returns the Hyper-V role install status to the calling script.
        $return = install-windowsfeature -name Hyper-V -IncludeManagementTools -ErrorAction Stop
    }
    catch {
        throw $_
        return $STATUS_ERROR
    }
    "END: Installing Hyper-V" | out-file -FilePath $logFile -Append
    $return.ExitCode
    write-host $return.ExitCode
    return $STATUS_SUCCESS
}

$scriptEndTime = get-date -f yyyyMMddHHmmss
$scriptEndTime | out-file -FilePath $logFile -Append


<# Output
20231009181851
START: Installing Hyper-V
END: Installing Hyper-V
20231009182414
[Info 10/09/2023 18:24:23]START: Creating nested guest VM
[Info 10/09/2023 18:24:27]New VMSwitch Successfully created
[Info 10/09/2023 18:24:32]New NetIPAddress Successfully created
[Info 10/09/2023 18:24:33]New NetNat Successfully created
[Info 10/09/2023 18:25:50]New NetIPAddress Successfully created
[Info 10/09/2023 18:25:53]Creating Gen2 VM with 4GB memory
[Info 10/09/2023 18:25:59]Gen2: Adding hard drive to SCSI controller
[Info 10/09/2023 18:25:59]Gen2: Modifying firmware boot order (we do not need to network boot)
END: Creating nested guest VM
20231009182601

#>

#endregion

#Creates a repair VM, mounts a copy of the problem VM OS disk, creates and boots a Hyper-V VM inside it with that mounted as direct disk
az vm repair create -g W10VmRG  -n W10VM --repair-username azure --repair-password 'RepairVMCred' --verbose --enable-nested

#Need to test
Set-AzVMOperatingSystem -VM $repairVMConfig -Windows -ComputerName $vmName  -Credential $cred -EnableNestedVirtualization
