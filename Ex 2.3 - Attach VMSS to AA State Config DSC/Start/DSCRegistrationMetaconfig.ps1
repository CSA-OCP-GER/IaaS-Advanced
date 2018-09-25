<#


#Define the parameters for Get-AzureRmAutomationDscOnboardingMetaconfig using PowerShell Splatting
$Params = @{
    ResourceGroupName = $RG; # The name of the Resource Group that contains your Azure Automation Account
    AutomationAccountName = $AutomationAccountName; # The name of the Azure Automation Account where you want a node on-boarded to
    ComputerName = $ComputerNames; # The names of the computers that the meta configuration will be generated for
    OutputFolder = "$env:UserProfile\Desktop\";
}
# Use PowerShell splatting to pass parameters to the Azure Automation cmdlet being invoked
# For more info about splatting, run: Get-Help -Name about_Splatting
Get-AzureRmAutomationDscOnboardingMetaconfig @Params

#>



# The DSC configuration that will generate metaconfigurations
[DscLocalConfigurationManager()]
Configuration DscRegistrationMetaConfig
{
     param
     (
        [Parameter(Mandatory=$True)]
        [String]$RegistrationUrl,
        [Parameter(Mandatory=$True)]
        [PSCredential]$RegistrationKey,

        [Int]$RefreshFrequencyMins = 30,
        [Int]$ConfigurationModeFrequencyMins = 15,
        [String]$ConfigurationMode = 'ApplyAndMonitor',
        [String]$NodeConfigurationName,
        [Boolean]$RebootNodeIfNeeded= $False,
        [String]$ActionAfterReboot = 'ContinueConfiguration',
        [Boolean]$AllowModuleOverwrite = $False
     )

     if(!$NodeConfigurationName -or $NodeConfigurationName -eq '')
     {
         $ConfigurationNames = $null
     }
     else
     {
         $ConfigurationNames = @($NodeConfigurationName)
     }

    Settings
    {
             RefreshFrequencyMins           = $RefreshFrequencyMins
             RefreshMode                    = 'Pull'
             ConfigurationMode              = $ConfigurationMode
             AllowModuleOverwrite           = $AllowModuleOverwrite
             RebootNodeIfNeeded             = $RebootNodeIfNeeded
             ActionAfterReboot              = $ActionAfterReboot
             ConfigurationModeFrequencyMins = $ConfigurationModeFrequencyMins
         }
    
    if(!$ReportOnly)
    {
            ConfigurationRepositoryWeb AzureAutomationStateConfiguration
            {
                ServerUrl          = $RegistrationUrl
                RegistrationKey    = $RegistrationKey.GetNetworkCredential().Password
                ConfigurationNames = $ConfigurationNames
            }

            ResourceRepositoryWeb AzureAutomationStateConfiguration
            {
                ServerUrl       = $RegistrationUrl
                RegistrationKey = $RegistrationKey.GetNetworkCredential().Password
            }
         }
    
    ReportServerWeb AzureAutomationStateConfiguration
    {
             ServerUrl       = $RegistrationUrl
             RegistrationKey = $RegistrationKey.GetNetworkCredential().Password
         }

}