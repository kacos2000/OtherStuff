# Parses the "AppData\Local\Microsoft\Office\16.0\MruServiceCache" folder
# which holds json files of available(Most Recently Used) office files
# for each Office application.
# Files are located in Onedrive or Sharepoint folders and not necessary available offline,
# or accessed from current computer.

# Show an Open File Dialog and return the file selected by the user
Function Get-Folder($initialDirectory)

{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")|Out-Null
    $foldername = New-Object System.Windows.Forms.FolderBrowserDialog
    $foldername.SelectedPath = [Environment]::GetFolderPath("LocalApplicationData ")+"\Microsoft\Office"
	$foldername.Description = "Select an 'MruServiceCache' folder"
	$foldername.ShowNewFolderButton = $false
	
    if($foldername.ShowDialog() -eq "OK")
		{
        $folder += $foldername.SelectedPath
		 }
	        else  
        {
            Write-Host "(MRUserviceCache.ps1):" -f Yellow -nonewline; Write-Host " User Cancelled" -f White
			exit
        }
    return $Folder

	}

$F = "$(Get-Folder)\"
$Fchildren = get-childitem $f -recurse -include "*Document*" ,"*Place*"
$MRUserviceCache = foreach($c in $Fchildren){
                
                    $fdoc = (Get-Content $c.FullName -Encoding UTF8| Out-String | ConvertFrom-Json)
                    foreach($d in $fdoc){
                
                
                    [PSCustomObject]@{
                               
                                TimeStamp            = if(!!$d.Timestamp){Get-date ($d.Timestamp) -f o}else{}
                                FolderName           = $d.FolderName
                                FileName             = $d.FileName
                                Application          = $d.Application
                                PlaceUrl             = $d.PlaceUrl
                                LocalizedServiceName = $d.LocalizedServiceName
                                StorageHost          = $d.StorageHost
                                ResourceID           = if($d.ResourceId -like "*!*"){$d.ResourceId.replace("!"," - ")}else{$d.ResourceId}
                                MruFile              = $c.Name
                                MruFolderName        = $c.Directory.Name
                                MruSize              = $c.length
                                MruFullPath          = $c.FullName
                                CreationTime         = Get-date ($c.CreationTime) -f o
                                LastAccessTime       = Get-date ($c.LastAccessTime) -f o
                                LastwriteTime        = Get-date ($c.Lastwritetime) -f o


                                }
                             }
                         }
# GUI output 
$MRUserviceCache|Out-GridView -title "MRUserviceCache - $($MRUserviceCache.count) entries found" -PassThru

# Saving the decoded data to a csv
if($MRUserviceCache.count -ge1){$snow = Get-Date -Format FileDateTimeUniversal
$dir = "$($env:TEMP)\MRUserviceCache"
if(!(Test-Path -Path $dir )){New-Item -ItemType directory -Path $dir
                             Write-Host "'$($dir)' created" -f yellow}
Write-Host "Saving 'MRUserviceCache' to (csv): 'MRUserviceCache-$($snow).txt' in $dir`n" -f Yellow
$MRUserviceCache|Export-Csv -Delimiter "|" -NoTypeInformation -Encoding UTF8 -Path "$($dir)\MRUserviceCache-$($snow).txt"
Invoke-Item $dir
}

