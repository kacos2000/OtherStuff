# Show an Open File Dialog and return the file selected by the user
$handle = [System.Diagnostics.Process]::GetCurrentProcess().MainWindowHandle
$getfolder = New-Object -ComObject Shell.Application 
$foldername = $getfolder.BrowseForFolder([int]$handle,"ODC-FSD.ps1: Select a folder containing FSD files", 0x018230, 0)
# https://docs.microsoft.com/en-us/windows/win32/api/shlobj_core/ns-shlobj_core-browseinfow
if($foldername -ne $null)
	{$folder = $foldername.Self.path}
	    else  
    {Write-warning "(ODC-FSD.ps1):" ; Write-Host "User Cancelled" -f White; exit}

$Folder = $Folder +"\"

Try{write-host "Selected: " (Get-Item $Folder)|out-null}
Catch{Write-warning "(ODC-FSD.ps1):" ; Write-Host "User Cancelled" -f White; exit}

try{$fsd_files = Get-ChildItem $Folder -Filter *.FSD
write-host "$($fsd_files.count) FSD files found" -f White}
Catch{Write-warning "(ODC-FSD.ps1):" ; Write-Host "No FSD files found in $($Folder)" -f White; exit}
$enc = [System.Text.Encoding]::Unicode


$output = @{}
$output = if($fsd_files.count -ge 1){foreach ($fsd in $fsd_files) {

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
                                  
            [PSCustomObject]@{
            "FSD FileName"      = $fsd.Name
            "FSD Size"          = "($($fsd.length/1024)Kb)"
            "FSD Size on disk"  = $fsd.length
            "FSD Size in File"  = $fsize
            "FSD Lastwritetime" = get-date $fsd.Lastwritetime -f o
            "FEF Guid"          = $FSF_id.ToUpper()
            "FSD=FSF Guid"      = if($fsd.Name -match $FSF_id.ToUpper()){"Match"}else{}
            "FSD url"           = [uri]::UnescapeDataString($ur)
            "Url length"        = "$($url_length) ($([int][char]$FSDcontent.substring($offS,1)))"
            "FSD url offset"    = $urloffset
            "https"             = "$fsd_url ($($regex.Matches($FSDcontent).count))"
            }
            
          [gc]::Collect()
            
        }
    }
}
$output|Out-GridView -title "FSD information - ($($fsd_files.count)) FSD files found [$($output.Filename.Count)]" -PassThru

# Saving output to a csv
if($output.count -ge1){$snow = Get-Date -Format FileDateTimeUniversal
$dir = "$($env:TEMP)\ODC-FSD"
if(!(Test-Path -Path $dir )){New-Item -ItemType directory -Path $dir
                             Write-Host "'$($dir)' created" -f yellow}
Write-Host "Saving FSD Information to 'FSD-Info-$($snow).csv' in $dir" -f White
$output|Export-Csv -Delimiter "|" -NoTypeInformation -Encoding UTF8 -Path "$($dir)\FSD-Info-$($snow).txt" 
Invoke-Item $dir
}

   