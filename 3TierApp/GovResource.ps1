$RG             = Get-AzResourceGroup -Name GitHubAction24
$AzParams       = @{Location = 'NorthCentralUS'; ResourceGroupName  = $RG.ResourceGroupName; Verbose=$true}

#region GovernanceResources
$SaParams       = @{SkuName = 'Standard_LRS'; Kind = 'StorageV2'; AccessTier = 'Hot'; EnableHierarchicalNamespace = $true}
$SaNwParams     = @{EnableHttpsTrafficOnly = $true; MinimumTlsVersion = 'TLS1_2';  }
$SaSecParams    = @{AllowSharedKeyAccess  = $false } 
$StorageAcc     = New-AzStorageAccount -Name $('Tiered' + (Get-Suffix)).ToLower() @AzParams @SaParams @SaNwParams @SaSecParams

$Identity       = New-AzUserAssignedIdentity -Name ('Tiered' + (Get-Suffix)) @AzParams 
$LAW            = New-AzOperationalInsightsWorkspace -Name ('Tiered' + 'LAW') @AzParams -RetentionInDays 30 
#$KV             = New-AzKeyvault -Name ('Tiered3' + (Get-Suffix)) @AzParams -EnabledForDiskEncryption -Sku Premium 
#Set-AzKeyVaultAccessPolicy -VaultName $KV.VaultName -PermissionsToSecrets get,list -Verbose -ObjectId $Identity.PrincipalId -ErrorAction SilentlyContinue

(ConvertFrom-MdTable -MarkdownFilePath .\3TierApp\VMs.md).AvSet|Select-Object -Unique| ForEach-Object {New-AzAvailabilitySet -Name $PSItem @AzParams -Sku Aligned}
#endregion

#region NetworkResources
$rules          = ConvertFrom-MdTable -MarkdownFilePath .\3TierApp\NsgRules.md                                                  #NSG Creation
$ConstParams    = @{Access = 'Allow'; SourcePortRange = '*'; Priority = '100'; Protocol = 'Tcp'}
$NSGRulesArray  = $rules | ForEach-Object {
    $DynParams  = @{Name = $_.Name + 'Rule'; Description = $_.Description; Direction = $_.Direction; DestinationPortRange = $_.DestPortRange
                    SourceAddressPrefix = $_.SourceAddressPrefix; DestinationAddressPrefix = $_.DestAddressPrefix
                   } + $ConstParams
    New-AzNetworkSecurityRuleConfig @DynParams}
$NSG            = New-AzNetworkSecurityGroup -Name ('Tiered' + (Get-Suffix)) @AzParams -SecurityRules $NSGRulesArray
                                                                                            
$SubnetConfigs  = @{DataTier = '192.168.0.0/29'; AppTier = '192.168.0.8/29'; WebTier = '192.168.0.16/29'}.GetEnumerator() |     #Vnet creation
                    ForEach-Object {New-AzVirtualNetworkSubnetConfig -Name $_.Key -AddressPrefix $_.Value -NetworkSecurityGroup $NSG}
$Vnet           = New-AzVirtualNetwork -Name ('Tiered' + (Get-Suffix)) @AzParams -AddressPrefix 192.168.0.0/27 -Subnet $SubnetConfigs     
#endregion

#region Output for next Job
$EnvVars        = @{"RG_NAME"=$RG.ResourceGroupName; "SA_NAME"=$StorageAcc.StorageAccountName; "LAW_NAME"=$LAW.Name;"NSG_NAME"=$NSG.Name; "VNET_NAME"=$Vnet.Name; "ID"=$Identity.Id}
$JsonEnvVars = $EnvVars | ConvertTo-Json -Compress
Write-Output "Env_Vars=$JsonEnvVars" >> $Env:GITHUB_OUTPUT      #Not working
#endregion