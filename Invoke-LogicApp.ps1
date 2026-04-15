$logicAppUrl = "https://prod-23.francecentral.logic.azure.com:443/.."

# Données à envoyer
$body = @{
    groupId  = "MON-GROUP-ID"
    message  = "Message envoyé grâce à AstraWorkplace"
    authToken = "MON_SECRET"
} | ConvertTo-Json -Depth 3

Invoke-RestMethod -Method POST -Uri $logicAppUrl -Body $body -ContentType "application/json"