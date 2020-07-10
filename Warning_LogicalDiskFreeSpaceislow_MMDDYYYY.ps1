<#
Summary: 
    Script to cleanup Disk space. 
    
Description: 
    This script Cleans up disk space.It is to be be modified by application team. Based on specific need steps can be added/removed.

Parameters: 
    writeToFile: Flag for Creating log file.
        (Values : True/False)
    LogFilePath: Log file Path. 
        (Ex. ".\Log\")
    BasePath: Script Location. 
        (Ex. "D:\TAO\1234\")
#>
Param (
    [Parameter(Mandatory = $true)]
    [string]$writeToFile,
    [Parameter(Mandatory = $true)]
    [string]$LogFilePath,
    [Parameter(Mandatory = $true)]
    [string]$BasePath
    )
    $ErrorActionPreference = 'SilentlyContinue'
    $RestrictedPaths = @("","C:","C:Documents and Settings","C:Program Files","C:Program Files (x86)","C:Recovery","C:Windows","D:")
    
    $cioToolsFolder = "C:\Windows\CIOTools\ED\"
    $EDScriptName = "StartCleanup.ps1"
    $EDScriptPath = "$cioToolsFolder$EDScriptName"

    $customizationFolder = "external"
    $settingFileName = "Tao_Warning_Customization.txt"
    
    $pidFileName = "$BasePath\Log\pid.txt"
    
    $newline = "`r`n"

    $global:flagRecycleBin = $null
    $global:flagWinTemp = $null
    $global:flagUserTemp = $null
    $global:flagCustomFolder = $null
    $global:flagCustomScripts = $null
    $global:flagEDScripts = $null
    $global:customfolders = $null

# Function to Write Output to Host/ Log to file
Function WriteLog{
    Param (
        [string]$log
    )
    $log = "Cleanup : $log"
    #write-Host $log -ForegroundColor Magenta 
    if($writeToFile -eq $true){
        Add-Content $LogFilePath $log
    }
}

# Read setting file and set flags
Function SetFlags{
    $myName = (&{If($PSCommandPath -ne $null) {$PSCommandPath} Else {(&{If($MyInvocation.ScriptName -ne $null) {$MyInvocation.ScriptName} Else {$MyInvocation.PSCommandPath}})}})
    if($myName -match "Error_LogicalDiskFreeSpaceislow_" -and $myName -ne $null){
        $settingFileName = "Tao_Error_Customization.txt"
    }
    else{
        $settingFileName = "Tao_Warning_Customization.txt"
    }
    $paramsTxt = Get-Content -Path "$BasePath\$customizationFolder\$settingFileName"
    $paramsPSObj = $paramsTxt | ConvertFrom-Json    
    $global:flagRecycleBin = $paramsPSObj.flagRecycleBin
    $global:flagWinTemp = $paramsPSObj.flagWinTemp
    $global:flagUserTemp = $paramsPSObj.flagUserTemp
    $global:flagCustomFolder = $paramsPSObj.flagCustomFolder
    $global:flagCustomScripts = $paramsPSObj.flagCustomScripts
    $global:flagEDScripts = $paramsPSObj.flagEDScripts
    $global:customfolders = $paramsPSObj.customfolders

    $ParamLog = "Parameters - writeToFile: "+ $writeToFile + " ,LogFilePath: " + $LogFilePath + " ,BasePath: " + $BasePath + " ,flagRecycleBin: " + $global:flagRecycleBin + " ,flagWinTemp: " + $global:flagWinTemp + " ,flagUserTemp: " + $global:flagUserTemp + " , flagCustomFolder: " + $global:flagCustomFolder + " ,flagCustomScripts: " + $global:flagCustomScripts + " ,flagEDScripts: " + $global:flagEDScripts + " ,myName : " + $myName
    WriteLog $ParamLog
}


Function GetProcessDetail{
    Param(
        [int] $previousPid,
        [String] $sTime
    )
    $pidDetails = Get-Process -Id $previousPid
    if($pidDetails -ne $null){
        $sTime1 = $pidDetails.StartTime.ToString()
        if($sTime -eq $sTime1){
            if($Global:retry_counter_val -ne 1){
                $Global:ed_stat = "Running"
            }
            return $true
        }
        else{
            if($Global:retry_counter_val -ne 1){
                $Global:ed_stat = "Finished"
            }
            return $false
        }
    }
    else{
        if($Global:retry_counter_val -ne 1){
            $Global:ed_stat = "Finished"
        }
        return $false
    }
}

#=Placeholder for pre-validation of expected sized of delete and exclusion==
function ValidateSize{
    Param(
        [string] $folderPath
    )
    return $true
}

#===========================================================================

Try{
# Setup flag values
    SetFlags    

# Execute ED Scripts at C:\Windows\CIOTools\ED 
    if($global:flagEDScripts -eq $true){
        WriteLog "Executing ED Scripts"
        If((test-path $EDScriptPath))
        {
            $previousProcess = Get-Content -Path $pidFileName
            $previousProcessDetails = GetProcessDetail -previousPid $previousProcess[0] -sTime $previousProcess[1]
            if($previousProcessDetails -eq $false -and $global:retry_counter_val -eq 1){
                $argVal = "-File " + $EDScriptPath
                $proc_ED = Start-Process -FilePath "powershell.exe" -WindowStyle Hidden -PassThru -ArgumentList $argVal
                $startTime = $proc_ED.StartTime.ToString()
                $contentVal = "{0}{1}{2}" -f $proc_ED.Id, $newline, $startTime
                Set-Content -Path $pidFileName -Value $contentVal
            }
        }
    }

# Empty Recycle Bin
    if($global:flagRecycleBin -eq $true){
        $objShell = New-Object -ComObject Shell.Application
	    $objFolder = $objShell.Namespace(0xA)

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
    if($global:flagUserTemp -eq $true){
        $temp = get-ChildItem "env:\TEMP"
	    $usrTemp = $temp.Value
        WriteLog "Removing Junk files in $usrTemp."
	    Remove-Item -Recurse  "$usrTemp\*" -Force # -Verbose -ErrorAction SilentlyContinue
    }
	
# Remove Windows Temp Directory 
    if($global:flagWinTemp -eq $true){
    	$WinTemp = "c:\Windows\Temp\*"    
        WriteLog "Removing Junk files in $WinTemp."
	    Remove-Item -Recurse $WinTemp -Force 
    }	

# Remove files located in "Customfolder"
    if($global:flagCustomFolder -eq $true){
        WriteLog "Clearing Generic folder"
        Foreach ($customfolder IN $customfolders){
            $customfolderWithoutSlash = $customfolder.replace("\","")
            if($RestrictedPaths -notcontains $customfolderWithoutSlash){
                if (Test-Path "$customfolder"){
                    Remove-Item -Recurse "$customfolder\*" -Force
                }
            }
        }
    }

# Execute Custom scripts by created by Application team
    if($global:flagCustomScripts -eq $true){
        WriteLog "Executing Custom Scripts"
        $customizationFolderPath = ".\$customizationFolder\"
        $customPSScripts = Get-ChildItem -Path $customizationFolderPath -ErrorAction "SilentlyContinue"
        $customPSScripts | ForEach-Object{
            if($_.Extension -eq ".ps1"){
                $argVal = "-File " + $_.FullName
                $proc_CS = Start-Process -FilePath "powershell.exe" -WindowStyle Hidden -PassThru -ArgumentList $argVal
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
