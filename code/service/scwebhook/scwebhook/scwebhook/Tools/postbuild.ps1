param(
    [string]$TargetPath,
    [string]$TargetMachine
)

$InstallUtilPath = "C:\Windows\Microsoft.NET\Framework\v4.0.30319\InstallUtil.exe"

$SCWebhookPath = (Resolve-Path -Path $TargetPath -ErrorAction Stop -Verbose).Path

<#
### Need to run this first to create a credential file. Comment out <# and run the script.
$Administrator = “lumalab\administrator”
$Credential = Get-Credential –Credential “lumalab\svc-scsm” | Export-Clixml -Path ".\Credentials.xml"
break
#>

$Credential = Import-Clixml -Path "$PSScriptRoot\Credentials.xml" -ErrorAction Stop -Verbose

Remove-PSDrive SCSM -Force -ErrorAction SilentlyContinue
# weird issue with this not working when providing a credential
New-PSDrive -Name SCSM -PSProvider FileSystem -Root "\\$TargetMachine\c$\temp\" -Verbose | Out-Null  # -Credential $Credential
Copy-Item -Path $InstallUtilPath -Destination "SCSM:\$((Get-ChildItem -Path $InstallUtilPath).Name)" -Verbose -Force
Copy-Item -Path $SCWebhookPath -Destination "SCSM:\$((Get-ChildItem -Path $SCWebhookPath).Name)" -Verbose -Force

$Session = New-PSSession -ComputerName $TargetMachine -Credential $Credential -Verbose

Invoke-Command -Session $Session -ScriptBlock {
    cd C:\temp
    Remove-Item scwebhook.InstallLog -ErrorAction SilentlyContinue -Verbose
    .\InstallUtil.exe scwebhook.exe /u | Out-Null
    .\InstallUtil.exe scwebhook.exe | Out-Null
    Start-Service -Name scwebhook -Verbose
}

# for troubleshooting uncomment bellow
#Copy-Item -Path "SCSM:\scwebhook.InstallLog" -Destination "c:\temp"; notepad scwebhook.InstallLog
