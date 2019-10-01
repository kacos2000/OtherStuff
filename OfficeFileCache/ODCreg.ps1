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
Catch{Write-warning "(OUCcentraltable.ps1):" ; Write-Host "User Cancelled" -f White; exit}


$ErrorActionPreference = "Stop"
Try{$before = (Get-FileHash $File -Algorithm SHA256).Hash}
Catch{
        Write-Host "(ODCreg.ps1):" -f Yellow -nonewline; Write-Host " User Cancelled" -f White
		[gc]::Collect()		
		reg unload HKEY_LOCAL_MACHINE\Temp 
		exit
} 
write-host "SHA256 Hash of ($File) = " -f magenta -nonewline;write-host "($before)" -f Yellow
#Load NTUser.dat to temp key in registry
reg load HKEY_LOCAL_MACHINE\Temp $File
 


# Looking for Metadata -> usually be found in the user's NTUser.dat at
# "SOFTWARE\Microsoft\Office\15.0\Common\Roaming\Identities\xxxxxxxxx_LiveId\Settings\1133\{00000000-0000-0000-0000-000000000000}\ListItems\"
# "SOFTWARE\Microsoft\Office\16.0\Common\Roaming\Identities\xxxxxxxxx_LiveId\Settings\1110\{00000000-0000-0000-0000-000000000000}\ListItems\"

$ver = $idpath =@{}
try{$Key = (Get-ItemProperty -Path "HKLM:\Temp\Software\")
}
Catch{
	Write-Host -ForegroundColor Yellow "The selectd ($File) does not have the" 
	Write-Host -ForegroundColor Yellow "'Software\' registry key." 
	[gc]::Collect()
    Timeout -T 60		
	reg unload HKEY_LOCAL_MACHINE\Temp 
    exit}
finally{}
Write-Host -ForegroundColor Green "$File loaded OK"
try{$ver = ((Get-ChildItem -Path "HKLM:\Temp\Software\Microsoft\office\") | Select-Object -ExpandProperty PSChildName)}
catch{   Write-warning "(ODCreg.ps1):" -f Yellow -nonewline; Write-Host " Office not installed?" -f White;
        [gc]::Collect()		
	    reg unload HKEY_LOCAL_MACHINE\Temp 
        exit} 

$ipath = ((Get-childItem -Path "HKLM:\Temp\Software\Microsoft\office\").pspath)
$Username = (get-itemproperty $ipath).username

$ver = @(((Get-ChildItem -Path "HKLM:\Temp\Software\Microsoft\office\" -ErrorAction Ignore)| Where-Object {$_.Name -match "\d*\.\d*"}).name -replace ("HKEY_LOCAL_MACHINE","HKLM:")).trimstart("HKLM:\Temp\Software\Microsoft\office\")
$ids = @(foreach($v in $ver) 
        {if(Test-Path "HKLM:\Temp\Software\Microsoft\office\$($v)\Common\Roaming\Identities\")
        {Get-ChildItem "HKLM:\Temp\Software\Microsoft\office\$($v)\Common\Roaming\Identities\"}  
        })
if($ids.count -ge 1){write-host "IDs found:"-f Red; foreach($d in $ids){Write-Host "$($d.name.trimstart("HKEY_LOCAL_MACHINE\Temp"))"-f DarkYellow}}
$idp =  @(foreach($i in $ids.name){if( !(Test-Path "$($i)\Settings\")){get-childitem ($i -replace ("HKEY_LOCAL_MACHINE","HKLM:"))}})
$idp1 = @(foreach($e in $idp.name){get-childitem ($e -replace ("HKEY_LOCAL_MACHINE","HKLM:"))})
$idp2 = @(foreach($g in $idp1.name){if( !(Test-Path "$($g)\{00000000-0000-0000-0000-000000000000}\ListItems\")){get-childitem ($g -replace ("HKEY_LOCAL_MACHINE","HKLM:"))}})
$idp3 = @(foreach($h in $idp2.name){if( !(Test-Path "$($h)")){get-childitem ($h -replace ("HKEY_LOCAL_MACHINE","HKLM:")) -recurse }})
$pdp4 = @(get-childitem ($idp3 -replace ("HKEY_LOCAL_MACHINE","HKLM:"))|Where-Object {!$_.ItemData -and !$_.ItemKey -and !$_.LastModified -and !$_.SortKey})
$LastModified =  @{}
$Itemkey =  @{}
$ItemData =  @{}
$SortKey =  @{}
$LastOperation =  @{}
$Metadata =  @{}
$metap = Get-ItemProperty ($pdp4 -replace ("HKEY_LOCAL_MACHINE","HKLM:"))
$c=$null
$year = @{}
$month= @{}
$dayofweek = @{}
$day = @{}
$Hour = @{}
$Minutes = @{}
$Seconds = @{}
$millisec = @{}
$dow = @{
0 = "Sunday"
1 = "MOnday"
2 = "Tuesday"
3 = "Wednesday"
4 = "Thursday"
5 = "Friday"
6 = "Saturday"
}
[gc]::Collect()	

$Metadata = foreach($m in $metap){$c++
            
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
                        
                        LastModified = Get-Date ("$($dow.($dayofweek)) $($year)-$($month)-$($day) $($Hour):$($Minutes):$($Seconds).$($millisec)")-f o #UTC
                        Itemkey =       $Itemkey
                        ServiceName =   $xmlitem.Metadata.ServiceName
                        LocalizedServiceName = $xmlitem.Metadata.LocalizedServiceName
                        DocOwnerID =    $xmlitem.Metadata.DocOwnerID
                        FriendlyPath =  $xmlitem.Metadata.FriendlyPath
                        DocTitle =      "$($xmlitem.Metadata.DocTitle).$($xmlitem.Metadata.DocExtension)"
                        FileSizeInBytes=$xmlitem.Metadata.FileSizeInBytes
                        StorageHost =   $xmlitem.Metadata.StorageHost
                        ResourceId  =   $xmlitem.Metadata.ResourceId
                        LastUpdateDate= if(!$xmlitem.Metadata.LastUpdatedDate){}else{Get-Date ([DateTime]::FromFileTime($xmlitem.Metadata.LastUpdatedDate)) -f o}
                        #ItemData =      $ItemData #Left out for screen economy
                        SortKey =       $SortKey
                        Path =          $m.pspath.trimstart("Microsoft.PowerShell.Core\Registry::")
                        }
            }

}
[gc]::Collect()
# GUI output of Metadata 
$Metadata|Out-GridView -Title "MS Roaming Metadata - $($File) - Entries found: $($c)"  -PassThru

# Saving the decoded data to a csv
if($Metadata.count -ge1){$snow = Get-Date -Format FileDateTimeUniversal
Write-Host "Saving Table 'MasterFile' to (csv): 'Metadata-$($snow).txt' in $env:TEMP" -f Yellow
$Metadata|Export-Csv -NoTypeInformation -Encoding UTF8 -Path "$($env:TEMP)\Metadata-$($snow).txt"
Invoke-Item $env:TEMP
}
[gc]::Collect()
try{reg unload HKEY_LOCAL_MACHINE\Temp} 
catch{
Write-Warning "There seems to be an issue unloading $($File)."
Write-Host "Please open a new Powershell terminal Window, copy/paste" -NoNewline;write-host "reg unload HKEY_LOCAL_MACHINE\Temp" -ForegroundColor whie -BackgroundColor DarkBlue
Write-Host "close this Powershell terminal and run the above command in the other terminal Window"
}

