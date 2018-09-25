<#
this custom script extension installs file services
#>


#this will be our temp folder - need it for download / logging

$tmpDir = "c:\temp\" 

#create folder if it doesn't exist
if (!(Test-Path $tmpDir)) { mkdir $tmpDir -force}

Start-Transcript "$tmpDir\ScriptExtension.log" -Append

#install IIS features 
$features = @("FileAndStorage-Services","File-Services", "FS-FileServer", "FS-Data-Deduplication", "Storage-Services")
Install-WindowsFeature -Name $features -Verbose 

Stop-Transcript