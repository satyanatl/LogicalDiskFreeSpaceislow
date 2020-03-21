<#
Summary: 
    IA Framework script to Validate Disk space. 
    
Description: 
    This script gets disk space details and validates/Verifies whether t meets threshold.

Parameters: 
    ci_name:             Name of VM.
                            (EX. "VW123456")
    threshold:            Disk space threshold in percent.
                            (Ex. 30)
    writeToFile:          Flag for Creating log file.
                            (Values : True/False)
    waitInSec:            Wait time in seconds before each retries. 
                           (Ex. 10) Default : 10
#>

Param (
    [Parameter(Mandatory = $true)]
    [string]$ci_name,
    [Parameter(Mandatory = $true)]
    [string]$Threshold,
    [Parameter(Mandatory = $true)]
    [string]$writeToFile,
    [Parameter(Mandatory = $true)]
    [string]$LogFilePath
)

$global:thresholdInGB = 0
# Function to Write Output to Host/ Log to file
Function WriteLog{
    Param (
        [string]$log
    )
    write-Host $log -ForegroundColor Magenta 
    if($writeToFile -eq "true"){
        Add-Content $LogFilePath $log
    }
}

WriteLog "Validator.ps1 : Executing"
Function GetDiskSpace
{
	Param(
        [string]$svr
    )
    $reply = "true"
    $source = Get-PSDrive -PSProvider 'FileSystem'
    foreach($a in $source) {
        $drive = $a.Root -replace "\\",""
        $disk = ([wmi]"\\$svr\root\cimv2:Win32_logicalDisk.DeviceID='$drive'")    
        #"Remotecomputer C: has {0:#.0} GB free of {1:#.0} GB Total" -f ($disk.FreeSpace/1GB),($disk.Size/1GB) | write-output
        $totalDiskSpace = [math]::Round(($disk.Size/1GB),2)
        $totalFreeSpace = [math]::Round(($disk.FreeSpace/1GB),2)
        $global:thresholdInGB = $totalDiskSpace * ($Threshold/100)
        
        if ($totalFreeSpace -le $global:thresholdInGB){
            $reply = "false"
            break
        }
    }
    return $reply
}
Try{
    $result = GetDiskSpace -svr $ci_name
    if ($result -eq 'true'){
        # Disk space within threshold limit
        WriteLog "Validator.ps1 : Execution completed"
        return "true"
    }
    else{
        # Disk space not within threshold limit
        WriteLog "Validator.ps1 :  Execution completed"
        return "false"
    }
    #Write-Host $diskSpace
}
Catch{
    WriteLog "Validator.ps1 : Execution completed"
    return "Error"
}