<#
see https://docs.microsoft.com/en-us/azure/automation/tutorial-configure-servers-desired-state

see https://docs.microsoft.com/en-us/azure/automation/automation-dsc-onboarding#secure-registration 
https://docs.microsoft.com/en-us/azure/virtual-machines/extensions/dsc-template

#>

#region Variables
    $RG = "Ex2-RG"
    $Location = "NorthEurope"
    $AutomationAccountName = 'myAutoAcc'
    $NodeConfigName = "Testconfig"
#endregion

#Login-AzureRmAccount

#Create the Azure Automation Account
New-AzureRmAutomationAccount -Name $AutomationAccountName -Location $Location -ResourceGroupName $RG

$currentPath=""
#region which path are we in?
if ($host.name -eq 'ConsoleHost') # or -notmatch 'ISE'
{
  $currentPath = split-path $SCRIPT:MyInvocation.MyCommand.Path -parent
}
else
{
  $currentPath = split-path $psISE.CurrentFile.FullPath -parent
}
#endregion

#import the DSC Script
Import-AzureRmAutomationDscConfiguration -SourcePath "$currentPath\Testconfig.ps1" -ResourceGroupName $RG -AutomationAccountName $AutomationAccountName -Published

#Compile it
Start-AzureRmAutomationDscCompilationJob -ConfigurationName $NodeConfigName -ResourceGroupName $RG -AutomationAccountName $AutomationAccountName
