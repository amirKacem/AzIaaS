$RG             = Get-AzResourceGroup -Name GitHubAction24
$AzParams       = @{Location = 'NorthCentralUS'; ResourceGroupName  = $RG.ResourceGroupName; Verbose=$true}

$SaParams       = @{SkuName = 'Standard_LRS'; Kind = 'StorageV2'; AccessTier = 'Hot'; EnableHierarchicalNamespace = $true}
$SaNwParams     = @{EnableHttpsTrafficOnly = $true; MinimumTlsVersion = 'TLS1_2';  }
$SaSecParams    = @{AllowSharedKeyAccess  = $false } 
New-AzStorageAccount -Name $('tiered' + (Get-Suffix)).ToLower() @AzParams @SaParams @SaNwParams @SaSecParams

New-AzUserAssignedIdentity @AzParams -Name ('tiered' + (Get-Suffix))
New-AzOperationalInsightsWorkspace -Name ('3Tier' + (Get-Suffix)) @AzParams -RetentionInDays 30 
New-AzKeyvault -Name ('Tiered1' + (Get-Suffix)) @AzParams -EnabledForDiskEncryption -Sku Premium -EnableRbacAuthorization -EnablePurgeProtection