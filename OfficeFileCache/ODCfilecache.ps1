# ODCfilecache.ps1
# Gets information from MS Office 'OfficeFileCache'folder files:
#       *  CentralTable.accdb database
#       *  FSF files
#       *  FSD Files
#       *  and if ArsenalRecon.com 's ODCrecon64.exe is available extract FSD files
#
# 2019/10 - Costas Katsavounidis 
#

# Check & if needed install module PSWriteHTML
if (Get-Module -ListAvailable -Name PSWriteHTML) {
    Write-Host "$((Get-Module -ListAvailable -Name PSWriteHTML).name) Module exists"
} 
else {
    Write-Host "'PSWriteHTML' Module does not exist - will try to install"
    Install-Module PSWriteHTML -Force
}

$ErrorActionPreference = 'Stop'
# Download Microsoft Access Database Engine 2016 Redistributable 
# from https://www.microsoft.com/en-us/download/details.aspx?id=54920
# and install via cmd terminal with the "/quiet" switch.
# ---> For use with 64-bit PowerShell:  <-----
# ---> AccessDatabaseEngine_X64.exe /quiet  <-----


if(Get-OdbcDriver "Microsoft Access Driver (*.mdb, *.accdb)" -Platform '64-bit'){Get-OdbcDriver "Microsoft Access Driver (*.mdb, *.accdb)" -Platform '64-bit'} 
else{ 
Add-Type -AssemblyName System.Windows.Forms
$msgBoxInput = [System.Windows.Forms.MessageBox]::Show('Would you like to Download and install the x64 Microsoft Access Database Engine 2016 Redistributable?

Yes will open your browser to the download page. 
Please use "AccessDatabaseEngine_X64.exe /quiet" from an elevated cmd window to install.','MS Access Database Engine missing','YesNo','Exclamation','Button1')

switch  ($msgBoxInput) {
'Yes' {Start-Process "https://www.microsoft.com/en-us/download/details.aspx?id=54920"; EXIT}
'No'  {Write-warning "(OUCcentraltable.ps1):" ; Write-Host "User Cancelled" -f White; EXIT}
    }
}

# Expected result:
# Name      : Microsoft Access Driver (*.mdb, *.accdb)
# Platform  : 64-bit
# Attribute : {Driver, APILevel, FileExtns, FileUsage...}


# Save Console Output
$snow = Get-Date -Format FileDateTimeUniversal
$sn=Get-Date
$dir = "$($env:TEMP)\ODCfilecache-$($snow)"
if(!(Test-Path -Path $dir )){New-Item -ItemType directory -Path $dir|Out-Null
                             Write-Host "'$($dir)' created" -f yellow}
Start-Transcript -path "$($dir)\PSConsole.txt" -append -IncludeInvocationHeader

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
# Open second Window to select ODCRecon executable.
$ODCpath = Get-FileName -initialDirectory $Env:userprofile -Filter "ODCRecon64.* (*.exe)|*.exe" -Title "Select Arsenal Recon's OSDrecon64.exe"



Try{write-host "Selected: " (Get-Item $Filepath)|out-null}
Catch{Write-warning "(ODCfilecache.ps1):" ; Write-Host "User Cancelled" -f White; exit}
 
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


#Get FSF Information
$fsf_files = Get-ChildItem ($filepath.trimEnd("CentralTable.accdb")) -Filter *.fsf
if(!!$fsf_files){
write-host "$($fsf_files.count) FSF files found" -f White
$output = @{}
$output = if($fsf_files.count -ge 1){
            foreach ($file in $fsf_files) {
              [PSCustomObject]@{
                "FSF Name"          = $file.Name
                "FSD Name"          = ((Get-content -path $file.FullName -Encoding Ascii).trimend(05).SubString(21)) -replace ('[\x00]', '') 
                "FSF Lastwritetime" = get-date $file.Lastwritetime -f o
                }
            }
        }
# Display GUI with FSF Information
# $output|Out-GridView -Title "FSF Information -> Number of FSF Files found ($($fsf_files.count))" -PassThru

# Save output to CSV
if($output.count -ge1){
Write-Host "Saving FSF Information to 'FSF List.txt' in $dir" -f White
$output|Export-Csv -Delimiter "|" -Encoding UTF8 -Path "$($dir)\FSF List.txt" -NoTypeInformation}
}
else{Write-warning "(ODCfilecache.ps1):" ; Write-Host "No FSF Files in Folder" -f White}

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
                        Corresponding_FSD = if(!$output){} else {foreach($ci in $output){if($ci."fsf name" -match $f.FileEntryFileID.Guid.ToUpper()){$ci."fsd name"}
                                                    else{}}} #From FSF Information 
                        "SubcacheID (GUID)" = $f.SubcacheID.Guid.ToUpper()
                        DocumentLastModifiedTime = if($DocLastMod-gt 0){Get-Date ([DateTime]::FromFileTime($DocLastMod)) -Format o}else{}
                        DocumentLastAccessedTime = if($DocLastAcc-gt 0){Get-Date ([DateTime]::FromFileTime($DocLastAcc)) -Format o}else{}
                        Filename = Split-Path ([uri]::UnescapeDataString($f.DisplayUrl.ToString())) -Leaf
                        DisplayUrl = [uri]::UnescapeDataString($f.DisplayUrl.ToString()) #converted web strings for easier reading
                        DocumentUserTypedUrl = [uri]::UnescapeDataString($f.DocumentUserTypedUrl)
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
$MasterFile|Out-HtmlView  -Title "MasterFile table of $($filepath) - $($counter) entries" -FilePath "$($dir)\Masterfile.html" -Style display
$conn.Close()

# Saving data to file(s) 
"Database:`n'$($filepath)'`n`n"|Out-File -FilePath "$($dir)\CentralTable Data.txt"

ForEach ($table in $tables)
{
    if($table -eq "Masterfile")
    {
    # Saving the decoded data from the Masterfile table to a csv
    Write-Host "Saving Table 'MasterFile'" -f Yellow
    $MasterFile| Export-Csv -Delimiter "|" -NoTypeInformation -Encoding UTF8 -Path "$($dir)\MasterFile.txt"
    }
    else{
    # Saving the other tables to a txt file
    Write-Host "Saving Table '$($table)'" -f Cyan
    "********** Table $($table) **********"|Out-File  -Append -FilePath "$($dir)\CentralTable Data.txt"
    $results[$table] |Out-File  -Append -FilePath "$($dir)\CentralTable Data.txt"
    }
}

# Parsing FSD Files for Information
$FSDpath = ($filepath.trimEnd("CentralTable.accdb"))
try{
$FSD_files = Get-ChildItem ($filepath.trimEnd("CentralTable.accdb")) -Filter *.FSD
$fsdc = $FSD_files.count
if($fsdc -ge 1){
Write-Host "$($fsdc) FSD Files found" -f White

$fsdoutput = @{}
$fsdoutput = if($fsd_files.count -ge 1){foreach ($fsd in $fsd_files) {

            if($fsd.name -ne "FSD-CNRY.FSD"){
            
            $StreamReader = $FSDcontent=$Stream=$urloffset=$Sfsd=$url=$fsd_url=$off=$urldec=$guid=$null

            # Read each FSD
            $path         = $fsd.FullName
            $Stream       = New-Object IO.FileStream -ArgumentList (Resolve-Path $Path), 'Open', 'Read' 
            $encoding     = [System.Text.Encoding]::GetEncoding(28591) 
            $StreamReader = New-Object IO.StreamReader -ArgumentList $Stream, $Encoding 
            $FSDcontent   = $StreamReader.ReadToEnd()
            $StreamReader.Close() 
            $Stream.Close()
            
            # FSD Size
            $Sfsd  = $FSDcontent.substring(172,4) # 0x00AC
            $sza   = [System.Text.Encoding]::getencoding(28591).GetBytes($sfsd)
            [array]::reverse($sza)
            $szb   = [System.BitConverter]::ToString($sza) -replace '-',''
            $fsize = [Convert]::TouInt64($szb,16)
            
            # Find the Url             
            [regex]$regex  = "(\x68\x00\x74\x00\x74\x00\x70\x00\x73\x00\x3A\x00)" # "https"
            # https://regex101.com/
                       
            # url offset
            if([string]::IsNullOrEmpty($regex.Matches($FSDcontent).value)){
            $name=$ur=$urloffset=$FSF_id="-"
            }  else  {
            $fsd_url = $regex.Matches($FSDcontent).groups[1].value
            $offurl = [Int64]($regex.Matches($FSDcontent)[0].index)
            $urloffset = "0x00$("{0:X}" -f $offurl)"
                                 
            #Url-length
            $h1=$h2=$offs=$url_length=$null
            $offS = $regex.Matches($FSDcontent)[0].index -1 #if > FF -> 2byte LE (/2)
            $url_length = if([int][char]$FSDcontent.substring($offS,1) -le 15)
            {$h =$FSDcontent.substring($offS-1,2)
             $h1 =[System.Text.Encoding]::getencoding(28591).GetBytes($h)
             [array]::reverse($h1)
             $h2 = [System.BitConverter]::ToString($h1) -replace '-',''
             ([Convert]::ToInt32($h2,16))/2
            }
            else{[int][char]$FSDcontent.substring($offS,1)}
            
            #url
            $url = $FSDcontent.substring($offurl,$url_length -1)
            $r   = [System.Text.Encoding]::getencoding(28591).GetBytes($url)
            $ur  = [System.Text.Encoding]::Unicode.GetString($r)
            $name = Split-Path $ur -Leaf

            ##Guid
            if($url_length -in (15..255))
                {$G = [System.Text.Encoding]::getencoding(28591).GetBytes($FSDcontent.substring($offurl -17,16))}
                else
                {$G = [System.Text.Encoding]::getencoding(28591).GetBytes($FSDcontent.substring($offurl -18,16))}
            $Wq = [System.BitConverter]::ToString($G) #-replace '-00','' #-replace "-",''
            $G1 = $Wq.Substring(0,12).split('-')
            [array]::Reverse($G1)
            $Guid += $G1 -join ''
            $G2 = $Wq.Substring(12,5).split('-')
            [array]::Reverse($G2)
            $Guid += $G2 -join ''
            $G3 = $Wq.Substring(18,5).split('-')
            [array]::Reverse($G3)
            $Guid += $G3 -join ''
            $G4 = $Wq.Substring(24,5).split('-')
            $Guid += $G4 -join ''
            $G5 = $Wq.Substring(30).split('-')
            $Guid += $G5 -join ''
            $FSF_id = [System.Guid]::Parse($Guid).guid
            }
         [PSCustomObject]@{
            "FSD FileName"      = $fsd.Name
            "FSF Guid"          = "{$($FSF_id.ToUpper())}"
            "Filename"          = [uri]::UnescapeDataString($name)
            "FSD Size (Disk)"   = $fsd.length
            "FSD Size (Dile)"   = $fsize
            "F/D"               = if($fsize -lt $fsd.length){"F < D"}elseif($fsize -eq $fsd.length){"F = D"}else{"F > D"}
            "FSD Lastwritetime" = get-date $fsd.Lastwritetime -f o # Examiner time + timezone
            "FSD url"           = [uri]::UnescapeDataString($ur)
            "FSD #MD5"          = (Get-FileHash -Algorithm MD5 $fsd.fullname).hash
            }
          [gc]::Collect()
        }
    }
}
# popup display of FSD Information
$fsdoutput|Out-GridView -title "FSD information - ($($fsd_files.count)) FSD files found - [$($output.Filename.Count) results]" -PassThru

# Saving FSD info to a csv
Write-Host "Saving FSD Information to 'FSD-List.txt' in $dir" -f White
$fsdoutput| Export-Csv -Delimiter "|" -Encoding UTF8 -Path "$($dir)\FSD List.txt" -NoTypeInformation 
}

# If https://arsenalrecon.com/ - OSDrecon64.exe is selected, runs it for a Summary Report & FSD extraction
try{$odc_dir = "$($dir)\ODCrecon"
if(!(Test-Path -Path $odc_dir))
       {write-host "ODCrecon output will be saved in '$($odc_dir)'" -f Yellow
        New-Item -ItemType directory -Path $odc_dir|Out-Null
        Write-Host "'$($odc_dir)' created" -f yellow

#ODCrecon Parameters:
$exe = $ODCpath 
$input = $FSDpath
$outpath = $odc_dir
$mode = (0,1) # can be 0 or 1. 0 is for printing some basic document info to a summary. 1 is for document extraction.
$ZipSig = 0   # can be 0 or 1. set value to 1 to tweak the identification of embedded ooxml documents. default is 0. 
$Force = 0    # can be 0 or 1. when an FSD is missing the file header signature it is assumed invalid 
if(test-path $ODCpath){foreach($p in $mode){& $exe /input:$input /OutputPath:$outpath /Mode:$p /ZipSig:$ZipSig /Force:$Force}
    }} 
}
catch{Write-warning "(ODCfilecache.ps1): Missing ODCrecon folder"}
}
catch{Write-warning "(ODCfilecache.ps1): No .FSD Files in Folder"}

# Stop Console Output
Stop-Transcript
$tn = NEW-TIMESPAN –Start $sn 
$msgBoxInput = [System.Windows.Forms.MessageBox]::Show("
`n$(Get-date -f F)
Total Processing time: $Tn`nOutput was saved in: $dir
`nThank you for playing :)",'ODCfilecache.ps1','OK','Information','Button1')
switch  ($msgBoxInput){'OK' {Invoke-Item $dir; EXIT}}
# The_End
