param(
    [Parameter(Mandatory = $false)]
    [pscredential] $Credential
)
$ErrorActionPreference = "Stop"
if (!$Credential) { $Credential = Get-Credential }
$BaseUri = "https://nuget.eos-solutions.it"

$r = Invoke-RestMethod "$BaseUri/nuget/PS/packages" -Credential $Credential -UseBasicParsing | `
    Where-Object { 
    $_.title.InnerText -eq "Eos.Common" 
} | `
    Sort-Object {
    [Version] $_.properties.version.InnerText
} | `
    Select-Object -Last 1

$ModuleName = $r.title.InnerText
$ModuleVersion = $r.properties.Version
Write-Host "Using $ModuleName v$ModuleVersion"

$str = "$($Credential.UserName):$($Credential.GetNetworkCredential().Password)"
$header = @{
    Authorization = "Basic $([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($str)))"
}

Write-Host "Downloading files"
$files = @(
    "Functions%2FPSGallery%2FRegister-EosPSGallery.ps1"
    "Functions%2FPSGallery%2FUnregister-EosPSGallery.ps1"
)
foreach ($file in $files) {
    $uri = "$BaseUri/package-files/download?packageId=$ModuleName&version=$ModuleVersion&feedName=PS&path=$($file)"
    $Content = [Text.Encoding]::UTF8.GetString((Invoke-WebRequest -Uri $uri -Headers $header).RawContentStream.ToArray())
    if ([int] $Content[0] -eq 65279) { $Content = $Content.Substring(1) } # fix encoding issue
    Invoke-Expression $Content
}

Write-Host "Installing"
$Gallery = Register-EosPSGallery -Credentials $Credential
Install-Module "Eos.Common" -Repository $Gallery -Credential $Credential