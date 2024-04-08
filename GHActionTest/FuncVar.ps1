#function Get-CurrentTime { (Get-Date).ToString("hh:mm:ss tt") }

<#
$RG = Get-AzResourceGroup -Name GitHubAction24
$rgName = $RG.ResourceGroupName

Write-Output "RG_NAME=$rgName" >> $Env:GITHUB_ENV  #Persists only across 'steps' in the same job. And is deleted after GHWorkflow run
#>

Write-Output "RG_NAME=$(Get-AzResourceGroup -Name GitHubAction24|ConvertTo-Json -Compress)" >> $Env:GITHUB_ENV


<# Across Jobs
#Set
$RG = Get-AzResourceGroup -Name GitHubAction24 -Verbose
$rgName = $RG.ResourceGroupName
Write-Output "rg_name=$rgName" >> $Env:GITHUB_OUTPUT

#Get
$rgName = "${{ needs.set_resource_group.outputs.rg }}"
Write-Host "Using Resource Group Name: $rgName"

$env:needs.set_resource_group.outputs.rg | ConvertFrom-Json
#>