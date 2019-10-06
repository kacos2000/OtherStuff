#Requires -RunAsAdministrator
$ErrorActionPreference = 'Stop'

# References:
# https://ad-pdf.s3.amazonaws.com/Microsoft_Office_2007-2010_Registry_ArtifactsFINAL.pdf
# https://df-stream.com/category/microsoft-office-forensics/

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
Catch{Write-warning "(OfficeMRU.ps1):" ; Write-Host "User Cancelled" -f White; exit}

#Load NTUser.dat to temp key in registry
reg load HKEY_LOCAL_MACHINE\Temp $File

try{Test-Path "HKLM:\Temp\Software\Microsoft\office\" |Out-Null
    $MRU = Get-ChildItem "HKLM:\Temp\Software\Microsoft\Office\*" -recurse -ea SilentlyContinue| 
    where { $_.Name -like "*File MRU" -or $_.Name -like "*Place MRU" -or $_.Name -like "*Document *"} 
    [string]::IsNullOrEmpty($MRU)}

Catch{
	Write-Host -ForegroundColor Yellow "The selectd $($File) does not have the" 
	Write-Host -ForegroundColor Yellow "'Software\Microsoft\office\' registry key."
    [gc]::Collect()
    [GC]::WaitForPendingFinalizers()
	reg unload HKEY_LOCAL_MACHINE\Temp}
Write-Host -ForegroundColor Green "$($File) loaded OK"

#Get The MRU List
$MRUresults=@{}
$MRUresults = foreach ($Item in ($MRU)){
              if ((![string]::IsNullOrEmpty($Item.Name) -or ![string]::IsNullOrEmpty($Item.Property))){
                       $Key  =  $item.name -replace ("HKEY_LOCAL_MACHINE","HKLM:")  # Key Path
              
              # Collect Word Recent Documents:  
              if($Item.Property -contains "Datetime"){
                $FKey       =  $item.name -replace ("HKEY_LOCAL_MACHINE","HKLM:")  # Key Path
                $FName  = (Get-ItemProperty -path($item -replace ("HKEY_LOCAL_MACHINE","HKLM:")))."File Path"
                $TStamp = (Get-ItemProperty -path($item -replace ("HKEY_LOCAL_MACHINE","HKLM:"))).Datetime
                $Fpos   = (Get-Item -path($item -replace ("HKEY_LOCAL_MACHINE","HKLM:"))).PSChildname
                
                        [PSCustomObject]@{ 
            
                        TimeStamp        = Get-Date $TStamp -f o 
                        File             = $FName
                        Nr               = ""
                        Key_Order        = $Fpos
                        Key              = $FKey.trimstart("HKLM:\Temp\") 
                        }
                } 

              # Collect File & Place MRU entries:
              elseif($item.Property -match 'Item *'){
                        $List =  Get-Item ($item -replace ("HKEY_LOCAL_MACHINE","HKLM:"))| select -Expand property | foreach {
                        $Order = $_
                        $Filename = (Get-ItemProperty -Path ($item.name -replace ("HKEY_LOCAL_MACHINE","HKLM:")) -Name $_).$_ 
                               
                        [PSCustomObject]@{ 
                               FileName = $Filename
                               Order    = $Order
                             }
                         }
                    foreach($l in $list){
                        $a,$File = if($l.FileName -like ("*F0000*")){$l.FileName.split('*')}else{"",$l.FileName}
                        $b,$c,$d = $a.split(']')  # Typical format looks like [F00000000][T01D28DD2845B9A10][O00000000], so it's split to 3 parts
                        $TimeStamp = $c -replace '.*T',''
                        $TimeStamp = $TimeStamp.replace("][O00000000]","")

                        [PSCustomObject]@{ 
            
                        TimeStamp        = if(!$TimeStamp){}else{Get-Date ([DateTime]::FromFileTime([Convert]::ToInt64($TimeStamp, 16))) -f o}  
                        File             = $File
                        Nr               = if([Int]($b.TrimStart("[F")) -gt 0){$b.TrimStart("[F")}else{} # Show only of different than 0000000
                        Key_Order        = $l.order
                        Key              = $Key.trimstart("HKLM:\Temp\") 
                        
                            }
                        }
                    }
                }   
            }
# GUI output
$MRUresults|Out-GridView -title "MS Office Most Recently Used Files/Folders ($($MRUresults.Count))" -PassThru 

# Saving output to a csv
if($MRUresults.count -ge1){$snow = Get-Date -Format FileDateTimeUniversal
Write-Host "Saving MRUresults to 'MasterFile' to (csv): 'OfficeMRU-$($snow).txt' in $env:TEMP`n" -f Yellow
$MRUresults|Export-Csv -NoTypeInformation -Encoding UTF8 -Path "$($env:TEMP)\OfficeMRU-$($snow).txt" 
Invoke-Item $env:TEMP}

# Unload NTUser.dat
try{
Write-host "`nAllocated Memory for this Thread: " -nonewline -f cyan;[gc]::GetAllocatedBytesForCurrentThread() 
[gc]::Collect()
[GC]::WaitForPendingFinalizers()
$MRU.Handle.Close()
reg unload HKEY_LOCAL_MACHINE\Temp # Unload mounted NTUset.dat
} 
catch{
Write-Warning "!"
Write-Host "Please copy/paste & run the following commands :" -f white 
write-host "[gc]::Collect()`nreg unload HKEY_LOCAL_MACHINE\Temp" -f white -b red
Write-Host "To unload $($File) from the registry." -f white 
}
