# Show an Open File Dialog 
# Show Open File Dialogs 
Function Get-FileName($initialDirectory, $Title ,$Filter)
{  
[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") |Out-Null
		$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
		$OpenFileDialog.Title = $Title
		$OpenFileDialog.initialDirectory = $initialDirectory
        $OpenFileDialog.Filter = $filter
		$OpenFileDialog.ShowDialog() | Out-Null
		$OpenFileDialog.ShowReadOnly = $true
		$OpenFileDialog.filename
		$OpenFileDialog.ShowHelp = $false
} #end function Get-FileName 

$DesktopPath =  [Environment]::GetFolderPath("Desktop")
$File = Get-FileName -initialDirectory $DesktopPath -Filter "$Bitmap (*.*)|$Bitmap" -Title 'Select ExFAT $Bitmap file'
$F =$File.replace($env:LOCALAPPDATA,'')

Write-Host "Loaded ($File)"

#Read the file:
$AllClusters = @(Get-Content $File -Encoding Byte -ReadCount 1) #readcount 1 to get each byte instead of the whole dump
$count = $AllClusters.count #Same as Filesize
$x=0

 
$Clusters = foreach ($c in $AllClusters){
            $cl1=$cl2=$cl31=$cl4=$cl5=$cl6=$cl7=$cl8=$v=$b=$null
            
            if ($c -ne 0){
                             
                             $offset="0x"+[System.Convert]::ToString(($x),16).PadLeft(2,'0').ToUpper() 
                             $v = "0x"+[System.Convert]::ToString(($c),16).PadLeft(2,'0').ToUpper()
                             $b = [System.Convert]::ToString($c,2).PadLeft(8,'0')
                             write-host "Offset $offset " -NoNewline -f cyan;
                             write-host "- (Starting cluster $(($x*8)+2) - End cluster -> $(($x*8)+9)):" -NoNewline -f yellow; 
                             write-host " HEX $($v)" -f cyan -NoNewline;
                             write-host " Binary  $($b)" -f white
                                                        

                                if($b[7] -ne '0') {$cl1 = $(($x*8)+2)}else{$cl1=$null}
                                if($b[6] -ne '0') {$cl2 = $(($x*8)+3)}else{$cl2=$null}
                                if($b[5] -ne '0') {$cl3 = $(($x*8)+4)}else{$cl3=$null}
                                if($b[4] -ne '0') {$cl4 = $(($x*8)+5)}else{$cl4=$null}
                                if($b[3] -ne '0') {$cl5 = $(($x*8)+6)}else{$cl5=$null}
                                if($b[2] -ne '0') {$cl6 = $(($x*8)+7)}else{$cl6=$null}
                                if($b[1] -ne '0') {$cl7 = $(($x*8)+8)}else{$cl7=$null}
                                if($b[0] -ne '0') {$cl8 = $(($x*8)+9)}else{$cl8=$null}
                            
                            $ccount += ($cl1.count)+($cl2.count)+($cl3.count)+($cl4.count)+($cl5.count)+($cl6.count)+($cl7.count)+($cl8.count)

                            [PSCustomObject]@{
                                 Offset = $offset
                                 StartingCluster = ($x*8)+2
                                 EndingCluster = ($x*8)+9
                                 Hex = $v
                                 Binary = $($b)
                                 Cluster1 = $cl1
                                 Cluster2 = $cl2
                                 Cluster3 = $cl3
                                 Cluster4 = $cl4
                                 Cluster5 = $cl5
                                 Cluster6 = $cl6
                                 Cluster7 = $cl7
                                 Cluster8 = $cl8
                          }
                      $x++
                      }
                      
          else {$x++}
}


$Clusters|Out-GridView -Title "$ccount Occupied Clusters in $File" -PassThru