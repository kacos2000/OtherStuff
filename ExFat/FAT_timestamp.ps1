# Clear screen
Clear-Host

# get HEX from the user
$Hex = Read-Host -Prompt 'Please enter 8 bytes (Hex) for Time/Date'
if($hex -match "0x")
{$hex = $hex.trimstart("0x")}

$hex = $hex.trim().replace("-","")
if($hex.Length -ne 8){write-warning "Not valid Hex - try again";exit}

$hex_time = "0x$(($hex -split "(....)")[1])"
$hex_date = "0x$(($hex -split "(....)")[3])"

#$hex_time = "0x8aD8"
#$hex_date = "0x4d98"

write-host "Hex values: $($hex_time) $($hex_date)`n" -f Cyan

$bin_t = [Convert]::ToString($hex_time,2).padleft(16,'0')
$bin_d = [Convert]::ToString($hex_date,2).padleft(16,'0')

$hour    = $bin_t.substring(0,5)
$minutes = $bin_t.substring(5,6)
$seconds = $bin_t.substring(11,5)

write-host "hour    : $([Convert]::toInt32($hour,2))" 
write-host "minutes : $([Convert]::toInt32($minutes,2))"
write-host "Seconds : $([Convert]::toInt32($seconds,2)*2)"
write-host "Binary time: $($bin_t)"
write-host "Time: $([Convert]::toInt32($hour,2)):$([Convert]::toInt32($minutes,2)):$([Convert]::toInt32($seconds,2)*2)`n" -f Yellow

$year  = $bin_d.substring(0,7)
$month = $bin_d.substring(7,4)
$day   = $bin_d.substring(11,5)

write-host "year  : $([Convert]::toInt32($year,2)+1980)" 
write-host "month : $([Convert]::toInt32($month,2))"
write-host "day   : $([Convert]::toInt32($day,2))"
write-host "Binary date: $($bin_d)"
write-host "Date: $([Convert]::toInt32($day,2))/$([Convert]::toInt32($month,2))/$([Convert]::toInt32($year,2)+1980)" -f Yellow