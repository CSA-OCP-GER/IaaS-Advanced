#region Variables
    $RG = "Ex2-RG"
    $Location = "NorthEurope"
    $VMScaleSetName = "myVMScaleSet"
    $StorageAccountName = "DSCmetasa$(get-random)".ToLower()  # needs to be unique and lower case
    $ContainerName = "DSCRegScritpContainer".ToLower()
#endregion

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

#get the DSCRegistrationMetaconfig file
$DSCRegistrationMetaconfig = Get-ChildItem -Path $currentPath -Filter "DSCRegistrationMetaconfig.ps1"

$DSCRegistrationMetaconfigZIP = "$($DSCRegistrationMetaconfig.FullName+".zip")"
Compress-Archive -LiteralPath $DSCRegistrationMetaconfig.FullName -CompressionLevel Optimal -DestinationPath $DSCRegistrationMetaconfigZIP -Force

#upload them to a place where the Scale Set VMs can access it e.g. github, onedrive, or Azure blob storage ;-)
    #create storageaccount & container 
    New-AzureRmStorageAccount -Name $StorageAccountName -ResourceGroupName $RG -SkuName Standard_LRS -Location $Location -Kind BlobStorage -AccessTier Cool 
    Set-AzureRmCurrentStorageAccount -Name $StorageAccountName -ResourceGroupName $RG
    New-AzureStorageContainer -Name $ContainerName -Permission Blob
    
    #upload DSCRegistrationMetaconfig to azure container reachable for VM Scale Sets to do AA Registration 
    Set-AzureStorageBlobContent -Container $ContainerName -File $DSCRegistrationMetaconfigZIP -Force
    $DSCRegistrationMetaconfigURI = "https://$StorageAccountName.blob.core.windows.net/$ContainerName/" + $(split-path $DSCRegistrationMetaconfigZIP -Leaf)


