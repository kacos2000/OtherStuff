#Requires -RunAsAdministrator

# Show Open File Dialogs 
Function Get-FileName($initialDirectory, $Title ,$Filter)
{[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") |Out-Null
		$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
		$OpenFileDialog.Title = $Title
		$OpenFileDialog.initialDirectory = $initialDirectory
        $OpenFileDialog.Filter = $filter
		$OpenFileDialog.ShowDialog() | Out-Null
		$OpenFileDialog.ShowReadOnly = $true
		$OpenFileDialog.filename
		$OpenFileDialog.ShowHelp = $false
} #end function Get-FileName 

$DesktopPath = [Environment]::GetFolderPath("Desktop")

$File = Get-FileName -initialDirectory $DesktopPath -Filter "NTUser.dat (*.dat)|NTUser.dat" -Title 'Select NTuser.dat'
Try{write-host "File Selected: " -f White -NoNewline; (Get-ItemProperty $File).FullName}
Catch{Write-warning "(ODCreg.ps1):" ; Write-Host "User Cancelled" -f White; exit}


$ErrorActionPreference = "Stop"

#Load NTUser.dat to temp key in registry
reg load HKEY_LOCAL_MACHINE\Temp $File
 


# Looking for Metadata -> usually be found in the user's NTUser.dat at
# "SOFTWARE\Microsoft\Office\15.0\Common\Roaming\Identities\xxxxxxxxx_LiveId\Settings\1133\{00000000-0000-0000-0000-000000000000}\ListItems\"
# "SOFTWARE\Microsoft\Office\16.0\Common\Roaming\Identities\xxxxxxxxx_LiveId\Settings\1110\{00000000-0000-0000-0000-000000000000}\ListItems\"

$ver = $idpath =@{}
try{Test-Path "HKLM:\Temp\Software\Microsoft\office\"|Out-Null}
Catch{
	Write-Host -ForegroundColor Yellow "The selectd $($File) does not have the" 
	Write-Host -ForegroundColor Yellow "'Software\' registry key." 
	[gc]::Collect()
	reg unload HKEY_LOCAL_MACHINE\Temp 
    exit}
Write-Host -ForegroundColor Green "$($File) loaded OK"

$Accounts = @{}
$ids = @{}
$meta = @{}
$versions = @(8..15)
$Metadata =  @{}
$c=$null
$year = @{}
$month= @{}
$dayofweek = @{}
$day = @{}
$Hour = @{}
$Minutes = @{}
$Seconds = @{}
$millisec = @{}

# Day of Week
$dow = @{
0 = "Sunday"
1 = "MOnday"
2 = "Tuesday"
3 = "Wednesday"
4 = "Thursday"
5 = "Friday"
6 = "Saturday"
}

# Find office versions
$meta = foreach ($v in $versions){
                $v = $v.ToString("#"".0")
                if(Test-Path "HKLM:\Temp\Software\Microsoft\office\$($v)\Common\Roaming\Identities\*\Settings\*\{00000000-0000-0000-0000-000000000000}\ListItems\*\")
                {
                $ids = Get-ChildItem -Path "HKLM:\Temp\Software\Microsoft\office\$($v)\Common\Roaming\Identities\"|Select-Object -ExpandProperty Name
                $ids = $ids.replace("HKEY_LOCAL_MACHINE\Temp\Software\Microsoft\office\$($v)\Common\Roaming\Identities\","")
                
# Find IDs     
foreach($id in $ids)
                {
                $ipath = "HKLM:\Temp\Software\Microsoft\office\$($v)\Common\Roaming\Identities\$($id)\Settings\"
                if(test-path $ipath){
                $st = Get-ChildItem -Path "$ipath"|Select-Object -ExpandProperty Name
                $st = $st.replace("HKEY_LOCAL_MACHINE\Temp\Software\Microsoft\office\$($v)\Common\Roaming\Identities\$($id)\Settings\","")
                               
# Find Settings path #1
foreach($s in $st){
                $lpath = "HKLM:\Temp\Software\Microsoft\office\$($v)\Common\Roaming\Identities\$($id)\Settings\$($s)\{00000000-0000-0000-0000-000000000000}\ListItems\"
                        
                if(test-path $lpath){
                $li = Get-ChildItem -Path $lpath|Select-Object -ExpandProperty Name
                $li = $li.replace("HKEY_LOCAL_MACHINE\Temp\Software\Microsoft\office\$($v)\Common\Roaming\Identities\$($id)\Settings\$($s)\{00000000-0000-0000-0000-000000000000}\ListItems\","")
               
# Find Settings path #2
foreach($l in $li){
                $xpath =  "HKLM:\Temp\Software\Microsoft\office\$($v)\Common\Roaming\Identities\$($id)\Settings\$($s)\{00000000-0000-0000-0000-000000000000}\ListItems\$($l)\"

                if(test-path $xpath){
                $xa = Get-ChildItem -Path "$xpath"|Select-Object -ExpandProperty Name
                $xa = $xa.replace("HKEY_LOCAL_MACHINE\Temp\Software\Microsoft\office\$($v)\Common\Roaming\Identities\$($id)\Settings\$($s)\{00000000-0000-0000-0000-000000000000}\ListItems\$($l)\","")
                }

# Find final path
foreach($x in $xa){
                $mpath = @("HKLM:\Temp\Software\Microsoft\office\$($v)\Common\Roaming\Identities\$($id)\Settings\$($s)\{00000000-0000-0000-0000-000000000000}\ListItems\$($l)\$($x)\")
    
                if(test-path $mpath){
                $mp = (get-item -path $mpath)|Where-Object {!$_.ItemData -and !$_.ItemKey -and !$_.LastModified -and !$_.SortKey}
                $mp = $mp -replace ("HKEY_LOCAL_MACHINE","HKLM:")
                [gc]::Collect()
                }

# Get Metadata
                foreach($o in $mp){
                Get-ItemProperty -path $o
                }}}}}}}}}


# List IDs found
write-host "`nMS Identities found : $($ids.count)" -f Yellow;$ids
[gc]::Collect(2) # Optimized 

# Collect Data                 
$Metadata = foreach($m in $meta){$c++
            
            if($m.Itemkey.length -gt 16){ 
            
            
            $LastModified = [System.BitConverter]::ToString($m.LastModified) -replace "-",""   # 128-bit SystemTime
            $SortKey      = Get-Date ([DateTime]::FromFileTime($m.SortKey)) -Format o  # Filetime (dec) - in local(user) time
            $Itemkey      = [System.Text.Encoding]::Unicode.GetString($m.Itemkey)
            $ItemData     = ([System.Text.Encoding]::Unicode.GetString($m.Itemdata))  #-replace ('[^x20-x7e]+','')
                        
            try {$xmlitem = [xml]($ItemData.TrimEnd([char]0))} catch {} 
            
            # Manual decoding of SYSTEMTIME 
            $systemtime = $LastModified -split '(....)' | ? { $_ }
            $st = foreach($s in $systemtime){$s = $s -split '(..)' | ? { $_ };[array]::reverse($s);$s}
            $year = [Convert]::ToInt32($st[0]+$st[1],16)
            $month= [Convert]::ToInt32($st[2]+$st[3],16)
            $dayofweek = [Convert]::ToInt32($st[4]+$st[5],16)
            $day = [Convert]::ToInt32($st[6]+$st[7],16)
            $Hour = [Convert]::ToInt32($st[8]+$st[9],16)
            $Minutes = [Convert]::ToInt32($st[10]+$st[11],16)
            $Seconds = [Convert]::ToInt32($st[12]+$st[13],16)
            $millisec = [Convert]::ToInt32($st[14]+$st[15],16)
            
            [PSCustomObject]@{            
                        
                        "LastModified (UTC)" = Get-Date ("$($dow.($dayofweek)) $($year)-$($month)-$($day) $($Hour):$($Minutes):$($Seconds).$($millisec)")-f o #UTC
                        Itemkey              = $Itemkey
                        ServiceName          = $xmlitem.Metadata.ServiceName
                        LocalizedServiceName = $xmlitem.Metadata.LocalizedServiceName
                        DocOwnerID           = $xmlitem.Metadata.DocOwnerID
                        FriendlyPath         = $xmlitem.Metadata.FriendlyPath
                        DocTitle             = "$($xmlitem.Metadata.DocTitle).$($xmlitem.Metadata.DocExtension)"
                        FileSizeInBytes      = $xmlitem.Metadata.FileSizeInBytes
                        StorageHost          = $xmlitem.Metadata.StorageHost
                        ResourceId           = $xmlitem.Metadata.ResourceId
                        LastUpdateDate       = if(!$xmlitem.Metadata.LastUpdatedDate){}else{Get-Date ([DateTime]::FromFileTime($xmlitem.Metadata.LastUpdatedDate)) -f o}
                        #ItemData            = $ItemData #Left out for screen economy
                        SortKey              = $SortKey
                        Path                 =  $m.pspath.trimstart("Microsoft.PowerShell.Core\Registry::")
                        }
            }

}
# GUI output of Metadata 
$Metadata|Out-GridView -Title "MS Roaming Metadata - $($File) - Entries found: $($c)"  -PassThru

# Saving the decoded data to a csv
if($Metadata.count -ge1){$snow = Get-Date -Format FileDateTimeUniversal
Write-Host "Saving Table 'MasterFile' to (csv): 'Metadata-$($snow).txt' in $env:TEMP`n" -f Yellow
$Metadata|Export-Csv -NoTypeInformation -Encoding UTF8 -Path "$($env:TEMP)\Metadata-$($snow).txt"
Invoke-Item $env:TEMP


# Unload mounted NTUset.dat
try{
[gc]::Collect();
reg unload HKEY_LOCAL_MACHINE\Temp} 
catch{
Write-Warning "!"
Write-Host "Please copy/paste & run the following commands :" -f white 
write-host "[gc]::Collect()`nreg unload HKEY_LOCAL_MACHINE\Temp" -f white -b red
Write-Host "To unload $($File) from the registry." -f white 
}



