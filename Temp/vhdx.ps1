# Ref: # https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-vhdx/f0efbb98-f555-4efc-8374-4e77945ad422

# Show an Open File Dialog 
Function Get-FileName($initialDirectory)
{  
[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") |Out-Null
		$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
		$OpenFileDialog.Title = 'Select a vhdx file'
		$OpenFileDialog.initialDirectory = $initialDirectory
		$OpenFileDialog.Filter = "vhdx files (*.vhdx)|*.vhdx|All files (*.*)|*.*"
		$OpenFileDialog.ShowDialog() | Out-Null
		$OpenFileDialog.ShowReadOnly = $true
		$OpenFileDialog.filename
		$OpenFileDialog.ShowHelp = $false
} #end function Get-FileName 

$fPath =  $env:USERPROFILE+"\Desktop\"
$vhdx = Get-FileName -initialDirectory $fPath

#read file
        $Stream = New-Object IO.FileStream -ArgumentList $vhdx, 'Open', 'Read'
		$Encoding = [System.Text.Encoding]::GetEncoding(28591)
		$StreamReader = New-Object IO.StreamReader -ArgumentList $Stream, $Encoding
		$Fcontent = $StreamReader.ReadToEnd()
		$StreamReader.Close()
		$Stream.Close()

# read header

# file type identifier - signature
$hrfts = $Fcontent.substring(0, 8)
if($hrfts -match "vhdxfile"){write-host "This is a $hrfts file" -f Yellow}
else{write-host "not a valid vhdx signature"
break}

# file type identifier - creator
$hrftc = $Fcontent.substring(8, 512)
$hrftcb = [System.Text.Encoding]::getencoding(28591).GetBytes($hrftc)
$creator = [System.Text.Encoding]::Unicode.GetString($hrftcb)
write-host "Creator: $($creator)" -f Cyan

### Headers

# header 1 -signature
$hrfth1 = $Fcontent.substring(64*1024, 4)
$hrfth1b = [System.Text.Encoding]::getencoding(28591).GetBytes($hrfth1)
$hrfth1h = [System.BitConverter]::ToString($hrfth1b) -replace '-',''
if($hrfth1h -match "68656164"){write-host "Header 1 signature is $([System.Text.Encoding]::Utf8.GetString($hrfth1b))" -f White}
else{write-host $hrfth1h}

# header 1 - checksum
$hrfth1c = $Fcontent.substring(64*1024+4, 4)
$hrfth1cb = [System.Text.Encoding]::getencoding(28591).GetBytes($hrfth1c)
$H1_CRC32 = [System.BitConverter]::ToString($hrfth1cb) -replace '-',''
write-host "Checksum = $($H1_CRC32)" -f White

# header 1 - SequenceNumber 
$hrfth1sn = $Fcontent.substring(64*1024+8, 8)
$hrfth1snb = [System.Text.Encoding]::getencoding(28591).GetBytes($hrfth1sn)
[array]::reverse($hrfth1snb)
$hrfth1snh = [System.BitConverter]::ToString($hrfth1snb) -replace '-',''
$h1SequenceNumber = [Convert]::ToUInt64($hrfth1snh,16)
write-host "SequenceNumber = $($h1SequenceNumber)" -f White

# header 1 - FileWriteGuid 
$hrfth1fwg = $Fcontent.substring(64*1024+16, 16)
$hrfth1fwgb = [System.Text.Encoding]::getencoding(28591).GetBytes($hrfth1fwg)
$h1fwguid = [System.BitConverter]::ToString($hrfth1fwgb) -replace '-',''
write-host "FileWriteGuid = {$(([System.Guid]::Parse($h1fwguid)).guid.ToUpper())}" -f White

# header 1 - DataWriteGuid  
$hrfth1dwg = $Fcontent.substring(64*1024+32, 16)
$hrfth1dwgb = [System.Text.Encoding]::getencoding(28591).GetBytes($hrfth1dwg)
$h1DataWriteGuid = [System.BitConverter]::ToString($hrfth1dwgb) -replace '-',''
write-host "DataWriteGuid = {$(([System.Guid]::Parse($h1DataWriteGuid)).guid.ToUpper())}" -f White

# header 1 - LogGuid  
$hrfth1lg = $Fcontent.substring(64*1024+48, 16)
$hrfth1lb = [System.Text.Encoding]::getencoding(28591).GetBytes($hrfth1lg)
$h1LogGuid = [System.BitConverter]::ToString($hrfth1lb) -replace '-',''
write-host "LogGuid = {$(([System.Guid]::Parse($h1LogGuid)).guid.ToUpper())}" -f White

# header 1 - LogVersion  
$hrfth1lv = $Fcontent.substring(64*1024+64, 2)
$hrfth1lvb = [System.Text.Encoding]::getencoding(28591).GetBytes($hrfth1lv)
[array]::reverse($hrfth1lvb)
$hrfth1lvh = [System.BitConverter]::ToString($hrfth1lvb) -replace '-',''
$h1logversion = [Convert]::ToInt32($hrfth1lvh,16)
write-host "LogVersion = $($h1logversion)" -f White

# header 1 - Version   
$hrfth1v = $Fcontent.substring(64*1024+68, 2)
$hrfth1vb = [System.Text.Encoding]::getencoding(28591).GetBytes($hrfth1v)
[array]::reverse($hrfth1vb)
$hrfth1vh = [System.BitConverter]::ToString($hrfth1vb) -replace '-',''
$h1Version = [Convert]::ToInt32($hrfth1vh,16)
write-host "Version  = $($h1Version)" -f White


# header 2 -signature
$hrfth2 = $Fcontent.substring(128*1024, 4)
$hrfth2b = [System.Text.Encoding]::getencoding(28591).GetBytes($hrfth2)
$hrfth2h = [System.BitConverter]::ToString($hrfth2b) -replace '-',''
if($hrfth2h -match "68656164"){write-host "Header 2 signature is $([System.Text.Encoding]::Utf8.GetString($hrfth2b))" -f cyan}
else{write-host $hrfth2h}

# header 2 - checksum
$hrfth2c = $Fcontent.substring(64*1024+4, 4)
$hrfth2cb = [System.Text.Encoding]::getencoding(28591).GetBytes($hrfth2c)
$H2_CRC32 = [System.BitConverter]::ToString($hrfth2cb) -replace '-',''
write-host "Checksum = $($H2_CRC32)" -f cyan

# header 2 - SequenceNumber 
$hrfth2sn = $Fcontent.substring(64*1024+8, 8)
$hrfth2snb = [System.Text.Encoding]::getencoding(28591).GetBytes($hrfth2sn)
[array]::reverse($hrfth2snb)
$hrfth2snh = [System.BitConverter]::ToString($hrfth2snb) -replace '-',''
$h2SequenceNumber = [Convert]::ToUInt64($hrfth2snh,16)
write-host "SequenceNumber = $($h2SequenceNumber)" -f cyan

# header 2 - FileWriteGuid 
$hrfth2fwg = $Fcontent.substring(64*1024+16, 16)
$hrfth2fwgb = [System.Text.Encoding]::getencoding(28591).GetBytes($hrfth2fwg)
$h2fwguid = [System.BitConverter]::ToString($hrfth2fwgb) -replace '-',''
write-host "FileWriteGuid = {$(([System.Guid]::Parse($h2fwguid)).guid.ToUpper())}" -f cyan

# header 1 - DataWriteGuid  
$hrfth2dwg = $Fcontent.substring(64*1024+32, 16)
$hrfth2dwgb = [System.Text.Encoding]::getencoding(28591).GetBytes($hrfth2dwg)
$h2DataWriteGuid = [System.BitConverter]::ToString($hrfth2dwgb) -replace '-',''
write-host "DataWriteGuid = {$(([System.Guid]::Parse($h2DataWriteGuid)).guid.ToUpper())}" -f cyan

# header 1 - LogGuid  
$hrfth2lg = $Fcontent.substring(64*1024+48, 16)
$hrfth2lb = [System.Text.Encoding]::getencoding(28591).GetBytes($hrfth2lg)
$h2LogGuid = [System.BitConverter]::ToString($hrfth2lb) -replace '-',''
write-host "LogGuid = {$(([System.Guid]::Parse($h2LogGuid)).guid.ToUpper())}" -f cyan

# header 2 - LogVersion  
$hrfth2lv = $Fcontent.substring(64*1024+64, 2)
$hrfth2lvb = [System.Text.Encoding]::getencoding(28591).GetBytes($hrfth2lv)
[array]::reverse($hrfth2lvb)
$hrfth2lvh = [System.BitConverter]::ToString($hrfth2lvb) -replace '-',''
$h2logversion = [Convert]::ToInt32($hrfth2lvh,16)
write-host "LogVersion = $($h2logversion)" -f cyan

# header 2 - Version   
$hrfth2v = $Fcontent.substring(64*1024+68, 2)
$hrfth2vb = [System.Text.Encoding]::getencoding(28591).GetBytes($hrfth2v)
[array]::reverse($hrfth2vb)
$hrfth2vh = [System.BitConverter]::ToString($hrfth2vb) -replace '-',''
$h2Version = [Convert]::ToInt32($hrfth2vh,16)
write-host "Version  = $($h2Version)" -f cyan

### Regions

# region table 1 - Signature
$hrftr1 = $Fcontent.substring(192*1024, 4)
$hrftr1b = [System.Text.Encoding]::getencoding(28591).GetBytes($hrftr1)
$hrftr1h = [System.BitConverter]::ToString($hrftr1b) -replace '-',''
if($hrftr1h -match "72656769"){write-host "Region Table 1 signature is $([System.Text.Encoding]::Utf8.GetString($hrftr1b))" -f white}
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


foreach($r1e in (0..($r1EntryCount-1))){

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
write-host "Region 1 Entry $($r1e+1) size is $($r1Length/1024/1024)Mb" -f white

# Required 
$r1r = $Fcontent.substring(192*1024+16+(32*$r1e)+28, 4)
$r1rb = [System.Text.Encoding]::getencoding(28591).GetBytes($r1r)
[array]::reverse($r1rb)
$r1rh = [System.BitConverter]::ToString($r1rb) -replace '-',''
$r1required = [Convert]::ToUInt32($r1rh,16)
if($r1required -eq 1){write-host "Required to load the VHDK" -f white}
else{write-host  "Not required ($($r1required))"}

    # Read Bat entry (array of 64-bit values)
    # https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-vhdx/a84d19eb-b843-4c6c-9aca-fbfb05a4015b
    if($r1Guid -eq "BAT"){
            $bat = $Fcontent.substring($r1FileOffset, 8)
            $batd = [System.Text.Encoding]::getencoding(28591).GetBytes($bat)
            [array]::reverse($batd)
            $bath = [System.BitConverter]::ToString($batd) -replace '-',''
            $batn = [Convert]::ToUInt32($bath,16)
            $batdb = [Convert]::ToString($batn,2).padleft(64,'0')

            write-host "BAT entry = $($batdb)" -f Red

            # to be continued
            # https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-vhdx/a84d19eb-b843-4c6c-9aca-fbfb05a4015b
            }

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
            write-host "Entry $($_m+1) - itemid = $($itemid)" -f Yellow

            $knownitem = if($itemid -match "6BE744AAF033B6B34D43FA36CAA16737"){"File Parameters"}
            elseif($itemid -match "B8F43BD8BE5D11B24876CD1B2FA54224"){"Virtual Disk Size"}
            elseif($itemid -match "5FABFAA833F247BA4709A96F8141BF1D"){"Logical Sector Size"}
            elseif($itemid -match "56C5515288E9C99C4471445DCDA348C7"){"Physical Sector Size"}
            elseif($itemid -match "46C700E009C3EF934523B2E6BECA12AB"){"Virtual Disk ID"}
            elseif($itemid -match "0CAB3448D8D3F7AB454DB30BA8D35F2D"){"Parent Locator"}
            write-host $knownitem -f White
            
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
                if($2[7] -match 0){$isuser = "User Metadata"}
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
               write-host "Block size = $($block/1024/1024)Mb"
               
               # Bits
               $bb = $Fcontent.substring($r1FileOffset+$itemoffset+4,1)
               $bbd = [System.Text.Encoding]::getencoding(28591).GetBytes($bb)
               [array]::reverse($bbd)
               $bbits = [Convert]::ToString($bbd[0],2).padleft(8,'0')
               
               # LeaveBlockAllocated
               if($bbits[7] -match 1){Write-Host "blocks can be unallocated from the file"}
               
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

        }




} #end foreach

# region table 2
$hrftr2 = $Fcontent.substring(256*1024, 4)
$hrftr2b = [System.Text.Encoding]::getencoding(28591).GetBytes($hrftr2)
$hrftr2h = [System.BitConverter]::ToString($hrftr2b) -replace '-',''
if($hrftr2h -match "72656769"){write-host "Region Table 2 signature is $([System.Text.Encoding]::Utf8.GetString($hrftr2b))" -f cyan}
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


# Reserved
#$Fcontent.substring(0+320, 1024-320)
