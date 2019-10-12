# Show an Open File Dialog and return the file selected by the user
Function Get-Folder($initialDirectory)
{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")|Out-Null
    $foldername = New-Object System.Windows.Forms.FolderBrowserDialog
    $foldername.SelectedPath = [Environment]::GetFolderPath("LocalApplicationData ")+"\Microsoft\Office"
	$foldername.Description = "Select the location of FSF files" 
	$foldername.ShowNewFolderButton = $false
	if($foldername.ShowDialog() -eq "OK")
		{$folder += $foldername.SelectedPath}
	        else  
        {Write-warning "(OUC-FSD.ps1):" ; Write-Host "User Cancelled" -f White; exit}
    return $Folder
    }

$F = Get-Folder
$Folder = $F +"\"

Try{write-host "Selected: " (Get-Item $Folder)|out-null}
Catch{Write-warning "(ODC-FSF.ps1):" ; Write-Host "User Cancelled" -f White; exit}

$fsd_files = Get-ChildItem $Folder -Filter *.FSD
write-host "$($fsd_files.count) FSD files found" -f White
$output = @{}
$output = if($fsd_files.count -ge 1){foreach ($fsd in $fsd_files) {
            $path = $fsd.FullName
            $Stream = New-Object IO.FileStream -ArgumentList (Resolve-Path $Path), 'Open', 'Read' 
             # Note: Codepage 28591 returns a 1-to-1 char to byte mapping 
            $encoding = [System.Text.Encoding]::Unicode 
            $StreamReader = New-Object IO.StreamReader -ArgumentList $Stream, $Encoding 
            $FSDcontent =  $StreamReader.ReadToEnd() 
            [regex]$regex = ‘([hH]ttps:\/\/)(\.)?(?!www)([\w\(\):%-_.,\[\]\s]+)’    
            $fsd_url = $regex.Matches($FSDcontent).Value
            $StreamReader.Close() 
            $Stream.Close() 
                                  
            [PSCustomObject]@{
            "FSD FileName"      = $fsd.Name
            "FSD Size"          = $fsd.length
            "FSD Lastwritetime" = $fsd.Lastwritetime
            "FSD url"           = [uri]::UnescapeDataString($fsd_url)
             }
          }
       }
$output|Out-GridView -title "FSD information - ($($fsd_files.count)) FSD files found" -PassThru

# Saving output to a csv
if($output.count -ge1){$snow = Get-Date -Format FileDateTimeUniversal
$dir = "$($env:TEMP)\ODC-FSD"
if(!(Test-Path -Path $dir )){New-Item -ItemType directory -Path $dir
                             Write-Host "'$($dir)' created" -f yellow}
Write-Host "Saving FSD Information to 'FSD-List-$($snow).csv' in $dir" -f White
$output|Export-Csv -Delimiter "|" -NoTypeInformation -Encoding UTF8 -Path "$($dir)\FSD-List-$($snow).txt" 
Invoke-Item $dir
}


   