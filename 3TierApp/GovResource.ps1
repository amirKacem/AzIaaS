$RG             = Get-AzResourceGroup -Name GitHubAction24
$AzParams       = @{Location = 'NorthCentralUS'; ResourceGroupName  = $RG.ResourceGroupName; Verbose=$true}
<#
$SaParams       = @{SkuName = 'Standard_LRS'; Kind = 'StorageV2'; AccessTier = 'Hot'; EnableHierarchicalNamespace = $true}
$SaNwParams     = @{EnableHttpsTrafficOnly = $true; MinimumTlsVersion = 'TLS1_2';  }
$SaSecParams    = @{AllowSharedKeyAccess  = $false } 
New-AzStorageAccount -Name $('tiered' + (Get-Suffix)).ToLower() @AzParams @SaParams @SaNwParams @SaSecParams

New-AzUserAssignedIdentity -Name ('tiered' + (Get-Suffix)) @AzParams 
New-AzOperationalInsightsWorkspace -Name ('3Tier' + (Get-Suffix)) @AzParams -RetentionInDays 30 
#New-AzKeyvault -Name ('Tiered1' + (Get-Suffix)) @AzParams -EnabledForDiskEncryption -Sku Premium -EnableRbacAuthorization -EnablePurgeProtection
#WARNING: Access policy is not set. No user or application have access permission to use this vault. 
#This can happen if the vault was created by a service principal. Please use Set-AzKeyVaultAccessPolicy to set access policies.
#>

$rules          = Convert-MdTable2PSObject -MarkdownFilePath .\3TierApp\NsgRules.md                            #NSG Creation
$ConstParams    = @{Access = 'Allow'; SourcePortRange = '*'; Priority = '100'; Protocol = 'Tcp'}
$NSGRulesArray  = $rules | ForEach-Object {
    $ruleParams = @{Name = $_.Name + 'Rule'; Description = $_.Description; Direction = $_.Direction; DestinationPortRange = $_.DestPortRange
                    SourceAddressPrefix = $_.SourceAddressPrefix; DestinationAddressPrefix = $_.DestAddressPrefix
                   } + $ConstParams
    New-AzNetworkSecurityRuleConfig @ruleParams}
New-AzNetworkSecurityGroup -Name ('tiered' + (Get-Suffix)) @AzParams -SecurityRules $NSGRulesArray