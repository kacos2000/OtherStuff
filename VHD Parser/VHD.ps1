# Read $ display the Footer & Header from a VHD file 
# Display the Block Allocation Entry Table (BAT) entries of a Dynamic Disk,
# Optionally extract the data blocks as a Raw Disk image file.
#
# Ref: https://download.microsoft.com/download/f/f/e/ffef50a5-07dd-4cf8-aaa3-442c0673a029/Virtual%20Hard%20Disk%20Format%20Spec_10_18_06.doc
# Ref: https://redcircle.blog/2008/12/01/dynamic-vhd-walkthrough/
[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")|Out-Null

Clear-Host
# Check Validity of script
if ((Get-AuthenticodeSignature $MyInvocation.MyCommand.Path).Status -ne "Valid")
{
	
	$check = [System.Windows.Forms.MessageBox]::Show($this, "WARNING:`n$(Split-path $MyInvocation.MyCommand.Path -Leaf) has been modified since it was signed.`nPress 'YES' to Continue or 'No' to Exit", "Warning", 'YESNO', 48)
	switch ($check)
	{
		"YES"{ Continue }
		"NO"{ Exit }
	}
}
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
$Encoding = [System.Text.Encoding]::GetEncoding(28591)

write-host "Selected VHD: " -NoNewline;write-host "$($vhd)`n" -f White
try{

#read file
        # determine the size of the file
        $file_size = (Get-Item $vhd).length
        $Stream = New-Object System.IO.FileStream $vhd, ([IO.FileMode]::Open), ([IO.FileAccess]::Read), ([IO.FileShare]::ReadWrite)
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
Start-Transcript -path "$($env:Temp)\vhd_$($snow).log" -Append
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
        $Stream = New-Object System.IO.FileStream $vhd, ([IO.FileMode]::Open), ([IO.FileAccess]::Read), ([IO.FileShare]::ReadWrite)
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
[UInt64]$BATbytes = [uint64]$maxtableentries *4

# Read BAT (table of absolute sector offsets)
        $Stream = New-Object System.IO.FileStream $vhd, ([IO.FileMode]::Open), ([IO.FileAccess]::Read), ([IO.FileShare]::ReadWrite)
        $BinaryReader  = New-Object System.IO.BinaryReader  -ArgumentList $Stream, $Encoding
        # Set offset to read the Footer data offset value
        $BinaryReader.BaseStream.Position = [UInt64]($headertableoffset)
        # Initialize the buffer 
        $buffer = [System.Byte[]]::new($BATbytes)
        # Read to the buffer
        $null = $BinaryReader.Read($buffer,0,$BATbytes)
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

$msgBoxInput = [System.Windows.Forms.MessageBox]::Show($this,"Would you like to extract & save the data blocks as a RAW disk image file in $($Env:Temp)?

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
            $null = $BinaryReader.Read($buffer,0,$blocksize)
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

$msgBoxInput = [System.Windows.Forms.MessageBox]::Show($this,"Would you like to extract & save the data as a RAW image file in $($Env:Temp)?

Disk Size needed: $($CurrentSize/1024/1024)Mb
Disk size available: $([math]::floor($frees/1024/1024))Mb
",'VHD','YesNo','Question')
switch  ($msgBoxInput) {

  'Yes' {

try{
        $Stream = New-Object System.IO.FileStream $vhd, ([IO.FileMode]::Open), ([IO.FileAccess]::Read), ([IO.FileShare]::ReadWrite)
        $BinaryReader  = New-Object System.IO.BinaryReader  -ArgumentList $Stream, $Encoding
        $outfile = "$($env:TEMP)\VHD_$($snow)_data.img"
        $streamWriter = New-Object System.IO.StreamWriter -ArgumentList ($outfile, $true, $Encoding)
        $outsize = $CurrentSize-512
        $buffer = $data = $null

        
        $blocks = (0..([math]::Ceiling($outsize/4096) -1))
        
        $datasize = $outsize

        foreach($block in $blocks){
        $blocksize = if($datasize -ge 4096){4096} else {$datasize}
        # Initialize the buffer  
        $buffer = [System.Byte[]]::new($blocksize)     
        # Read block to the buffer
        $null = $BinaryReader.BaseStream.Position = ($block*$blocksize)
        $null = $BinaryReader.Read($buffer,0,$blocksize)
        $datasize = $datasize - $blocksize
        #  Convert the buffer data to byte array
        $data = [System.Text.Encoding]::GetEncoding(28591).getstring($buffer)
      
        # write the Data to file
        $streamWriter.write($data)
        }

        # Close
        $streamWriter.Dispose()
        $BinaryReader.Dispose()
        $Stream.Dispose()

if($outsize -eq [io.FileInfo]::new("$outfile").Length){
   write-host "$($outfile)" -f White -NoNewline
   write-host " was exported successfully" -f Yellow    
}        
# Open output folder
Invoke-Item $env:TEMP
}
catch{
        write-host "Oops. Extaction failed" -f Red
        Continue
        }
}

  'No' {
  Continue
  }
} # End switch
} # End free space check
}
# Stop Transcript
Stop-Transcript




# SIG # Begin signature block
# MIIviAYJKoZIhvcNAQcCoIIveTCCL3UCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDmv5QKtJjuwaap
# lQAnxKMMpGrXA5ifAti7oOf2WO03lKCCKI0wggQyMIIDGqADAgECAgEBMA0GCSqG
# SIb3DQEBBQUAMHsxCzAJBgNVBAYTAkdCMRswGQYDVQQIDBJHcmVhdGVyIE1hbmNo
# ZXN0ZXIxEDAOBgNVBAcMB1NhbGZvcmQxGjAYBgNVBAoMEUNvbW9kbyBDQSBMaW1p
# dGVkMSEwHwYDVQQDDBhBQUEgQ2VydGlmaWNhdGUgU2VydmljZXMwHhcNMDQwMTAx
# MDAwMDAwWhcNMjgxMjMxMjM1OTU5WjB7MQswCQYDVQQGEwJHQjEbMBkGA1UECAwS
# R3JlYXRlciBNYW5jaGVzdGVyMRAwDgYDVQQHDAdTYWxmb3JkMRowGAYDVQQKDBFD
# b21vZG8gQ0EgTGltaXRlZDEhMB8GA1UEAwwYQUFBIENlcnRpZmljYXRlIFNlcnZp
# Y2VzMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAvkCd9G7h6naHHE1F
# RI6+RsiDBp3BKv4YH47kAvrzq11QihYxC5oG0MVwIs1JLVRjzLZuaEYLU+rLTCTA
# vHJO6vEVrvRUmhIKw3qyM2Di2olV8yJY897cz++DhqKMlE+faPKYkEaEJ8d2v+PM
# NSyLXgdkZYLASLCokflhn3YgUKiRx2a163hiA1bwihoT6jGjHqCZ/Tj29icyWG8H
# 9Wu4+xQrr7eqzNZjX3OM2gWZqDioyxd4NlGs6Z70eDqNzw/ZQuKYDKsvnw4B3u+f
# mUnxLd+sdE0bmLVHxeUp0fmQGMdinL6DxyZ7Poolx8DdneY1aBAgnY/Y3tLDhJwN
# XugvyQIDAQABo4HAMIG9MB0GA1UdDgQWBBSgEQojPpbxB+zirynvgqV/0DCktDAO
# BgNVHQ8BAf8EBAMCAQYwDwYDVR0TAQH/BAUwAwEB/zB7BgNVHR8EdDByMDigNqA0
# hjJodHRwOi8vY3JsLmNvbW9kb2NhLmNvbS9BQUFDZXJ0aWZpY2F0ZVNlcnZpY2Vz
# LmNybDA2oDSgMoYwaHR0cDovL2NybC5jb21vZG8ubmV0L0FBQUNlcnRpZmljYXRl
# U2VydmljZXMuY3JsMA0GCSqGSIb3DQEBBQUAA4IBAQAIVvwC8Jvo/6T61nvGRIDO
# T8TF9gBYzKa2vBRJaAR26ObuXewCD2DWjVAYTyZOAePmsKXuv7x0VEG//fwSuMdP
# WvSJYAV/YLcFSvP28cK/xLl0hrYtfWvM0vNG3S/G4GrDwzQDLH2W3VrCDqcKmcEF
# i6sML/NcOs9sN1UJh95TQGxY7/y2q2VuBPYb3DzgWhXGntnxWUgwIWUDbOzpIXPs
# mwOh4DetoBUYj/q6As6nLKkQEyzU5QgmqyKXYPiQXnTUoppTvfKpaOCibsLXbLGj
# D56/62jnVvKu8uMrODoJgbVrhde+Le0/GreyY+L1YiyC1GoAQVDxOYOflek2lphu
# MIIFbzCCBFegAwIBAgIQSPyTtGBVlI02p8mKidaUFjANBgkqhkiG9w0BAQwFADB7
# MQswCQYDVQQGEwJHQjEbMBkGA1UECAwSR3JlYXRlciBNYW5jaGVzdGVyMRAwDgYD
# VQQHDAdTYWxmb3JkMRowGAYDVQQKDBFDb21vZG8gQ0EgTGltaXRlZDEhMB8GA1UE
# AwwYQUFBIENlcnRpZmljYXRlIFNlcnZpY2VzMB4XDTIxMDUyNTAwMDAwMFoXDTI4
# MTIzMTIzNTk1OVowVjELMAkGA1UEBhMCR0IxGDAWBgNVBAoTD1NlY3RpZ28gTGlt
# aXRlZDEtMCsGA1UEAxMkU2VjdGlnbyBQdWJsaWMgQ29kZSBTaWduaW5nIFJvb3Qg
# UjQ2MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAjeeUEiIEJHQu/xYj
# ApKKtq42haxH1CORKz7cfeIxoFFvrISR41KKteKW3tCHYySJiv/vEpM7fbu2ir29
# BX8nm2tl06UMabG8STma8W1uquSggyfamg0rUOlLW7O4ZDakfko9qXGrYbNzszwL
# DO/bM1flvjQ345cbXf0fEj2CA3bm+z9m0pQxafptszSswXp43JJQ8mTHqi0Eq8Nq
# 6uAvp6fcbtfo/9ohq0C/ue4NnsbZnpnvxt4fqQx2sycgoda6/YDnAdLv64IplXCN
# /7sVz/7RDzaiLk8ykHRGa0c1E3cFM09jLrgt4b9lpwRrGNhx+swI8m2JmRCxrds+
# LOSqGLDGBwF1Z95t6WNjHjZ/aYm+qkU+blpfj6Fby50whjDoA7NAxg0POM1nqFOI
# +rgwZfpvx+cdsYN0aT6sxGg7seZnM5q2COCABUhA7vaCZEao9XOwBpXybGWfv1Vb
# HJxXGsd4RnxwqpQbghesh+m2yQ6BHEDWFhcp/FycGCvqRfXvvdVnTyheBe6QTHrn
# xvTQ/PrNPjJGEyA2igTqt6oHRpwNkzoJZplYXCmjuQymMDg80EY2NXycuu7D1fkK
# dvp+BRtAypI16dV60bV/AK6pkKrFfwGcELEW/MxuGNxvYv6mUKe4e7idFT/+IAx1
# yCJaE5UZkADpGtXChvHjjuxf9OUCAwEAAaOCARIwggEOMB8GA1UdIwQYMBaAFKAR
# CiM+lvEH7OKvKe+CpX/QMKS0MB0GA1UdDgQWBBQy65Ka/zWWSC8oQEJwIDaRXBeF
# 5jAOBgNVHQ8BAf8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zATBgNVHSUEDDAKBggr
# BgEFBQcDAzAbBgNVHSAEFDASMAYGBFUdIAAwCAYGZ4EMAQQBMEMGA1UdHwQ8MDow
# OKA2oDSGMmh0dHA6Ly9jcmwuY29tb2RvY2EuY29tL0FBQUNlcnRpZmljYXRlU2Vy
# dmljZXMuY3JsMDQGCCsGAQUFBwEBBCgwJjAkBggrBgEFBQcwAYYYaHR0cDovL29j
# c3AuY29tb2RvY2EuY29tMA0GCSqGSIb3DQEBDAUAA4IBAQASv6Hvi3SamES4aUa1
# qyQKDKSKZ7g6gb9Fin1SB6iNH04hhTmja14tIIa/ELiueTtTzbT72ES+BtlcY2fU
# QBaHRIZyKtYyFfUSg8L54V0RQGf2QidyxSPiAjgaTCDi2wH3zUZPJqJ8ZsBRNraJ
# AlTH/Fj7bADu/pimLpWhDFMpH2/YGaZPnvesCepdgsaLr4CnvYFIUoQx2jLsFeSm
# TD1sOXPUC4U5IOCFGmjhp0g4qdE2JXfBjRkWxYhMZn0vY86Y6GnfrDyoXZ3JHFuu
# 2PMvdM+4fvbXg50RlmKarkUT2n/cR/vfw1Kf5gZV6Z2M8jpiUbzsJA8p1FiAhORF
# e1rYMIIFgzCCA2ugAwIBAgIORea7A4Mzw4VlSOb/RVEwDQYJKoZIhvcNAQEMBQAw
# TDEgMB4GA1UECxMXR2xvYmFsU2lnbiBSb290IENBIC0gUjYxEzARBgNVBAoTCkds
# b2JhbFNpZ24xEzARBgNVBAMTCkdsb2JhbFNpZ24wHhcNMTQxMjEwMDAwMDAwWhcN
# MzQxMjEwMDAwMDAwWjBMMSAwHgYDVQQLExdHbG9iYWxTaWduIFJvb3QgQ0EgLSBS
# NjETMBEGA1UEChMKR2xvYmFsU2lnbjETMBEGA1UEAxMKR2xvYmFsU2lnbjCCAiIw
# DQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAJUH6HPKZvnsFMp7PPcNCPG0RQss
# grRIxutbPK6DuEGSMxSkb3/pKszGsIhrxbaJ0cay/xTOURQh7ErdG1rG1ofuTToV
# Bu1kZguSgMpE3nOUTvOniX9PeGMIyBJQbUJmL025eShNUhqKGoC3GYEOfsSKvGRM
# IRxDaNc9PIrFsmbVkJq3MQbFvuJtMgamHvm566qjuL++gmNQ0PAYid/kD3n16qIf
# KtJwLnvnvJO7bVPiSHyMEAc4/2ayd2F+4OqMPKq0pPbzlUoSB239jLKJz9CgYXfI
# WHSw1CM69106yqLbnQneXUQtkPGBzVeS+n68UARjNN9rkxi+azayOeSsJDa38O+2
# HBNXk7besvjihbdzorg1qkXy4J02oW9UivFyVm4uiMVRQkQVlO6jxTiWm05OWgtH
# 8wY2SXcwvHE35absIQh1/OZhFj931dmRl4QKbNQCTXTAFO39OfuD8l4UoQSwC+n+
# 7o/hbguyCLNhZglqsQY6ZZZZwPA1/cnaKI0aEYdwgQqomnUdnjqGBQCe24DWJfnc
# BZ4nWUx2OVvq+aWh2IMP0f/fMBH5hc8zSPXKbWQULHpYT9NLCEnFlWQaYw55PfWz
# jMpYrZxCRXluDocZXFSxZba/jJvcE+kNb7gu3GduyYsRtYQUigAZcIN5kZeR1Bon
# vzceMgfYFGM8KEyvAgMBAAGjYzBhMA4GA1UdDwEB/wQEAwIBBjAPBgNVHRMBAf8E
# BTADAQH/MB0GA1UdDgQWBBSubAWjkxPioufi1xzWx/B/yGdToDAfBgNVHSMEGDAW
# gBSubAWjkxPioufi1xzWx/B/yGdToDANBgkqhkiG9w0BAQwFAAOCAgEAgyXt6NH9
# lVLNnsAEoJFp5lzQhN7craJP6Ed41mWYqVuoPId8AorRbrcWc+ZfwFSY1XS+wc3i
# EZGtIxg93eFyRJa0lV7Ae46ZeBZDE1ZXs6KzO7V33EByrKPrmzU+sQghoefEQzd5
# Mr6155wsTLxDKZmOMNOsIeDjHfrYBzN2VAAiKrlNIC5waNrlU/yDXNOd8v9EDERm
# 8tLjvUYAGm0CuiVdjaExUd1URhxN25mW7xocBFymFe944Hn+Xds+qkxV/ZoVqW/h
# pvvfcDDpw+5CRu3CkwWJ+n1jez/QcYF8AOiYrg54NMMl+68KnyBr3TsTjxKM4kEa
# SHpzoHdpx7Zcf4LIHv5YGygrqGytXm3ABdJ7t+uA/iU3/gKbaKxCXcPu9czc8FB1
# 0jZpnOZ7BN9uBmm23goJSFmH63sUYHpkqmlD75HHTOwY3WzvUy2MmeFe8nI+z1TI
# vWfspA9MRf/TuTAjB0yPEL+GltmZWrSZVxykzLsViVO6LAUP5MSeGbEYNNVMnbrt
# 9x+vJJUEeKgDu+6B5dpffItKoZB0JaezPkvILFa9x8jvOOJckvB595yEunQtYQEg
# fn7R8k8HWV+LLUNS60YMlOH1Zkd5d9VUWx+tJDfLRVpOoERIyNiwmcUVhAn21klJ
# wGW45hpxbqCo8YLoRT5s1gLXCmeDBVrJpBAwggYaMIIEAqADAgECAhBiHW0MUgGe
# O5B5FSCJIRwKMA0GCSqGSIb3DQEBDAUAMFYxCzAJBgNVBAYTAkdCMRgwFgYDVQQK
# Ew9TZWN0aWdvIExpbWl0ZWQxLTArBgNVBAMTJFNlY3RpZ28gUHVibGljIENvZGUg
# U2lnbmluZyBSb290IFI0NjAeFw0yMTAzMjIwMDAwMDBaFw0zNjAzMjEyMzU5NTla
# MFQxCzAJBgNVBAYTAkdCMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0ZWQxKzApBgNV
# BAMTIlNlY3RpZ28gUHVibGljIENvZGUgU2lnbmluZyBDQSBSMzYwggGiMA0GCSqG
# SIb3DQEBAQUAA4IBjwAwggGKAoIBgQCbK51T+jU/jmAGQ2rAz/V/9shTUxjIztNs
# fvxYB5UXeWUzCxEeAEZGbEN4QMgCsJLZUKhWThj/yPqy0iSZhXkZ6Pg2A2NVDgFi
# gOMYzB2OKhdqfWGVoYW3haT29PSTahYkwmMv0b/83nbeECbiMXhSOtbam+/36F09
# fy1tsB8je/RV0mIk8XL/tfCK6cPuYHE215wzrK0h1SWHTxPbPuYkRdkP05ZwmRmT
# nAO5/arnY83jeNzhP06ShdnRqtZlV59+8yv+KIhE5ILMqgOZYAENHNX9SJDm+qxp
# 4VqpB3MV/h53yl41aHU5pledi9lCBbH9JeIkNFICiVHNkRmq4TpxtwfvjsUedyz8
# rNyfQJy/aOs5b4s+ac7IH60B+Ja7TVM+EKv1WuTGwcLmoU3FpOFMbmPj8pz44MPZ
# 1f9+YEQIQty/NQd/2yGgW+ufflcZ/ZE9o1M7a5Jnqf2i2/uMSWymR8r2oQBMdlyh
# 2n5HirY4jKnFH/9gRvd+QOfdRrJZb1sCAwEAAaOCAWQwggFgMB8GA1UdIwQYMBaA
# FDLrkpr/NZZILyhAQnAgNpFcF4XmMB0GA1UdDgQWBBQPKssghyi47G9IritUpimq
# F6TNDDAOBgNVHQ8BAf8EBAMCAYYwEgYDVR0TAQH/BAgwBgEB/wIBADATBgNVHSUE
# DDAKBggrBgEFBQcDAzAbBgNVHSAEFDASMAYGBFUdIAAwCAYGZ4EMAQQBMEsGA1Ud
# HwREMEIwQKA+oDyGOmh0dHA6Ly9jcmwuc2VjdGlnby5jb20vU2VjdGlnb1B1Ymxp
# Y0NvZGVTaWduaW5nUm9vdFI0Ni5jcmwwewYIKwYBBQUHAQEEbzBtMEYGCCsGAQUF
# BzAChjpodHRwOi8vY3J0LnNlY3RpZ28uY29tL1NlY3RpZ29QdWJsaWNDb2RlU2ln
# bmluZ1Jvb3RSNDYucDdjMCMGCCsGAQUFBzABhhdodHRwOi8vb2NzcC5zZWN0aWdv
# LmNvbTANBgkqhkiG9w0BAQwFAAOCAgEABv+C4XdjNm57oRUgmxP/BP6YdURhw1aV
# cdGRP4Wh60BAscjW4HL9hcpkOTz5jUug2oeunbYAowbFC2AKK+cMcXIBD0ZdOaWT
# syNyBBsMLHqafvIhrCymlaS98+QpoBCyKppP0OcxYEdU0hpsaqBBIZOtBajjcw5+
# w/KeFvPYfLF/ldYpmlG+vd0xqlqd099iChnyIMvY5HexjO2AmtsbpVn0OhNcWbWD
# RF/3sBp6fWXhz7DcML4iTAWS+MVXeNLj1lJziVKEoroGs9Mlizg0bUMbOalOhOfC
# ipnx8CaLZeVme5yELg09Jlo8BMe80jO37PU8ejfkP9/uPak7VLwELKxAMcJszkye
# iaerlphwoKx1uHRzNyE6bxuSKcutisqmKL5OTunAvtONEoteSiabkPVSZ2z76mKn
# zAfZxCl/3dq3dUNw4rg3sTCggkHSRqTqlLMS7gjrhTqBmzu1L90Y1KWN/Y5JKdGv
# spbOrTfOXyXvmPL6E52z1NZJ6ctuMFBQZH3pwWvqURR8AgQdULUvrxjUYbHHj95E
# jza63zdrEcxWLDX6xWls/GDnVNueKjWUH3fTv1Y8Wdho698YADR7TNx8X8z2Bev6
# SivBBOHY+uqiirZtg0y9ShQoPzmCcn63Syatatvx157YK9hlcPmVoa1oDE5/L9Uo
# 2bC5a4CH2RwwggZZMIIEQaADAgECAg0B7BySQN79LkBdfEd0MA0GCSqGSIb3DQEB
# DAUAMEwxIDAeBgNVBAsTF0dsb2JhbFNpZ24gUm9vdCBDQSAtIFI2MRMwEQYDVQQK
# EwpHbG9iYWxTaWduMRMwEQYDVQQDEwpHbG9iYWxTaWduMB4XDTE4MDYyMDAwMDAw
# MFoXDTM0MTIxMDAwMDAwMFowWzELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2Jh
# bFNpZ24gbnYtc2ExMTAvBgNVBAMTKEdsb2JhbFNpZ24gVGltZXN0YW1waW5nIENB
# IC0gU0hBMzg0IC0gRzQwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDw
# AuIwI/rgG+GadLOvdYNfqUdSx2E6Y3w5I3ltdPwx5HQSGZb6zidiW64HiifuV6PE
# Ne2zNMeswwzrgGZt0ShKwSy7uXDycq6M95laXXauv0SofEEkjo+6xU//NkGrpy39
# eE5DiP6TGRfZ7jHPvIo7bmrEiPDul/bc8xigS5kcDoenJuGIyaDlmeKe9JxMP11b
# 7Lbv0mXPRQtUPbFUUweLmW64VJmKqDGSO/J6ffwOWN+BauGwbB5lgirUIceU/kKW
# O/ELsX9/RpgOhz16ZevRVqkuvftYPbWF+lOZTVt07XJLog2CNxkM0KvqWsHvD9WZ
# uT/0TzXxnA/TNxNS2SU07Zbv+GfqCL6PSXr/kLHU9ykV1/kNXdaHQx50xHAotIB7
# vSqbu4ThDqxvDbm19m1W/oodCT4kDmcmx/yyDaCUsLKUzHvmZ/6mWLLU2EESwVX9
# bpHFu7FMCEue1EIGbxsY1TbqZK7O/fUF5uJm0A4FIayxEQYjGeT7BTRE6giunUln
# EYuC5a1ahqdm/TMDAd6ZJflxbumcXQJMYDzPAo8B/XLukvGnEt5CEk3sqSbldwKs
# DlcMCdFhniaI/MiyTdtk8EWfusE/VKPYdgKVbGqNyiJc9gwE4yn6S7Ac0zd0hNkd
# Zqs0c48efXxeltY9GbCX6oxQkW2vV4Z+EDcdaxoU3wIDAQABo4IBKTCCASUwDgYD
# VR0PAQH/BAQDAgGGMBIGA1UdEwEB/wQIMAYBAf8CAQAwHQYDVR0OBBYEFOoWxmnn
# 48tXRTkzpPBAvtDDvWWWMB8GA1UdIwQYMBaAFK5sBaOTE+Ki5+LXHNbH8H/IZ1Og
# MD4GCCsGAQUFBwEBBDIwMDAuBggrBgEFBQcwAYYiaHR0cDovL29jc3AyLmdsb2Jh
# bHNpZ24uY29tL3Jvb3RyNjA2BgNVHR8ELzAtMCugKaAnhiVodHRwOi8vY3JsLmds
# b2JhbHNpZ24uY29tL3Jvb3QtcjYuY3JsMEcGA1UdIARAMD4wPAYEVR0gADA0MDIG
# CCsGAQUFBwIBFiZodHRwczovL3d3dy5nbG9iYWxzaWduLmNvbS9yZXBvc2l0b3J5
# LzANBgkqhkiG9w0BAQwFAAOCAgEAf+KI2VdnK0JfgacJC7rEuygYVtZMv9sbB3DG
# +wsJrQA6YDMfOcYWaxlASSUIHuSb99akDY8elvKGohfeQb9P4byrze7AI4zGhf5L
# FST5GETsH8KkrNCyz+zCVmUdvX/23oLIt59h07VGSJiXAmd6FpVK22LG0LMCzDRI
# RVXd7OlKn14U7XIQcXZw0g+W8+o3V5SRGK/cjZk4GVjCqaF+om4VJuq0+X8q5+dI
# ZGkv0pqhcvb3JEt0Wn1yhjWzAlcfi5z8u6xM3vreU0yD/RKxtklVT3WdrG9KyC5q
# ucqIwxIwTrIIc59eodaZzul9S5YszBZrGM3kWTeGCSziRdayzW6CdaXajR63Wy+I
# Lj198fKRMAWcznt8oMWsr1EG8BHHHTDFUVZg6HyVPSLj1QokUyeXgPpIiScseeI8
# 5Zse46qEgok+wEr1If5iEO0dMPz2zOpIJ3yLdUJ/a8vzpWuVHwRYNAqJ7YJQ5NF7
# qMnmvkiqK1XZjbclIA4bUaDUY6qD6mxyYUrJ+kPExlfFnbY8sIuwuRwx773vFNgU
# QGwgHcIt6AvGjW2MtnHtUiH+PvafnzkarqzSL3ogsfSsqh3iLRSd+pZqHcY8yvPZ
# HL9TTaRHWXyVxENB+SXiLBB+gfkNlKd98rUJ9dhgckBQlSDUQ0S++qCV5yBZtnjG
# pGqqIpswggZoMIIEUKADAgECAhABSJA9woq8p6EZTQwcV7gpMA0GCSqGSIb3DQEB
# CwUAMFsxCzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNhMTEw
# LwYDVQQDEyhHbG9iYWxTaWduIFRpbWVzdGFtcGluZyBDQSAtIFNIQTM4NCAtIEc0
# MB4XDTIyMDQwNjA3NDE1OFoXDTMzMDUwODA3NDE1OFowYzELMAkGA1UEBhMCQkUx
# GTAXBgNVBAoMEEdsb2JhbFNpZ24gbnYtc2ExOTA3BgNVBAMMMEdsb2JhbHNpZ24g
# VFNBIGZvciBNUyBBdXRoZW50aWNvZGUgQWR2YW5jZWQgLSBHNDCCAaIwDQYJKoZI
# hvcNAQEBBQADggGPADCCAYoCggGBAMLJ3AO2G1D6Kg3onKQh2yinHfWAtRJ0I/5e
# L8MaXZayIBkZUF92IyY1xiHslO+1ojrFkIGbIe8LJ6TjF2Q72pPUVi8811j5bazA
# L5B4I0nA+MGPcBPUa98miFp2e0j34aSm7wsa8yVUD4CeIxISE9Gw9wLjKw3/QD4A
# QkPeGu9M9Iep8p480Abn4mPS60xb3V1YlNPlpTkoqgdediMw/Px/mA3FZW0b1XRF
# OkawohZ13qLCKnB8tna82Ruuul2c9oeVzqqo4rWjsZNuQKWbEIh2Fk40ofye8eEa
# VNHIJFeUdq3Cx+yjo5Z14sYoawIF6Eu5teBSK3gBjCoxLEzoBeVvnw+EJi5obPrL
# TRl8GMH/ahqpy76jdfjpyBiyzN0vQUAgHM+ICxfJsIpDy+Jrk1HxEb5CvPhR8toA
# Ar4IGCgFJ8TcO113KR4Z1EEqZn20UnNcQqWQ043Fo6o3znMBlCQZQkPRlI9Lft3L
# bbwbTnv5qgsiS0mASXAbLU/eNGA+vQIDAQABo4IBnjCCAZowDgYDVR0PAQH/BAQD
# AgeAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMIMB0GA1UdDgQWBBRba3v0cHQIwQ0q
# yO/xxLlA0krG/TBMBgNVHSAERTBDMEEGCSsGAQQBoDIBHjA0MDIGCCsGAQUFBwIB
# FiZodHRwczovL3d3dy5nbG9iYWxzaWduLmNvbS9yZXBvc2l0b3J5LzAMBgNVHRMB
# Af8EAjAAMIGQBggrBgEFBQcBAQSBgzCBgDA5BggrBgEFBQcwAYYtaHR0cDovL29j
# c3AuZ2xvYmFsc2lnbi5jb20vY2EvZ3N0c2FjYXNoYTM4NGc0MEMGCCsGAQUFBzAC
# hjdodHRwOi8vc2VjdXJlLmdsb2JhbHNpZ24uY29tL2NhY2VydC9nc3RzYWNhc2hh
# Mzg0ZzQuY3J0MB8GA1UdIwQYMBaAFOoWxmnn48tXRTkzpPBAvtDDvWWWMEEGA1Ud
# HwQ6MDgwNqA0oDKGMGh0dHA6Ly9jcmwuZ2xvYmFsc2lnbi5jb20vY2EvZ3N0c2Fj
# YXNoYTM4NGc0LmNybDANBgkqhkiG9w0BAQsFAAOCAgEALms+j3+wsGDZ8Z2E3JW2
# 318NvyRR4xoGqlUEy2HB72Vxrgv9lCRXAMfk9gy8GJV9LxlqYDOmvtAIVVYEtuP+
# HrvlEHZUO6tcIV4qNU1Gy6ZMugRAYGAs29P2nd7KMhAMeLC7VsUHS3C8pw+rcryN
# y+vuwUxr2fqYoXQ+6ajIeXx2d0j9z+PwDcHpw5LgBwwTLz9rfzXZ1bfub3xYwPE/
# DBmyAqNJTJwEw/C0l6fgTWolujQWYmbIeLxpc6pfcqI1WB4m678yFKoSeuv0lmt/
# cqzqpzkIMwE2PmEkfhGdER52IlTjQLsuhgx2nmnSxBw9oguMiAQDVN7pGxf+LCue
# 2dZbIjj8ZECGzRd/4amfub+SQahvJmr0DyiwQJGQL062dlC8TSPZf09rkymnbOfQ
# MD6pkx/CUCs5xbL4TSck0f122L75k/SpVArVdljRPJ7qGugkxPs28S9Z05LD7Mtg
# Uh4cRiUI/37Zk64UlaiGigcuVItzTDcVOFBWh/FPrhyPyaFsLwv8uxxvLb2qtuto
# I/DtlCcUY8us9GeKLIHTFBIYAT+Eeq7sR2A/aFiZyUrCoZkVBcKt3qLv16dVfLyE
# G02Uu45KhUTZgT2qoyVVX6RrzTZsAPn/ct5a7P/JoEGWGkBqhZEcr3VjqMtaM7WU
# M36yjQ9zvof8rzpzH3sg23IwggZyMIIE2qADAgECAhALYufvMdbwtA/sWXrOPd+k
# MA0GCSqGSIb3DQEBDAUAMFQxCzAJBgNVBAYTAkdCMRgwFgYDVQQKEw9TZWN0aWdv
# IExpbWl0ZWQxKzApBgNVBAMTIlNlY3RpZ28gUHVibGljIENvZGUgU2lnbmluZyBD
# QSBSMzYwHhcNMjIwMjA3MDAwMDAwWhcNMjUwMjA2MjM1OTU5WjB2MQswCQYDVQQG
# EwJHUjEdMBsGA1UECAwUS2VudHJpa8OtIE1ha2Vkb27DrWExIzAhBgNVBAoMGkth
# dHNhdm91bmlkaXMgS29uc3RhbnRpbm9zMSMwIQYDVQQDDBpLYXRzYXZvdW5pZGlz
# IEtvbnN0YW50aW5vczCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAIxd
# u9+Lc83wVLNDuBn9NzaXp9JzWaiQs6/uQ6fbCUHC4/2lLfKzOUus3e76lSpnmo7b
# kCLipjwZH+yqWRuvrccrfZCoyVvBAuzdE69AMR02Z3Ay5fjN6kWPfACkgLe4D9og
# SDh/ZsOfHD89+yKKbMqsDdj4w/zjIRwcYGgBR6QOGP8mLAIKH7TwvoYBauLlb6aM
# /eG/TGm3cWd4oonwjiYU2fDkhPPdGgCXFem+vhuIWoDk0A0OVwEzDFi3H9zdv6hB
# bv+d37bl4W81zrm42BMC9kWgiEuoDUQeY4OX2RdNqNtzkPMI7Q93YlnJwitLfSrg
# GmcU6fiE0vIW3mkf7mebYttI7hJVvqt0BaCPRBhOXHT+KNUvenSXwBzTVef/9h70
# POF9ZXbUhTlJJIHJE5SLZ2DvjAOLUvZuvo3bGJIIASHnTKEIVLCUwJB77NeKsgDx
# YGDFc2OQiI9MuFWdaty4B0sXQMj+KxZTb/Q0O850xkLIbQrAS6T2LKEuviE6Ua7b
# QFXi1nFZ+r9XjOwZQmQDuKx2D92AUR/qwcpIM8tIbJdlNzEqE/2wwaE10G+sKuX/
# SaJFZbKXqDMqJr1fw0M9n0saSTX1IZrlrEcppDRN+OIdnQL3cf6PTqv1PTS4pZ/9
# m7iweMcU4lLJ7L/8ZKiIb0ThD9kIddJ5coICzr/hAgMBAAGjggGcMIIBmDAfBgNV
# HSMEGDAWgBQPKssghyi47G9IritUpimqF6TNDDAdBgNVHQ4EFgQUidoax6lNhMBv
# wMAg4rCjdP30S8QwDgYDVR0PAQH/BAQDAgeAMAwGA1UdEwEB/wQCMAAwEwYDVR0l
# BAwwCgYIKwYBBQUHAwMwEQYJYIZIAYb4QgEBBAQDAgQQMEoGA1UdIARDMEEwNQYM
# KwYBBAGyMQECAQMCMCUwIwYIKwYBBQUHAgEWF2h0dHBzOi8vc2VjdGlnby5jb20v
# Q1BTMAgGBmeBDAEEATBJBgNVHR8EQjBAMD6gPKA6hjhodHRwOi8vY3JsLnNlY3Rp
# Z28uY29tL1NlY3RpZ29QdWJsaWNDb2RlU2lnbmluZ0NBUjM2LmNybDB5BggrBgEF
# BQcBAQRtMGswRAYIKwYBBQUHMAKGOGh0dHA6Ly9jcnQuc2VjdGlnby5jb20vU2Vj
# dGlnb1B1YmxpY0NvZGVTaWduaW5nQ0FSMzYuY3J0MCMGCCsGAQUFBzABhhdodHRw
# Oi8vb2NzcC5zZWN0aWdvLmNvbTANBgkqhkiG9w0BAQwFAAOCAYEAG+2x4Vn8dk+Y
# w0Khv6CZY+/QKXW+aG/siN+Wn24ijKmvbjiNEbEfCicwZ12YpkOCnuFtrXs8k9zB
# PusV1/wdH+0buzzSuCmkyx5v4wSqh8OsyWIyIsW/thnTyzYys/Gw0ep4RHFtbNTR
# K4+PowRHW1DxOjaxJUNi9sbNG1RiDSAVkGAnHo9m+wAK6WFOIFV5vAbCp8upQPwh
# aGo7u2hXP/d18mf/4BtQ+J7voX1BFwgCLhlrho0NY8MgLGuMBcu5zw07j0ZFBvyr
# axDPVwDoZw07JM018c2Nn4hg2XbYyMtUkvCi120uI6299fGs6Tmi9ttP4c6pubs4
# TY40jVxlxxnqqvIA/wRYXpWOe5Z3n80OFEatcFtzLrQTyO9Q1ptk6gso/RNpRu3r
# ug+aXqfvP3a32FNZAQ6dUGr0ae57OtgM+hlLMhSSyhugHrnbi9oNAsqa/KA6UtD7
# MxWJIwAqACTqqVjUTKjzaaE+12aS3vaO6tEqCuT+DOtu7aJRPnyyMYIGUTCCBk0C
# AQEwaDBUMQswCQYDVQQGEwJHQjEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMSsw
# KQYDVQQDEyJTZWN0aWdvIFB1YmxpYyBDb2RlIFNpZ25pbmcgQ0EgUjM2AhALYufv
# MdbwtA/sWXrOPd+kMA0GCWCGSAFlAwQCAQUAoEwwGQYJKoZIhvcNAQkDMQwGCisG
# AQQBgjcCAQQwLwYJKoZIhvcNAQkEMSIEIJiV3OnFttMklj4P8TQ3Tx/nubW0uAYC
# T76uh0xkTHAfMA0GCSqGSIb3DQEBAQUABIICADxgPiod6jcJcBr37rWmze3lzd0G
# smHCEyJBQEIqUHJaQv5h5svUlCSYM91TohPto53hrInvNchp05BMr0R++eqs8i/B
# vcklehaiOTw/XBaa9+2PKA/A3fFOMXXS9lxeP3+c5r/r82/K+ykAXP+v99gviJ0a
# MTPgiXQR5cEWKAm4HGXGa8mIWRSAr1opck1fokBWAdyGPPSLCd/io2NAYdWILuiV
# Ef4TSqWn4Miq5RP3phRb/uLoIYK8KLFmUYap7vbbfGWl/LQrSza/I4vHuWSYkgZ7
# tI01Q0jQG1elMF7OM+MLpIltkJL1V4BQVEFZpiDWBuJYYmBJsVtdvef+FX2O2hQJ
# 8zC23B6tC4jZs7nYxkpvyhrv/Q8JWo3gZzIeVMSeMy4lwYDMfJMvDO7QgUUOT99g
# BzSvA4LGUGaLskdIxYb+3FT7Iw4tUCDO+B3OM5Vj+IhcOVGt0NIPTIZUgpSLyDQF
# OWDugHCVQtEOmXYkc8HVhGEWAwozFpeRcdwONCf/RVHNLseZK3IeO6P18oXW/Zdv
# LXlPRkXGARca6+mJV3OUrtyKOJcqMtrO9w6X763NFoiDAImFOwf+NiayGsSif0AX
# rNcACFDYQtQad/0vv3FuQT43O26Py4itbUZ7LRiXgR3oZ4tc1nIM5RPihGuj8ebj
# BTsKdP2pLzC/Zwb6oYIDbDCCA2gGCSqGSIb3DQEJBjGCA1kwggNVAgEBMG8wWzEL
# MAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExMTAvBgNVBAMT
# KEdsb2JhbFNpZ24gVGltZXN0YW1waW5nIENBIC0gU0hBMzg0IC0gRzQCEAFIkD3C
# irynoRlNDBxXuCkwCwYJYIZIAWUDBAIBoIIBPTAYBgkqhkiG9w0BCQMxCwYJKoZI
# hvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yMjA3MTMxNDQ0NTBaMCsGCSqGSIb3DQEJ
# NDEeMBwwCwYJYIZIAWUDBAIBoQ0GCSqGSIb3DQEBCwUAMC8GCSqGSIb3DQEJBDEi
# BCArcoEc09hnX1ydbPburQkRoHHsiDC1wVVId72GiQ6w8DCBpAYLKoZIhvcNAQkQ
# AgwxgZQwgZEwgY4wgYsEFDEDDhdqpFkuqyyLregymfy1WF3PMHMwX6RdMFsxCzAJ
# BgNVBAYTAkJFMRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNhMTEwLwYDVQQDEyhH
# bG9iYWxTaWduIFRpbWVzdGFtcGluZyBDQSAtIFNIQTM4NCAtIEc0AhABSJA9woq8
# p6EZTQwcV7gpMA0GCSqGSIb3DQEBCwUABIIBgFLcnXqeIpVJa9GhFky06TTD+Gy7
# z1IYAI408G6tufffVLjOPWZqz+7zsnQa8/gTVseguJb5CMA/S5AFVaHXAL9AOXS5
# keiSg4QJ1Pp/rnLCjduy7x88vcrYV9XLDsWQHDYnueOZJH5BKOt/gF2QDD5jkn6v
# DU6IBMFdu/EanPjFESdvRZVGxb8R4ruZE8pvurnlXg9+wotVyNWKNp8eTUs75sO/
# h7daWOeTMg2NkOgsRGmXXFIsdiY3UL7FKUzik9jgUCzidGWHBNrb3ADYo8Kzjyd8
# 7UdvTtQNffqluz2bJ5ZkTbHMDEGo8SbwGYA6tWwpyOS2lTPj/V5zCuYXBCOKCQod
# juigoO/2NpO91SZsse0zpgOZ3JMPBFaiY5HjkYwcbEzxeGSp8VznAS+JiEIZR1CU
# y+2cQdky3IAKbwi/Vz4VmGf0XRrikRoP4wY4Cg+h4qskoqQLR5WMvJhk++ZAirM/
# wDREfrCQz+qg0RfPSLMNw9zkmWQOMZ/wNad1lQ==
# SIG # End signature block
