function Get-Suffix {
    $ast        = ([System.Management.Automation.Language.Parser]::ParseInput($MyInvocation.Line, [ref]$null, [ref]$null)).EndBlock.Statements[0]
    $pipeline   = $ast.left ? $ast.right.PipelineElements : $ast.PipelineElements
    $commandName= $pipeline[0].commandElements[0].Value
    $command    = $ExecutionContext.InvokeCommand.GetCommand($commandName, 'All') ?? {throw "Command not found: $commandName"}
    
    $command.Noun.TrimStart('A') -creplace '[^A-Z]'
                    }

$RG             = Get-AzResourceGroup -Name GitHubAction24
$AzParams       = @{Location = 'NorthCentralUS'; ResourceGroupName  = $RG.ResourceGroupName; Verbose=$true}

$Identity       = New-AzUserAssignedIdentity @AzParams -Name ('tiered' + (Get-Suffix))
$SaParams       = @{SkuName = 'Standard_LRS'; Kind = 'StorageV2'; AccessTier = 'Hot'; EnableHierarchicalNamespace = $true}
$SaNwParams     = @{EnableHttpsTrafficOnly = $true; MinimumTlsVersion = 'TLS1_2';  }
$SaSecParams    = @{AllowSharedKeyAccess  = $false; UserAssignedIdentityId = $Identity.Id } 
New-AzStorageAccount -Name $('tiered' + (Get-Suffix)).ToLower() @AzParams @SaParams @SaNwParams @SaSecParams


#New-AzOperationalInsightsWorkspace -Name ('3Tier' + (Get-Suffix)) @AzParams -RetentionInDays 30 
#New-AzKeyvault -Name ('Tiered' + (Get-Suffix)) @AzParams -EnabledForDiskEncryption -Sku Premium -EnableRbacAuthorization -EnablePurgeProtection