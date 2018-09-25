<# 
    This Script Extension downloads a Windows Server Eval Iso
    https://sourceforge.net/projects/iometer/files/iometer-stable/1.1.0/iometer-1.1.0-win64.x86_64-bin.zip/download
    https://downloads.sourceforge.net/project/iometer/iometer-stable/1.1.0/iometer-1.1.0-win64.x86_64-bin.zip?r=https%3A%2F%2Fsourceforge.net%2Fprojects%2Fiometer%2Ffiles%2Fiometer-stable%2F1.1.0%2Fiometer-1.1.0-win64.x86_64-bin.zip%2Fdownload&ts=1537728138
    https://sourceforge.net/projects/iometer/files/iometer-stable/1.1.0/iometer-1.1.0-win64.x86_64-bin.zip/download#
    https://vorboss.dl.sourceforge.net/project/iometer/iometer-stable/1.1.0/iometer-1.1.0-win64.x86_64-bin.zip
#>

#this will be our temp folder - need it for download / logging
$tmpDir = "c:\temp\" 
$log = $($tmpDir+"\ScriptExtension.log")

#create folder if it doesn't exist
if (!(Test-Path $tmpDir)) { mkdir $tmpDir -force}

"I was run at: {0}" -f (Get-Date)  | Out-File -FilePath $log -Append

Start-Transcript $log -Append

$URI = "https://vorboss.dl.sourceforge.net/project/iometer/iometer-stable/1.1.0/iometer-1.1.0-win64.x86_64-bin.zip"
$URIPath = $tmpDir + "\$(Split-Path $URI -Leaf)"


if (!(Test-Path $URIPath )) 
{
    Write-Output "starting download...."
    start-bitstransfer "$URI" "$URIPath" -Priority High -RetryInterval 60 -Verbose -TransferType Download
    Write-Output "finished downloading: $URIPath"
}

Stop-Transcript

