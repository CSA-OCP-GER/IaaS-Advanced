<#
see https://docs.microsoft.com/en-us/azure/virtual-machine-scale-sets/quick-create-powershell
#>

#region Variables
    $RG = "Ex2-RG"
    $Location = "NorthEurope"
    $VMScaleSetName = "myVMScaleSet"
    $VNETName = "VNET"
    $SubnetName= "SubNet1"
    $PublicIPAddressName = "LBPubIP"
    $LoadBalancerName = "myLoadBalancer"
    $InboundNatPoolName = "myLBinNatPool"
    $VMScaleSetName = "myVMScaleSet"
#endregion

#Login-AzureRmAccount

New-AzureRmResourceGroup -Name $RG -Location $Location

#region create VNET
    $Subnets = @()
    $Subnets += New-AzureRmVirtualNetworkSubnetConfig -Name "SubNet1" -AddressPrefix "10.1.1.0/24"
    $Subnets += New-AzureRmVirtualNetworkSubnetConfig -Name "SubNet2" -AddressPrefix "10.1.2.0/24"
    $Subnets += New-AzureRmVirtualNetworkSubnetConfig -Name "SubNet3" -AddressPrefix "10.1.3.0/24"
    
    #Create VNET
    $VNET = New-AzureRmVirtualNetwork -Name $VNETName -ResourceGroupName $RG -Location $Location -Subnet $Subnets -AddressPrefix "10.1.0.0/16"
#endregion

#region Create LoadBalancer First

    #run this
    help New-AzureRmLoadBalancer -Examples | clip
    
    <do a CTRL-V here>
    #now modify to have a:
    # pubIP static standard pub ip address
    # tcp probe to port 80 
    # load balancer rule for port 80 (http)
    # use a natrule or natpool to allow RDP in

#endregion

#chooses a template suitable for a windows vm scale set
$PublisherName = "MicrosoftWindowsServer" 
$Offer         = "WindowsServer" 
$Sku           = (Get-AzureRmVMImageSku -Location $Location -PublisherName $PublisherName -Offer $Offer) | Out-GridView -Title 'Take 2016 Datacenter !' -PassThru
$Version       = "latest"

$ExtName = "CSETest";
$Publisher = "Microsoft.Compute";
$ExtType = "BGInfo";
$ExtVer = "2.1";

#to prompt for credentials
$credential = Get-Credential -Message "Your VM Scale Set Admin User"
$AdminUsername = $credential.UserName
$AdminPassword = $credential.GetNetworkCredential().Password

.
.
.
#remember PowerShell 'help' is your friend.

#Create the VMSS -AsJob
New-AzureRmVmss ...
