# Read & display the Header & Structures from a VHDX file (first 10Mb raw data can also be used)
# Display the Block Allocation Entry Table (BAT) entries,
# Optionally extract the data blocks (as listed in BAT) as a raw disk image file.
#
#
#    .-----------------------------------------------------------------.
#    |   (A)    |   (B)    |    (C)    |     (D)       |     (E)       |
#    |  File ID |  Header1 |  Header 2 |  Region Tbl 1 |  Region Tbl 2 |
#    |          |          |           |               |               |
#    .-----------------------------------------------------------------.
#    0         64KB      128KB       192KB           256KB           320KB
#    .---- ~ ----------- ~ ------------ ~ ---------------- ~ -----------.
#    |     (F)     |     (G)       |    (H)    |                        |
#    | Journal Log |  BAT / Bitmap |  Metadata |  .... data ......      |
#    |             |               |           |                        |
#    .---- ~ ----------- ~ ------------ ~ ---------------- ~ -----------.
#   1MB
#
# Diagram above was copied from https://github.com/qemu/qemu/blob/master/block/vhdx.c
# Ref: # https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-vhdx/f0efbb98-f555-4efc-8374-4e77945ad422

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
		$OpenFileDialog.Title = 'Select a vhdx file'
		$OpenFileDialog.initialDirectory = $initialDirectory
		$OpenFileDialog.Filter = "VHDX file (*.vhdx)|*.vhdx|All files (*.*)|*.*"
		$OpenFileDialog.ShowDialog() | Out-Null
		$OpenFileDialog.ShowReadOnly = $true
		$OpenFileDialog.filename
		$OpenFileDialog.ShowHelp = $false
} #end function Get-FileName 

$fPath =  $env:USERPROFILE+"\Desktop\"
$vhdx = Get-FileName -initialDirectory $fPath
# get timestamp for data dump file
$snow = Get-Date -Format "dd-MMM-yyyyTHH-mm-ss"

try{

#read file
        # determine the size of the file
        $file_size = (Get-Item $vhdx).length
        $Stream = New-Object System.IO.FileStream -ArgumentList $vhdx, 'Open', 'Read'
		$Encoding = [System.Text.Encoding]::GetEncoding(28591)
        $BinaryReader  = New-Object System.IO.BinaryReader  -ArgumentList $Stream, $Encoding
        # Read first 10Mb of the selected vhdx file               
        $Fcontent = $BinaryReader.ReadBytes(1048576*10)
        $Fcontent = [System.Text.Encoding]::GetEncoding(28591).getstring($Fcontent)
        $BinaryReader.Close()
		$Stream.Close()
        [gc]::Collect()	


# Start transcript
Start-Transcript -path "$($env:Temp)\vhdx_$($snow).log" -Append
}
catch{
Write-Host "Oops, something went wrong" -f Red
Exit
}

# read header

# file type identifier - signature
$hrfts = $Fcontent.substring(0, 8)
if($hrfts -match "vhdxfile"){write-host "File is a '$($hrfts)' file" -f Yellow}
else{write-host "Not a valid vhdx signature"
break}

# file type identifier - creator
$hrftc = $Fcontent.substring(8, 512)
$hrftcb = [System.Text.Encoding]::getencoding(28591).GetBytes($hrftc)
$creator = [System.Text.Encoding]::Unicode.GetString($hrftcb)
write-host "Creator: $($creator -replace('\x00',''))" -f Cyan

### Headers

# header 1 -signature
$hrfth1 = $Fcontent.substring(64*1024, 4)
$hrfth1b = [System.Text.Encoding]::getencoding(28591).GetBytes($hrfth1)
$hrfth1h = [System.BitConverter]::ToString($hrfth1b) -replace '-',''

# header 1 - checksum
$hrfth1c = $Fcontent.substring(64*1024+4, 4)
$hrfth1cb = [System.Text.Encoding]::getencoding(28591).GetBytes($hrfth1c)
$H1_CRC32 = [System.BitConverter]::ToString($hrfth1cb) -replace '-',''

# header 1 - SequenceNumber 
$hrfth1sn = $Fcontent.substring(64*1024+8, 8)
$hrfth1snb = [System.Text.Encoding]::getencoding(28591).GetBytes($hrfth1sn)
[array]::reverse($hrfth1snb)
$hrfth1snh = [System.BitConverter]::ToString($hrfth1snb) -replace '-',''
$h1SequenceNumber = [Convert]::ToUInt64($hrfth1snh,16)

# header 1 - FileWriteGuid 
$hrfth1fwg = $Fcontent.substring(64*1024+16, 16)
$hrfth1fwgb = [System.Text.Encoding]::getencoding(28591).GetBytes($hrfth1fwg)
$h1fwguid = [System.BitConverter]::ToString($hrfth1fwgb) -replace '-',''

# header 1 - DataWriteGuid  
$hrfth1dwg = $Fcontent.substring(64*1024+32, 16)
$hrfth1dwgb = [System.Text.Encoding]::getencoding(28591).GetBytes($hrfth1dwg)
$h1DataWriteGuid = [System.BitConverter]::ToString($hrfth1dwgb) -replace '-',''

# header 1 - LogGuid  
$hrfth1lg = $Fcontent.substring(64*1024+48, 16)
$hrfth1lb = [System.Text.Encoding]::getencoding(28591).GetBytes($hrfth1lg)
$h1LogGuid = [System.BitConverter]::ToString($hrfth1lb) -replace '-',''

# header 1 - LogVersion  
$hrfth1lv = $Fcontent.substring(64*1024+64, 2)
$hrfth1lvb = [System.Text.Encoding]::getencoding(28591).GetBytes($hrfth1lv)
[array]::reverse($hrfth1lvb)
$hrfth1lvh = [System.BitConverter]::ToString($hrfth1lvb) -replace '-',''
$h1logversion = [Convert]::ToInt32($hrfth1lvh,16)

# header 1 - Version   
$hrfth1v = $Fcontent.substring(64*1024+68, 2)
$hrfth1vb = [System.Text.Encoding]::getencoding(28591).GetBytes($hrfth1v)
[array]::reverse($hrfth1vb)
$hrfth1vh = [System.BitConverter]::ToString($hrfth1vb) -replace '-',''
$h1Version = [Convert]::ToInt32($hrfth1vh,16)

# header 2 -signature
$hrfth2 = $Fcontent.substring(128*1024, 4)
$hrfth2b = [System.Text.Encoding]::getencoding(28591).GetBytes($hrfth2)
$hrfth2h = [System.BitConverter]::ToString($hrfth2b) -replace '-',''

# header 2 - checksum
$hrfth2c = $Fcontent.substring(128*1024+4, 4)
$hrfth2cb = [System.Text.Encoding]::getencoding(28591).GetBytes($hrfth2c)
$H2_CRC32 = [System.BitConverter]::ToString($hrfth2cb) -replace '-',''


# header 2 - SequenceNumber 
$hrfth2sn = $Fcontent.substring(128*1024+8, 8)
$hrfth2snb = [System.Text.Encoding]::getencoding(28591).GetBytes($hrfth2sn)
[array]::reverse($hrfth2snb)
$hrfth2snh = [System.BitConverter]::ToString($hrfth2snb) -replace '-',''
$h2SequenceNumber = [Convert]::ToUInt64($hrfth2snh,16)


# header 2 - FileWriteGuid 
$hrfth2fwg = $Fcontent.substring(128*1024+16, 16)
$hrfth2fwgb = [System.Text.Encoding]::getencoding(28591).GetBytes($hrfth2fwg)
$h2fwguid = [System.BitConverter]::ToString($hrfth2fwgb) -replace '-',''


# header 2 - DataWriteGuid  
$hrfth2dwg = $Fcontent.substring(128*1024+32, 16)
$hrfth2dwgb = [System.Text.Encoding]::getencoding(28591).GetBytes($hrfth2dwg)
$h2DataWriteGuid = [System.BitConverter]::ToString($hrfth2dwgb) -replace '-',''


# header 2 - LogGuid  
$hrfth2lg = $Fcontent.substring(128*1024+48, 16)
$hrfth2lb = [System.Text.Encoding]::getencoding(28591).GetBytes($hrfth2lg)
$h2LogGuid = [System.BitConverter]::ToString($hrfth2lb) -replace '-',''


