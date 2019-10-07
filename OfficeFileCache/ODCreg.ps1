#Requires -RunAsAdministrator
$ErrorActionPreference = 'Stop'
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

#Load NTUser.dat to temp key in registry
reg load HKEY_LOCAL_MACHINE\Temp $File

# Metadata -> usually found in the user's NTUser.dat at
# "SOFTWARE\Microsoft\Office\15.0\Common\Roaming\Identities\xxxxxxxxx_LiveId\Settings\1133\{00000000-0000-0000-0000-000000000000}\ListItems\*\*\"
# "SOFTWARE\Microsoft\Office\16.0\Common\Roaming\Identities\xxxxxxxxx_LiveId\Settings\1110\{00000000-0000-0000-0000-000000000000}\ListItems\*\*\"

try{Test-Path "HKLM:\Temp\Software\Microsoft\office\" |Out-Null
$path = Get-ChildItem -Path "HKLM:\Temp\Software\Microsoft\office\*\Common\Roaming\Identities\*\Settings\*" -Include "Listitems" -Recurse -Exclude "Explorer"|
Where-Object {!$_.ItemData -and !$_.ItemKey -and !$_.LastModified -and !$_.SortKey} |Select-Object 
}

Catch{
	Write-Host -f Yellow "The selectd $($File) does not have the" 
	Write-Host -f Yellow "'Software\Microsoft\office\' registry key."
    [gc]::Collect()
    [GC]::WaitForPendingFinalizers()
	reg unload HKEY_LOCAL_MACHINE\Temp
    EXIT 
    }
Write-Host -f Green "$($File) loaded OK"

$Metadata =  @{}

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

# Looking for Metadata
$x = foreach($p in $path){$p -replace ("HKEY_LOCAL_MACHINE","HKLM:")}
$mpt = foreach ($u in $x){ (get-item  -path "$($u)\*\*\" |
 Where-Object {!$_.ItemData -and !$_.ItemKey -and !$_.LastModified -and !$_.SortKey}) -replace ("HKEY_LOCAL_MACHINE","HKLM:") }
$meta = @(foreach($m in $mpt){Get-ItemProperty -path $m})
if(!$path){[gc]::Collect()
Write-Host "There are no entries in $($File)" -f Red
reg unload HKEY_LOCAL_MACHINE\Temp
EXIT}
else{$path.Handle.Close()}


# Collect Data                 
$Metadata = foreach($m in $meta){
            
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
                        
                        "LastModified (UTC)"  = Get-Date ("$($dow.($dayofweek)) $($year)-$($month)-$($day) $($Hour):$($Minutes):$($Seconds).$($millisec)") -f o #UTC
                        Itemkey               = $Itemkey
                        ServiceName           = $xmlitem.Metadata.ServiceName
                        LocalizedServiceName  = $xmlitem.Metadata.LocalizedServiceName
                        DocOwnerID            = $xmlitem.Metadata.DocOwnerID
                        FriendlyPath          = $xmlitem.Metadata.FriendlyPath
                        DocTitle              = "$($xmlitem.Metadata.DocTitle).$($xmlitem.Metadata.DocExtension)"
                        FileSizeInBytes       = $xmlitem.Metadata.FileSizeInBytes
                        StorageHost           = $xmlitem.Metadata.StorageHost
                        ResourceId            = $xmlitem.Metadata.ResourceId
                        LastUpdateDate        = if(!$xmlitem.Metadata.LastUpdatedDate){}else{Get-Date ([DateTime]::FromFileTime($xmlitem.Metadata.LastUpdatedDate)) -f o}
                        #ItemData             = $ItemData #Left out for screen economy
                        SortKey               = $SortKey
                        "Entry Location"      =  $m.pspath.trimstart("Microsoft.PowerShell.Core\Registry::").replace("HKEY_LOCAL_MACHINE\Temp","")
                        }
            }

}
$path = $null

# GUI output of Metadata 
$Metadata|Out-GridView -Title "MS Roaming Metadata - $($File) - Entries found: $($Metadata.count)"  -PassThru

# Saving the decoded data to a csv
if($Metadata.count -ge1){$snow = Get-Date -Format FileDateTimeUniversal
$dir = "$($env:TEMP)\ODCreg"
if(!(Test-Path -Path $dir )){New-Item -ItemType directory -Path $dir
                             Write-Host "'$($dir)' created" -f yellow}
Write-Host "Saving 'Metadata' to (csv): 'Metadata-$($snow).txt' in $($dir)`n" -f Yellow
$Metadata|Export-Csv -Delimiter "|" -NoTypeInformation -Encoding UTF8 -Path "$($dir)\Metadata-$($snow).txt"
Invoke-Item $dir
}


# Unload mounted NTUset.dat
try{
Write-host "Allocated Memory for this Thread: " -nonewline -f cyan;[gc]::GetAllocatedBytesForCurrentThread() 
[gc]::Collect()
[GC]::WaitForPendingFinalizers()

reg unload HKEY_LOCAL_MACHINE\Temp 
} 
catch{
Write-Warning "!"
Write-Host "Please copy/paste & run the following commands :" -f white 
write-host "[gc]::Collect()`nreg unload HKEY_LOCAL_MACHINE\Temp" -f white -b red
Write-Host "To unload $($File) from the registry." -f white 
}



