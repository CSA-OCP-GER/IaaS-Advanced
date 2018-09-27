<# 

    What are the costs of a Resource Group?
    
    Usage API: Resource Usage - Get consumption data for an Azure subscription
    https://docs.microsoft.com/en-us/previous-versions/azure/reference/mt219003%28v%3dazure.100%29

    RateCard API: Get price and metadata information for resources used in an Azure subscription
    https://docs.microsoft.com/en-us/previous-versions/azure/reference/mt219005%28v%3dazure.100%29

#>


#region Variables
    $RG = "Ex2-RG"
    $Location = "NorthEurope"
#endregion

Login-AzureRmAccount
Set-AzureRmContext -Subscription $(Get-AzureSubscription | Out-GridView -Title "Select your subscription - Azure Pass might fail" -PassThru).SubscriptionName

#to make time selection a bit more comfortable
function DateTimePicker ()
{
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    
    $form = New-Object Windows.Forms.Form
    
    $form.Text = 'Select a Date'
    $form.Size = New-Object Drawing.Size @(243,230)
    $form.StartPosition = 'CenterScreen'
    
    $calendar = New-Object System.Windows.Forms.MonthCalendar
    $calendar.ShowTodayCircle = $false
    $calendar.MaxSelectionCount = 1
    $form.Controls.Add($calendar)
    
    $OKButton = New-Object System.Windows.Forms.Button
    $OKButton.Location = New-Object System.Drawing.Point(38,165)
    $OKButton.Size = New-Object System.Drawing.Size(75,23)
    $OKButton.Text = 'OK'
    $OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.AcceptButton = $OKButton
    $form.Controls.Add($OKButton)
    
    $CancelButton = New-Object System.Windows.Forms.Button
    $CancelButton.Location = New-Object System.Drawing.Point(113,165)
    $CancelButton.Size = New-Object System.Drawing.Size(75,23)
    $CancelButton.Text = 'Cancel'
    $CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.CancelButton = $CancelButton
    $form.Controls.Add($CancelButton)
    
    $form.Topmost = $true
    
    $result = $form.ShowDialog()
    
    if ($result -eq [System.Windows.Forms.DialogResult]::OK)
    {
        $date = $calendar.SelectionStart
        return $date
    }
}

#Get the consumption details for a specifig period and ResourceGroup
#Note - AzurePass subscription throws an error!
$consumptionDet = Get-AzureRmConsumptionUsageDetail -ResourceGroup $RG -StartDate (([datetime](DateTimePicker)).ToUniversalTime()) -EndDate (([datetime](DateTimePicker)).ToUniversalTime()) -IncludeMeterDetails -IncludeAdditionalProperties 
$consumptionDet | Out-GridView

#Problem: Ein bisschen mehr Details wär schön - z.B. welche OS Disk Größe, VM Type? -> MeterID als GUID.

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

#Lösung: RATECARD Result zur Auflösung der MeterID verwenden
$RateCard = Import-Csv -Path "$currentPath\RateCard_EU.csv" -Delimiter ';' -Encoding UTF8

#mapping magic mit PowerShell Expressions
$consumptionDet | select UsageStart,UsageEnd,InstanceName,UsageQuantity,PretaxCost,Currency,@{L='MeterResolvedName';E={ $MeterID = $_.MeterId ;$RateCard | where {$_.MeterId -eq $MeterId}| select MeterName}}, MeterID,Name | Out-GridView

#export als CSV
$consumptionDet | select UsageStart,UsageEnd,InstanceName,@{L='RateCardMeterRates';E={ $MeterID = $_.MeterId ;$RateCard | where {$_.MeterId -eq $MeterId}| select MeterRates}},@{L='RateCardUnit';E={ $MeterID = $_.MeterId ;$RateCard | where {$_.MeterId -eq $MeterId}| select Unit}},UsageQuantity,PretaxCost,Currency,@{L='RateCardMeterResolvedName';E={ $MeterID = $_.MeterId ;$RateCard | where {$_.MeterId -eq $MeterId}| select MeterName}}, MeterID,Name | Export-Csv -Path "$currentPath\$RG-ConsumptionDetails.csv" -Delimiter ';' -Encoding UTF8 -NoTypeInformation