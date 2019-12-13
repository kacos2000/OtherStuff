# Reference: https://docs.microsoft.com/en-us/windows/win32/fileio/exfat-specification 
# chapter "7.6.4 NameHash Field"

# Clear screen
Clear-Host

# get Filename from the user
$FileName = Read-Host -Prompt 'Input a Filename'

# Remove any invalid characters from the Filename
# https://docs.microsoft.com/en-us/windows/win32/fileio/naming-a-file
$FileName = $FileName.Split([IO.Path]::GetInvalidFileNameChars()) -join ''

# Convert filename to UPPERCASE
$FileName = $FileName.ToUpper()

# Get the integer value of each unicode byte of the filename
$unicodebytes = [System.Text.Encoding]::Unicode.getbytes($FileName)

# Filename to Hex (for Analysis table)
$hex = [System.BitConverter]::ToString($unicodebytes).split("-")

# Count the number of unicode bytes
$NumberOfBytes = $unicodebytes.Count

# Set Hash to zero
$Hash = 0

# Start loop from 0 to the length of the filename byte count
$calc = for($index = 0; $index -lt $NumberOfBytes; $index++){

# if previous hash (binary) number ends in 1 (odd numbers) add 32768 (0x8000) to the hash value in the next line
If ($Hash -band 1) {$h = 0x8000} Else {$h = 0}

# Analysis of values table 
        [pscustomobject]@{
          "#" = $index
          byte = "0x$($hex[$index])"
          "byte value" = $unicodebytes[$index]
          "Hash is odd" = if(!!$h){"Add $($h)"}else{}
          "Hash value" = $hash
          "Hash Binary value" = [Convert]::ToString($hash,2).PadLeft(16,'0')
          "Hash Binary right shift 1 Decimal" = $hash -shr 1
          "Hash Binary right shift 1" = [Convert]::ToString($hash -shr 1,2).PadLeft(16,'0')
          "New Hash" = $h + ($Hash -shr 1) + $unicodebytes[$index]
          "New Hash (hex)" = "0x$(("{0:X}" -f ($h + ($Hash -shr 1) + $unicodebytes[$index])).PadLeft(4,'0'))"
          }


# for each iteration add to the $Hash the $h value if any, the binary right shift of the hash value and the filename character integer value
# (When shifting right with a binary right shift, the least-significant bit is lost and a 0 is inserted on the other end. )
$Hash = $h + ($Hash -shr 1) + $unicodebytes[$index]
} # Loop ends

# Convert Hash to little endian

# Convert hash from integer to Hexadecimal
$Namehash = "{0:X}" -f $Hash
# Split each byte hex value
$Namehash = $Namehash -split '(..)'
# Reverese byte order
[array]::reverse($Namehash)
# Join the reversed bytes together
$Namehash = -join $Namehash

# Show Analysis
$calc|Out-GridView -Title "ExFat Name Hash - $($FileName)" -PassThru


# Write output to console
write-host "The ExFat NameHash (LE) of: '" -f white -NoNewline
write-host $filename -f Yellow -NoNewline
Write-Host "' is:" -f white -NoNewline
Write-Host " $("{0:X}" -f $Namehash)" -f Yellow 


