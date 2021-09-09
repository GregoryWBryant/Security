<#
Script for parsing logs from Cisco AMP
I am not the original Autho of this but do not recall where it is from.
#>

#A Powershell version of the Cisco AMP for Windows debug log parser.
#Based on the bash script found: https://supportforums.cisco.com/document/13318916/review-scanned-files-amp-endpoints-windows-exclusions
#Log files are stored in C:\Program Files\Cisco\AMP\"Version-Number" and named sfc.exe.log with a timestamp in the name if more than one present

#Sets execution policy for current session to Bypass
Set-ExecutionPolicy Bypass -Scope Process -Force


#Creates a new folder with the name of the Computer
New-Item -Path C:\AMP\${Env:ComputerName} -ItemType Directory

#Only collect lines regarding HandleCreation and a space
$DebugLogs = (Get-Content -path (Get-ChildItem "C:\*\Cisco\AMP\*\SFC.*.log")) -match 'event::handlecreation'

#Search terms being written to terms.txt
#Collect only the word preceding .exe and .exe, not the entire line
$Terms = ($DebugLogs | select-string -pattern "\w*.exe" | % { $_.Matches }).value | Sort-Object | Get-Unique
$Terms | Out-File C:\AMP\${Env:ComputerName}\terms.txt

#Removing time stamps from line that starts and ends with parenthesis and has ms at the end
#Have to use \ as the escape character for the ( and ) to work in the regex
$DebugLogs = $DebugLogs -replace "\(.*ms\) "

#Only include lines that contain a litteral ? and not lines representing errors
#\ is escape character for the question mark
$DebugLogs = $DebugLogs -match "\?"

#Removing the ID and Event component and replacing with a comma
#Have to use \ as the escape character for the [ to work in the regex
$DebugLogs = $DebugLogs -replace " \[.*Creation ",","

#Removing the temp file name, leaving only the file scanned and executable
$DebugLogs = $DebugLogs -replace "\(\\\\?\\*.*tmpscan\)"

#Remove extra slashes before paths
#Not a direct replacement for the bash script but combining two of the final sed commands
$DebugLogs = $DebugLogs -replace "\\\\\?\\"

#Replace command plus space with just a comma
$DebugLogs = $DebugLogs -replace ", ",","

# Cleaned log data being written to data.csv
$DebugLogs | Out-File C:\AMP\${Env:ComputerName}\"data.csv"


Out-File results.txt #Empty existing file



foreach ($line in $terms) {
    #Count the number of matches for the current executable
    $count = @($DebugLogs | ? { $_ -match $line }).Count
    #Cast $count as string to concatenate and append to file
    [String]$count + "`t" + $line | Out-File C:\AMP\${Env:ComputerName}\results.txt -Append
    }

    
#Sort output based on the first number, cast as an interger so Sort-Object works as expected
Get-Content results.txt | Sort-Object {[int]($_-split"`t")[0]} -Descending | Out-File C:\AMP\${Env:ComputerName}\sorted_results.txt