# header 2 - LogVersion  
$hrfth2lv = $Fcontent.substring(128*1024+64, 2)
$hrfth2lvb = [System.Text.Encoding]::getencoding(28591).GetBytes($hrfth2lv)
[array]::reverse($hrfth2lvb)
$hrfth2lvh = [System.BitConverter]::ToString($hrfth2lvb) -replace '-',''
$h2logversion = [Convert]::ToInt32($hrfth2lvh,16)


# header 2 - Version   
$hrfth2v = $Fcontent.substring(128*1024+68, 2)
$hrfth2vb = [System.Text.Encoding]::getencoding(28591).GetBytes($hrfth2v)
[array]::reverse($hrfth2vb)
$hrfth2vh = [System.BitConverter]::ToString($hrfth2vb) -replace '-',''
$h2Version = [Convert]::ToInt32($hrfth2vh,16)


$main_info = [PSCustomObject]@{
Signature = $hrfts
Creator = $Creator -replace "\x00",""
"Header 1 signature" = [System.Text.Encoding]::Utf8.GetString($hrfth1b)
"Header 1 Checksum" = $H1_CRC32
"Header 1 Sequence Nr" = $h1SequenceNumber
"Header 1 FileWriteGUID" = $h1fwguid.ToUpper()
"Header 1 DataWriteGuid" = $h1DataWriteGuid.ToUpper()
"Header 1 LogGUID" = $h1LogGuid.ToUpper()
"Header 1 LogVersion" = $h1logversion
"Header 1 Version" = $h1version
"Header 2 signature" = [System.Text.Encoding]::Utf8.GetString($hrfth2b)
"Header 2 Checksum" = $H2_CRC32
"Header 2 Sequence Nr" = $h2SequenceNumber
"Header 2 FileWriteGUID" = $h2fwguid.ToUpper()
"Header 2 DataWriteGuid" = $h2DataWriteGuid.ToUpper()
"Header 2 LogGUID" = $h2LogGuid.ToUpper()
"Header 2 LogVersion" = $h2logversion
"Header 2 Version" = $h2version
}
$main_info

### Regions

# region table 1 - Signature
$hrftr1 = $Fcontent.substring(192*1024, 4)
$hrftr1b = [System.Text.Encoding]::getencoding(28591).GetBytes($hrftr1)
$hrftr1h = [System.BitConverter]::ToString($hrftr1b) -replace '-',''
if($hrftr1h -match "72656769"){write-host "Region Table 1 signature is '$([System.Text.Encoding]::Utf8.GetString($hrftr1b))'" -f white}
else{write-host $hrftr1h}

# region table 1 - Checksum
$hrftr1c = $Fcontent.substring(192*1024+4, 4)
$hrftr1cb = [System.Text.Encoding]::getencoding(28591).GetBytes($hrftr1c)
$hrftr1ch = [System.BitConverter]::ToString($hrftr1cb) -replace '-',''
write-host "Region 1 Checksum = $($hrftr1ch)" -f white

# region table 1 - EntryCount 
$hrftr1ec = $Fcontent.substring(192*1024+8, 4)
$hrftr1ecb = [System.Text.Encoding]::getencoding(28591).GetBytes($hrftr1ec)
[array]::reverse($hrftr1ecb)
$hrftr1ech = [System.BitConverter]::ToString($hrftr1ecb) -replace '-',''
$r1EntryCount = [Convert]::ToUInt64($hrftr1ech)
write-host "Region 1 EntryCount = $($r1EntryCount)" -f white


