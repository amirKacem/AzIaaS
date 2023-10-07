1. [Deploy Win11 Arm VM](https://ayanmullick.github.io/AzIaaS/?path=https://raw.githubusercontent.com/ayanmullick/AzIaaS/master/Blog/DeployWindows11ArmVM.md)
2.    

   

## Script Installation steps

```ps
$Script   = 'Hello-World' #Replace with Script name
$DestPath = [Environment]::GetFolderPath('MyDocuments')+"\PowerShell\Scripts"  #User's default script folder

(New-Object System.Net.WebClient).DownloadFile("https://github.com/Ayanmullick/AzIaaS/raw/master/$Script.ps1","$DestPath\$Script.ps1")   #Download script
If (($env:PATH -split ';') -notcontains $DestPath) {$env:Path += ";$DestPath"} #Add Script folder path to environment variable, if not present, for intellisense.
```
