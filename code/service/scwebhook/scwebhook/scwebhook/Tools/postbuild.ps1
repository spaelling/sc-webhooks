param(
    $TargetPath 
)

$VerbosePreference = 'Continue'

<# place a file called postbuildparams.txt in the same folder as this script with the following content
# machine name or ip
TargetMachine=192.168.42.56
# copy InstallUtil.exe from here
InstallUtilPath = C:\Windows\Microsoft.NET\Framework\v4.0.30319\InstallUtil.exe
#>

#<# Need to run this first to create a credential file. Comment out <# and run the script.
#$Administrator = “coretech\mme”
#$Credential = Get-Credential –Credential “coretech\sm_sa” | Export-Clixml -Path ".\Credentials.xml"
#break

$ParameterFile = Get-Content -Path "$PSScriptRoot\postbuildparams.txt"
foreach($Line in $ParameterFile)
{
    if($Line -notlike '#*')
    {
        $Name, $Value = $Line.Split('=')
        Set-Variable -Name $Name -Value $Value
    }
}

$Credential = Import-Clixml -Path "$PSScriptRoot\Credentials.xml" -ErrorAction Stop -Verbose

$SCWebhookPath = (Resolve-Path -Path $TargetPath -ErrorAction Stop -Verbose).Path

Write-Verbose "`$TargetMachine = $TargetMachine"
Write-Verbose "`$SCWebhookPath = $SCWebhookPath" 
Write-Verbose "`$InstallUtilPath = $InstallUtilPath"

$Session = New-PSSession -ComputerName $TargetMachine -Credential $Credential -Verbose

# cannot overwrite file if the service is running
Invoke-Command -Session $Session -ScriptBlock {
    Write-Verbose "stopping scwebhook service"
    Stop-Service -Name scwebhook -ErrorAction SilentlyContinue -Verbose
}

Remove-PSDrive SCSM -Force -ErrorAction SilentlyContinue
# weird issue with this not working when providing a credentialcls
New-PSDrive -Name SCSM -PSProvider FileSystem -Root "\\$TargetMachine\c$\temp\" -Verbose | Out-Null  # -Credential $Credential
Copy-Item -Path $InstallUtilPath -Destination "SCSM:\$((Get-ChildItem -Path $InstallUtilPath).Name)" -Verbose -Force
Copy-Item -Path $SCWebhookPath -Destination "SCSM:\$((Get-ChildItem -Path $SCWebhookPath).Name)" -Verbose -Force

Invoke-Command -Session $Session -ScriptBlock {
    cd C:\temp
    Remove-Item scwebhook.InstallLog -ErrorAction SilentlyContinue -Verbose
    Write-Verbose "removing scwebhook service"
    .\InstallUtil.exe scwebhook.exe /u
    Write-Verbose "installing scwebhook service"
    .\InstallUtil.exe scwebhook.exe 
    Write-Verbose "starting scwebhook service"
    Start-Service -Name scwebhook -Verbose
}

# for troubleshooting uncomment bellow
#Copy-Item -Path "SCSM:\scwebhook.InstallLog" -Destination "c:\temp"; notepad scwebhook.InstallLog