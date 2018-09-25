<#
    The Mission:
    Create a PowerShell Script that should deploy a single VM just like 
    https://docs.microsoft.com/en-us/azure/architecture/reference-architectures/virtual-machines-windows/single-vm

    - Create a VM that can use Premium Disks !!!
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
   
#Create ResourceGroup

   
#Create Subnets "192.168.1.0/24", "192.168.2.0/24"
$Subnets = @()
$Subnets += New-AzureRmVirtualNetworkSubnetConfig...

#Create VNET
$VNET = New-AzureRmVirtualNetwork... 

#optional: create a 3rd subnet "192.168.3.0/24" after the VNET was created
$Subnet3 = New-Azur...
$VNET = Get-AzureRm...
$VNET.Subnets.Add($...
Set-AzureRmVirtualN...

#Create Network Security Group to allow inbount RDP traffic (dest port: 3389)
$NSGRules = @()
$NSGRules += New-AzureRm...
$NSG = New-AzureRmNetworkS...

#Create PublicIP
$PIP = 

#Create NIC
$NIC = 

#Create Availabilityset - do it now - after a vm has been created it is too late...
$AVSet = New-AzureRmAvailability...

#Get VMSize hardcode or selectable "out-gridview -passthrough"
$VMSize = Get-AzureRmVMSize ... 
$VM = New-AzureRmVMConfig ...

#Attach VNIC to VMConfig
$VM = Add-AzureRmVMNetworkInterface ...

#Get the image e.g. Publishername e.g. "MicrosoftWindowsServer" Offer: e.g. "WindowsServer"
$Publisher = (Get-AzureRmVMImagePublisher -Location $location | Out-GridView -PassThru).PublisherName 
$PublisherOffer = Get-AzureRmVMImageOffer ...

$VMImageSKU = (Get-AzureRmVMImageSku ... ).Skus | Out-GridView -PassThru
$VMImage = Get-AzureRmVMImage ... | Sort-Object -Descending | Select-Object -First 1

$VM= Set-AzureRmVMSourceImage ... -Version $VMImage.Version # try also 'latest'

#Disable Boot Diagnostics for VM    (is demo - don't need it AND it would require storage account which I don't want to provision)
$VM =  Set-AzureRmVMBootDiagnostics -VM $VM -Disable 

#Get a credential please don't hardcode ;-)
$Credential = Get-Credential -Message "Your VMs admin credentials don't use 'administrator' or weak passwords"

#and put it into the VM OS config
$VM = Set-AzureRmVMOperatingS...

#Config OSDisk
$VM = Set-AzureRmVM...

#New VM
New-AzureRmVM ... -AsJob   #-AsJob immediately runs the job in the background -> get-job