foreach($r1e in (($r1EntryCount-1)..0)){

# Guid 
$r1eg = $Fcontent.substring(192*1024+16+(32*$r1e), 16)
$r1egb = [System.Text.Encoding]::getencoding(28591).GetBytes($r1eg)
$r1EntryGuid = [System.BitConverter]::ToString($r1egb) -replace '-',''
    if($r1EntryGuid -match "6677C22D23F600429D64115E9BFD4A08"){
$r1Guid = "BAT"
write-host "Region 1 Entry $($r1e+1) = Block Allocation Table" -f Green}
elseif($r1EntryGuid -match "06A27C8B90479A4BB8FE575F050F886E"){
$r1Guid = "Metadata"
write-host "Region 1 Entry $($r1e+1) = Metadata Region" -f Green}
else{Write-Host $r1EntryGuid }

# FileOffset
$r1fo = $Fcontent.substring(192*1024+16+(32*$r1e)+16, 8)
$r1fob = [System.Text.Encoding]::getencoding(28591).GetBytes($r1fo)
[array]::reverse($r1fob)
$r1foh = [System.BitConverter]::ToString($r1fob) -replace '-',''
$r1FileOffset = [Convert]::ToUInt64($r1foh,16)
write-host "Region 1 Entry $($r1e+1) offset is $($r1FileOffset) dec or 0x$($r1foh)" -f white

# Length
$r1l = $Fcontent.substring(192*1024+16+(32*$r1e)+24, 4)
$r1lb = [System.Text.Encoding]::getencoding(28591).GetBytes($r1l)
[array]::reverse($r1lb)
$r1lh = [System.BitConverter]::ToString($r1lb) -replace '-',''
$r1Length = [Convert]::ToUInt64($r1lh,16)
write-host "Region 1 Entry $($r1e+1) size is $($r1Length)" -f white

# Required 
$r1r = $Fcontent.substring(192*1024+16+(32*$r1e)+28, 4)
$r1rb = [System.Text.Encoding]::getencoding(28591).GetBytes($r1r)
[array]::reverse($r1rb)
$r1rh = [System.BitConverter]::ToString($r1rb) -replace '-',''
$r1required = [Convert]::ToUInt32($r1rh,16)
if($r1required -eq 1){write-host "Required to load the VHDX" -f white}
else{write-host  "Not required ($($r1required))"}


   # Read Metadata entry 
    if($r1Guid -eq "Metadata"){

            # Metadata Header (32bytes)
            # Metadata - Signature
            $ms = $Fcontent.substring($r1FileOffset, 8)
            if($ms -match "metadata"){write-host $ms -f DarkYellow}

            # Metadata - Entry Count 
            $mec = $Fcontent.substring($r1FileOffset+10, 2)
            $mecb = [System.Text.Encoding]::getencoding(28591).GetBytes($mec)
            [array]::reverse($mecb)
            $mech = [System.BitConverter]::ToString($mecb) -replace '-',''
            $metaentrycount = [Convert]::ToUInt32($mech,16)
            Write-Host "Metadata entries: $($metaentrycount)" -f DarkYellow


            # Metadata entries ( 128-bit identifier for the metadata item)
            foreach ($_m in (0..($metaentrycount-1))){
            # ItemID
            $ii = $Fcontent.substring($r1FileOffset+32+32*$_m, 16)
            $iib = [System.Text.Encoding]::getencoding(28591).GetBytes($ii)
            [array]::reverse($iib)
            $itemid  = [System.BitConverter]::ToString($iib) -replace '-',''
            #write-host "Entry $($_m+1) - itemid = $($itemid)" -f Yellow

            write-host "__________________________"
            $knownitem = if($itemid -match "6BE744AAF033B6B34D43FA36CAA16737"){"File Parameters"}
            elseif($itemid -match "B8F43BD8BE5D11B24876CD1B2FA54224"){"Virtual Disk Size"}
            elseif($itemid -match "5FABFAA833F247BA4709A96F8141BF1D"){"Logical Sector Size"}
            elseif($itemid -match "56C5515288E9C99C4471445DCDA348C7"){"Physical Sector Size"}
            elseif($itemid -match "46C700E009C3EF934523B2E6BECA12AB"){"Virtual Disk ID"}
            elseif($itemid -match "0CAB3448D8D3F7AB454DB30BA8D35F2D"){"Parent Locator"}
            write-host Entry $($_m+1) - $($knownitem) -f Yellow
            
            # Offset
            # the Offset field MUST be at least 64 KB and is relative to the beginning of the metadata region
            $io = $Fcontent.substring($r1FileOffset+32+32*$_m +16, 4)
            $iob = [System.Text.Encoding]::getencoding(28591).GetBytes($io)
            [array]::reverse($iob)
            $ioh = [System.BitConverter]::ToString($iob) -replace '-',''
            $itemoffset = [Convert]::ToUInt32($ioh,16)
            write-host "Item Offset (dec) = $($itemoffset+$r1FileOffset) " -f Magenta

            # Length
            $mil = $Fcontent.substring($r1FileOffset+32+32*$_m +20, 4)
            $milb = [System.Text.Encoding]::getencoding(28591).GetBytes($mil)
            [array]::reverse($milb)
            $milh = [System.BitConverter]::ToString($milb) -replace '-',''
            $itemlength = [Convert]::ToUInt32($milh,16)
            write-host "Item Length = $($itemlength)" -f Magenta
            
            #  Read next byte ..
            $0 = $Fcontent.substring($r1FileOffset+32+32*$_m +24, 1)
            $0b = [System.Text.Encoding]::getencoding(28591).GetBytes($0)
            #[array]::reverse($0b)
            $1 = [System.BitConverter]::ToString($0b) -replace '-', ''
            $2 = [Convert]::ToString($1,2).padleft(8,'0')

                # IsUser
                if($2[7] -match 1){$isuser = "User Metadata"}
                else{$isuser = "System Metadata"}
                write-host $isuser -f Gray
            
                # IsVirtualDisk 
                if($2[6] -match 0
                ){$IsVirtualDisk = "File Metadata"}
                else{$IsVirtualDisk = "Virtual Disk Metadata"}
                 write-host $IsVirtualDisk -f Gray

                # IsRequired  
                if($2[5] -match 0){$IsRequired = "not required for vhdx"}
                else{$IsRequired = "Required for vhdx"}
                write-host $IsRequired -f Gray

                # Read the metadata data
                $md = $Fcontent.substring($r1FileOffset+$itemoffset,$itemlength)
               
               if($knownitem -eq "File Parameters"){
               # BlockSize
               $bs = $Fcontent.substring($r1FileOffset+$itemoffset,4)
               $bsb = [System.Text.Encoding]::getencoding(28591).GetBytes($bs)
               [array]::reverse($bsb)
               $bsh = [System.BitConverter]::ToString($bsb) -replace '-', ''
               $block = [Convert]::ToUInt32($bsh,16)
               write-host "Block size = $($block)"
               
               # Bits
               $bb = $Fcontent.substring($r1FileOffset+$itemoffset+4,1)
               $bbd = [System.Text.Encoding]::getencoding(28591).GetBytes($bb)
               [array]::reverse($bbd)
               $bbits = [Convert]::ToString($bbd[0],2).padleft(8,'0')
               
               # LeaveBlockAllocated
               # https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-vhdx/ec0e9d25-69e4-439e-806a-e0c23f0e1ae6
               # https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-vhdx/af7334e6-ad2c-4378-9b81-afc1334a6ee7
               if($bbits[7] -match 1){Write-Host "--------> Fixed Size VHDX" -f Yellow}else
               {write-host "--------> Dynamic/differencing size VHDX" -f Yellow}
               
               # HasParent
               if($bbits[6] -match 1){Write-Host "the file is a differencing file"}
               } # end file parameters

               if($knownitem -eq "Virtual Disk Size"){
               # VirtualDiskSize 
               $vds = $Fcontent.substring($r1FileOffset+$itemoffset,8)
               $vdsb = [System.Text.Encoding]::getencoding(28591).GetBytes($vds)
               [array]::reverse($vdsb)
               $vdsh = [System.BitConverter]::ToString($vdsb) -replace '-', ''
               $VirtualDiskSize = [Convert]::ToUInt64($vdsh,16)
               write-host "Virtual Disk Size = $($VirtualDiskSize/1024/1024)Mb"

               }# end Virtual Disk Size

               if($knownitem -eq "Virtual Disk ID"){
               # Virtual Disk ID 
               $vdid = $Fcontent.substring($r1FileOffset+$itemoffset,16)
               $vdidb = [System.Text.Encoding]::getencoding(28591).GetBytes($vdid)
               $vdGuid = [System.BitConverter]::ToString($vdidb) -replace '-',''
               write-host "Virtual Disk ID = $vdGuid" 


               }# end Virtual Disk ID

               if($knownitem -eq "Logical Sector Size"){
               # Logical Sector Size 
               $lss = $Fcontent.substring($r1FileOffset+$itemoffset,4)
               $lssb = [System.Text.Encoding]::getencoding(28591).GetBytes($lss)
               [array]::reverse($lssb)
               $lssh = [System.BitConverter]::ToString($lssb) -replace '-',''
               $LogicalSectorSize = [Convert]::ToUInt64($lssh,16)
               write-host "Logical Sector Size = $($LogicalSectorSize)"
               
               }# end Logical Sector Size

               if($knownitem -eq "Physical Sector Size"){
               # Physical Sector Size 
               $pss = $Fcontent.substring($r1FileOffset+$itemoffset,4)
               $pssb = [System.Text.Encoding]::getencoding(28591).GetBytes($lss)
               [array]::reverse($pssb)
               $pssh = [System.BitConverter]::ToString($pssb) -replace '-',''
               $PhysicalSectorSize = [Convert]::ToUInt64($pssh,16)
               write-host "Physical Sector Size = $($PhysicalSectorSize)"
               
               }# end Physical Sector Size


            }

        
        } # End Metadata
    

    # Read Bat entry (array of 64-bit values)
    # https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-vhdx/a84d19eb-b843-4c6c-9aca-fbfb05a4015b

   if($r1Guid -eq "BAT"){
            
    
    try{
            write-host "__________________________"
            $chunks =  $block/$LogicalSectorSize
            write-host "Nr of Chunks: $($chunks)" -f DarkYellow
            
            $chunkratio = (([Math]::Pow(2,13) *$LogicalSectorSize)/$block)
            write-host "Chunk Ratio: $([math]::Ceiling($chunkratio))" -f DarkYellow
            
            $datablocksCount =  [math]::Ceiling($VirtualDiskSize/$block)
            write-host "Data blocks count = $(($datablocksCount))" -f DarkYellow
            
            $SectorBitmapBlocks = [math]::Ceiling($datablocksCount/$chunkratio)
            write-host "Sector Bitmap Blocks = $(($SectorBitmapBlocks))" -f DarkYellow
            
            $TotalBATentries = $datablocksCount * ([math]::floor(($datablocksCount-1)/$chunkratio))
            Write-host "Total BAT entries (Dynamic): $($TotalBATentries)" -f DarkYellow
            
            $TotalBATentries2= $SectorBitmapBlocks*($chunkratio+1)
            Write-host "Total BAT entries (Differencing): $($TotalBATentries2)" -f DarkYellow

            write-host "__________________________"
            }
       catch{write-host "BAT section before Metadata ?? WTF" -f Red;Exit}
    $bat1offsets =   foreach($_b in (0..($datablocksCount-1))){
            
            $bat = $Fcontent.substring($r1FileOffset+8*$_b, 8)
            $batd = [System.Text.Encoding]::getencoding(28591).GetBytes($bat)
            [array]::reverse($batd)
            $bath = [System.BitConverter]::ToString($batd) -replace '-',''
            #Write-Host "BAT entry $($_b) = $($bath)" -f gray
            $batn = [Convert]::ToUInt64($bath,16)
            $batdb = [Convert]::ToString($batn,2).padleft(64,'0')
            #write-host "BAT entry $($_b) = $($batdb)" -f gray

            # A - State
            $b1state = [Convert]::ToUInt32($batdb[61]+$batdb[62]+$batdb[63],2)
             
            $payload1state = if($b1state -eq 6){"PAYLOAD_BLOCK_FULLY_PRESENT"}
            elseif($b1state -eq 0){"PAYLOAD_BLOCK_NOT_PRESENT"} 
            elseif($b1state -eq 1){"PAYLOAD_BLOCK_UNDEFINED"}
            elseif($b1state -eq 2){"PAYLOAD_BLOCK_ZERO"}
            elseif($b1state -eq 3){"PAYLOAD_BLOCK_UNMAPPED"}
            elseif($b1state -eq 7){"PAYLOAD_BLOCK_PARTIALLY_PRESENT"}
            else{$b1state}
            
        
            # FileOffsetMB 
            $batoffset = [Convert]::ToUInt64($bath,16) -shr 20
            
            [PSCustomObject]@{
            Entry_Nr      = $_b
            Payload_State = $payload1state
            Offset        = "$($batoffset) Mb"
             }
            #write-host "_________________________"
            } # #end bat loop
            } # end if

} #end foreach

