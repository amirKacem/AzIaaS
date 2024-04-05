function Get-CurrentTime { (Get-Date).ToString("hh:mm:ss tt") }


$RG = Get-AzResourceGroup -Name GitHubAction24
$rgName = $RG.ResourceGroupName

echo "RG_NAME=$rgName" >> $Env:GITHUB_ENV
