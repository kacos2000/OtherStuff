<#
	.SYNOPSIS
		Convert TikTok & Ring door bell filenames to timestamps
	
	.DESCRIPTION
		Reference:
		https://dfir.blog/tinkering-with-tiktok-timestamps/
	
	
	.EXAMPLE
				PS C:\> name-to-timestamp -path "C:\Test Folder"
        
        Save the txt file to user's desktop
	      PS C:\> name-to-timestamp -path "C:\Test Folder" -outpath "C:\users\username\desktop"
	.NOTES
		Additional information about the function.
#>
function name-to-timestamp 
{
    [CmdletBinding()]
    param(
    [Parameter(Mandatory = $false)]
    [System.String]$path = [System.Environment]::CurrentDirectory, # default value is current directory
    [Parameter(Mandatory = $false)]
    [string]$outpath = [System.Environment]::CurrentDirectory # default value is current directory
    )
    
    $timestamps = [System.Collections.Hashtable]::new()
    $files = [System.IO.Directory]::EnumerateFiles($path).foreach{Split-Path $_ -Leaf} 

    foreach($filename in $files)
    {
        try  { $name = [IO.Path]::GetFileNameWithoutExtension($filename)}
        catch{ $name = $filename -replace "\..+"}
        # limit to filenames with 19 characters
        if($name.Length -eq 19){
        try{ 
            $null = $timestamps.add($filename,(([System.DateTimeOffset]::FromUnixTimeSeconds($name -shr 32)).DateTime).ToString("dd/MM/yyyy HH:mm:ss.ff"))
            write-host "$($filename): " -f Yellow -NoNewline
            Write-Host "$($timestamp)" -f Green
            }
        catch{write-host "$($filename) is not a number" -f Red}
        }
    }
    if($timestamps.Count -ge 1 -and !!$outpath){
       # save to a text file
       $timestamps|Out-String|Out-File -FilePath "$($outpath)\timestamps.txt" -Encoding utf8 -NoClobber -Force
       if([System.IO.FileInfo]::new("$($outpath)\timestamps.txt").Exists){
        [system.Diagnostics.Process]::start("$($outpath)\timestamps.txt") # open the file
        }
    }
    $timestamps.Clear()
  } 
} 
name-to-timestamp -ErrorAction SilentlyContinue
