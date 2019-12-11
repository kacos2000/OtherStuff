# Reference: https://docs.microsoft.com/en-us/windows/win32/fileio/exfat-specification 
# chapter "7.6.4 NameHash Field"

# Clear screen and get Filename from the user
Clear-Host
$FileName = Read-Host -Prompt 'Input a Filename'
$FileName = $FileName.Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
$FileName = $FileName.ToUpper()

# Get the inter value of each unicode byte of the filename
$utf8bytes = [System.Text.Encoding]::Unicode.getbytes($FileName)

# Count the number of unicode bytes
$NumberOfBytes = $utf8bytes.Count

# Set index & hash to zero
$index = 0
$Hash = 0

# Start loop from 0 to the length of the filename byte count
for($index = 0; $index -lt $NumberOfBytes; $index++){

If ($Hash -band 1) {$h = 0x8000} Else {$h = 0}
$Hash = $h + ($Hash -shr 1) + $utf8bytes[$index]
}

# Convert Hash to little endian
$Namehash = "{0:X}" -f $Hash
$Namehash = $Namehash -split '(..)'
[array]::reverse($Namehash)
$Namehash = -join $Namehash

# Write output
write-host "ExFat NameHash of: '" -f white -NoNewline
write-host $filename -f Yellow -NoNewline
Write-Host "' is:" -f white -NoNewline
Write-Host " $("{0:X}" -f $Namehash)" -f Yellow 


