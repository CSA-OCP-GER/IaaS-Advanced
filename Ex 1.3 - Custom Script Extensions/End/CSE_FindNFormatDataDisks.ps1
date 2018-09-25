<# 
    This Custom Script Extension finds and formats data disks.... 
#>

#this will be our temp folder - need it for download / logging
$tmpDir = "c:\temp\" 
$log = $($tmpDir+"\ScriptExtension.log")

#create folder if it doesn't exist
if (!(Test-Path $tmpDir)) { mkdir $tmpDir -force}

"I was run at: {0}" -f (Get-Date)  | Out-File -FilePath $log -Append

Start-Transcript $log -Append

$disks = Get-Disk

$driveLetters = ("f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z")

$i = 0
foreach ($disk in $disks){
    if ($disk.PartitionStyle -eq "RAW"){

        # to fix 
        $currentDriveLetter = $driveLetters[$i]

        New-Volume -DiskNumber $disk.DiskNumber -FriendlyName "Data" -FileSystem NTFS -DriveLetter $currentDriveLetter -AllocationUnitSize 64kB
        $i++
    }
}

Stop-Transcript