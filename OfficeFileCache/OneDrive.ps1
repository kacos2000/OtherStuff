#Requires -RunAsAdministrator

# Show Open File Dialogs 
Function Get-FileName($initialDirectory, $Title ,$Filter)
{[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") |Out-Null
		$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
		$OpenFileDialog.Title = $Title
		$OpenFileDialog.initialDirectory = $initialDirectory
        $OpenFileDialog.Filter = $filter
		$OpenFileDialog.ShowDialog() | Out-Null
		$OpenFileDialog.ShowReadOnly = $true
		$OpenFileDialog.filename
		$OpenFileDialog.ShowHelp = $false
} #end function Get-FileName 

$DesktopPath = [Environment]::GetFolderPath("Desktop")

$File = Get-FileName -initialDirectory $DesktopPath -Filter "NTUser.dat (*.dat)|NTUser.dat" -Title 'Select NTuser.dat'
Try{write-host "File Selected: " -f White -NoNewline; (Get-ItemProperty $File).FullName}
Catch{Write-warning "(OneDrive.ps1):" ; Write-Host "User Cancelled" -f White; exit}

$ErrorActionPreference = "Stop"
Try{$before = (Get-FileHash $File -Algorithm SHA256).Hash}
Catch{
        Write-Host "(ODCreg.ps1):" -f Yellow -nonewline; Write-Host " User Cancelled" -f White
		[gc]::Collect()		
		reg unload HKEY_LOCAL_MACHINE\Temp 
		exit
} 
write-host "SHA256 Hash of ($File) = " -f magenta -nonewline;write-host "($before)" -f Yellow
#Load NTUser.dat to temp key in registry
reg load HKEY_LOCAL_MACHINE\Temp $File

try{$Key = @((Get-ChildItem -Path "HKLM:\Temp\SOFTWARE\Microsoft\OneDrive\Accounts" -name)|Select-Object)
}
Catch{
	Write-Host -f Yellow "The selectd $($File) does not have the" 
	Write-Host -f Yellow "'Software\Microsoft\OneDrive\Accounts' registry key." 
	[gc]::Collect()
    reg unload HKEY_LOCAL_MACHINE\Temp 
    exit}
finally{}
Write-Host -f Yellow "$File loaded OK`n"
Write-host "Key ""\SOFTWARE\Microsoft\OneDrive\Accounts"" was last updated on :" -f Yellow -nonewline;Get-Date ((Get-Date 01.01.1970)+([System.TimeSpan]::fromseconds($key.LastUpdate)))  -f u

$Accounts = @((Get-ChildItem -Path "HKLM:\Temp\SOFTWARE\Microsoft\OneDrive\Accounts\" -name)|Select-Object)

if($Accounts.count -ge 1){
$OneDrive = @(foreach($a in $Accounts){

            $dpath                       = "HKLM:\Temp\SOFTWARE\Microsoft\OneDrive\Accounts\" + "$($a)"
            $Type                        = $a
            $UserEmail                   = (get-itemproperty -path $dpath).UserEmail
            $UserFolder                  = (get-itemproperty -path $dpath).UserFolder
            $cid                         = (get-itemproperty -path $dpath).cid
            $UserCID                     = (get-itemproperty -path $dpath).UserCID
            $LastSignInTime              = (Get-Date 01.01.1970)+([System.TimeSpan]::fromseconds(((get-itemproperty -path $dpath).LastSignInTime)))  # Unix Seconds
            $ClientFirstSignInTimestamp  = (Get-Date 01.01.1970)+([System.TimeSpan]::fromseconds(((get-itemproperty -path $dpath).ClientFirstSignInTimestamp)))  # Unix Seconds
            $ECSConfigurationLastSuccess = (get-itemproperty -path $dpath).ECSConfigurationLastSuccess #DOS time (?)
            $ECSConfigurationMaxAge      = (get-itemproperty -path $dpath).ECSConfigurationMaxAge #Seconds (?)
            $NamespaceRootId             = (get-itemproperty -path $dpath).NamespaceRootId

[PSCustomObject]@{
            Account_Type                 = $Type
            UserEmail                    = $UserEmail
            UserFolder                   = $UserFolder
            cid                          = $cid
            UserCID                      = $UserCID
            LastSignInTime               = $LastSignInTime
            ClientFirstSignInTimestamp   = $ClientFirstSignInTimestamp
            NamespaceRootId              = $NamespaceRootId
    }
})
}

$OneDrive|Out-GridView -PassThru -title "Onedrive Accounts $($Accounts.count)"

[gc]::Collect()
try{reg unload HKEY_LOCAL_MACHINE\Temp} 
catch{
Write-Warning "There seems to be an issue unloading $($File)."
Write-Host "Please open a new Powershell terminal Window, copy/paste " -NoNewline; write-host "reg unload HKEY_LOCAL_MACHINE\Temp" -f white -b red
Write-Host "close this Powershell terminal and run the above command in the other terminal Window"
}

