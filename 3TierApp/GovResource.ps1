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

$envVars        = @{"RG_NAME"=$RG.ResourceGroupName; "SA_NAME"=$StorageAcc.StorageAccountName; "LAW_NAME"=$LAW.Name;"KV_NAME"=$KV.VaultName; "NSG_NAME"=$NSG.Name; "VNET_NAME"=$Vnet.Name; "ID"=$Identity.Id}
foreach ($key in $envVars.Keys) {"$key=$($envVars[$key])" | Out-File -FilePath $Env:GITHUB_ENV -Append}                         #Env variables for next steps

Get-Content -Path $Env:GITHUB_ENV                                                                                               # Print the contents of the GITHUB_ENV file
Write-Output "Resource group is $env:RG_NAME"                                                                                   # Print the Resource Group Name
#>