<#


see https://docs.microsoft.com/en-us/azure/automation/tutorial-configure-servers-desired-state

https://docs.microsoft.com/en-us/azure/automation/automation-dsc-onboarding#secure-registration 
https://docs.microsoft.com/en-us/azure/virtual-machines/extensions/dsc-template

#>

#region Variables
    $RG = "Ex2-RG"
    $Location = "NorthEurope"

    $StorageAccountPrefix = "DSCmeta".ToLower()  # needs to be unique and lower case"dscmeta*"
    $ContainerName = "DSCRegScritpContainer".ToLower()

    $AutomationAccountName = 'myAutoAcc'
    $NodeConfigName = "Testconfig"
    $VMScaleSetName = "myVMScaleSet"
    $VNETName = "VNET"
    $SubnetName= "SubNet1"
    $PublicIPAddressName = "LBPubIP"
    $LoadBalancerName = "myLoadBalancer"
    $InboundNatPoolName = "myLBinNatPool"
    $VMScaleSetName = "myVMScaleSet"
#endregion

#Login-AzureRmAccount

# get Azure Automation State Configuration registration info
$Account = Get-AzureRmAutomationAccount -ResourceGroupName $RG -Name $AutomationAccountName
$RegistrationInfo = $Account | Get-AzureRmAutomationRegistrationInfo

$DSCRegistrationMetaconfigSA = AzureRmStorageAccount -ResourceGroupName $RG | where StorageAccountName -Like "$StorageAccountPrefix*"
$DSCRegistrationMetaconfigZIP = "DSCRegistrationMetaconfig.ps1.zip"
$DSCRegistrationMetaconfigURI = "https://$($DSCRegistrationMetaconfigSA.StorageAccountName).blob.core.windows.net/$ContainerName/" + $DSCRegistrationMetaconfigZIP
#test in browser if URI is downloadable...

$Settings =  @{
    ModulesUrl = $DSCRegistrationMetaconfigURI
    ConfigurationFunction = 'DSCRegistrationMetaconfig.ps1\DscRegistrationMetaConfig'

# update these PowerShell DSC Local Configuration Manager defaults if they do not match your use case.
# See https://docs.microsoft.com/powershell/dsc/metaConfig for more details
    Properties = @{
        RegistrationKey = @{
            UserName = 'PLACEHOLDER_DONOTUSE'
            Password = 'PrivateSettingsRef:RegistrationKey'
        }
        RegistrationUrl = $RegistrationInfo.Endpoint
        NodeConfigurationName = $($NodeConfigName + ".webserver"); #'TestConfig.webserver';
        ConfigurationMode = 'ApplyAndMonitor'
        ConfigurationModeFrequencyMins = 15
        RefreshFrequencyMins = 30
        RebootNodeIfNeeded = $False
        ActionAfterReboot = 'ContinueConfiguration'
        AllowModuleOverwrite = $False
    }
}
$ProtectedSettings = @{
    Items = @{"RegistrationKey" = $($RegistrationInfo.PrimaryKey)}
}

#add Powershell Extension to Scale Set
$vmss = Get-AzureRmVmss -ResourceGroupName $RG -VMScaleSetName $VMScaleSetName
$ExtName = "DSC";
$Publisher = "Microsoft.Powershell";
$ExtType = "DSC";
$ExtVer = "2.76";

Add-AzureRmVmssExtension -VirtualMachineScaleSet $vmss -Name $ExtName -Publisher $Publisher  `
  -Type $ExtType -TypeHandlerVersion $ExtVer -AutoUpgradeMinorVersion $True  `
  -Setting $Settings -ProtectedSetting $ProtectedSettings

Update-AzureRmVmss -VirtualMachineScaleSet $vmss -ResourceGroupName $RG -VMScaleSetName $vmss.Name

#after this you should see your nodes appear in Azure Portal -> %Ressource Group% -> %Azure Automation Account -> State configuration (DSC)
