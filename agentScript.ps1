<#
Application director service installation for Windows systems. This script will 
automate the entire provisioning of the application director, jre, and vcac components

Created and maintained by Gary Coburn - Automation specialist  

Tested on windows server 2008x64 not designed for 32 bit!
#>

param(
    [string]$jreURL="https://www.dropbox.com/s/rz26rbvqn6w5xql",#http://va-appdir.bh.lab/agent
    [string]$appdURL="https://www.dropbox.com/s/24hh6uvx500pex5",#http://va-appdir.bh.lab/agent
    [string]$vcacURL="https://www.dropbox.com/s/gx2y9zqkkpusy8r",#https://va-vcac.bh.lab:5480/installer
    [string]$ntrightsURL="https://www.dropbox.com/s/m3qahf5w3yunubt",#http://va-appdir.bh.lab/agent
    [string]$vcacServer="win-vCAC.bh.lab",
    [string]$pass="P@ssw0rd"
)
Start-Transcript -Path "c:\appdAgentInstall.txt"
#functions
#Download the files from local or default (dropbox location)
function downloadNeededFiles($url,$file)
{
    #Download files to specific location
    [Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
    $clnt = New-Object System.Net.WebClient
    $clnt.DownloadFile($url,$file) 
    write-output "$file downloaded"    
}
#Extract the files into the needed locations
function extractZip($file,$dest)
{
    write-output "$file extracting files"
    $shell = new-object -com shell.application
    if (!(Test-Path "$file"))
    {
        throw "$file does not exist" 
    }
    New-Item -ItemType Directory -Force -Path $dest -WarningAction SilentlyContinue
    $shell.namespace($dest).copyhere($shell.namespace("$file").items()) 
    write-output "$file extracted"
}
#file extraction verification we need to make sure the files exist and are in the proper location
function verifyPath($file)
{
    while(!(Test-Path "$file"))
    {
        write-output "$file doesn't exist sleeping for 5"
        start-sleep -s 10
    }    
    write-output "$file does exist"
    if ($file -eq "c:\windows\temp\VRMGuestAgent\site\customizeos\workitem1.js")
    {
        write-output "moving $file to C:\"
        Move-Item "c:\windows\temp\VRMGuestAgent" "C:\"
    }
}

#jre zip file definition and calls the functions to download, extract, and verify
$url="$jreURL/jre-1.7.0_45-win64.zip"
$file="c:\windows\temp\jre.zip"
$dest="c:\opt\vmware-jre\jre"
downloadNeededFiles $url $file
extractZip $file $dest
#verify extract succeeded
$file="c:\opt\vmware-jre\jre\lib\zi\systemv\yst9ydt"
verifyPath $file

#vcac agent zip file definition and calls the functions to download, extract, and verify
$url="$vcacURL/GugentZip_x64.zip"
$file="c:\windows\temp\gugentzip.zip"
$dest="C:\windows\temp"
downloadNeededFiles $url $file
extractZip $file $dest
#verify extract succeeded
$file="c:\windows\temp\VRMGuestAgent\site\customizeos\workitem1.js"
verifyPath $file
$file="c:\VRMGuestAgent\site\customizeos\workitem1.js"
verifyPath $file

#application director agent zip file definition and calls the functions to download, extract, and verify
$url="$appdURL/vmware-appdirector-agent-bootstrap-windows_6.0.0.0.zip"
$file="c:\windows\temp\appd.zip"
$dest="c:\appd"
downloadNeededFiles $url $file
extractZip $file $dest
#verify extract succeeded
$file="c:\appd\install.bat"
verifyPath $file

#application director agent zip file definition and calls the functions to download, extract, and verify
$url="$ntrightsURL/ntrights.exe"
$file="c:\appd\ntrights.exe"
downloadNeededFiles $url $file
#verify extract succeeded
verifyPath $file

write-output "Running install.bat" 
set-location C:\appd
& .\install.bat password=$pass cloudProvider=vcac vcacServer=$vcacServer httpsMode=true >> "c:\windows\temp\appdAgentService.txt"
write-output "install.bat completed"

Write-Output "starting appd service"
start-service AppDAgentBootstrap
Stop-Transcript
Move-Item "c:\appdAgentInstall.txt" "C:\Windows\Temp\appdAgentInstall.txt"