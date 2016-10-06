param(
    [string]$TargetPath = "C:\Users\mme\Dropbox\_VSProjects\sc-webhooks\code\service\scwebhook\scwebhook\scwebhook\bin\Debug\scwebhook.exe",
    [string]$TargetMachine = "ctsm1-dev"
)

$InstallUtilPath = "C:\Windows\Microsoft.NET\Framework\v4.0.30319\InstallUtil.exe"

$SCWebhookPath = (Resolve-Path -Path $TargetPath -ErrorAction Stop -Verbose).Path


### Need to run this first to create a credential file. Comment out <# and run the script.
#$Administrator = “coretech\mme”
#$Credential = Get-Credential –Credential “coretech\sm_sa” | Export-Clixml -Path ".\Credentials.xml"
#break



$Credential = Import-Clixml -Path ".\Credentials.xml" -ErrorAction Stop -Verbose

Remove-PSDrive SCSM -Force -ErrorAction SilentlyContinue
# weird issue with this not working when providing a credentialcls

New-PSDrive -Name SCSM -PSProvider FileSystem -Root "\\$TargetMachine\c$\temp\" -Verbose | Out-Null  # -Credential $Credential
Copy-Item -Path $InstallUtilPath -Destination "SCSM:\$((Get-ChildItem -Path $InstallUtilPath).Name)" -Verbose -Force
Copy-Item -Path $SCWebhookPath -Destination "SCSM:\$((Get-ChildItem -Path $SCWebhookPath).Name)" -Verbose -Force

$Session = New-PSSession -ComputerName $TargetMachine -Credential $Credential -Verbose

Invoke-Command -Session $Session -ScriptBlock {
    cd C:\temp
    Remove-Item scwebhook.InstallLog -ErrorAction SilentlyContinue -Verbose
    .\InstallUtil.exe scwebhook.exe /u
    .\InstallUtil.exe scwebhook.exe 
    #Start-Service -Name scwebhook -Verbose
}

# for troubleshooting uncomment bellow
#Copy-Item -Path "SCSM:\scwebhook.InstallLog" -Destination "c:\temp"; notepad scwebhook.InstallLog
