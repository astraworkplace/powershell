param(
    [Parameter(Mandatory=$true)]
    [string]$Tag = $null
)
#Variables 

$SasUrl = "SASURL"

## Vérification des droits administrateur
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "Le script doit etre execute en tant qu'administrateur."
    exit 1
}

## Vérification de la connexion réseau
Write-Host "Verification de la connexion reseau..."
try {
    $networkTest = Test-Connection -ComputerName "8.8.8.8" -Count 2 -Quiet -ErrorAction Stop
    if (-not $networkTest) {
        Write-Error "Pas de connexion reseau disponible."
        exit 1
    }
    Write-Host "Connexion reseau OK"
}
catch {
    Write-Error "Erreur lors du test réseau : $_"
    exit 1
}

# TLS
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Vérifie Nuget si déjà installé
if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope AllUsers
}

# Trust PSGallery
if ((Get-PSRepository -Name "PSGallery").InstallationPolicy -ne "Trusted") {
    Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
}

## Vérification / installation du script AutoPilot
Write-Host "Verification du script Get-WindowsAutoPilotInfo..."
try {
    if (-not (Get-Command Get-WindowsAutoPilotInfo -ErrorAction SilentlyContinue)) {
        Write-Host "Installation du script..."
        Install-Script -Name Get-WindowsAutoPilotInfo -Force -ErrorAction Stop
    }
    else {
        Write-Host "Script deja present"
    }
}
catch {
    Write-Error "Erreur lors de l'installation du script : $_"
    exit 1
}

## Récupération du numéro de série
try {
    $serialNumber = (Get-WmiObject -Class Win32_BIOS | Select-Object -ExpandProperty SerialNumber)
    if (-not $serialNumber) {
        throw "Impossible de recuperer le numero de serie"
    }
}
catch {
    Write-Error $_
    exit 1
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$folderpath = "C:\windows\temp\"
$filename = $serialNumber + '_'+ $timestamp +'.csv'
$hashpath = "$folderpath\$filename"

if (-not (Test-Path -Path $folderpath -PathType Container)) {
    New-Item -Path $folderpath -ItemType Directory -Force | Out-Null
}

#Recuperation du hash
if ($null -ne $Tag -and $Tag -ne "") {
    Get-WindowsAutoPilotInfo -OutputFile $hashpath -GroupTag $Tag
}
else {
    Get-WindowsAutoPilotInfo -OutputFile $hashpath
}

#Envoyer dans le blob storage
$FilePath = $hashpath
$FileName = Split-Path $FilePath -Leaf

$baseUrl, $sasToken = $SasUrl -split "\?", 2
$UploadUrl = "$baseUrl/$FileName`?$sasToken"

Invoke-RestMethod -Uri $UploadUrl `
    -Method Put `
    -Headers @{
        "x-ms-blob-type" = "BlockBlob"
    } `
    -InFile $FilePath `
    -ContentType "application/octet-stream"

Write-Output "Le Hash est transmit vers le stockage Azure, vous pouvez fermer la fenetre"
Pause