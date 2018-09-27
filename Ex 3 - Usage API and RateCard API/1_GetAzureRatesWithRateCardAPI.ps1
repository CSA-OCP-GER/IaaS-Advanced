<#

This is how I used PowerShell to query the RateCard API (REST) authenticated 
to get relevant Azure prices (for my region & subscription)

thanks Keith for the powershell code to do the Auth
https://blogs.technet.microsoft.com/keithmayer/2014/12/30/leveraging-the-azure-service-management-rest-api-with-azure-active-directory-and-powershell-list-azure-administrators/

Get-AzureADServicePrincipal | where displayname -Like "Microsoft Azure Power*"
ObjectId                             AppId                                DisplayName               
--------                             -----                                -----------               
c574b597-7eb0-474e-bbcc-ddc5d39ffafe 1950a258-227b-4e31-a9cf-717495945fc2 Microsoft Azure PowerShel
#>

# Set well-known client ID for Azure PowerShell
# this will eliminate the need for register a new app for this access ;-)
$clientId = "1950a258-227b-4e31-a9cf-717495945fc2" 

# Set redirect URI for Azure PowerShell
$redirectUri = "urn:ietf:wg:oauth:2.0:oob"

# Set Resource URI to Azure Service Management API
$resourceAppIdURI = "https://management.core.windows.net/"

#RateCardAPI Settings
$ApiVersion = '2016-08-31-preview'
$Currency = 'EUR'
$Locale = 'en-DE'            #de-DE would give your german translations (e.g. "Europa" instead of EU North )which you might not want 
$RegionInfo = 'DE'

#https://azure.microsoft.com/en-us/support/legal/offer-details/
$OfferDurableId = 'MS-AZR-0003P'  #Pay as you go

Login-AzureRmAccount
$subscription = Get-AzureRmSubscription | Out-GridView -Title "Select Your Azure Subscription" -PassThru

# Set Azure AD Tenant name    $adTenant = "%something%.onmicrosoft.com"
#trying to parse it from the first user we find.
$adTenant = (Get-AzureRmADUser | Select-Object -First 1).UserPrincipalName.split('@')[1]

# Set Authority to Azure AD Tenant
$authority = "https://login.windows.net/$adTenant"

# Create Authentication Context tied to Azure AD Tenant
$authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority -Verbose 

# Acquire token
$authContext.TokenCache.Clear()
$authResult = $authContext.AcquireToken($resourceAppIdURI, $clientId, $redirectUri,"Always") #
#$authResult = $authContext.AcquireToken($resourceAppIdURI, $clientId, $redirectUri, "Auto") #may not prompt when already authenticated

$ResourceCard = "https://management.azure.com/subscriptions/{5}/providers/Microsoft.Commerce/RateCard?api-version={0}&`$filter=OfferDurableId eq '{1}' and Currency eq '{2}' and Locale eq '{3}' and RegionInfo eq '{4}'" -f $ApiVersion, $OfferDurableId, $Currency, $Locale, $RegionInfo, $($Subscription.Id)
$authHeader = @{"Authorization" = "BEARER " + $authResult.AccessToken} 
$r = Invoke-WebRequest -Uri "$ResourceCard" -Method GET -Headers $authHeader 

$mcontent = ($r.Content -split '[rn]')
$mContent = ($mResponse.Content -split '[rn]')

$currentPath = ""
#region what directory are we in?
    if ($host.name -eq 'ConsoleHost') # or -notmatch 'ISE'
    {
      $currentPath = split-path $SCRIPT:MyInvocation.MyCommand.Path -parent
    }
    else
    {
      $currentPath = split-path $psISE.CurrentFile.FullPath -parent
    }
#endregion  
#output RateCard Result as RAW json
$File = "$currentPath\$OfferDurableId-RateCaredRAW.json"
$r.Content | Out-File $File

#work with it 
$Resources = Get-Content -Raw -Path $File -Encoding UTF8 | ConvertFrom-Json

#you Europeans might want to have the counters a bit more handy ;-)
$Europe = $Resources.Meters.Where({$_.MeterRegion -like "EU *"})      #"EU North" - "EU West" specific for datacenters in Dublin and Amsterdam
$Europe += $Resources.Meters.Where({$_.MeterRegion -like "Zone*"})    # some networking counters are defined in Zones.
$Europe += $Resources.Meters.Where({$_.MeterRegion -eq ""})           # some values are global and have no 'Region'
$Europe | Export-Csv -Path "$currentPath\RateCard_EU.csv" -Encoding UTF8 -Delimiter ';' -NoTypeInformation
