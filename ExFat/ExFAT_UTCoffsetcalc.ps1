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

$mod = (([Int16]("0x$($Hex)") +64) % 128)-64

$zones = @{
    "-12" = "Dateline Standard Time"
    "-11" = "Samoa Standard Time"
    "-10" = "Hawaii Standard Time"
    "-9" = "Alaska Standard Time"
    "-8" = "Pacific Standard Time"
    "-7" = "Mountain Standard Time"
    "-6" = "Central Standard Time"
    "-5" = "Eastern Standard Time"
    "-4" = "Atlantic Standard time"
    "-3.5" = "Newfoundland Standard Time"
    "-3" = "Greenland Standard Time"
    "-2" = "Mid-Atlantic Standard Time"
    "-1" = "Azores Standard Time"
    "0" = "Greenwich Standard Time"
    "1" = "Central Europe Time"
    "2" = "Eastern Europe Standard Time"
    "3" = "Moscow Standard Time"
    "4" = "Arabian Standard Time"
    "5" = "West Asia Standard Time"
    "6" = "Central Asia Standard Time"
    "7" = "North Asia Standard Time"
    "8" = "North Asia East Standard Time"
    "9" = "Tokyo Standard Time"
    "10" = "West Pacific Standard Time"
    "11" = "Central Pacific Standard Time"
    "12" = "New Zealand Standard Time"
    "13" = "Tonga Standard Time"
}


$utc_offset = ($mod * 15)/60

write-host "UTC offset is: $($utc_offset)`nZone: "$($Zones["$($utc_offset)"])"`n" -f White