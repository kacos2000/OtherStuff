# Read $ display the Footer & Header from a VHD file 
# Display the Block Allocation Entry Table (BAT) entries of a Dynamic Disk,
# Optionally extract the data blocks as a Raw Disk image file.
#
# Ref: https://download.microsoft.com/download/f/f/e/ffef50a5-07dd-4cf8-aaa3-442c0673a029/Virtual%20Hard%20Disk%20Format%20Spec_10_18_06.doc
# Ref: https://redcircle.blog/2008/12/01/dynamic-vhd-walkthrough/

Clear-Host
# Show an Open File Dialog 
Function Get-FileName($initialDirectory)
{  
[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") |Out-Null
		$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
		$OpenFileDialog.Title = 'Select a vhd file'
		$OpenFileDialog.initialDirectory = $initialDirectory
		$OpenFileDialog.Filter = "VHD file (*.vhd)|*.vhd|All files (*.*)|*.*"
		$OpenFileDialog.ShowDialog() | Out-Null
		$OpenFileDialog.ShowReadOnly = $true
		$OpenFileDialog.filename
		$OpenFileDialog.ShowHelp = $false
} #end function Get-FileName 

$fPath =  $env:USERPROFILE+"\Desktop\"
$vhd = Get-FileName -initialDirectory $fPath
# get timestamp for data dump file
$snow = Get-Date -Format "dd-MMM-yyyyTHH-mm-ss"
write-host "Selected VHD: " -NoNewline;write-host "$($vhd)`n" -f White
try{

#read file
        # determine the size of the file
        $file_size = (Get-Item $vhd).length
        $Stream = New-Object System.IO.FileStream -ArgumentList $vhd, 'Open', 'Read'
		$Encoding = [System.Text.Encoding]::GetEncoding(28591)
        $BinaryReader  = New-Object System.IO.BinaryReader  -ArgumentList $Stream, $Encoding
        $data = $null
        # Set offset to read the last 512 bytes of the file (Footer)
        $BinaryReader.BaseStream.Position = [UInt64]($file_size-512)
        # Initialize a 512byte buffer 
        $buffer = [System.Byte[]]::new(512)
        # Read offset to the buffer
        [Void]$BinaryReader.Read($buffer,0,512)
        $data = [System.Text.Encoding]::GetEncoding(28591).getstring($buffer)
        $BinaryReader.Close()
		$Stream.Close()
        [gc]::Collect()	
# Start transcript
#Start-Transcript -path "$($env:Temp)\vhdx_$($snow).log" -Append
}
catch{
Write-Host "Oops, something went wrong" -f Red
Exit
}
write-host "`n****  Footer ****`n" -f Yellow

# Cookie
$cookie = $data.Substring(0,8)
write-host "Cookie: " $cookie -f Cyan

# Features
$f = $data.Substring(8,4)
$fb = [System.Text.Encoding]::getencoding(28591).GetBytes($f)
$fh = [System.BitConverter]::ToString($fb) -replace '-',''
$Features = if($fh -match "00000000"){"No features enabled"}
elseif($fh -match "00000001"){"Temporary Disk"}
elseif($fh -match "00000002"){"Reserved"}
write-host "Features: " $features -f Cyan

# File Format version
$ffv = $data.Substring(12,4)
$ffvb = [System.Text.Encoding]::getencoding(28591).GetBytes($ffv)
$fileformatversion = [System.BitConverter]::ToString($ffvb) -replace '-',''
write-host "File Format version: " $fileformatversion -f Cyan

# Data Offset from the beginning of the file, to the next structure
$do = $data.Substring(16,8)
$dob = [System.Text.Encoding]::getencoding(28591).GetBytes($do)
$dataoffset = [System.BitConverter]::ToString($dob) -replace '-',''
if($dataoffset -match "FFFFFFFFFFFFFFFF"){$dataoffsetdec = $null}
else{$dataoffsetdec = [Uint64]"0x$($dataoffset)"}
write-host "Data Offset: 0x" $dataoffset "($($dataoffsetdec))"-f Cyan

# Creation Timestamp in UTC/GMT
$ts = $data.Substring(24,4)
$tsb = [System.Text.Encoding]::getencoding(28591).GetBytes($ts)
$tsh = [System.BitConverter]::ToString($tsb) -replace '-',''
$seconds = [Uint64]"0x$($tsh)"
$Timestamp = (get-date ("1/1/2000 00:00")).addseconds($seconds) 
write-host "Creation timeStamp (UTC):" $Timestamp -f DarkYellow

# Creator Application
$ca = $data.Substring(28,4)
write-host "Creator: " $ca -f Cyan

# Creator Version
$cv = $data.Substring(32,4)
$cvb = [System.Text.Encoding]::getencoding(28591).GetBytes($cv)
$creatorversion = [System.BitConverter]::ToString($cvb) -replace '-',''
write-host "Creator Version: " $creatorversion -f Cyan

# Creator Host OS
$chos = $data.Substring(36,4)
write-host "Creator Host OS: " $chos -f Cyan

# Original Size
$os = $data.Substring(40,8)
$osb = [System.Text.Encoding]::getencoding(28591).GetBytes($os)
$osh = [System.BitConverter]::ToString($osb) -replace '-',''
$OriginalSize = [Convert]::ToUInt64($osh,16)
write-host "Original Size: " $OriginalSize "($($OriginalSize/1024/1024)Mb)" -f Cyan

# Current Size
$cs = $data.Substring(48,8)
$csb = [System.Text.Encoding]::getencoding(28591).GetBytes($cs)
$csh = [System.BitConverter]::ToString($csb) -replace '-',''
$CurrentSize = [Convert]::ToUInt64($csh,16)
write-host "Current Size: " $CurrentSize "($($CurrentSize/1024/1024)Mb)"  -f Green

# Disk Geometry 
$cyl = $data.Substring(56,2)
$cylb = [System.Text.Encoding]::getencoding(28591).GetBytes($cyl)
$cylh = [System.BitConverter]::ToString($cylb) -replace '-',''
$cylinders = [Convert]::ToUInt32($cylh,16)

$hea = $data.Substring(58,1)
$heab = [System.Text.Encoding]::getencoding(28591).GetBytes($hea)
$heah = [System.BitConverter]::ToString($heab)
$heads = [Convert]::ToUInt32($heah,16)

$sec = $data.Substring(59,1)
$secb = [System.Text.Encoding]::getencoding(28591).GetBytes($sec)
$sech = [System.BitConverter]::ToString($secb)
$Sectors = [Convert]::ToUInt32($sech,16)
write-host "Disk Geometry (CHS): "$cylinders"/"$heads"/"$Sectors   -f Cyan

# Disk Type
$dt = $data.Substring(60,4)
$dtb = [System.Text.Encoding]::getencoding(28591).GetBytes($dt)
$dth = [System.BitConverter]::ToString($dtb) -replace '-',''
$disktype = if($dth -match "00000000"){"None"}
elseif($dth -match "00000001"){"Reserved"}
elseif($dth -match "00000002"){"Fixed hard disk"}
elseif($dth -match "00000003"){"Dynamic hard disk"}
elseif($dth -match "00000004"){"Differencing hard disk"}
elseif($dth -match "00000005"){"Reserved"}
elseif($dth -match "00000006"){"Reserved"}
write-host "Disk Type: "$disktype   -f Green


# Checksum
$chks = $data.Substring(64,4)
$chksb = [System.Text.Encoding]::getencoding(28591).GetBytes($chks)
$Checksum = [System.BitConverter]::ToString($chksb) -replace '-',''
write-host "Checksum: "$Checksum   -f Cyan

# Validate Checksum
$check = 0; 
$size = $data.Length 
for ($counter = 0 ; $counter -lt $size ; $counter++) 

{ if($counter -notin(64..67)){
   $check += $data[$counter]; 
} 
else{$check += 0x00}
}
$check = -bNot $check
$check = "{0:X}" -f $check
write-host "Calculated checksum: "$($check) -f Cyan
if($Checksum -eq $check){Write-Host "Checksum $($checksum) is Valid" -f Green}
else{Write-Host "Checksum $($checksum) mismach" -f Red}

# Unique ID (128-bit universally unique identifier)
$uid = $data.Substring(68,16)
$uidb = [System.Text.Encoding]::getencoding(28591).GetBytes($uid)
$uidh = [System.BitConverter]::ToString($uidb) -replace '-',''
write-host "Unique ID: "$uidh   -f Cyan

# Saved State 
$ss = $data.Substring(84,1)
$ssb = [System.Text.Encoding]::getencoding(28591).GetBytes($ss)
write-host "Saved State: "$ssb   -f Cyan

############################
# Dynamic Disk Header

# If the Offset is not FFFFFFFFFFFFFFFF read the Dynamic Disk Header
if (!!$dataoffsetdec){
        $Stream = New-Object System.IO.FileStream -ArgumentList $vhd, 'Open', 'Read'
        $BinaryReader  = New-Object System.IO.BinaryReader  -ArgumentList $Stream, $Encoding
        # Set offset to read the Footer data offset value
        $BinaryReader.BaseStream.Position = [UInt64]($dataoffsetdec)
        # Initialize the buffer 
        $buffer = [System.Byte[]]::new(1024)
        # Read to the buffer
        [Void]$BinaryReader.Read($buffer,0,1024)
        # Convert the buffer data to byte array
        $data = [System.Text.Encoding]::GetEncoding(28591).getstring($buffer)

        $BinaryReader.Close()
        $Stream.Close()

        write-host "`n****  Dynamic Disk Header ****`n" -f Yellow

        # Cookie
        $headercookie = $data.Substring(0,8)
        Write-Host "Header Cookie :"$headercookie -f Cyan

        # Data Offset (absolute byte offset to the next structure in the hard disk - currently unused )
        $hdo = $data.Substring(8,8)
        $hdob = [System.Text.Encoding]::getencoding(28591).GetBytes($hdo)
        $headerdataoffset = [System.BitConverter]::ToString($hdob) -replace '-',''
        write-host "Header Data Offset :"$headerdataoffset -f Cyan
        if($headerdataoffset -eq "FFFFFFFFFFFFFFFF"){$headerdataoffset = $null}

        # Table Offset (absolute byte offset to the Block Allocation Table (BAT)
        $hto = $data.Substring(16,8)
        $htob = [System.Text.Encoding]::getencoding(28591).GetBytes($hto)
        $htoh = [System.BitConverter]::ToString($htob) -replace '-',''
        $headertableoffset = [Convert]::ToUInt64($htoh,16)
        write-host "Table Data Offset (BAT):"$headertableoffset -f Green

        # Header Version
        $hv = $data.Substring(24,4)
        $hvb = [System.Text.Encoding]::getencoding(28591).GetBytes($hv)
        $headerVersion = [System.BitConverter]::ToString($hvb) -replace '-',''
        write-host "Header Version :0x$($headerVersion)" -f Cyan

        # Max Table Entries (maximum entries present in the BAT. This should be equal to the number of blocks in the disk)
        $hmte = $data.Substring(28,4)
        $hmteb = [System.Text.Encoding]::getencoding(28591).GetBytes($hmte)
        $hmteh = [System.BitConverter]::ToString($hmteb) -replace '-',''
        $MaxTableEntries = [Convert]::ToUInt64($hmteh,16)
        write-host "Max (BAT) Table Entries :"$MaxTableEntries -f Cyan

        # Block Size (default value is 0x00200000 (indicating a block size of 2 MB)
        $bs = $data.Substring(32,4)
        $bsb = [System.Text.Encoding]::getencoding(28591).GetBytes($bs)
        $bsh = [System.BitConverter]::ToString($bsb) -replace '-',''
        $BlockSize = [Convert]::ToUInt64($bsh,16)
        write-host "Block Size :"$BlockSize -f Cyan

        # Checksum 
        $hchks = $data.Substring(36,4)
        $hchksb = [System.Text.Encoding]::getencoding(28591).GetBytes($hchks)
        $HeaderChecksum = [System.BitConverter]::ToString($hchksb) -replace '-',''
        write-host "Header Checksum: "$HeaderChecksum   -f Cyan

        # Validate Checksum
        $hcheck = 0; 
        $hsize = 512 
        for ($counter = 0 ; $counter -lt $hsize ; $counter++) 

        { if($counter -notin(36..39)){
            $hcheck += $data[$counter]; 
        } 
        else{$hcheck += 0x00}
        }
        $hcheck = -bNot $hcheck
        $hcheck = "{0:X}" -f $hcheck
        write-host "Calculated checksum:"$($hcheck) -f Cyan
        if($HeaderChecksum -eq $hcheck){Write-Host "Header Checksum $($HeaderChecksum) is Valid" -f Green}
        else{Write-Host "Header Checksum $($HeaderChecksum) mismach" -f Red}
        
        # Parent Unique ID 
        $pui = $data.Substring(40,16)
        $puib = [System.Text.Encoding]::getencoding(28591).GetBytes($pui)
        $ParentUniqueID = [System.BitConverter]::ToString($puib) -replace '-',''
        if($ParentUniqueID -ne "00000000000000000000000000000000"){
        write-host "Parent Unique ID: "$ParentUniqueID -f Cyan}

        # Parent Time Stamp
        $pts = $data.Substring(56,4)
        $ptsb = [System.Text.Encoding]::getencoding(28591).GetBytes($pts)
        if($ptsh -ne "00000000"){
        $ptsh = [System.BitConverter]::ToString($ptsb) -replace '-',''
        $pseconds = [Uint64]"0x$($ptsh)"
        $ParentTimestamp = (get-date ("1/1/2000 00:00")).addseconds($pseconds) 
        write-host "Creation timeStamp (UTC):" $ParentTimestamp -f DarkYellow
        }
        
        # Parent Unicode Name 
        $pun = $data.Substring(64,512)
        $punb = [System.Text.Encoding]::getencoding(28591).GetBytes($pun)
        $ParentUnicodeName = [System.Text.Encoding]::Unicode.GetString($punb)
        if ($ParentUnicodeName -notmatch ""){
        write-host "Parent Unicode Name: $($ParentUnicodeName -replace('\x00',''))" -f Cyan}
        
        # Parent Locator Entries (8*24)
        # These entries store an absolute byte offset in the file where the parent locator 
        # for a differencing hard disk is stored. This field is used only for differencing 
        # disks and should be set to zero for dynamic disks
            # Platform Code 4
            # Platform Data Space 4
            # Platform Data Length 4
            # Platform Data Offset 8


##### End Dynamic Disk Header

##### BAT (Block Allocation Table) - Each entry is four bytes long.!

#  By default, the size of a block is 4096 512-byte sectors (2 MB).
#  All sectors within a block whose corresponding bits in the bitmap are zero must 
#  contain 512 bytes of zero on disk. 

# Calculate size of BAT table in bytes
$BATbytes = $maxtableentries *4

# Read BAT (table of absolute sector offsets)
        $Stream = New-Object System.IO.FileStream -ArgumentList $vhd, 'Open', 'Read'
        $BinaryReader  = New-Object System.IO.BinaryReader  -ArgumentList $Stream, $Encoding
        # Set offset to read the Footer data offset value
        $BinaryReader.BaseStream.Position = [UInt64]($headertableoffset)
        # Initialize the buffer 
        $buffer = [System.Byte[]]::new($BATbytes)
        # Read to the buffer
        [Void]$BinaryReader.Read($buffer,0,$BATbytes)
        # Convert the buffer data to byte array
        $data = [System.Text.Encoding]::GetEncoding(28591).getstring($buffer)
        $BinaryReader.Close()
        $Stream.Close()

 $BAT = foreach($d in (0..(($data.length /4)-1))){

        $ofb = $data.Substring(4*$d,4)
        $ofbd = [System.Text.Encoding]::getencoding(28591).GetBytes($ofb)
        $ofbh = [System.BitConverter]::ToString($ofbd) -replace '-',''
        if($ofbh -ne "FFFFFFFF"){
        $entryoffset = [Convert]::ToUInt64($ofbh,16)
        $actualoffset = $entryoffset*512+512}
        else{$entryoffset = $actualoffset= $null}
        
        [PSCustomObject]@{
        Entry = $d
        Offset = $entryoffset
        "Actual offset" = $actualoffset
        }
        }
        
Write-Host "Block Allocated Entries & Offsets:" -f Green
$bat| ?{$_.offset -ne $null}

$frees = (gwmi Win32_LogicalDisk -Filter "DeviceID='$(((Get-ItemProperty $env:Temp).Parent.Name).trim("\"))'").freespace
if($frees -gt $VirtualDiskSize){

$msgBoxInput = [System.Windows.Forms.MessageBox]::Show($this,"Would you like to extract & save the Payload blocks as a RAW disk image file in $($Env:Temp)?

Disk Size needed: $($CurrentSize/1024/1024)Mb
Disk size available: $([math]::floor($frees/1024/1024))Mb
",'VHD','YesNo','Question')
switch  ($msgBoxInput) {

  'Yes' {

## Extract entries to RAW image file CRAAAAAAAP page 12
try{
        $Stream = New-Object System.IO.FileStream -ArgumentList $vhd, 'Open', 'Read'
        $BinaryReader  = New-Object System.IO.BinaryReader  -ArgumentList $Stream, $Encoding
        $outfile = "$($env:TEMP)\VHD_$($snow)_data.img"
        $streamWriter = New-Object System.IO.StreamWriter -ArgumentList ($outfile,$true, $Encoding)

foreach ($entry in $BAT){
        
        # Initialize the buffer
        $buffer = $data = $null
        $buffer = [System.Byte[]]::new($blocksize)
        # Set offset to read the last 512 bytes of the file (Footer)
        if(![string]::IsNullOrEmpty($entry.offset)){
            $BinaryReader.BaseStream.Position = [UInt64]($entry.offset*512+512)
            # Read vhd to the buffer
            [Void]$BinaryReader.Read($buffer,0,$blocksize)
            }
        #  Convert the buffer data to byte array
        $data = [System.Text.Encoding]::GetEncoding(28591).getstring($buffer)
        
        # write the Data to file
        $streamWriter.write($data)
}
        $streamWriter.Close()
        $BinaryReader.Close()
        $Stream.Close()

# Open output folder
Invoke-Item $env:TEMP
}
catch{write-host "Oops. Extaction failed" -f Red}
}
  'No' {
  Continue
  }
} # End switch
} # End free space check
} # End Dynamic


# Extract Fixed VHD to raw image
#(The space allocated for data is followed by a 512 byte footer structure)

if($disktype -eq "Fixed hard disk"){
$frees = (gwmi Win32_LogicalDisk -Filter "DeviceID='$(((Get-ItemProperty $env:Temp).Parent.Name).trim("\"))'").freespace
if($frees -gt $VirtualDiskSize){

$msgBoxInput = [System.Windows.Forms.MessageBox]::Show($this,"Would you like to extract & save the Payload blocks as a RAW image file in $($Env:Temp)?

Disk Size needed: $($CurrentSize/1024/1024)Mb
Disk size available: $([math]::floor($frees/1024/1024))Mb
",'VHD','YesNo','Question')
switch  ($msgBoxInput) {

  'Yes' {

try{
        $Stream = New-Object System.IO.FileStream -ArgumentList $vhd, 'Open', 'Read'
        $BinaryReader  = New-Object System.IO.BinaryReader  -ArgumentList $Stream, $Encoding
        $outfile = "$($env:TEMP)\VHD_$($snow)_data.img"
        $streamWriter = New-Object System.IO.StreamWriter -ArgumentList ($outfile,$true, $Encoding)
        
        # Initialize the buffer
        $buffer = [System.Byte[]]::new($CurrentSize-512)
        # Read vhd to the buffer
        [Void]$BinaryReader.Read($buffer,0,$CurrentSize-512)
        #  Convert the buffer data to byte array
        $data = [System.Text.Encoding]::GetEncoding(28591).getstring($buffer)

        # write the Data to file
        $streamWriter.write($data)
        $streamWriter.Close()
        $BinaryReader.Close()
        $Stream.Close()

# Open output folder
Invoke-Item $env:TEMP
}
catch{write-host "Oops. Extaction failed" -f Red}
}

  'No' {
  Continue
  }
} # End switch
} # End free space check
}



