function Get-CurrentTime { (Get-Date).ToString("hh:mm:ss tt") }

<#
$RG = Get-AzResourceGroup -Name GitHubAction24
$rgName = $RG.ResourceGroupName

Write-Output "RG_NAME=$rgName" >> $Env:GITHUB_ENV  #Persists only across 'steps' in the same job. And is deleted after GHWorkflow run
#>