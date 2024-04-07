$RG             = Get-AzResourceGroup -Name GitHubAction24
$AzParams       = @{Location = 'NorthCentralUS'; ResourceGroupName  = $RG.ResourceGroupName; Verbose=$true}

$SaParams       = @{SkuName = 'Standard_LRS'; Kind = 'StorageV2'; AccessTier = 'Hot'; EnableHierarchicalNamespace = $true}
$SaNwParams     = @{EnableHttpsTrafficOnly = $true; MinimumTlsVersion = 'TLS1_2';  }
$SaSecParams    = @{AllowSharedKeyAccess  = $false } 
$StorageAcc     = New-AzStorageAccount -Name $('tiered' + (Get-Suffix)).ToLower() @AzParams @SaParams @SaNwParams @SaSecParams

$Identity       = New-AzUserAssignedIdentity -Name ('tiered' + (Get-Suffix)) @AzParams 
$LAW            =New-AzOperationalInsightsWorkspace -Name ('3Tier' + (Get-Suffix)) @AzParams -RetentionInDays 30 
$KV             = New-AzKeyvault -Name ('Tiered2' + (Get-Suffix)) @AzParams -EnabledForDiskEncryption -Sku Premium -EnableRbacAuthorization -EnablePurgeProtection
#New-AzRoleAssignment -Scope $KV.ResourceId -SignInName <> -RoleDefinitionName 'Key Vault Administrator'  #For user
New-AzRoleAssignment -Scope $KV.ResourceId -ObjectId $Identity.PrincipalId -RoleDefinitionName 'Key Vault Contributor' #For UAI


$rules          = ConvertFrom-MdTable -MarkdownFilePath .\3TierApp\NsgRules.md                                                  #NSG Creation
$ConstParams    = @{Access = 'Allow'; SourcePortRange = '*'; Priority = '100'; Protocol = 'Tcp'}
$NSGRulesArray  = $rules | ForEach-Object {
    $DynParams  = @{Name = $_.Name + 'Rule'; Description = $_.Description; Direction = $_.Direction; DestinationPortRange = $_.DestPortRange
                    SourceAddressPrefix = $_.SourceAddressPrefix; DestinationAddressPrefix = $_.DestAddressPrefix
                   } + $ConstParams
    New-AzNetworkSecurityRuleConfig @DynParams}
$NSG            = New-AzNetworkSecurityGroup -Name ('tiered' + (Get-Suffix)) @AzParams -SecurityRules $NSGRulesArray
                                                                                            
$SubnetConfigs  = @{DataTier = '192.168.0.0/29'; AppTier = '192.168.0.8/29'; WebTier = '192.168.0.16/29'}.GetEnumerator() |     #Vnet creation
                    ForEach-Object {New-AzVirtualNetworkSubnetConfig -Name $_.Key -AddressPrefix $_.Value -NetworkSecurityGroup $NSG}
$Vnet           =New-AzVirtualNetwork -Name ('tiered1' + (Get-Suffix)) @AzParams -AddressPrefix 192.168.0.0/27 -Subnet $SubnetConfigs     

$envVars = @{
    "RG_NAME"   = $RG.ResourceGroupName
    "SA_NAME"   = $StorageAcc.StorageAccountName
    "LAW_NAME"  = $LAW.Name 
    "KV_NAME"   = $KV.VaultName
    "NSG_NAME"  = $NSG.Name
    "VNET_NAME" = $Vnet.Name
}

foreach ($key in $envVars.Keys) {
    "$key=$($envVars[$key])" | Out-File -FilePath $Env:GITHUB_ENV -Append
}
