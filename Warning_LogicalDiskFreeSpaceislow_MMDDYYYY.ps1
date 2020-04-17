<#
Summary: 
    Script to cleanup Disk space. 
    
Description: 
    This script Cleans up disk space.It is to be be modified by application team. Based on specific need steps can be added/removed.

Parameters: 
    writeToFile: Flag for Creating log file.
        (Values : True/False)
    waitInSec: Wait time in seconds before each retries. 
        (Ex. 10) Default : 10
#>

Param (
    [Parameter(Mandatory = $true)]
    [string]$writeToFile,
    [Parameter(Mandatory = $true)]
    [string]$LogFilePath
    )
    $flagRecycleBin = $false
    $flagWinTemp = $false
    $flagUserTemp = $false
    $flagCustomFolder = $false

    $ErrorActionPreference = 'SilentlyContinue'
	$objShell = New-Object -ComObject Shell.Application
	$objFolder = $objShell.Namespace(0xA)
	$temp = get-ChildItem "env:\TEMP"
	$temp2 = $temp.Value
    $RestrictedPaths = @("","C:","C:Documents and Settings","C:Program Files","C:Program Files (x86)","C:Recovery","C:Windows","D:")
    
    # Add absolute path to custom folders to be cleaned. Separate each by comma
    # Ex. @("<C:\path1\>","<D:\path2\>")   
	$customfolders = @("D:\Test1\")
	$WinTemp = "c:\Windows\Temp\*"

# Function to Write Output to Host/ Log to file
Function WriteLog{
    Param (
        [string]$log
    )
    $log = "Cleanup : $log"
    #write-Host $log -ForegroundColor Magenta 
    if($writeToFile -eq "true"){
        Add-Content $LogFilePath $log
    }
}

Try{
#	Empty Recycle Bin
    if($flagRecycleBin -eq "true"){
        WriteLog "Emptying Recycle Bin."
	    $objFolder.items() | %{ remove-item $_.path -Recurse -Confirm:$false}
        $disks = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3"

        foreach ($disk in $disks)
        {
	        if (Test-Path "$($disk.DeviceID)\Recycle")
	        {
		        Remove-Item "$($disk.DeviceID)\Recycle" -Force -Recurse
	        }
	        else
	        {
		        Remove-Item "$($disk.DeviceID)\`$Recycle.Bin" -Force -Recurse 
	        }
        }
        #Clear-RecycleBin -Force
    }
	

# Remove temp files located in "C:\Users\<USERNAME>\AppData\Local\Temp"
    if($flagUserTemp -eq "true"){
        WriteLog "Removing Junk files in $temp2."
	    Remove-Item -Recurse  "$temp2\*" -Force # -Verbose -ErrorAction SilentlyContinue
    }
	

# Remove Windows Temp Directory 
    if($flagWinTemp -eq "true"){
        WriteLog "Removing Junk files in $WinTemp."
	    Remove-Item -Recurse $WinTemp -Force 
    }
	

# Remove files located in "Customfolder"
    if($flagCustomFolder -eq "true"){
        WriteLog "Clearing Generic folder"
        Foreach ($customfolder IN $customfolders){
            $customfolderWithoutSlash = $customfolder.replace("\","")
            if($RestrictedPaths -notcontains $customfolderWithoutSlash){
                if (Test-Path "$customfolder"){
                    Remove-Item -Recurse  "$customfolder\*" -Force
                }
            }
        }
    }
	
Write-Output "true"
}
catch
{
    Write-Output "true"
}

##### End of the Script #####
