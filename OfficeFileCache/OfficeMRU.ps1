#Requires -RunAsAdministrator
$ErrorActionPreference = 'Stop'


# Ref: https://ad-pdf.s3.amazonaws.com/Microsoft_Office_2007-2010_Registry_ArtifactsFINAL.pdf

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

try{Test-Path "HKLM:\Temp\Software\Microsoft\office\" |Out-Null
$MRU = Get-ChildItem "HKLM:\Temp\Software\Microsoft\Office\*" -recurse -ea SilentlyContinue| 
    where { $_.Name -like "*File MRU" -or $_.Name -like "*Place MRU" } 
}

Catch{
	Write-Host -ForegroundColor Yellow "The selectd $($File) does not have the" 
	Write-Host -ForegroundColor Yellow "'Software\Microsoft\office\' registry key."
    [gc]::Collect()
    [GC]::WaitForPendingFinalizers()
	reg unload HKEY_LOCAL_MACHINE\Temp
    EXIT 
    }
Write-Host -ForegroundColor Green "$($File) loaded OK"

# Get The MRU List
$MRUresults=@{}
$MRUresults = foreach ($Item in ($MRU)){
              if (![string]::IsNullOrEmpty($Item.Property)){
                        
                        # Key LastModified Timestamp & Path
                        $KeyTime = if(test-path !"$($item.name -replace ("HKEY_LOCAL_MACHINE","HKLM:"))\change\"){} else
                                   {get-itemproperty -path "$($item.name -replace ("HKEY_LOCAL_MACHINE","HKLM:"))\change"|Select-Object -ExpandProperty ChangeId}
                        $Key     = $item.name -replace ("HKEY_LOCAL_MACHINE","HKLM:")
            
                        #MRU
                        $List =  Get-Item ($item -replace ("HKEY_LOCAL_MACHINE","HKLM:"))| select -Expand property | foreach {
                                 $Order = $_
                                 $Filename = (Get-ItemProperty -Path ($item.name -replace ("HKEY_LOCAL_MACHINE","HKLM:")) -Name $_).$_ 
                               
                                 [PSCustomObject]@{ 
                                        FileName = $Filename
                                        Order   = $Order
                                    }
                                }

                foreach($l in $list){
                        $a,$File = $l.FileName.split('*')
                        $TimeStamp = $a -replace '.*T',''
                        $TimeStamp = $TimeStamp.replace("][O00000000]","")

                        [PSCustomObject]@{ 
            
                        TimeStamp        = [DateTime]::FromFileTime([Convert]::ToInt64($TimeStamp, 16))  
                        File             = $File
                        Key_Order        = $l.order
                        Key              = $Key.trimstart("HKLM:\Temp\") 
                                  
                            }
                        }
}
}
# GUI output
$MRUresults|Out-GridView -title "MS Office Most Recently Used Files/Folders" -PassThru

# Saving output to a csv
$MRUresults|Export-Csv -NoTypeInformation -Encoding UTF8 -Path "$($env:TEMP)\OfficeMRU.txt"
Invoke-Item $env:TEMP


if(!$MRU){[gc]::Collect()
Write-Host "There are no entries in $($File)" -f Red
reg unload HKEY_LOCAL_MACHINE\Temp
EXIT}
else{$MRU.Handle.Close()}


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
