function Get-Suffix {
    $ast        = ([System.Management.Automation.Language.Parser]::ParseInput($MyInvocation.Line, [ref]$null, [ref]$null)).EndBlock.Statements[0]
    $pipeline   = $ast.left ? $ast.right.PipelineElements : $ast.PipelineElements
    $commandName= $pipeline[0].commandElements[0].Value
    $command    = $ExecutionContext.InvokeCommand.GetCommand($commandName, 'All') ?? {throw "Command not found: $commandName"}
    
    $command.Noun.TrimStart('A') -creplace '[^A-Z]'
                    }

$RG             = Get-AzResourceGroup -Name GitHubAction24
$AzParams       = @{Location = 'NorthCentralUS'; ResourceGroupName  = $RG.ResourceGroupName; Verbose=$true}
<#
$Identity       = New-AzUserAssignedIdentity @AzParams -Name ('Func' + (Get-Suffix))
$SaParams       = @{SkuName = 'Standard_LRS'; Kind = 'StorageV2'; AccessTier = 'Hot'; LargeFileSharesState = 'Disabled'; EnableHierarchicalNamespace = $true}
$SaNwParams     = @{EnableHttpsTrafficOnly = $true; MinimumTlsVersion = 'TLS1_2'; EncryptionServices = 'Blob'; AllowBlobPublicAccess = 'Disabled'; }
$SaSecParams    = @{AllowStorageAccountKeyAccess = 'Disabled'; AllowSharedAccessSignatureExpiryIntervalInYear = 1; EnableAzureActiveDirectoryAuthorization = $true; UserAssignedIdentityId = $Identity.Id}
New-AzStorageAccount -Name ('Func' + (Get-Suffix)) @AzParams @SaParams @SaNwParams @SaSecParams
#>
New-AzOperationalInsightsWorkspace -Name ('Func' + (Get-Suffix)) @AzParams -RetentionInDays 30 
New-AzKeyvault -Name ('Func' + (Get-Suffix)) @AzParams -EnabledForDiskEncryption -Sku Premium -EnableRbacAuthorization -EnablePurgeProtection