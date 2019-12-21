# Ref: # https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-vhdx/f0efbb98-f555-4efc-8374-4e77945ad422
Clear-Host
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

# get timestamp for data dump file
$snow = Get-Date -Format FileDateTimeUniversal

try{
#read file
        $Stream = New-Object IO.FileStream -ArgumentList $vhdx, 'Open', 'Read'
		$Encoding = [System.Text.Encoding]::GetEncoding(28591)
		$StreamReader = New-Object IO.StreamReader -ArgumentList $Stream, $Encoding
		$Fcontent = $StreamReader.ReadToEnd()
		$StreamReader.Close()
		$Stream.Close()

#Create log filename
$Logfile = "$($env:Temp)\vhdx_$($snow).log"

# Start transcript
Start-Transcript -path $Logfile
}
catch{
Write-Host "Sorry. Can not read the selected file (ie file in use/not enough memory/etc)" -f Red
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
$hrfth2c = $Fcontent.substring(64*1024+4, 4)
$hrfth2cb = [System.Text.Encoding]::getencoding(28591).GetBytes($hrfth2c)
$H2_CRC32 = [System.BitConverter]::ToString($hrfth2cb) -replace '-',''


# header 2 - SequenceNumber 
$hrfth2sn = $Fcontent.substring(64*1024+8, 8)
$hrfth2snb = [System.Text.Encoding]::getencoding(28591).GetBytes($hrfth2sn)
[array]::reverse($hrfth2snb)
$hrfth2snh = [System.BitConverter]::ToString($hrfth2snb) -replace '-',''
$h2SequenceNumber = [Convert]::ToUInt64($hrfth2snh,16)


# header 2 - FileWriteGuid 
$hrfth2fwg = $Fcontent.substring(64*1024+16, 16)
$hrfth2fwgb = [System.Text.Encoding]::getencoding(28591).GetBytes($hrfth2fwg)
$h2fwguid = [System.BitConverter]::ToString($hrfth2fwgb) -replace '-',''


# header 1 - DataWriteGuid  
$hrfth2dwg = $Fcontent.substring(64*1024+32, 16)
$hrfth2dwgb = [System.Text.Encoding]::getencoding(28591).GetBytes($hrfth2dwg)
$h2DataWriteGuid = [System.BitConverter]::ToString($hrfth2dwgb) -replace '-',''


# header 1 - LogGuid  
$hrfth2lg = $Fcontent.substring(64*1024+48, 16)
$hrfth2lb = [System.Text.Encoding]::getencoding(28591).GetBytes($hrfth2lg)
$h2LogGuid = [System.BitConverter]::ToString($hrfth2lb) -replace '-',''


# header 2 - LogVersion  
$hrfth2lv = $Fcontent.substring(64*1024+64, 2)
$hrfth2lvb = [System.Text.Encoding]::getencoding(28591).GetBytes($hrfth2lv)
[array]::reverse($hrfth2lvb)
$hrfth2lvh = [System.BitConverter]::ToString($hrfth2lvb) -replace '-',''
$h2logversion = [Convert]::ToInt32($hrfth2lvh,16)


# header 2 - Version   
$hrfth2v = $Fcontent.substring(64*1024+68, 2)
$hrfth2vb = [System.Text.Encoding]::getencoding(28591).GetBytes($hrfth2v)
[array]::reverse($hrfth2vb)
$hrfth2vh = [System.BitConverter]::ToString($hrfth2vb) -replace '-',''
$h2Version = [Convert]::ToInt32($hrfth2vh,16)


$main_info = [PSCustomObject]@{
Signature = $hrfts
Creator = $Creator -replace "\x00",""
"Header 1 signature" = [System.Text.Encoding]::Utf8.GetString($hrfth1b)
"Header 1 Checksum" = $H1_CRC32
"Header 1 Sequence Nt" = $h1SequenceNumber
"Header 1 FileWriteGUID" = $h1fwguid.ToUpper()
"Header 1 DataWriteGuid" = $h1DataWriteGuid.ToUpper()
"Header 1 LogGUID" = $h1LogGuid.ToUpper()
"Header 1 LogVersion" = $h1logversion
"Header 1 Version" = $h1version
"Header 2 signature" = [System.Text.Encoding]::Utf8.GetString($hrfth2b)
"Header 2 Checksum" = $H2_CRC32
"Header 2 Sequence Nt" = $h2SequenceNumber
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
            write-host "Nr of chunks: $($chunks)" -f DarkYellow
            $chunkratio = (([Math]::Pow(2,13) *$LogicalSectorSize)/$block)
            write-host "Chunk Ratio: $([math]::Ceiling($chunkratio))" -f DarkYellow
            $datablocksCount =  [math]::Ceiling($VirtualDiskSize/$block)
            write-host "Data blocks count = $(($datablocksCount))" -f DarkYellow
            $SectorBitmapBlocks = [math]::Ceiling($datablocksCount/$chunkratio)
            write-host "Sector Bitmap Blocks = $(($SectorBitmapBlocks))" -f DarkYellow
            $TotalBATentries = $datablocksCount * ([math]::floor(($datablocksCount-1)/$chunkratio))
            Write-host "Total BAT entries: $($TotalBATentries)" -f DarkYellow
            $TotalBATentries2= $SectorBitmapBlocks*([math]::Ceiling($chunkratio)+1)
            Write-host "Total BAT entries: $($TotalBATentries2)" -f DarkYellow

            write-host "__________________________"
            }
       catch{write-host "BAT section before Metadata ?? WTF" -f Red;Exit}
    $bat1offsets =   foreach($_b in (0..($datablocksCount-1))){
            
            $bat = $Fcontent.substring($r1FileOffset+8*$_b, 8)
            $batd = [System.Text.Encoding]::getencoding(28591).GetBytes($bat)
            [array]::reverse($batd)
            $bath = [System.BitConverter]::ToString($batd) -replace '-',''
            #Write-Host "BAT entry $($_b) = $($bath)" -f gray
            $batn = [Convert]::ToUInt32($bath,16)
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

# Dump payload data to file 
} #end foreach

$bat1offsets|Format-Table
# Should we dump the Payload?
$msgBoxInput = [System.Windows.Forms.MessageBox]::Show($this,'Would  you like to save the Payload block to a RAW image file?','VHDX','YesNo','Question')
switch  ($msgBoxInput) {

  'Yes' {

if(!!$bat1offsets){
foreach($o in ($bat1offsets)){
            if($o.Payload_State -match "PAYLOAD_BLOCK_FULLY_PRESENT"){
            
            $data = $Fcontent.substring([Uint64]($o.offset.TrimEnd(" Mb"))*1024*1024,$block)
            }
            write-host $data.length -f Red
            # Dump payload data to file
            write-host "**** Saving Payload Data (#Entry: $($o.Entry_Nr) - Offset:$($o.offset)) from VHDX to: '$($env:TEMP)\vhdx_$($snow)_data.img'" -f Green
            $streamWriter = New-Object System.IO.StreamWriter -ArgumentList ("$($env:TEMP)\vhdx_$($snow)_data.img",$true, [System.Text.Encoding]::GetEncoding(28591))
            $streamWriter.write($data)
            $streamWriter.close()
            
            }
} 
  }
  'No' {
  Continue
  }
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
                $batn = [Convert]::ToUInt32($bath,16)
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
$bat2offsets|Format-Table

# Stop Transcript
Stop-Transcript
# Open output folder
Invoke-Item $env:TEMP|sort -Descending