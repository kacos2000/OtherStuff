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
            Write-Host "(PartitionDiagnostic.ps1):" -f Yellow -nonewline; Write-Host " User Cancelled" -f White
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
                               
                                TimeStamp            = Get-date ($d.Timestamp) -f o
                                FolderName           = $d.FolderName
                                FileName             = $d.FileName
                                Application          = $d.Application
                                PlaceUrl             = $d.PlaceUrl
                                LocalizedServiceName = $d.LocalizedServiceName
                                StorageHost          = $d.StorageHost
                                ResourceId           = $d.ResourceId
                                MruFile              = $c.Name
                                MruFolderName        = $c.Directory.Name
                                MruSize              = $c.length
                                MruFullPath          = $c.FullName
                                CreationTime         = Get-date ($c.CreationTimeUtc) -f o
                                LastAccessTime       = Get-date ($c.LastAccessTimeUtc) -f o
                                LastwriteTime        = Get-date ($c.Lastwritetime) -f o


                                }
                             }
                         }
# GUI output 
$MRUserviceCache|Out-GridView -title "MRUserviceCache - $($MRUserviceCache.count) entries found" -PassThru

# Saving the decoded data to a csv
if($MRUserviceCache.count -ge1){$snow = Get-Date -Format FileDateTimeUniversal
Write-Host "Saving 'MRUserviceCache' to (csv): 'MRUserviceCache-$($snow).txt' in $env:TEMP`n" -f Yellow
$MRUserviceCache|Export-Csv -NoTypeInformation -Encoding UTF8 -Path "$($env:TEMP)\MRUserviceCache-$($snow).txt"
Invoke-Item $env:TEMP
}