Import-Module AzurePSDrive
New-PSDrive -Name Azure -PSProvider SHiPS -root 'AzurePSDrive#Azure'
Set-Location Azure:
