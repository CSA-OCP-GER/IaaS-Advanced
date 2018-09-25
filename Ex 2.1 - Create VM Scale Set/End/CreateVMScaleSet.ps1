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
    $publicIP = New-AzureRmPublicIpAddress -Name $PublicIPAddressName -ResourceGroupName $RG -Location $Location -AllocationMethod Static -Sku Standard # -DomainNameLabel $LBDomainNameLabel
    $LBFrontendIPConfigName = "LBFEConfig-" +$PublicIPAddressName
    $frontendIP = New-AzureRmLoadBalancerFrontendIpConfig -Name $LBFrontendIPConfigName -PublicIpAddress $publicIP

    #TCP probe
    $healthProbe = New-AzureRmLoadBalancerProbeConfig -Name HealthProbe -Protocol Tcp -Port 80 -IntervalInSeconds 15 -ProbeCount 2
    #http probe
    #$healthProbe = New-AzureRmLoadBalancerProbeConfig -Name HealthProbe -RequestPath 'HealthProbe.aspx' -Protocol http -Port 80 -IntervalInSeconds 15 -ProbeCount 2

    $beaddresspool = New-AzureRmLoadBalancerBackendAddressPoolConfig -Name "LBBEPool"
    
    #Create a load balancer rule
    $lbrule = New-AzureRmLoadBalancerRuleConfig -Name HTTP -FrontendIpConfiguration $frontendIP -BackendAddressPool $beAddressPool -Probe $healthProbe -Protocol Tcp -FrontendPort 80 -BackendPort 80 -LoadDistribution SourceIP
    
    #$inboundNATRule1= New-AzureRmLoadBalancerInboundNatRuleConfig -Name RDP1 -FrontendIpConfiguration $frontendIP -Protocol TCP -FrontendPort 3341 -BackendPort 3389
    #$inboundNATRule2= New-AzureRmLoadBalancerInboundNatRuleConfig -Name RDP2 -FrontendIpConfiguration $frontendIP -Protocol TCP -FrontendPort 3442 -BackendPort 3389
    $inboundNATPool = New-AzureRmLoadBalancerInboundNatPoolConfig -Name RDP -FrontendIPConfigurationId $frontendIP.Id -Protocol Tcp -FrontendPortRangeStart 3360 -FrontendPortRangeEnd 3380 -BackendPort 3389

    #create the load balancer
    $LB = New-AzureRmLoadBalancer -ResourceGroupName $RG -Name $LoadBalancerName -Location $Location -FrontendIpConfiguration $frontendIP -LoadBalancingRule $lbrule -BackendAddressPool $beAddressPool -Probe $healthProbe -InboundNatPool $inboundNATPool -Sku Standard
#endregion

$PublisherName = "MicrosoftWindowsServer" 
$Offer         = "WindowsServer" 
$Sku           = (Get-AzureRmVMImageSku -Location $Location -PublisherName $PublisherName -Offer $Offer) | Out-GridView -PassThru
$Version       = "latest"

$ExtName = "CSETest";
$Publisher = "Microsoft.Compute";
$ExtType = "BGInfo";
$ExtVer = "2.1";

$credential = Get-Credential -Message "Your VM Scale Set Admin User"
$AdminUsername = $credential.UserName
$AdminPassword = $credential.GetNetworkCredential().Password

