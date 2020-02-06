# Calculate the UtcOffset 
# Ref: https://docs.microsoft.com/en-us/windows/win32/fileio/exfat-specification#7410-utcoffset-fields

# Clear screen
Clear-Host

# get HEX from the user
$Hex = Read-Host -Prompt 'Please enter 1 byte (Hex) for Time Stamp UTC Differential'
if($hex -match "0x")
{$hex = $hex.trimstart("0x")}

$hex = $hex.trim().replace("-","")
if($hex.Length -ne 2){write-warning "Not valid Hex - try again";exit}
Clear-Host
write-host "Hex value: 0x$($hex.ToUpper())" -f Cyan
$bin = [Convert]::ToString("0x$($hex)" ,2).padleft(8,'0')

# Convert ($hex -shr 1) to binary 
$bin_valid = ([Convert]::ToString("0x$($hex)" ,2).padleft(8,'0'))[0]
if(!!$bin_valid){write-host "Offset is Valid" -f Green}else{write-host "Offset NOT Valid" -f Red}

$bin_utc = [convert]::ToInt32($bin.Substring(1,7),2)
$utc_offset = ($bin_utc * 15)/60
write-host "UTC offset is: $($utc_offset)`n" -f White