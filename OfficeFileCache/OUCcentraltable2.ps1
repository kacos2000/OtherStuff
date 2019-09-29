# Get-ComputerInfo ## If needed
$ErrorActionPreference = 'Stop'
# Download Microsoft Access Database Engine 2016 Redistributable 
# from https://www.microsoft.com/en-us/download/details.aspx?id=54920
# and install via cmd terminal with the "/quiet" switch.
# ---> For use with 64-bit PowerShell:  <-----
# ---> AccessDatabaseEngine_X64.exe /quiet  <-----

try{Get-OdbcDriver "Microsoft Access Driver (*.mdb, *.accdb)"}
catch{

$msgBoxInput = [System.Windows.MessageBox]::Show('Would you like to Download and install the x64 
Microsoft Access Database Engine 2016 Redistributable?
If yes, please use "AccessDatabaseEngine_X64.exe /quiet" from an
elevated cmd window to install.','Access Database Engine','YesNo','Error')
switch  ($msgBoxInput) {
'Yes' {Start-Process "https://www.microsoft.com/en-us/download/details.aspx?id=54920"; exit}
'No'  {Write-warning "(OUCcentraltable.ps1):" ; Write-Host "User Cancelled" -f White; exit}
    }
}

#
# Expected result:
# Name      : Microsoft Access Driver (*.mdb, *.accdb)
# Platform  : 64-bit
# Attribute : {Driver, APILevel, FileExtns, FileUsage...}

Function Get-FileName($initialDirectory, $Title ,$Filter)
{  
[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") |Out-Null
		$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
		$OpenFileDialog.Title = $Title
		$OpenFileDialog.initialDirectory = $initialDirectory
        $OpenFileDialog.Filter = $filter
		$OpenFileDialog.ShowDialog() | Out-Null
		$OpenFileDialog.ShowReadOnly = $true
		$OpenFileDialog.filename
		$OpenFileDialog.ShowHelp = $false
} #end function Get-FileName
$DesktopPath =  [Environment]::GetFolderPath("LocalApplicationData ")+"\Microsoft\Office"
$filepath = Get-FileName -initialDirectory $DesktopPath -Filter "CentralTable (*.accdb)|*.accdb" -Title 'Select CentralTable.accdb file to parse'
Try{write-host "Selected: " (Get-Item $Filepath)|out-null}
Catch{Write-warning "(OUCcentraltable.ps1):" ; Write-Host "User Cancelled" -f White; exit}
 
$tables = @( 
        "CacheProperties", 
        "EventClients",
        "EventMetaInfo"
        "IncomingEvents",
        "MasterFile",
        "OutgoingEvents",
        "ServerTarget",
        "Subcache" 
        )

# Metadata can also be found in the user's NTUser.dat at
# "SOFTWARE\Microsoft\Office\15.0\Common\Roaming\Identities\xxxxxxxxx_LiveId\Settings\1133\{00000000-0000-0000-0000-000000000000}\ListItems\"
# "SOFTWARE\Microsoft\Office\16.0\Common\Roaming\Identities\xxxxxxxxx_LiveId\Settings\1110\{00000000-0000-0000-0000-000000000000}\ListItems\"
$snow = Get-Date -Format FileDateTimeUniversal
#Get FSF Information
try{$fsf_files = Get-ChildItem ($filepath.trimEnd("CentralTable.accdb")) -Filter *.fsf
$output = @{}
$output = foreach ($file in $fsf_files) {

            
            [PSCustomObject]@{
            "FSF Name" = $file.Name
            "FSD Name" = ((Get-content -path "$($filepath.trimEnd("CentralTable.accdb"))$($file)" -Encoding Ascii).trimend(05).SubString(21)) -replace ('[\x00]', '') 
            "FSF Lastwritetime" = $file.Lastwritetime
                }
            }
# Display GUI with FSF Information
$output|Out-GridView -Title "FSF Information -> Number of FSF Files found ($($fsf_files.count))" -PassThru
# Save output to CSV
Write-Host "Saving FSF Information to 'FSF List - $($snow).txt' in $env:TEMP" -f White
$output|Export-Csv -Encoding UTF8 -Path "$($env:TEMP)\FSF List - $($snow).txt" -NoTypeInformation
}
Catch{Write-warning "(OUCcentraltable.ps1):" ; Write-Host "No FSF Files in Folder" -f White}



 
# Parsing the Database
$results = @{}
$Masterfile = @{}
$Conn = 
$conn = New-Object System.Data.Odbc.OdbcConnection
$conn.ConnectionString = "Driver={Microsoft Access Driver (*.mdb, *.accdb)};Dbq=$filepath"
$conn.Open()
 
$cmd = New-Object System.Data.Odbc.OdbcCommand
$cmd.Connection = $conn


ForEach ($table in $tables)
{
    Write-Host "Reading $table" $MatchCount -f Yellow
    $cmd.CommandText = "SELECT * FROM $table"
    $reader = $cmd.ExecuteReader()
    $results[$table] = New-Object System.Data.DataTable
    $results[$table].Load($reader)
    }

# Decoding information from the Masterfile table
$Masterfile = ForEach ($f in $results.Masterfile){
                
                # Convertind date data to little Endian
                [array]::reverse($f.FileStoreFileSize)
                [array]::reverse($f.DocumentLastModifiedTime)
                [array]::reverse($f.DocumentLastAccessedTime)
                #[array]::reverse($f.DocumentCreateTime) 
                #[array]::reverse($f.DocumentLastModifiedTimeOnServer)
                if(-not ([string]::IsNullOrEmpty($f.SavedToServer))){[array]::reverse($f.SavedToServer)}else{}
                [array]::reverse($f.DataLastUploadTime)
                [array]::reverse($f.DataLastSuccessfulUploadTime)
                [array]::reverse($f.DataLastDownloadTime)
                [array]::reverse($f.DataLastSuccessfulDownloadTime)
                [array]::reverse($f.MetaLastDownloadTime)
                [array]::reverse($f.MetaLastSuccessfulDownloadTime)
                [array]::reverse($f.EditLastDownloadTime)
                [array]::reverse($f.EditLastSuccessfulDownloadTime)

                # Convert Timestamps to Decimal (Timestamps are stored in UTC in the database
                $DocLastMod = if(-not ([string]::IsNullOrEmpty($f.DocumentLastModifiedTime))){[Convert]::ToUInt64(([System.BitConverter]::ToString($f.DocumentLastModifiedTime) -replace "-",""),16)}else{}
                $DocLastAcc = if(-not ([string]::IsNullOrEmpty($f.DocumentLastAccessedTime))){[Convert]::ToUInt64(([System.BitConverter]::ToString($f.DocumentLastAccessedTime) -replace "-",""),16)}else{}
                $DocSaSe = if(-not ([string]::IsNullOrEmpty($f.SavedToServer))){[Convert]::ToUInt64(([System.BitConverter]::ToString($f.SavedToServer) -replace "-",""),16)}else{}
                $LaUp = if(-not ([string]::IsNullOrEmpty($f.DataLastUploadTime))){[Convert]::ToUInt64(([System.BitConverter]::ToString($f.DataLastUploadTime) -replace "-",""),16)}else{}
                $LaSuUp = if(-not ([string]::IsNullOrEmpty($f.DataLastSuccessfulUploadTime))){[Convert]::ToUInt64(([System.BitConverter]::ToString($f.DataLastSuccessfulUploadTime) -replace "-",""),16)}else{}
                $LaDow = if(-not ([string]::IsNullOrEmpty($f.DataLastDownloadTime))){[Convert]::ToUInt64(([System.BitConverter]::ToString($f.DataLastDownloadTime) -replace "-",""),16)}else{}
                $LaSuDow = if(-not ([string]::IsNullOrEmpty($f.DataLastSuccessfulDownloadTime))){[Convert]::ToUInt64(([System.BitConverter]::ToString($f.DataLastSuccessfulDownloadTime) -replace "-",""),16)}else{}
                $MetaLaDo = if(-not ([string]::IsNullOrEmpty($f.MetaLastDownloadTime))){[Convert]::ToUInt64(([System.BitConverter]::ToString($f.MetaLastDownloadTime) -replace "-",""),16)}else{}
                $MetaLaSuDo = if(-not ([string]::IsNullOrEmpty($f.MetaLastSuccessfulDownloadTime))){[Convert]::ToUInt64(([System.BitConverter]::ToString($f.MetaLastSuccessfulDownloadTime) -replace "-",""),16)}else{}
                $EditLaDo = if(-not ([string]::IsNullOrEmpty($f.EditLastDownloadTime))){[Convert]::ToUInt64(([System.BitConverter]::ToString($f.EditLastDownloadTime) -replace "-",""),16)}else{}
                $EditLaSuDo = if(-not ([string]::IsNullOrEmpty($f.EditLastSuccessfulDownloadTime))){[Convert]::ToUInt64(([System.BitConverter]::ToString($f.EditLastSuccessfulDownloadTime) -replace "-",""),16)}else{}


                # Formating output - Timestamps are converted to examiners local date/time
                [PSCustomObject]@{
                        "FileEntryFileID (GUID)" = $f.FileEntryFileID.Guid.ToUpper()  # FSF dentifier - also stored inside the FSD (before the DisplayURL)
                        "Corresponding FSD" = if(!$output){} else {foreach($ci in $output){if($ci."fsf name" -match $f.FileEntryFileID.Guid.ToUpper()){$ci."fsd name"}
                                                    else{}}} #From FSF Information 
                        "SubcacheID (GUID)" = $f.SubcacheID.Guid.ToUpper()
                        DocumentLastModifiedTime = if($DocLastMod-gt 0){Get-Date ([DateTime]::FromFileTime($DocLastMod)) -Format o}else{}
                        DocumentLastAccessedTime = if($DocLastAcc-gt 0){Get-Date ([DateTime]::FromFileTime($DocLastAcc)) -Format o}else{}
                        DisplayUrl = [uri]::UnescapeDataString($f.DisplayUrl.ToString()) #converted web strings for easier reading
                        DocumentUserTypedUrl = $f.DocumentUserTypedUrl
                        FileStoreFileSize = [Convert]::ToInt64(([System.BitConverter]::ToString($f.FileStoreFileSize) -replace "-",""),16)
                        Username = $f.Username
                        UserLogin = if($f.userlogin -match '^[a-zA-Z0-9]+$' -or $f.userlogin -eq ""){$f.userlogin}elseif($f.userlogin.Length -eq 20 -or $f.userlogin -match "^\-+.*"){"{0:X}" -f [int64]$f.userlogin}else{$f.userlogin}
                        UserEmailAddress = $f.UserEmailAddress
                        UserSipAddress = $f.UserSipAddress
                        SavedToServer = if($DocSaSe-gt 0){Get-Date ([DateTime]::FromFileTime($DocSaSe)) -Format o}else{}
                        DocumentLastModifiedBy = $f.DocumentLastModifiedBy
                        DataLastUploadTime = if($LaUp-gt 0){Get-Date ([DateTime]::FromFileTime($LaUp)) -Format o}else{}
                        DataLastSuccessfulUploadTime = if($LaSuUp-gt 0){Get-Date ([DateTime]::FromFileTime($LaSuUp)) -Format o}else{}
                        DataLastDownloadTime = if($LaDow-gt 0){Get-Date ([DateTime]::FromFileTime($LaDow)) -Format o}else{}
                        DataLastSuccessfulDownloadTime = if($LaSuDow-gt 0){Get-Date ([DateTime]::FromFileTime($LaSuDow)) -Format o}else{}
                        MetaLastDownloadTime = if($MetaLaDo-gt 0){Get-Date ([DateTime]::FromFileTime($MetaLaDo)) -Format o}else{}
                        MetaLastSuccessfulDownloadTime = if($MetaLaSuDo-gt 0){Get-Date ([DateTime]::FromFileTime($MetaLaSuDo)) -Format o}else{}
                        EditLastDownloadTime = if($EditLaDo-gt 0){Get-Date ([DateTime]::FromFileTime($EditLaDo)) -Format o}else{}
                        EditLastSuccessfulDownloadTime = if($EditLaSuDo-gt 0){Get-Date ([DateTime]::FromFileTime($EditLaSuDo)) -Format o}else{}
                                            
            }
}

$counter = $results.MasterFile.FileEntryFileID.Count # Number of entries in the Mastertable

# GUI output of Masterfile table information
$MasterFile|Out-GridView -Title "MasterFile table of $($filepath) - $($counter) entries" -PassThru

$conn.Close()


# Saving data to file(s) 
"Database:`n'$($filepath)'`n`n"|Out-File -FilePath "$($env:TEMP)\CentralTable - $($snow).txt"

ForEach ($table in $tables)
{
    if($table -eq "Masterfile")
    {
    # Saving the decoded data from the Masterfile table to a csv
    Write-Host "Saving Table 'MasterFile' to 'MasterFile - $($snow).csv in $env:TEMP" -f Yellow
    $MasterFile| Export-Csv -NoTypeInformation -Encoding UTF8 -Path "$($env:TEMP)\MasterFile - $($snow).csv"
    }
    else{
    # Saving the other tables to a txt file
    Write-Host "Saving Table '$($table)' to 'CentralTable - $($snow).txt' in $env:TEMP" -f Cyan
    "********** Table $($table) **********"|Out-File  -Append -FilePath "$($env:TEMP)\CentralTable - $($snow).txt"
    $results[$table] |Out-File  -Append -FilePath "$($env:TEMP)\CentralTable - $($snow).txt"
    }
}


# open Temp folder to view saved output files
Invoke-Item $env:TEMP