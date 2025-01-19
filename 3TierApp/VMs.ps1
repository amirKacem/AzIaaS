$AzParams     = @{Location = 'NorthCentralUS'; ResourceGroupName  = $env:RG_NAME; Verbose=$true}

$VMs          = ConvertFrom-MdTable -MarkdownFilePath .\3TierApp\VMs.md                                                  
$Cred         = New-Object System.Management.Automation.PSCredential "TestAdmin",$(ConvertTo-SecureString "Passw0rd" -asplaintext -force)

$VMs|ForEach-Object {
    $SubnetId = ((Get-AzVirtualNetwork -ResourceGroupName $env:RG_NAME).Subnets|Where-Object name -EQ $PSItem.Subnet).Id
    $NIC      = New-AzNetworkInterface @AzParams -Name ('Tiered' + $Psitem.Name+ (Get-Suffix)) -IpConfiguration $(New-AzNetworkInterfaceIpConfig -Name IPconfig -SubnetId $SubnetId -Primary)
    $Nic.IpConfigurations[0].PrivateIpAllocationMethod = 'Static'
    $Nic|Set-AzNetworkInterface

    $vmConfig = New-AzVMConfig -VMName $Psitem.Name -VMSize $Psitem.Tier -IdentityType UserAssigned -IdentityId $env:ID|
       Set-AzVMOperatingSystem -Windows -ComputerName $Psitem.Name -Credential $Cred -TimeZone 'Central Standard Time' -ProvisionVMAgent -EnableAutoUpdate -PatchMode AutomaticByPlatform|
       Set-AzVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus '2025-datacenter-azure-edition-core-smalldisk' -Version latest -Verbose|
       Set-AzVMOSDisk -Name ('Tiered' + $Psitem.Name+ (Get-Suffix)) -Caching ReadWrite -CreateOption FromImage|
       Set-AzVMSecurityProfile -SecurityType TrustedLaunch|Set-AzVmUefi -EnableVtpm $true -EnableSecureBoot $true|
       Add-AzVMNetworkInterface -Id $NIC.Id|Set-AzVMBootDiagnostic -ResourceGroupName $env:RG_NAME -Enable

    $disks    = ($Psitem|Select-Object -Property Drive*).psobject.Properties|Select-Object -Property Name,Value|Where-Object value
    $disks|ForEach-Object{
        Add-AzVMDataDisk -VM $vmConfig -Name ('Tiered' + $Psitem.Name+ (Get-Suffix)) -Caching ReadWrite -DiskSizeInGB $Psitem.Value -Lun  $([array]::indexof($disks,$PSItem)+1) -CreateOption Empty
                        }

    New-AzVM @AzParams -VM $vmConfig
                  }