$AzParams     = @{Location = 'NorthCentralUS'; ResourceGroupName  = $($EnvVars.RG_NAME); Verbose=$true}
$VMs          = ConvertFrom-MdTable -MarkdownFilePath .\3TierApp\VMs.md                                                  
$Cred         = New-Object System.Management.Automation.PSCredential "TestAdmin",$(ConvertTo-SecureString "Passw0rd" -asplaintext -force)        #Use a Password secret

#region VirtualMachineCreation
$VMs|ForEach-Object {
    $SubnetId = ((Get-AzVirtualNetwork -ResourceGroupName $($EnvVars.RG_NAME) -Name $($EnvVars.VNET_NAME)).Subnets|Where-Object name -EQ $PSItem.Subnet).Id
    $NIC      = New-AzNetworkInterface @AzParams -Name ('Tiered' + $($VmName=$Psitem.Name;$VmName)+ (Get-Suffix)) -IpConfiguration $(New-AzNetworkInterfaceIpConfig -Name IPconfig -SubnetId $SubnetId -Primary)
    $Nic.IpConfigurations[0].PrivateIpAllocationMethod = 'Static'
    $Nic|Set-AzNetworkInterface

    $vmConfig = New-AzVMConfig -VMName ('Tiered' + $Psitem.Name+ 'VM') -VMSize $Psitem.Tier -IdentityType UserAssigned -IdentityId $($EnvVars.ID) `
                               -AvailabilitySetId $((Get-AzAvailabilitySet -ResourceGroupName $($EnvVars.RG_NAME) -Name $Psitem.AvSet).Id)|
       Set-AzVMOperatingSystem -Windows -ComputerName ('Tiered' + $Psitem.Name+ 'VM') -Credential $Cred -TimeZone 'Central Standard Time' -ProvisionVMAgent -EnableAutoUpdate -PatchMode AutomaticByPlatform|
       Set-AzVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus '2025-datacenter-azure-edition-core-smalldisk' -Version latest -Verbose|
       Set-AzVMOSDisk -Name ('Tiered' + $Psitem.Name+ (Get-Suffix)) -Caching ReadWrite -CreateOption FromImage|
       Set-AzVMSecurityProfile -SecurityType TrustedLaunch|Set-AzVmUefi -EnableVtpm $true -EnableSecureBoot $true|
       Add-AzVMNetworkInterface -Id $NIC.Id|Set-AzVMBootDiagnostic -ResourceGroupName $($EnvVars.RG_NAME) -Enable

    $disks    = ($Psitem|Select-Object -Property Drive*).psobject.Properties|Select-Object -Property Name,Value|Where-Object value
    $disks|ForEach-Object{
        Add-AzVMDataDisk -VM $vmConfig -Name ('Tiered'+ $VmName + (Get-Suffix)+ $Psitem.Name) -Caching ReadWrite -DiskSizeInGB $Psitem.Value -Lun  $([array]::indexof($disks,$PSItem)+1) -CreateOption Empty
                        }

    New-AzVM @AzParams -VM $vmConfig
                  }
#endregion                  