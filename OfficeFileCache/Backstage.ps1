# Parses the "AppData\Local\Microsoft\Office\16.0\BackstageInAppNavCache" folder
# which holds json files of available files to open from 'MyComputer', 'Onedrive' or 'Sharepoint',
# Short of 'Folder list cache' for each location accessed /per account used.

# Show an Open File Dialog and return the file selected by the user
Function Get-Folder($initialDirectory)

{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")|Out-Null
    $foldername = New-Object System.Windows.Forms.FolderBrowserDialog
    $foldername.SelectedPath = [Environment]::GetFolderPath("LocalApplicationData ")+"\Microsoft\Office\16.0\BackstageInAppNavCache"
	$foldername.Description = "Select a 'BackstageInAppNavCache' folder"
	$foldername.ShowNewFolderButton = $false
	
    if($foldername.ShowDialog() -eq "OK")
		{
        $folder += $foldername.SelectedPath
		 }
	        else  
        {
            Write-Host "(Backstage.ps1):" -f Yellow -nonewline; Write-Host " User Cancelled" -f White
			exit
        }
    return $Folder

	}

$F = "$(Get-Folder)\"
$Fchildren = get-childitem $f -recurse -include *.json 
$Backstage = foreach($c in $Fchildren){
                    
                    $fdoc = (Get-Content $c.FullName -Encoding Unicode| Out-String | ConvertFrom-Json)

                    foreach($d in $fdoc){
                        $lcid                  = $d.lcid
                        $ContainerUrl          = $d.ContainerUrl
                        $FileCreationAllowed   = $d.Metadata.FileCreationAllowed
                        $FolderCreationAllowed = $d.Metadata.FolderCreationAllowed
                        
                        foreach($fl in $d){
                               $url                     = $fl.folders.url
                               $DisplayName             = $fl.folders.DisplayName
                               $Author                  = $fl.folders.Author
                               $ResourceId              = $fl.folders.ResourceId
                               $RootResourceId          = $fl.folders.RootResourceId
                               $LastModified            = $fl.folders.LastModified
                               $SharingLevelDescription = $fl.folders.SharingLevelDescription
                               $OneNoteItem             = $fl.folders.OneNoteItem

                            foreach($f in $fl.files){
                                   $url                     = $f.url
                                   $DisplayName             = $f.DisplayName
                                   $Author                  = $f.Author
                                   $ResourceId              = $f.ResourceId
                                   $RootResourceId          = $f.RootResourceId
                                   $LastModified            = $f.LastModified
                                   $SharingLevelDescription = $f.SharingLevelDescription
                                   $OneNoteItem             = $f.OneNoteItem
 
                        
                        [PSCustomObject]@{
                               
                               LCID                    = $lcid
                               DisplayName             = $DisplayName
                               Author                  = $Author
                               LastModified            = Get-Date ([DateTime]::FromFileTime($LastModified )) -f o
                               ContainerUrl            = $ContainerUrl
                               Url                     = [uri]::UnescapeDataString($Url)
                               SharingLevelDescription = $SharingLevelDescription
                               OneNoteItem             = $OneNoteItem
                               FileCreationAllowed     = $FileCreationAllowed
                               FolderCreationAllowed   = $FolderCreationAllowed
                               ContainerResourceId     = $ContainerResourceId
                               ResourceId              = $ResourceId
                               RootResourceId          = $RootResourceId
                               Directory               = $c.DirectoryName
                               Filename                = $c.Name
                               FileSize                = $c.length
                               CreationTime            = Get-Date $c.CreationTime -f o
                               LastWriteTime           = Get-Date $c.LastWriteTime -f o
                               LastAccessTime          = Get-Date $c.LastAccessTime -f o

                               }
                            }
                        }
                     }          
}

# GUI output 
$Backstage|Out-GridView -title "BackstageInAppNavCache - $($Backstage.count) entries found" -PassThru

Saving the decoded data to a csv
if($Backstage.count -ge1){$snow = Get-Date -Format FileDateTimeUniversal
$dir = "$($env:TEMP)\BackstageInAppNavCache"}
if(!(Test-Path -Path $dir )){New-Item -ItemType directory -Path $dir
                             Write-Host "'$($dir)' created" -f yellow}
Write-Host "Saving 'Backstage' to (csv): 'BackstageInAppNavCache-$($snow).txt' in $dir`n" -f Yellow
$Backstage|Export-Csv -Delimiter "|" -NoTypeInformation -Encoding UTF8 -Path "$($dir)\BackstageInAppNavCache-$($snow).txt"
Invoke-Item $dir
