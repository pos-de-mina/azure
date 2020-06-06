<#
 # Azure SubNets
 # List in All Objects Hierarquicaly Via Azure REST API
 #   - List All Subscription
 #     - List All Resources Groups
 #       - List All Virtual NetWorks
 #         - List All Subnets
 #
 # Credits:
 #   - Bruno Corsino https://github.com/bmcorsino
 #
 # (c) António Pós-de-Mina | https://github.com/pos-de-mina
 #>
param (
    # Azure
    $AzTenantID,
    $AzAppID,
    $AzPwd,
    # use On-Prem
    $Proxy
)
# Login to Azure
$result = Invoke-RestMethod `
    -Uri https://login.microsoftonline.com/$AzTenantID/oauth2/token?api-version=1.0 `
    -Method POST `
    -Body @{
        "grant_type"    = "client_credentials"; 
        "resource"      = "https://management.core.windows.net/";
        "client_id"     = "$AzAppID";
        "client_secret" = "$AzPwd"
    } `
    -Proxy $Proxy
# Create Header for the next calls
$Headers = @{
    'Authorization' = "$($result.token_type) $($result.access_token)"
    'Host'          = "management.azure.com"
    'Content-Type'  = 'application/json'
}
# Get subscriptions
$subscriptions = Invoke-RestMethod `
    -Uri "https://management.azure.com/subscriptions?api-version=2019-11-01" `
    -Method GET `
    -Headers $Headers `
    -Proxy $Proxy
# Get All Virtual Networks and SubNets
$subscriptions.value | ForEach-Object {
    $AzSubscriptionName = $_.displayName
    $vnets = Invoke-RestMethod `
        -Uri "https://management.azure.com$($_.id)/providers/Microsoft.Network/virtualNetworks?api-version=2020-04-01" `
        -Method GET `
        -Headers $Headers `
        -Proxy $Proxy
    $vnet = $vnets.value.name
    $vnets.value.properties.subnets | ForEach-Object {
        [PSCustomObject]@{
            SubscriptionName = $AzSubscriptionName
            VirtualNetwork = $vnet
            SubNetName = $_.name
            SubNetID = $_.id
        }
    }
}
