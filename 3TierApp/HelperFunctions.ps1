#Retry on Windows
#$Host.UI.RawUI.BufferSize = New-Object Management.Automation.Host.Size(127, $Host.UI.RawUI.BufferSize.Height)  #Exception: setting "BufferSize": "Operation is not supported on this platform."

#Example Connection function for logging in while using mcr.microsoft.com/azure-powershell:latest.
function Connect-MySubscription {param ( $TenantId, $SubId, $ClientId, $SPNPswd )
    $Secret     = ConvertTo-SecureString -String $SPNPswd -AsPlainText -Force -Verbose
    $PScred     = New-Object -TypeName System.Management.Automation.PSCredential($ClientId,$Secret)
    Connect-AzAccount -ServicePrincipal -Tenant $TenantId -Subscription $SubId -Credential $PScred -Verbose
}

function Get-Suffix {
    $ast        = ([System.Management.Automation.Language.Parser]::ParseInput($MyInvocation.Line, [ref]$null, [ref]$null)).EndBlock.Statements[0]
    $pipeline   = $ast.left ? $ast.right.PipelineElements : $ast.PipelineElements
    $commandName= $pipeline[0].commandElements[0].Value
    $command    = $ExecutionContext.InvokeCommand.GetCommand($commandName, 'All') ?? {throw "Command not found: $commandName"}
    
    $command.Noun.TrimStart('A') -creplace '[^A-Z]'
                    }

function ConvertFrom-MdTable {param([Parameter(Mandatory=$true)][string]$MarkdownFilePath)
    $lines = (Get-Content -Path $MarkdownFilePath -Raw) -replace "`r`n", "`n" -split "`n"
    $headers = (($lines[0] -split '\|').Where({ $_.Trim() -ne '' })).Trim()
    ($lines[2..$lines.Length]).Where({ $_ -ne '' }) | ForEach-Object {
        $properties = [ordered]@{}
        $cells = (($_ -split '\|').Where({ $_.Trim() -ne '' })).Trim()
        for ($i = 0; $i -lt $headers.Count; $i++) { $properties[$headers[$i]] = $cells[$i] }
        [PSCustomObject]$properties
    }
}                    