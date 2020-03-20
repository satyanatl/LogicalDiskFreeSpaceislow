 Param (
    [Parameter(Mandatory = $true)]
    [string]$writeToFile,
    [Parameter(Mandatory = $true)]
    [string]$LogFilePath
    )

	$objShell = New-Object -ComObject Shell.Application
	$objFolder = $objShell.Namespace(0xA)
	$temp = get-ChildItem "env:\TEMP"
	$temp2 = $temp.Value
	$customfolders = @("C:\Users\kaushal.kumar.sharma\Test\customfolder\",
                       "C:\Users\kaushal.kumar.sharma\Test\customfolder1\"
                      )
	$WinTemp = "c:\Windows\Temp\*"
# Function to Write Output to Host/ Log to file(to be implemented later)
Function WriteLog{
    Param (
        [string]$log
    )
    write-Host $log -ForegroundColor Magenta 
    if($writeToFile -eq "true"){
        Add-Content $LogFilePath $log
    }
}

Try{
    # Remove files located in "Customfolder"
	WriteLog "Clearing Generic folder"
    Foreach ($customfolder IN $customfolders){
        Remove-Item -Recurse  "$customfolder\*" -Force -Verbose
    }
	

# Remove temp files located in "C:\Users\USERNAME\AppData\Local\Temp"
	WriteLog "Removing Junk files in $temp2."
	Remove-Item -Recurse  "$temp2\*" -Force -Verbose

#	Empty Recycle Bin
	WriteLog "Emptying Recycle Bin."
	$objFolder.items() | %{ remove-item $_.path -Recurse -Confirm:$false}
	
# Remove Windows Temp Directory 
	WriteLog "Removing Junk files in $WinTemp."
	Remove-Item -Recurse $WinTemp -Force 
	
# Running Disk Clean up Tool 
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
    Write-Output "false"
}


##### End of the Script #####
