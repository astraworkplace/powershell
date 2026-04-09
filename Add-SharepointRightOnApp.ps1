<##
.SYNOPSIS
    Ce script ajoute un droit à une app registration pour l'utilisation de la permission Site.Selected.

.AUTHOR
    Mathéo Bourlet

.VERSION
    1.0

.DATE
    2026-04-09

.REQUIREMENTS
    - PowerShell 7 ou supérieur
    - Accès à Internet pour installation du module
    - PSGallery disponible
    - Modifier les variables 

.EXAMPLE
    .\Add-SharepointRightOnApp.ps1

##>

### Variables ###

#Application Maitre
$ClientId = "clientid"
$Thumbprint = "thumbprint"

#Application Cible
$AppId = "appid"
$DisplayName = "DisplayName"
$SharepointUrl = "https://tenant.sharepoint.com"

#Autre
$Tenantid
$SiteName = "site"
$Permissions = "Write" # FullControl , Read ou Write

$site = $SharepointUrl +"/sites/"+$SiteName

### Script ###

if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Error "PowerShell 7 minimum requis"
    exit 1
}

try {
    if (-not (Get-Module -ListAvailable -Name "PnP.PowerShell")) {
        Install-Module PnP.PowerShell -Scope CurrentUser -Force -ErrorAction Stop
    }

    Import-Module PnP.PowerShell -ErrorAction Stop
}
catch {
    Write-Error "Impossible de charger PnP : $($_.Exception.Message)"
    exit 1
}

Connect-PnPOnline -Url $SharepointUrl -ClientId $ClientId -Thumbprint $Thumbprint -Tenant $Tenantid

Grant-PnPAzureADAppSitePermission -AppId $Appid -DisplayName $DisplayName -Site $Site -Permissions $Permissions 
