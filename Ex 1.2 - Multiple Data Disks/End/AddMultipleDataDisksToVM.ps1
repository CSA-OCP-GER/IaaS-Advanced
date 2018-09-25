<#

Attach a count of $DataDiskCount data disks to a VM as a basis for some perf tests.

#>

#region Variables
   $RG = "Ex1-RG"
   $Location = "NorthEurope"

   $VMName = "myVMName"

   $DataDiskPrefix = "myDataDisk"
   $DataDiskCount = 6
   #Premium - SSD based disks - requires VMs with 'S' in VM Type
   #There are no transaction costs for Premium Disks. 
   $PremiumDiskTypes = @{"P4"=32 ; "P6"=64 ; "P10"=128 ; "P20"=512 ; "P30"=1024 ; "P40"=2048 ; "P50"=4096}    #https://docs.microsoft.com/en-us/azure/virtual-machines/windows/premium-storage#premium-storage-disk-limits

   #Standard Disks -> VM Types with / without 'S' in VM Type
   # 'Sx'- disks HDD based
   # 'Ex'- disks SSD based - low latency - (new-preview)
   #Note: there are transactions costs Standard Managed Disks. Any type of operation against the storage is counted as a transaction, including reads, writes and deletes. 
   $StandardDiskTypes = @{"S4"=32 ; "S6"=64 ; "S10"=128 ; "S15"=256 ; "S20"=512 ; "S30"=1024 ; "S40"=2048 ; "S50"=4095; "E10"=128 ; "E15"=256 ; "E20"=512 ; "E30"=1024 ; "E40"=2048; "E50"=4096}    #https://azure.microsoft.com/en-us/pricing/details/managed-disks/
#endregion
   
#Login to Azure
Login-AzureRMAccount
   
$VM = Get-AzureRmVM -ResourceGroupName $RG -Name $VMName

for ($disknum = 1; $disknum -le $DataDiskCount; $disknum++)
{ 
    "creating data disk:{0}" -f $($DataDiskPrefix+$disknum)
    #attach Premium DataDisk
    $DataDiskConfig = $null
    $DataDiskConfig = New-AzureRmDiskConfig -SkuName Premium_LRS -DiskSizeGB $PremiumDiskTypes.P20 -Location $location -CreateOption Empty 

    #attach Standard DataDisk
    #$DataDiskConfig = New-AzureRmDiskConfig -SkuName Standard_LRS -DiskSizeGB $StandardDiskTypes.S15 -Location $location -CreateOption Empty

    $DataDisk = New-AzureRmDisk -ResourceGroupName $RG -DiskName $($DataDiskPrefix+$disknum) -Disk $DataDiskConfig 
    $VM = Add-AzureRmVMDataDisk -VM $VM -Name $($DataDisk.Name) -Caching None -ManagedDiskId $DataDisk.Id -CreateOption Attach -Lun $disknum
}

Update-AzureRmVM -ResourceGroupName $RG -VM $VM -AsJob  #-AsJob immediately runs the job in the background -> get-job

while (get-job -Newest 1 -State Running)
{
    "job is still running"
    sleep 3
}

#you may not open Disk manager in Azure VM to see how the disks get addedd. Don't online them or format - we'll do this later.