<#
Used for gathering information on a device after a virus detection.
#>

#Creates a new folder with the name of the Computer
New-Item -Path "C:\Temp\${Env:ComputerName}" -ItemType Directory -ErrorAction SilentlyContinue


#Downlaod Autoruns commandline version from Microsoft SysInternal
(New-Object Net.WebClient).DownloadFile("https://live.sysinternals.com/autorunsc.exe", "C:\Temp\${Env:ComputerName}\Autorunsc.exe")


#Reads the registry for all installed 32bit Applications
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Export-Csv "C:\Temp\${Env:ComputerName}\32BitApplications.csv" -NoTypeInformation

#Reads the registry for all installed 64bit Applications
Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Export-Csv "C:\Temp\${Env:ComputerName}\64BitApplications.csv" -NoTypeInformation


#Gets all services
Get-Service | Export-Csv "C:\Temp\${Env:ComputerName}\Services.csv"


#Get Firefox Add-ons
Get-ChildItem C:\users\*\AppData\Roaming\Mozilla\Firefox\Profiles -Recurse -Filter Addons.json | ForEach-Object {

(Get-Content $_.FullName | ConvertFrom-Json).addons | Select name, Version

} | Export-Csv "C:\Temp\${Env:ComputerName}\FirefoxADDons.csv" -NoTypeInformation



#Get Chrome Add-ons
Get-ChildItem "C:\users\*\AppData\Local\Google\Chrome\User Data\Default\Extensions" -Recurse -Filter Manifest.json | ForEach-Object {

Get-content $_.FullName -Raw | ConvertFrom-Json | Select Name, Version

}  | Export-Csv "C:\Temp\${Env:ComputerName}\ChromeADDons.csv" -NoTypeInformation


#Checks the following with the commands after -a tell it what to list
# /accepteula accepts the EULA for Autorunsc
#command i  Internet Explorer addons.
#command l Logon startups
#command o Office addins
#command t Scheduled tasks
#command w Winlogon entries
# -m ignores all Microsoft entries
# -vt uses VirusTotal and accepts its EULA
# -c tells it to do it in CSV format
# -o tells it what file to put the output into
# -h provides hashes
Start-Process "C:\Temp\${Env:ComputerName}\autorunsc.exe" -ArgumentList "\ /accepteula -a ilotw -vt -h -m -c -o C:\Temp\${Env:ComputerName}\Autoruns.csv" | Out-Null

#Gets the ID of Autorunsc process and waits for it to exit before continuing
$AutorunscID = (Get-Process -Name Autorunsc).Id
Wait-Process -Id $AutorunscID

#Goes through all users temp folder and deletes everything it can
Remove-Item "C:\Users\*\Appdata\Local\Temp\*" -recurse -force -ErrorAction SilentlyContinue

#Empties the generic temp folder
Remove-Item "C:\Windows\Temp\*" -recurse -force -ErrorAction SilentlyContinue

#Delete File
Remove-Item "C:\Temp\${Env:ComputerName}\autorunsc.exe" -Recurse -Force

#Zips Folder
Compress-Archive -Path "C:\Temp\${Env:ComputerName}" -DestinationPath "C:\Temp\${Env:ComputerName}"

#Waits 10 seconds
Start-Sleep -Seconds 10

#Removes original folder
Remove-Item -Path "C:\Temp\${Env:ComputerName}" -Recurse
