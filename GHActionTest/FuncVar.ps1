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

Write-Output "RG=$(Get-AzResourceGroup -Name GitHubAction24|ConvertTo-Json -Compress)" >> $Env:GITHUB_OUTPUT  #v2            



#Get
$rgName = "${{ needs.set_resource_group.outputs.rg }}"
Write-Host "Using Resource Group Name: $rgName"

${{ needs.set_resource_group.outputs.rg_name }}| ConvertFrom-Json  #v2: It gets the values but results in a parser error

Error: 
{"ResourceGroupName":"GitHubAction24","Location":"northcentralus","ProvisioningState":"Succeeded","Tags":{},"TagsTable":null,"ResourceId":"/subscriptions/8b77f191-3d4a-498e-8bb1-9e1fbb927ea7/resourceGroups/GitHubAction24","ManagedBy":null}| ConvertFrom-Json
  shell: /usr/bin/pwsh -command ". '{0}'"
ParserError: /home/runner/work/_temp/638506b1-b906-4ad1-b33a-0e3d9d0ec1eb.ps1:2
Line |
   2 |  {"ResourceGroupName":"GitHubAction24","Location":"northcentralus","Pr …
     |                      ~~~~~~~~~~~~~~~~~
     | Unexpected token ':"GitHubAction24"' in expression or statement.
Error: Process completed with exit code 1.

#>