$SKUNames = "Standard_A0,Standard_A1,Standard_A2,Standard_A3,Standard_A5,Standard_A4,Standard_A6,Standard_A7,Basic_A0,Basic_A1,Basic_A2,Basic_A3,Basic_A4,Standard_B1ms,Standard_B1s,Standard_B2ms,Standard_B2s,Standard_B4ms,Standard_B8ms,Standard_DS1_v2,Standard_DS2_v2,Standard_DS3_v2,Standard_DS4_v2,Standard_DS5_v2,Standard_DS11-1_v2,Standard_DS11_v2,Standard_DS12-1_v2,Standard_DS12-2_v2,Standard_DS12_v2,Standard_DS13-2_v2,Standard_DS13-4_v2,Standard_DS13_v2,Standard_DS14-4_v2,Standard_DS14-8_v2,Standard_DS14_v2,Standard_DS15_v2,Standard_DS2_v2_Promo,Standard_DS3_v2_Promo,Standard_DS4_v2_Promo,Standard_DS5_v2_Promo,Standard_DS11_v2_Promo,Standard_DS12_v2_Promo,Standard_DS13_v2_Promo,Standard_DS14_v2_Promo,Standard_F1s,Standard_F2s,Standard_F4s,Standard_F8s,Standard_F16s,Standard_D2s_v3,Standard_D4s_v3,Standard_D8s_v3,Standard_D16s_v3,Standard_D32s_v3,Standard_D1_v2,Standard_D2_v2,Standard_D3_v2,Standard_D4_v2,Standard_D5_v2,Standard_D11_v2,Standard_D12_v2,Standard_D13_v2,Standard_D14_v2,Standard_D2_v2_Promo,Standard_D3_v2_Promo,Standard_D4_v2_Promo,Standard_D5_v2_Promo,Standard_D11_v2_Promo,Standard_D12_v2_Promo,Standard_D13_v2_Promo,Standard_D14_v2_Promo,Standard_F1,Standard_F2,Standard_F4,Standard_F8,Standard_F16,Standard_A1_v2,Standard_A2m_v2,Standard_A2_v2,Standard_A4m_v2,Standard_A4_v2,Standard_A8m_v2,Standard_A8_v2,Standard_D2_v3,Standard_D4_v3,Standard_D8_v3,Standard_D16_v3,Standard_D32_v3,Standard_D64_v3,Standard_D64s_v3,Standard_E2_v3,Standard_E4_v3,Standard_E8_v3,Standard_E16_v3,Standard_E20_v3,Standard_E32_v3,Standard_E64i_v3,Standard_E64_v3,Standard_E2s_v3,Standard_E4-2s_v3,Standard_E4s_v3,Standard_E8-2s_v3,Standard_E8-4s_v3,Standard_E8s_v3,Standard_E16-4s_v3,Standard_E16-8s_v3,Standard_E16s_v3,Standard_E20s_v3,Standard_E32-8s_v3,Standard_E32-16s_v3,Standard_E32s_v3,Standard_E64-16s_v3,Standard_E64-32s_v3,Standard_E64is_v3,Standard_E64s_v3,Standard_D15_v2,Standard_G1,Standard_G2,Standard_G3,Standard_G4,Standard_G5,Standard_GS1,Standard_GS2,Standard_GS3,Standard_GS4,Standard_GS4-4,Standard_GS4-8,Standard_GS5,Standard_GS5-8,Standard_GS5-16,Standard_L4s,Standard_L8s,Standard_L16s,Standard_L32s,Standard_D1,Standard_D2,Standard_D3,Standard_D4,Standard_D11,Standard_D12,Standard_D13,Standard_D14,Standard_NV6,Standard_NV12,Standard_NV24,Standard_M8-2ms,Standard_M8-4ms,Standard_M8ms,Standard_M16-4ms,Standard_M16-8ms,Standard_M16ms,Standard_M32-8ms,Standard_M32-16ms,Standard_M32ls,Standard_M32ms,Standard_M32ts,Standard_M64-16ms,Standard_M64-32ms,Standard_M64ls,Standard_M64ms,Standard_M64s,Standard_M128-32ms,Standard_M128-64ms,Standard_M128ms,Standard_M128s,Standard_M64,Standard_M64m,Standard_M128,Standard_M128m,Standard_NC6,Standard_NC12,Standard_NC24,Standard_NC24r,Standard_DS1,Standard_DS2,Standard_DS3,Standard_DS4,Standard_DS11,Standard_DS12,Standard_DS13,Standard_DS14,Standard_F2s_v2,Standard_F4s_v2,Standard_F8s_v2,Standard_F16s_v2,Standard_F32s_v2,Standard_F64s_v2,Standard_F72s_v2,Standard_A8,Standard_A9,Standard_A10,Standard_A11,Standard_H8,Standard_H16,Standard_H8m,Standard_H16m,Standard_H16r,Standard_H16mr".Split(',')
$SKUName = $SKUNames | Out-GridView -PassThru

#IP Config for the NIC
$IPCfg = New-AzureRmVmssIPConfig -Name "Test" `
    -LoadBalancerInboundNatPoolsId $LB.InboundNatPools[0].Id `
    -LoadBalancerBackendAddressPoolsId $LB.BackendAddressPools[0].Id `
    -SubnetId $VNet.Subnets[0].Id
      
#Create NSG
$NSGName = "myNSG"
$NSGRules = @()
$NSGRules += New-AzureRmNetworkSecurityRuleConfig -Name "RDP" -Priority 101 -Description "inbound RDP access" -Protocol Tcp -SourcePortRange * -SourceAddressPrefix * -DestinationPortRange 3389 -DestinationAddressPrefix * -Access Allow -Direction Inbound 
$NSGRules += New-AzureRmNetworkSecurityRuleConfig -Name "http" -Priority 102 -Description "inbound http access" -Protocol Tcp -SourcePortRange * -SourceAddressPrefix * -DestinationPortRange 80 -DestinationAddressPrefix * -Access Allow -Direction Inbound 
$NSG = New-AzureRmNetworkSecurityGroup -Name $NSGName -ResourceGroupName $RG -Location $Location -SecurityRules $NSGRules
      
#VMSS Config
$VMSS = New-AzureRmVmssConfig -Location $Location -SkuCapacity 2 -SkuName $SKUName -UpgradePolicyMode "Automatic" `
    | Add-AzureRmVmssNetworkInterfaceConfiguration -Name "Test" -Primary $True -IPConfiguration $IPCfg -NetworkSecurityGroupId $NSG.Id `
    | Set-AzureRmVmssOSProfile -ComputerNamePrefix "Test"  -AdminUsername $AdminUsername -AdminPassword $AdminPassword `
    | Set-AzureRmVmssStorageProfile -OsDiskCreateOption 'FromImage' -OsDiskCaching "None" `
    -ImageReferenceOffer $Offer -ImageReferenceSku $Sku.Skus -ImageReferenceVersion $Version `
    -ImageReferencePublisher $PublisherName -OsDiskOsType Windows -ManagedDisk Premium_LRS `
    | Add-AzureRmVmssExtension -Name $ExtName -Publisher $Publisher -Type $ExtType -TypeHandlerVersion $ExtVer -AutoUpgradeMinorVersion $True

    
#Create the VMSS
New-AzureRmVmss -ResourceGroupName $RG -Name $VMScaleSetName -VirtualMachineScaleSet $VMSS -AsJob
