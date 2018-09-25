<#
    This Script is about making a VM to something useful using Custom Script Extensions (CSE)
    
    use CSEs for e.g.
    ------------
    installing roles & features
    Downloads something / unzip / install
    Domain join
    Attaches data disk - format 
    ....
#>

#region Variables
   $RG = "Ex1-RG"
   $Location = "NorthEurope"
   $VMName = "myVMName"
   $StorageAccountName = "CSEstore$(get-random)".ToLower()  # needs to be unique and lower case
   $ContainerName = "CustomScriptsContainer".ToLower()
#endregion
   
#Login to Azure
Login-AzureRMAccount

#sample
#$myCSE1URL = "https://raw.githubusercontent.com/bernhardfrank/AzureBlackMagicVeeam/master/CSE/HelloCustomScriptExtension.ps1"
#Set-AzureRmVMCustomScriptExtension -ResourceGroupName $RG -VMName $VMName  -Location $Location -FileUri $myCSE1URL -Run "$(Split-Path -Leaf -Path $myCSE1URL)" -Name DemoScriptExtension

$CSEs = ""
#region get an ordered list of Custom Script Extensions in current directory to work with 
    # what directory are we in?
    if ($host.name -eq 'ConsoleHost') # or -notmatch 'ISE'
    {
      $currentPath = split-path $SCRIPT:MyInvocation.MyCommand.Path -parent
    }
    else
    {
      $currentPath = split-path $psISE.CurrentFile.FullPath -parent
    }
    
    #take only CSEs that start with 'CSE_XX_...'
    $CSEs = Get-ChildItem -Path $currentPath -Filter "CSE_*_*" | Sort-Object

    #upload them to a place where the VMs can access it e.g. github, onedrive, or Azure blob storage ;-)
        #create storageaccount & container 
        New-AzureRmStorageAccount -Name $StorageAccountName -ResourceGroupName $RG -SkuName Standard_LRS -Location $Location -Kind BlobStorage -AccessTier Cool 
        Set-AzureRmCurrentStorageAccount -Name $StorageAccountName -ResourceGroupName $RG
        New-AzureStorageContainer -Name $ContainerName -Permission Blob
        
        #upload CSEs to azure container
        $CSEsOnAzure = @()
        foreach ($CSE in $CSEs)
        {
           Set-AzureStorageBlobContent -Container $ContainerName -File $($CSE.FullName) -Force
           $CSEsOnAzure += "https://$StorageAccountName.blob.core.windows.net/$ContainerName/" + $CSE.Name
        }

        #make sure CSEs are ordered
        $CSEsOnAzure = $CSEsOnAzure | Sort-Object 
#endregion  

#iterate through Custom Script Extensions
foreach ($CSE in $CSEsOnAzure)
{
    $RunCmd = "$(Split-Path -Leaf -Path $CSE)"    # e.g. strip off path result e.g. "CSE_02_DownloadIOmeter.ps1"
    "running CSE:{0}" -f $CSE
    
    #Doesn't work? Errors? Go to Azure Portal ->  Resource groups  -> %RG$  -> myVMName -> Extensions -> %ScriptExtension%
    Set-AzureRmVMCustomScriptExtension -ResourceGroupName $RG -VMName $VMName -Location $Location -FileUri $CSE -Run $RunCmd -Name $RunCmd

    #when finished - remove as only only CSE can execute at a time... ;-)
    Remove-AzureRmVMCustomScriptExtension -ResourceGroupName $RG -VMName $VMName -Name $RunCmd -Force
}

