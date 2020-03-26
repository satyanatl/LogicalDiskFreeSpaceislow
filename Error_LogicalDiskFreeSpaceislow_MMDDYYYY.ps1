<#
Summary: 
    Script to cleanup Disk space. 
    
Description: 
    This script Cleans up disk space.It is to be be modified by application team. Based on specific need steps can be added/removed.

Parameters: 
    writeToFile:          Flag for Creating log file.
                            (Values : True/False)
    waitInSec:            Wait time in seconds before each retries. 
                           (Ex. 10) Default : 10
#>

Param (
    [Parameter(Mandatory = $true)]
    [string]$writeToFile,
    [Parameter(Mandatory = $true)]
    [string]$LogFilePath
    )
    
    $ErrorActionPreference = 'SilentlyContinue'
	$objShell = New-Object -ComObject Shell.Application
	$objFolder = $objShell.Namespace(0xA)
	$temp = get-ChildItem "env:\TEMP"
	$temp2 = $temp.Value

    # Add absolute path to custom folders to be cleaned. Separate each by comma
    # Ex. @("<C:\path1\>","<D:\path2\>")   
	$customfolders = @("C:\Users\kaushal.kumar.sharma\Test\", 
                       "C:\Users\kaushal.kumar.sharma\Test1\"
                      )
	$WinTemp = "c:\Windows\Temp\*"

# Function to Write Output to Host/ Log to file
Function WriteLog{
    Param (
        [string]$log
    )
    #write-Host $log -ForegroundColor Magenta 
    if($writeToFile -eq "true"){
        Add-Content $LogFilePath $log
    }
}

Try{
#	Empty Recycle Bin
	WriteLog "Emptying Recycle Bin."
	$objFolder.items() | %{ remove-item $_.path -Recurse -Confirm:$false}

# Remove temp files located in "C:\Users\<USERNAME>\AppData\Local\Temp"
	WriteLog "Removing Junk files in $temp2."
	Remove-Item -Recurse  "$temp2\*" -Force # -Verbose -ErrorAction SilentlyContinue

# Remove Windows Temp Directory 
	WriteLog "Removing Junk files in $WinTemp."
	Remove-Item -Recurse $WinTemp -Force 

# Remove files located in "Customfolder"
	WriteLog "Clearing Generic folder"
    Foreach ($customfolder IN $customfolders){
        Remove-Item -Recurse  "$customfolder\*" -Force # -Verbose -ErrorAction SilentlyContinue
    }
	
# Running Disk Clean up Tool (Not Tested)
#	WriteLog "Running Windows disk Clean up Tool"
#	cleanmgr /sagerun:1 | out-Null 
#	
#	$([char]7)
#	Sleep 1 
#	$([char]7)
#	Sleep 1 	
	
#	WriteLog "Cleanup task complete" 


Write-Output "true"
}
catch
{
    Write-Output "true"
}


##### End of the Script #####