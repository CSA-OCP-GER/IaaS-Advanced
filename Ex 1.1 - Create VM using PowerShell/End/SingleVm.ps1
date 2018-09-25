<#
    The Mission:
    Create a PowerShell Script that should deploy a single VM just like 
    https://docs.microsoft.com/en-us/azure/architecture/reference-architectures/virtual-machines-windows/single-vm

    - Create a VM that can use Premium Disks
    - Create 2 Subnets within the VNET
    - Use variables 
    - Use Powershell help .... -examples 
    - Copy 'n Paste with pride!

     have fun!
#>

#region Variables
   $RG = "Ex1-RG"
   $Location = "NorthEurope"
   $VNETName = "VNET"
   $NSGName = "myNSG"
   $AVSetName = "myAVSet"
   $VMName = "myVMName"
   $PublicIPAddressName = "myPIP"
   $NICName = "myNICName"
   $OSDiskCaching = "ReadWrite"
   $OSDiskName = "myOSDisk"
#endregion
   
#Login to Azure
Login-AzureRMAccount
   
#Create RG
New-AzureRmResourceGroup -Name $RG -Location $Location
   
#Create Subnet
$Subnets = @()
$Subnets += New-AzureRmVirtualNetworkSubnetConfig -Name "SubNet1" -AddressPrefix "192.168.1.0/24"
$Subnets += New-AzureRmVirtualNetworkSubnetConfig -Name "SubNet2" -AddressPrefix "192.168.2.0/24"

#Create VNET
$VNET = New-AzureRmVirtualNetwork -Name $VNETName -ResourceGroupName $RG -Location $Location -Subnet $Subnets -AddressPrefix "192.168.0.0/16"

#Create a Subnet after VNET was created
$Subnet3 = New-AzureRmVirtualNetworkSubnetConfig -Name "SubNet3" -AddressPrefix "192.168.3.0/24"
$VNET = Get-AzureRmVirtualNetwork -Name $VNETName -ResourceGroupName $RG
$VNET.Subnets.Add($Subnet3)
Set-AzureRmVirtualNetwork -VirtualNetwork $VNET

#Create NSG
$NSGRules = @()
$NSGRules += New-AzureRmNetworkSecurityRuleConfig -Name "RDP" -Priority 101 -Description "inbound RDP access" -Protocol Tcp -SourcePortRange * -SourceAddressPrefix * -DestinationPortRange 3389 -DestinationAddressPrefix * -Access Allow -Direction Inbound 
$NSG = New-AzureRmNetworkSecurityGroup -Name $NSGName -ResourceGroupName $RG -Location $Location -SecurityRules $NSGRules

#Create PublicIP
$PIP = New-AzureRmPublicIpAddress -Name $PublicIPAddressName -ResourceGroupName $RG -Location $Location -AllocationMethod Dynamic

#Create NIC
$NIC = New-AzureRmNetworkInterface -Name $NICName -ResourceGroupName $RG -Location $Location -SubnetId $VNET.Subnets.Item(0).id -PublicIpAddressId $PIP.Id -NetworkSecurityGroupId $NSG.Id

#Create Availabilityset
$AVSet = New-AzureRmAvailabilitySet -ResourceGroupName $RG -Name $AVSetName -Location $Location -PlatformUpdateDomainCount 1 -PlatformFaultDomainCount 1 -Sku Aligned

#Get VMSize
$VMSize = Get-AzureRmVMSize -Location $Location | Out-GridView -PassThru -Title "Select Your Size"
$VM = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize.Name -AvailabilitySetId $AVSet.Id

#Attach VNIC to VMConfig
$VM = Add-AzureRmVMNetworkInterface -VM $VM -Id $NIC.Id

#Get the image e.g. Publishername e.g. "MicrosoftWindowsServer" Offer: e.g. "WindowsServer"
$Publisher = (Get-AzureRmVMImagePublisher -Location $location | Out-GridView -PassThru).PublisherName 
$PublisherOffer = Get-AzureRmVMImageOffer -Location $Location -PublisherName $Publisher | Out-GridView -PassThru

$VMImageSKU = (Get-AzureRmVMImageSku -Location $Location -PublisherName $PublisherOffer.PublisherName -Offer $PublisherOffer.Offer).Skus | Out-GridView -PassThru
$VMImage = Get-AzureRmVMImage -Location $Location -PublisherName $PublisherOffer.PublisherName -Offer $PublisherOffer.Offer -Skus $VMImageSKU | Sort-Object -Descending | Select-Object -First 1

$VM= Set-AzureRmVMSourceImage -VM $VM -PublisherName $PublisherOffer.PublisherName -Offer $PublisherOffer.Offer -Skus $VMImageSKU -Verbose -Version $VMImage.Version

#Disable Boot Diagnostics for VM    (is demo - don't need it AND it would require storage account which I don't want to provision)
$VM =  Set-AzureRmVMBootDiagnostics -VM $VM -Disable 

#Get a credential
$Credential = Get-Credential -Message "Your VMs admin credentials don't use 'administrator' or weak passwords"

#pls don't hardcode ;-)
#$VMLocalAdminUser = "LocalAdminUser"
#$VMLocalAdminSecurePassword = ConvertTo-SecureString "**************" -AsPlainText -Force 
#$Credential = New-Object System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword)
$VM = Set-AzureRmVMOperatingSystem -VM $VM -Windows -ComputerName $VMName -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate

#Config OSDisk
$VM = Set-AzureRmVMOSDisk -VM $VM -Name $OSDiskName -Caching $OSDiskCaching -CreateOption FromImage -DiskSizeInGB 128

#new VM
New-AzureRmVM -ResourceGroupName $RG -Location $location -VM $VM -AsJob   #-AsJob immediately runs the job in the background -> get-job