$bat1offsets|Format-Table
# Should we dump the Payload?
# Check freeSpace
$frees = (gwmi Win32_LogicalDisk -Filter "DeviceID='$(((Get-ItemProperty $env:Temp).Parent.Name).trim("\"))'").freespace
if($frees -gt $VirtualDiskSize){


$msgBoxInput = [System.Windows.Forms.MessageBox]::Show($this,"Would you like to extract & save the Payload blocks as a RAW image file in $($Env:Temp)?

Disk Size needed: $($VirtualDiskSize/1024/1024)Mb
Disk size available: $([math]::floor($frees/1024/1024))Mb
",'VHDX','YesNo','Question')
switch  ($msgBoxInput) {

  'Yes' {

if(!!$bat1offsets){
# Dump payload data to file
$Stream = New-Object System.IO.FileStream -ArgumentList $vhdx, 'Open', 'Read'
$BinaryReader  = New-Object System.IO.BinaryReader  -ArgumentList $Stream, $Encoding
$outfile = "$($env:TEMP)\vhdx_$($snow)_data.img"
$streamWriter = New-Object System.IO.StreamWriter -ArgumentList ($outfile,$true, $Encoding)

foreach($o in ($bat1offsets)){
            if($o.Payload_State -match "PAYLOAD_BLOCK_FULLY_PRESENT"){
            # reset $data
            $data = $null
            # Set offset to read from the file
            $BinaryReader.BaseStream.Position = [UInt64]($o.offset.TrimEnd(" Mb"))*1024*1024
            # Initialize the buffer to be save size as the data block
            $buffer = [System.Byte[]]::new($block)
            # Read each offset to the buffer
                try{
                [Void]$BinaryReader.Read($buffer,0,$block)
                # Convert the buffer data to byte
                $data = [System.Text.Encoding]::GetEncoding(28591).getstring($buffer)
                }
                catch{write-host "Problem reading offset $($o.offset)" -f Red}
                }
            elseif($o.Payload_State -in ("PAYLOAD_BLOCK_ZERO")) # "PAYLOAD_BLOCK_NOT_PRESENT",
            {
            # insert a block full of 0x00 for the Payload block with Zero size
            $data = [System.Text.Encoding]::GetEncoding(28591).getstring($buffer)
            write-host "**** Data block $($o.Entry_Nr) is Zero, so we are adding a $($block/1024/1024)Mb block padded with 0x00" -f Cyan
            }
            else{
            $data = $null
            }
            if($o.Entry_Nr -eq 0){
            write-host "**** Saving Payload Data (#Entry: $($o.Entry_Nr) - Offset:$($o.offset) - State: $($o.Payload_State)) from VHDX to: '$($env:TEMP)\vhdx_$($snow)_data.img'" -f Green
            }else{
            write-host "**** Appending Payload Data (#Entry: $($o.Entry_Nr) - Offset:$($o.offset) - State: $($o.Payload_State))" -f Green
            }
            # Write block to Image file
            $streamWriter.write($data)
            
            }
            $streamWriter.close()
            $buffer.Clear()
            $BinaryReader.Close()
            $Stream.Close()
            [gc]::Collect()	
} 
  }
  'No' {
  Continue
  }
}
}
else{
Write-Host "Available disk space on $((Get-ItemProperty $env:Temp).Parent.Name) is: $($frees) bytes" -f DarkYellow
Write-Host "Virtual Disk size is: $($VirtualDiskSize)" -f DarkYellow
}

###############################################

# region table 2
$hrftr2 = $Fcontent.substring(256*1024, 4)
$hrftr2b = [System.Text.Encoding]::getencoding(28591).GetBytes($hrftr2)
$hrftr2h = [System.BitConverter]::ToString($hrftr2b) -replace '-',''
if($hrftr2h -match "72656769"){write-host "Region Table 2 signature is '$([System.Text.Encoding]::Utf8.GetString($hrftr2b))'" -f cyan}
else{write-host $hrftr2h}

# region table 2 - Checksum
$hrftr2c = $Fcontent.substring(192*1024+4, 4)
$hrftr2cb = [System.Text.Encoding]::getencoding(28591).GetBytes($hrftr2c)
$hrftr2ch = [System.BitConverter]::ToString($hrftr2cb) -replace '-',''
write-host "Region 2 Checksum = $($hrftr2ch)" -f cyan

# region table 2 - EntryCount 
$hrftr2ec = $Fcontent.substring(192*1024+8, 4)
$hrftr2ecb = [System.Text.Encoding]::getencoding(28591).GetBytes($hrftr2ec)
[array]::reverse($hrftr2ecb)
$hrftr2ech = [System.BitConverter]::ToString($hrftr2ecb) -replace '-',''
$r2EntryCount = [Convert]::ToUInt64($hrftr2ech)
write-host "Region 2 EntryCount = $($r2EntryCount)" -f cyan

foreach($r2e in (0..($r2EntryCount-1))){

    # Guid 
    $r2eg = $Fcontent.substring(256*1024+16+(32*$r2e), 16)
    $r2egb = [System.Text.Encoding]::getencoding(28591).GetBytes($r2eg)
    $r2EntryGuid = [System.BitConverter]::ToString($r2egb) -replace '-',''
        if($r2EntryGuid -match "6677C22D23F600429D64115E9BFD4A08"){
    $r2Guid = "BAT"
    write-host "Region 2 Entry $($r2e+1) = Block Allocation Table" -f Green}
    elseif($r2EntryGuid -match "06A27C8B90479A4BB8FE575F050F886E"){
    $r2Guid = "Metadata"
    write-host "Region 2 Entry $($r2e+1) = Metadata Region" -f Green}
    else{Write-Host $r2EntryGuid }

    # FileOffset
    $r2fo = $Fcontent.substring(256*1024+16+(32*$r2e)+16, 8)
    $r2fob = [System.Text.Encoding]::getencoding(28591).GetBytes($r2fo)
    [array]::reverse($r2fob)
    $r2foh = [System.BitConverter]::ToString($r2fob) -replace '-',''
    $r2FileOffset = [Convert]::ToUInt64($r2foh,16)
    write-host "Region 2 Entry $($r2e+1) offset is $($r2FileOffset) dec or 0x$($r2foh)" -f white

    # Length
    $r2l = $Fcontent.substring(256*1024+16+(32*$r2e)+24, 4)
    $r2lb = [System.Text.Encoding]::getencoding(28591).GetBytes($r2l)
    [array]::reverse($r1lb)
    $r2lh = [System.BitConverter]::ToString($r2lb) -replace '-',''
    $r2Length = [Convert]::ToUInt64($r2lh,16)
    write-host "Region 2 Entry $($r2e+1) size is $($r2Length)" -f white

    # Required 
    $r2r = $Fcontent.substring(256*1024+16+(32*$r2e)+28, 4)
    $r2rb = [System.Text.Encoding]::getencoding(28591).GetBytes($r2r)
    [array]::reverse($r2rb)
    $r2rh = [System.BitConverter]::ToString($r2rb) -replace '-',''
    $r2required = [Convert]::ToUInt32($r2rh,16)
    if($r2required -eq 1){write-host "Required to load the VHDX" -f white}
    else{write-host  "Not required ($($r2required))"}

        # Read Metadata entry 
     if($r2Guid -eq "Metadata"){

                # Metadata Header (32bytes)
                # Metadata - Signature
                $ms = $Fcontent.substring($r2FileOffset, 8)
                if($ms -match "metadata"){write-host $ms -f DarkYellow}

                # Metadata - Entry Count 
                $mec = $Fcontent.substring($r2FileOffset+10, 2)
                $mecb = [System.Text.Encoding]::getencoding(28591).GetBytes($mec)
                [array]::reverse($mecb)
                $mech = [System.BitConverter]::ToString($mecb) -replace '-',''
                $metaentrycount = [Convert]::ToUInt32($mech,16)
                Write-Host "Metadata entries: $($metaentrycount)" -f DarkYellow


                # Metadata entries ( 128-bit identifier for the metadata item)
                foreach ($_m in (0..($metaentrycount-1))){
                # ItemID
                $ii = $Fcontent.substring($r2FileOffset+32+32*$_m, 16)
                $iib = [System.Text.Encoding]::getencoding(28591).GetBytes($ii)
                [array]::reverse($iib)
                $itemid  = [System.BitConverter]::ToString($iib) -replace '-',''
                #write-host "Entry $($_m+1) - itemid = $($itemid)" -f Yellow

                write-host "__________________________"
                $knownitem = if($itemid -match "6BE744AAF033B6B34D43FA36CAA16737"){"File Parameters"}
                elseif($itemid -match "B8F43BD8BE5D11B24876CD1B2FA54224"){"Virtual Disk Size"}
                elseif($itemid -match "5FABFAA833F247BA4709A96F8141BF1D"){"Logical Sector Size"}
                elseif($itemid -match "56C5515288E9C99C4471445DCDA348C7"){"Physical Sector Size"}
                elseif($itemid -match "46C700E009C3EF934523B2E6BECA12AB"){"Virtual Disk ID"}
                elseif($itemid -match "0CAB3448D8D3F7AB454DB30BA8D35F2D"){"Parent Locator"}
                write-host Entry $($_m+1) - $($knownitem) -f Yellow
            
                # Offset
                # the Offset field MUST be at least 64 KB and is relative to the beginning of the metadata region
                $io = $Fcontent.substring($r2FileOffset+32+32*$_m +16, 4)
                $iob = [System.Text.Encoding]::getencoding(28591).GetBytes($io)
                [array]::reverse($iob)
                $ioh = [System.BitConverter]::ToString($iob) -replace '-',''
                $itemoffset = [Convert]::ToUInt32($ioh,16)
                write-host "Item Offset (dec) = $($itemoffset+$r2FileOffset) " -f Magenta

                # Length
                $mil = $Fcontent.substring($r2FileOffset+32+32*$_m +20, 4)
                $milb = [System.Text.Encoding]::getencoding(28591).GetBytes($mil)
                [array]::reverse($milb)
                $milh = [System.BitConverter]::ToString($milb) -replace '-',''
                $itemlength = [Convert]::ToUInt32($milh,16)
                write-host "Item Length = $($itemlength)" -f Magenta
            
                #  Read next byte ..
                $0 = $Fcontent.substring($r2FileOffset+32+32*$_m +24, 1)
                $0b = [System.Text.Encoding]::getencoding(28591).GetBytes($0)
                #[array]::reverse($0b)
                $1 = [System.BitConverter]::ToString($0b) -replace '-', ''
                $2 = [Convert]::ToString($1,2).padleft(8,'0')

                    # IsUser
                    if($2[7] -match 1){$isuser = "User Metadata"}
                    else{$isuser = "System Metadata"}
                    write-host $isuser -f Gray
            
                    # IsVirtualDisk 
                    if($2[6] -match 0
                    ){$IsVirtualDisk = "File Metadata"}
                    else{$IsVirtualDisk = "Virtual Disk Metadata"}
                     write-host $IsVirtualDisk -f Gray

                    # IsRequired  
                    if($2[5] -match 0){$IsRequired = "not required for vhdx"}
                    else{$IsRequired = "Required for vhdx"}
                    write-host $IsRequired -f Gray

                    # Read the metadata data
                    $md = $Fcontent.substring($r2FileOffset+$itemoffset,$itemlength)
               
                   if($knownitem -eq "File Parameters"){
                   # BlockSize
                   $bs = $Fcontent.substring($r2FileOffset+$itemoffset,4)
                   $bsb = [System.Text.Encoding]::getencoding(28591).GetBytes($bs)
                   [array]::reverse($bsb)
                   $bsh = [System.BitConverter]::ToString($bsb) -replace '-', ''
                   $block = [Convert]::ToUInt32($bsh,16)
                   write-host "Block size = $($block)"
               
                   # Bits
                   $bb = $Fcontent.substring($r2FileOffset+$itemoffset+4,1)
                   $bbd = [System.Text.Encoding]::getencoding(28591).GetBytes($bb)
                   [array]::reverse($bbd)
                   $bbits = [Convert]::ToString($bbd[0],2).padleft(8,'0')
               
                   # LeaveBlockAllocated
                   # https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-vhdx/ec0e9d25-69e4-439e-806a-e0c23f0e1ae6
                   # https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-vhdx/af7334e6-ad2c-4378-9b81-afc1334a6ee7
                   if($bbits[7] -match 1){Write-Host "--------> Fixed Size VHDX" -f Yellow}else
                   {write-host "--------> Dynamic/differencing size VHDX" -f Yellow}
               
                   # HasParent
                   if($bbits[6] -match 1){Write-Host "the file is a differencing file"}
                   } # end file parameters

                   if($knownitem -eq "Virtual Disk Size"){
                   # VirtualDiskSize 
                   $vds = $Fcontent.substring($r2FileOffset+$itemoffset,8)
                   $vdsb = [System.Text.Encoding]::getencoding(28591).GetBytes($vds)
                   [array]::reverse($vdsb)
                   $vdsh = [System.BitConverter]::ToString($vdsb) -replace '-', ''
                   $VirtualDiskSize = [Convert]::ToUInt64($vdsh,16)
                   write-host "Virtual Disk Size = $($VirtualDiskSize/1024/1024)Mb"

                   }# end Virtual Disk Size

                   if($knownitem -eq "Virtual Disk ID"){
                   # Virtual Disk ID 
                   $vdid = $Fcontent.substring($r2FileOffset+$itemoffset,16)
                   $vdidb = [System.Text.Encoding]::getencoding(28591).GetBytes($vdid)
                   $vdGuid = [System.BitConverter]::ToString($vdidb) -replace '-',''
                   write-host "Virtual Disk ID = $vdGuid" 


                   }# end Virtual Disk ID

                   if($knownitem -eq "Logical Sector Size"){
                   # Logical Sector Size 
                   $lss = $Fcontent.substring($r2FileOffset+$itemoffset,4)
                   $lssb = [System.Text.Encoding]::getencoding(28591).GetBytes($lss)
                   [array]::reverse($lssb)
                   $lssh = [System.BitConverter]::ToString($lssb) -replace '-',''
                   $LogicalSectorSize = [Convert]::ToUInt64($lssh,16)
                   write-host "Logical Sector Size = $($LogicalSectorSize)"
               
                   }# end Logical Sector Size

                   if($knownitem -eq "Physical Sector Size"){
                   # Physical Sector Size 
                   $pss = $Fcontent.substring($r2FileOffset+$itemoffset,4)
                   $pssb = [System.Text.Encoding]::getencoding(28591).GetBytes($lss)
                   [array]::reverse($pssb)
                   $pssh = [System.BitConverter]::ToString($pssb) -replace '-',''
                   $PhysicalSectorSize = [Convert]::ToUInt64($pssh,16)
                   write-host "Physical Sector Size = $($PhysicalSectorSize)"
               
                   }# end Physical Sector Size


                }
                write-host "__________________________"
            } # End Metadata

        
        # Read Bat entry (array of 64-bit values)
        # https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-vhdx/a84d19eb-b843-4c6c-9aca-fbfb05a4015b
        if($r2Guid -eq "BAT"){

                $bat2offsets = foreach($_b2 in (0..($datablocksCount-1))){
            
                $bat = $Fcontent.substring($r2FileOffset+8*$_b2, 8)
                $batd = [System.Text.Encoding]::getencoding(28591).GetBytes($bat)
                [array]::reverse($batd)
                $bath = [System.BitConverter]::ToString($batd) -replace '-',''
                $batn = [Convert]::ToUInt64($bath,16)
                $batdb = [Convert]::ToString($batn,2).padleft(64,'0')
                # write-host "BAT entry $($_b+1) = $($batdb)" -f gray


                # A - State
                $b2state = [Convert]::ToUInt32($batdb[61]+$batdb[62]+$batdb[63],2)
                
                $payload2State = if($b2state -eq 6){ "PAYLOAD_BLOCK_FULLY_PRESENT"}
                elseif($b2state -eq 0){"PAYLOAD_BLOCK_NOT_PRESENT"} 
                elseif($b2state -eq 1){"PAYLOAD_BLOCK_UNDEFINED"}
                elseif($b2state -eq 2){"PAYLOAD_BLOCK_ZERO"}
                elseif($b2state -eq 3){"PAYLOAD_BLOCK_UNMAPPED"}
                elseif($b2state -eq 7){"PAYLOAD_BLOCK_PARTIALLY_PRESENT"}
                else{$b2state}
        
                # FileOffsetMB 
                $batoffset = [Convert]::ToUInt64($bath,16) -shr 20
                
                [PSCustomObject]@{
                
                Payload_Entry_Nr  = $_b2
                State             = $payload2State
                Offset            = "$($batoffset) Mb"
                }

                } # #end bat loop
                } # end if

} #end foreach
$bat2offsets#Format-Table

[gc]::Collect()	
# Stop Transcript
Stop-Transcript 
# Open output folder
Invoke-Item $env:TEMP
# SIG # Begin signature block
# MIIfcAYJKoZIhvcNAQcCoIIfYTCCH10CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAR4fe1QTjThi7A
# nMWR3jYXvHkSnIIerVJMwsC0GitLWaCCGf4wggQVMIIC/aADAgECAgsEAAAAAAEx
# icZQBDANBgkqhkiG9w0BAQsFADBMMSAwHgYDVQQLExdHbG9iYWxTaWduIFJvb3Qg
# Q0EgLSBSMzETMBEGA1UEChMKR2xvYmFsU2lnbjETMBEGA1UEAxMKR2xvYmFsU2ln
# bjAeFw0xMTA4MDIxMDAwMDBaFw0yOTAzMjkxMDAwMDBaMFsxCzAJBgNVBAYTAkJF
# MRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNhMTEwLwYDVQQDEyhHbG9iYWxTaWdu
# IFRpbWVzdGFtcGluZyBDQSAtIFNIQTI1NiAtIEcyMIIBIjANBgkqhkiG9w0BAQEF
# AAOCAQ8AMIIBCgKCAQEAqpuOw6sRUSUBtpaU4k/YwQj2RiPZRcWVl1urGr/SbFfJ
# MwYfoA/GPH5TSHq/nYeer+7DjEfhQuzj46FKbAwXxKbBuc1b8R5EiY7+C94hWBPu
# TcjFZwscsrPxNHaRossHbTfFoEcmAhWkkJGpeZ7X61edK3wi2BTX8QceeCI2a3d5
# r6/5f45O4bUIMf3q7UtxYowj8QM5j0R5tnYDV56tLwhG3NKMvPSOdM7IaGlRdhGL
# D10kWxlUPSbMQI2CJxtZIH1Z9pOAjvgqOP1roEBlH1d2zFuOBE8sqNuEUBNPxtyL
# ufjdaUyI65x7MCb8eli7WbwUcpKBV7d2ydiACoBuCQIDAQABo4HoMIHlMA4GA1Ud
# DwEB/wQEAwIBBjASBgNVHRMBAf8ECDAGAQH/AgEAMB0GA1UdDgQWBBSSIadKlV1k
# sJu0HuYAN0fmnUErTDBHBgNVHSAEQDA+MDwGBFUdIAAwNDAyBggrBgEFBQcCARYm
# aHR0cHM6Ly93d3cuZ2xvYmFsc2lnbi5jb20vcmVwb3NpdG9yeS8wNgYDVR0fBC8w
# LTAroCmgJ4YlaHR0cDovL2NybC5nbG9iYWxzaWduLm5ldC9yb290LXIzLmNybDAf
# BgNVHSMEGDAWgBSP8Et/qC5FJK5NUPpjmove4t0bvDANBgkqhkiG9w0BAQsFAAOC
# AQEABFaCSnzQzsm/NmbRvjWek2yX6AbOMRhZ+WxBX4AuwEIluBjH/NSxN8RooM8o
# agN0S2OXhXdhO9cv4/W9M6KSfREfnops7yyw9GKNNnPRFjbxvF7stICYePzSdnno
# 4SGU4B/EouGqZ9uznHPlQCLPOc7b5neVp7uyy/YZhp2fyNSYBbJxb051rvE9ZGo7
# Xk5GpipdCJLxo/MddL9iDSOMXCo4ldLA1c3PiNofKLW6gWlkKrWmotVzr9xG2wSu
# kdduxZi61EfEVnSAR3hYjL7vK/3sbL/RlPe/UOB74JD9IBh4GCJdCC6MHKCX8x2Z
# faOdkdMGRE4EbnocIOM28LZQuTCCBMYwggOuoAMCAQICDCRUuH8eFFOtN/qheDAN
# BgkqhkiG9w0BAQsFADBbMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFsU2ln
# biBudi1zYTExMC8GA1UEAxMoR2xvYmFsU2lnbiBUaW1lc3RhbXBpbmcgQ0EgLSBT
# SEEyNTYgLSBHMjAeFw0xODAyMTkwMDAwMDBaFw0yOTAzMTgxMDAwMDBaMDsxOTA3
# BgNVBAMMMEdsb2JhbFNpZ24gVFNBIGZvciBNUyBBdXRoZW50aWNvZGUgYWR2YW5j
# ZWQgLSBHMjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBANl4YaGWrhL/
# o/8n9kRge2pWLWfjX58xkipI7fkFhA5tTiJWytiZl45pyp97DwjIKito0ShhK5/k
# Ju66uPew7F5qG+JYtbS9HQntzeg91Gb/viIibTYmzxF4l+lVACjD6TdOvRnlF4RI
# shwhrexz0vOop+lf6DXOhROnIpusgun+8V/EElqx9wxA5tKg4E1o0O0MDBAdjwVf
# ZFX5uyhHBgzYBj83wyY2JYx7DyeIXDgxpQH2XmTeg8AUXODn0l7MjeojgBkqs2Iu
# YMeqZ9azQO5Sf1YM79kF15UgXYUVQM9ekZVRnkYaF5G+wcAHdbJL9za6xVRsX4ob
# +w0oYciJ8BUCAwEAAaOCAagwggGkMA4GA1UdDwEB/wQEAwIHgDBMBgNVHSAERTBD
# MEEGCSsGAQQBoDIBHjA0MDIGCCsGAQUFBwIBFiZodHRwczovL3d3dy5nbG9iYWxz
# aWduLmNvbS9yZXBvc2l0b3J5LzAJBgNVHRMEAjAAMBYGA1UdJQEB/wQMMAoGCCsG
# AQUFBwMIMEYGA1UdHwQ/MD0wO6A5oDeGNWh0dHA6Ly9jcmwuZ2xvYmFsc2lnbi5j
# b20vZ3MvZ3N0aW1lc3RhbXBpbmdzaGEyZzIuY3JsMIGYBggrBgEFBQcBAQSBizCB
# iDBIBggrBgEFBQcwAoY8aHR0cDovL3NlY3VyZS5nbG9iYWxzaWduLmNvbS9jYWNl
# cnQvZ3N0aW1lc3RhbXBpbmdzaGEyZzIuY3J0MDwGCCsGAQUFBzABhjBodHRwOi8v
# b2NzcDIuZ2xvYmFsc2lnbi5jb20vZ3N0aW1lc3RhbXBpbmdzaGEyZzIwHQYDVR0O
# BBYEFNSHuI3m5UA8nVoGY8ZFhNnduxzDMB8GA1UdIwQYMBaAFJIhp0qVXWSwm7Qe
# 5gA3R+adQStMMA0GCSqGSIb3DQEBCwUAA4IBAQAkclClDLxACabB9NWCak5BX87H
# iDnT5Hz5Imw4eLj0uvdr4STrnXzNSKyL7LV2TI/cgmkIlue64We28Ka/GAhC4evN
# GVg5pRFhI9YZ1wDpu9L5X0H7BD7+iiBgDNFPI1oZGhjv2Mbe1l9UoXqT4bZ3hcD7
# sUbECa4vU/uVnI4m4krkxOY8Ne+6xtm5xc3NB5tjuz0PYbxVfCMQtYyKo9JoRbFA
# uqDdPBsVQLhJeG/llMBtVks89hIq1IXzSBMF4bswRQpBt3ySbr5OkmCCyltk5lXT
# 0gfenV+boQHtm/DDXbsZ8BgMmqAc6WoICz3pZpendR4PvyjXCSMN4hb6uvM0MIIF
# PDCCBCSgAwIBAgIRALjpohQ9sxfPAIfj9za0FgUwDQYJKoZIhvcNAQELBQAwfDEL
# MAkGA1UEBhMCR0IxGzAZBgNVBAgTEkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4GA1UE
# BxMHU2FsZm9yZDEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMSQwIgYDVQQDExtT
# ZWN0aWdvIFJTQSBDb2RlIFNpZ25pbmcgQ0EwHhcNMjAwMjIwMDAwMDAwWhcNMjIw
# MjE5MjM1OTU5WjCBrDELMAkGA1UEBhMCR1IxDjAMBgNVBBEMBTU1NTM1MRUwEwYD
# VQQIDAxUaGVzc2Fsb25pa2kxDzANBgNVBAcMBlB5bGFpYTEbMBkGA1UECQwSMzIg
# Qml6YW5pb3UgU3RyZWV0MSMwIQYDVQQKDBpLYXRzYXZvdW5pZGlzIEtvbnN0YW50
# aW5vczEjMCEGA1UEAwwaS2F0c2F2b3VuaWRpcyBLb25zdGFudGlub3MwggEiMA0G
# CSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDa2C7McRZbPAGLVPCcYCmhqbVRVGBV
# JXZhqJKFbJA95o2z4AiyB7C/cQGy1F3c3jW9Balp3uESAsy6JrJI+g62vxzk6chx
# tcre1PPnjqdcDQyetHRA7ZseDnFhk6DvxDR0emBHmdycAjWq3kACWwkKQADyuQ3D
# 6MxRhG3InKkv+e1OjVjW8zJobo8wxfVVrxDML8TIOu2QzgpCMf67gcFtzhtkNYKO
# 0ukSgVZ4YXrv8tenw5jLxR9Yv5RKGE1yXzafUy17RsxsEIEZx2IGBxmSF2HJCSbW
# vEXtcVslnzmttRS+tyNBxnXB/NK8Zf2h189414mjZy/pfUmTMQwcZOKdAgMBAAGj
# ggGGMIIBgjAfBgNVHSMEGDAWgBQO4TqoUzox1Yq+wbutZxoDha00DjAdBgNVHQ4E
# FgQUH9X2tKd+540Ixy1znv3RfwoyR9cwDgYDVR0PAQH/BAQDAgeAMAwGA1UdEwEB
# /wQCMAAwEwYDVR0lBAwwCgYIKwYBBQUHAwMwEQYJYIZIAYb4QgEBBAQDAgQQMEAG
# A1UdIAQ5MDcwNQYMKwYBBAGyMQECAQMCMCUwIwYIKwYBBQUHAgEWF2h0dHBzOi8v
# c2VjdGlnby5jb20vQ1BTMEMGA1UdHwQ8MDowOKA2oDSGMmh0dHA6Ly9jcmwuc2Vj
# dGlnby5jb20vU2VjdGlnb1JTQUNvZGVTaWduaW5nQ0EuY3JsMHMGCCsGAQUFBwEB
# BGcwZTA+BggrBgEFBQcwAoYyaHR0cDovL2NydC5zZWN0aWdvLmNvbS9TZWN0aWdv
# UlNBQ29kZVNpZ25pbmdDQS5jcnQwIwYIKwYBBQUHMAGGF2h0dHA6Ly9vY3NwLnNl
# Y3RpZ28uY29tMA0GCSqGSIb3DQEBCwUAA4IBAQBbQmN6mJ6/Ff0c3bzLtKFKxbXP
# ZHjHTxB74mqp38MGdhMfPsQ52I5rH9+b/d/6g6BKJnTz293Oxcoa29+iRuwljGbv
# /kkjM80iALnorUQsk+RA+jCJ9XTqUbiWtb2Zx828GoCE8OJ1EyAozVVEA4bcu+nc
# cAFDd78YGyguDMHaYfnWjA2R2HkT4nYSu2u80+FeRuodmnB2dcM89k0a+XjuhDuG
# 8DJRcI2tjRZnR7geRHwVEFFPc/ZdAjRaFpAUgEArCWoIHAMtIf0W/fdtXrbdIeg9
# ibmcGiFH70Q/VvaXoDx+9qYLeYvEtAAEiHflfFElV2WIC+N47DLZxpkO7D68MIIF
# 3jCCA8agAwIBAgIQAf1tMPyjylGoG7xkDjUDLTANBgkqhkiG9w0BAQwFADCBiDEL
# MAkGA1UEBhMCVVMxEzARBgNVBAgTCk5ldyBKZXJzZXkxFDASBgNVBAcTC0plcnNl
# eSBDaXR5MR4wHAYDVQQKExVUaGUgVVNFUlRSVVNUIE5ldHdvcmsxLjAsBgNVBAMT
# JVVTRVJUcnVzdCBSU0EgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkwHhcNMTAwMjAx
# MDAwMDAwWhcNMzgwMTE4MjM1OTU5WjCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgT
# Ck5ldyBKZXJzZXkxFDASBgNVBAcTC0plcnNleSBDaXR5MR4wHAYDVQQKExVUaGUg
# VVNFUlRSVVNUIE5ldHdvcmsxLjAsBgNVBAMTJVVTRVJUcnVzdCBSU0EgQ2VydGlm
# aWNhdGlvbiBBdXRob3JpdHkwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoIC
# AQCAEmUXNg7D2wiz0KxXDXbtzSfTTK1Qg2HiqiBNCS1kCdzOiZ/MPans9s/B3PHT
# sdZ7NygRK0faOca8Ohm0X6a9fZ2jY0K2dvKpOyuR+OJv0OwWIJAJPuLodMkYtJHU
# YmTbf6MG8YgYapAiPLz+E/CHFHv25B+O1ORRxhFnRghRy4YUVD+8M/5+bJz/Fp0Y
# vVGONaanZshyZ9shZrHUm3gDwFA66Mzw3LyeTP6vBZY1H1dat//O+T23LLb2VN3I
# 5xI6Ta5MirdcmrS3ID3KfyI0rn47aGYBROcBTkZTmzNg95S+UzeQc0PzMsNT79uq
# /nROacdrjGCT3sTHDN/hMq7MkztReJVni+49Vv4M0GkPGw/zJSZrM233bkf6c0Pl
# fg6lZrEpfDKEY1WJxA3Bk1QwGROs0303p+tdOmw1XNtB1xLaqUkL39iAigmTYo61
# Zs8liM2EuLE/pDkP2QKe6xJMlXzzawWpXhaDzLhn4ugTncxbgtNMs+1b/97lc6wj
# Oy0AvzVVdAlJ2ElYGn+SNuZRkg7zJn0cTRe8yexDJtC/QV9AqURE9JnnV4eeUB9X
# VKg+/XRjL7FQZQnmWEIuQxpMtPAlR1n6BB6T1CZGSlCBst6+eLf8ZxXhyVeEHg9j
# 1uliutZfVS7qXMYoCAQlObgOK6nyTJccBz8NUvXt7y+CDwIDAQABo0IwQDAdBgNV
# HQ4EFgQUU3m/WqorSs9UgOHYm8Cd8rIDZsswDgYDVR0PAQH/BAQDAgEGMA8GA1Ud
# EwEB/wQFMAMBAf8wDQYJKoZIhvcNAQEMBQADggIBAFzUfA3P9wF9QZllDHPFUp/L
# +M+ZBn8b2kMVn54CVVeWFPFSPCeHlCjtHzoBN6J2/FNQwISbxmtOuowhT6KOVWKR
# 82kV2LyI48SqC/3vqOlLVSoGIG1VeCkZ7l8wXEskEVX/JJpuXior7gtNn3/3ATiU
# FJVDBwn7YKnuHKsSjKCaXqeYalltiz8I+8jRRa8YFWSQEg9zKC7F4iRO/Fjs8PRF
# /iKz6y+O0tlFYQXBl2+odnKPi4w2r78NBc5xjeambx9spnFixdjQg3IM8WcRiQyc
# E0xyNN+81XHfqnHd4blsjDwSXWXavVcStkNr/+XeTWYRUc+ZruwXtuhxkYzeSf7d
# NXGiFSeUHM9h4ya7b6NnJSFd5t0dCy5oGzuCr+yDZ4XUmFF0sbmZgIn/f3gZXHlK
# YC6SQK5MNyosycdiyA5d9zZbyuAlJQG03RoHnHcAP9Dc1ew91Pq7P8yF1m9/qS3f
# uQL39ZeatTXaw2ewh0qpKJ4jjv9cJ2vhsE/zB+4ALtRZh8tSQZXq9EfX7mRBVXyN
# WQKV3WKdwrnuWih0hKWbt5DHDAff9Yk2dDLWKMGwsAvgnEzDHNb842m1R0aBL6KC
# q9NjRHDEjf8tM7qtj3u1cIiuPhnPQCjY/MiQu12ZIvVS5ljFH4gxQ+6IHdfGjjxD
# ah2nGN59PRbxYvnKkKj9MIIF9TCCA92gAwIBAgIQHaJIMG+bJhjQguCWfTPTajAN
# BgkqhkiG9w0BAQwFADCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCk5ldyBKZXJz
# ZXkxFDASBgNVBAcTC0plcnNleSBDaXR5MR4wHAYDVQQKExVUaGUgVVNFUlRSVVNU
# IE5ldHdvcmsxLjAsBgNVBAMTJVVTRVJUcnVzdCBSU0EgQ2VydGlmaWNhdGlvbiBB
# dXRob3JpdHkwHhcNMTgxMTAyMDAwMDAwWhcNMzAxMjMxMjM1OTU5WjB8MQswCQYD
# VQQGEwJHQjEbMBkGA1UECBMSR3JlYXRlciBNYW5jaGVzdGVyMRAwDgYDVQQHEwdT
# YWxmb3JkMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0ZWQxJDAiBgNVBAMTG1NlY3Rp
# Z28gUlNBIENvZGUgU2lnbmluZyBDQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCC
# AQoCggEBAIYijTKFehifSfCWL2MIHi3cfJ8Uz+MmtiVmKUCGVEZ0MWLFEO2yhyem
# mcuVMMBW9aR1xqkOUGKlUZEQauBLYq798PgYrKf/7i4zIPoMGYmobHutAMNhodxp
# ZW0fbieW15dRhqb0J+V8aouVHltg1X7XFpKcAC9o95ftanK+ODtj3o+/bkxBXRIg
# CFnoOc2P0tbPBrRXBbZOoT5Xax+YvMRi1hsLjcdmG0qfnYHEckC14l/vC0X/o84X
# pi1VsLewvFRqnbyNVlPG8Lp5UEks9wO5/i9lNfIi6iwHr0bZ+UYc3Ix8cSjz/qfG
# FN1VkW6KEQ3fBiSVfQ+noXw62oY1YdMCAwEAAaOCAWQwggFgMB8GA1UdIwQYMBaA
# FFN5v1qqK0rPVIDh2JvAnfKyA2bLMB0GA1UdDgQWBBQO4TqoUzox1Yq+wbutZxoD
# ha00DjAOBgNVHQ8BAf8EBAMCAYYwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHSUE
# FjAUBggrBgEFBQcDAwYIKwYBBQUHAwgwEQYDVR0gBAowCDAGBgRVHSAAMFAGA1Ud
# HwRJMEcwRaBDoEGGP2h0dHA6Ly9jcmwudXNlcnRydXN0LmNvbS9VU0VSVHJ1c3RS
# U0FDZXJ0aWZpY2F0aW9uQXV0aG9yaXR5LmNybDB2BggrBgEFBQcBAQRqMGgwPwYI
# KwYBBQUHMAKGM2h0dHA6Ly9jcnQudXNlcnRydXN0LmNvbS9VU0VSVHJ1c3RSU0FB
# ZGRUcnVzdENBLmNydDAlBggrBgEFBQcwAYYZaHR0cDovL29jc3AudXNlcnRydXN0
# LmNvbTANBgkqhkiG9w0BAQwFAAOCAgEATWNQ7Uc0SmGk295qKoyb8QAAHh1iezrX
# MsL2s+Bjs/thAIiaG20QBwRPvrjqiXgi6w9G7PNGXkBGiRL0C3danCpBOvzW9Ovn
# 9xWVM8Ohgyi33i/klPeFM4MtSkBIv5rCT0qxjyT0s4E307dksKYjalloUkJf/wTr
# 4XRleQj1qZPea3FAmZa6ePG5yOLDCBaxq2NayBWAbXReSnV+pbjDbLXP30p5h1zH
# QE1jNfYw08+1Cg4LBH+gS667o6XQhACTPlNdNKUANWlsvp8gJRANGftQkGG+OY96
# jk32nw4e/gdREmaDJhlIlc5KycF/8zoFm/lv34h/wCOe0h5DekUxwZxNqfBZslkZ
# 6GqNKQQCd3xLS81wvjqyVVp4Pry7bwMQJXcVNIr5NsxDkuS6T/FikyglVyn7URnH
# oSVAaoRXxrKdsbwcCtp8Z359LukoTBh+xHsxQXGaSynsCz1XUNLK3f2eBVHlRHjd
# Ad6xdZgNVCT98E7j4viDvXK6yz067vBeF5Jobchh+abxKgoLpbn0nu6YMgWFnuv5
# gynTxix9vTp3Los3QqBqgu07SqqUEKThDfgXxbZaeTMYkuO1dfih6Y4KJR7kHvGf
# Wocj/5+kUZ77OYARzdu1xKeogG/lU9Tg46LC0lsa+jImLWpXcBw8pFguo/NbSwfc
# Mlnzh6cabVgxggTIMIIExAIBATCBkTB8MQswCQYDVQQGEwJHQjEbMBkGA1UECBMS
# R3JlYXRlciBNYW5jaGVzdGVyMRAwDgYDVQQHEwdTYWxmb3JkMRgwFgYDVQQKEw9T
# ZWN0aWdvIExpbWl0ZWQxJDAiBgNVBAMTG1NlY3RpZ28gUlNBIENvZGUgU2lnbmlu
# ZyBDQQIRALjpohQ9sxfPAIfj9za0FgUwDQYJYIZIAWUDBAIBBQCgTDAZBgkqhkiG
# 9w0BCQMxDAYKKwYBBAGCNwIBBDAvBgkqhkiG9w0BCQQxIgQgj6cNp9QAYChXeqRU
# qlgOLCs9USwUIuBMejP12U4ibAowDQYJKoZIhvcNAQEBBQAEggEAvcp1TT58+bbz
# DZRMk4xLuEM8wu6LLpsp3QvkbwwwhidpNu6cVLU+TQrRJrWzTlYVmlMBPxxuXDQ5
# ERWrdzbHKD2G0C7gHaOclaDSHR6iACtSkQZX2TVhrccw70/9T2L5FOXszCROGY28
# CMYAcByMXFmZ9wYGSSth4+17Ok/pAM1dd4n1uy7lgOcElY3fT4kLn8xS6olE63gO
# ZY8ptegwbSvnMsVXId7ZPh2kaiFoiN8xtiQlG/VASJAa+zXnxcKWEDJfeiL13NF+
# ekpQ4ywzig6Q+3gBVt78SldYo7uSChueOiCMbqV6D1xX9hoJoLXZHMass3dxaeQf
# 5XymZ/6z06GCArkwggK1BgkqhkiG9w0BCQYxggKmMIICogIBATBrMFsxCzAJBgNV
# BAYTAkJFMRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNhMTEwLwYDVQQDEyhHbG9i
# YWxTaWduIFRpbWVzdGFtcGluZyBDQSAtIFNIQTI1NiAtIEcyAgwkVLh/HhRTrTf6
# oXgwDQYJYIZIAWUDBAIBBQCgggEMMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEw
# HAYJKoZIhvcNAQkFMQ8XDTIwMDMwMTEyMjYwMVowLwYJKoZIhvcNAQkEMSIEIOBD
# 7yQXIPmxLSD5FP8MxCgydcb8bH68xakxnHNeOtXcMIGgBgsqhkiG9w0BCRACDDGB
# kDCBjTCBijCBhwQUPsdm1dTUcuIbHyFDUhwxt5DZS2gwbzBfpF0wWzELMAkGA1UE
# BhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExMTAvBgNVBAMTKEdsb2Jh
# bFNpZ24gVGltZXN0YW1waW5nIENBIC0gU0hBMjU2IC0gRzICDCRUuH8eFFOtN/qh
# eDANBgkqhkiG9w0BAQEFAASCAQBR52V/d2xL8jzljBCX42yHW08jX1RL5zxffVq/
# BqmB+Ohuoy7VCSddcnAi5zZC79KzJRWr+qYwV4xxcb5xqeYsL1td8ew1bny0jvCf
# VuNW+1N1DzcypOH7CdUWeNfONhX5HSa7vRp3vbDfKtlQaBr+MHFWB5IN4daw9ppf
# 83YBHJMMJHZYpi69g60peHcF2n+h0Xl5AkM2NNAS5zot8Xf4hYhHPLPOeKnSUoer
# W9xRaKYszVzMsRwIuK+iXuFp+Rwge+rJoiykC0GrOsGVE1JmOIXXhghcCifui/Ff
# mxsBgLdw36uhtSSe0qFThtnVaNjQdyj0NM1hWOe0QDkSKFaT
# SIG # End signature block
