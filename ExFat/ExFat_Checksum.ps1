# Reference: https://docs.microsoft.com/en-us/windows/win32/fileio/exfat-specification 
# chapter "6.3.3 SetChecksum Field"

# Clear screen
Clear-Host

# get bytes from the user
$bytes = Read-Host -Prompt "Input File directory entry bytes (eg'85028F4020000000B95B9')"
# Split bytes to pairs
$bytes = $bytes -split '(..)'| ? { $_ }
#Count number of bytes
$NumberOfBytes = $bytes.count 

# Set initial checksum value to 0
$Checksum = 0

# Start the iteration
$CS = for ($Index = 0; $Index -lt $NumberOfBytes; $Index++){

# Exclude 'SetChecksum' field bytes from the calculation
if($index -notin (2,3)){

# Get the decimal value of the current hex byte
$int = [int]"0x$($bytes[$index].PadLeft(2,'0'))"

# check if current value of the checksum is odd number 
If ($Checksum -band 1) {$h = 0x8000} Else {$h = 0}

# Analysis of values table 
        [pscustomobject]@{
          "#" = $index
          byte = "0x$($bytes[$index].PadLeft(2,'0'))"
          "byte value" = $int
          "Checksum is odd" = if(!!$h){"Add $($h)"}else{}
          "Checksum value" = $Checksum
          "Checksum Binary value" = [Convert]::ToString($Checksum,2).PadLeft(16,'0')
          "Checksum Binary right shift 1 Decimal" = $Checksum -shr 1
          "Checksum Binary right shift 1" = [Convert]::ToString($Checksum -shr 1,2).PadLeft(16,'0')
          "New Checksum" = $h + ($Checksum -shr 1) + $int
          "New Checksum (hex)" = "0x$(("{0:X}" -f ($h + ($Checksum -shr 1) + $int)).PadLeft(4,'0'))"
          }

# Calculate checksum for current byte
$Checksum = $h + ($Checksum -shr 1) + $int
}

} # Iteration ends
$cs|Out-GridView -Title "ExFat file directory entry Checksum calculation analysis" -PassThru

# Convert Checksum to little Endian to match the ExFat directory entry stored value
# for easier verification.

$Check = "{0:X}" -f $Checksum
# Split each byte hex value
$Check = $Check -split '(..)'
# Reverse byte order
[array]::reverse($Check)
# Join the reversed bytes together
$Check = -join $Check

# Write resulting Checksum to console
Write-Host "The Checksum value is: " -f White -nonewline;Write-Host $Check -f Yellow