<#
Summary: 
    IA Framework script to Validate Disk space. 
    
Description: 
    This script gets disk space details and validates/Verifies whether t meets threshold.

Parameters: 
    ci_name:             Name of VM.
                            (EX. "VW123456")
    threshold:           Disk space threshold in percent.
                            (Ex. 30)
    writeToFile:         Flag for Creating log file.
                            (Values : True/False)
    waitInSec:           Wait time in seconds before each retries. 
                           (Ex. 10) Default : 10
    caller:              Caller Method.
                           (Ex. 30)
#>

Param (
    [Parameter(Mandatory = $true)]
    [string]$ci_name,
    [Parameter(Mandatory = $true)]
    [string]$Threshold,
    [Parameter(Mandatory = $true)]
    [string]$writeToFile,
    [Parameter(Mandatory = $true)]
    [string]$LogFilePath,
    [Parameter(Mandatory = $true)]
    [string]$caller
)
$ErrorActionPreference = 'SilentlyContinue'
# Function to Write Output to Host/ Log to file
Function WriteLog{
    Param (
        [string]$log
    )
    $log = "Validator : $log"
    #write-Host $log -ForegroundColor Magenta 
    if($writeToFile -eq "true"){
        Add-Content $LogFilePath $log
    }
}

WriteLog "Execution Started"
# Function to Validte if Cleanup is required
Function ValidateCleanup
{
	Param(
        [string]$svr
    )
    $reply = "true"
    $source = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3"
    #$source = Get-PSDrive -PSProvider 'FileSystem'
    foreach($a in $source) {
        If($a.VolumeName -notmatch "Temporary"){
            #$drive = $a.Root -replace "\\",""
            $drive = $a.DeviceID
            $disk = ([wmi]"\\$svr\root\cimv2:Win32_logicalDisk.DeviceID='$drive'")    
            #"Remotecomputer C: has {0:#.0} GB free of {1:#.0} GB Total" -f ($disk.FreeSpace/1GB),($disk.Size/1GB) | write-output
            $totalDiskSpace = [math]::Round(($disk.Size/1GB),2)
            $totalFreeSpace = [math]::Round(($disk.FreeSpace/1GB),2)
            $global:thresholdInGB = $totalDiskSpace * ($Threshold/100)
        
            if ($totalFreeSpace -le $global:thresholdInGB){
                $global:workingDrive = $drive
                $global:preCleanupSize = $totalFreeSpace
                $reply = "false"
                break
            }
        }
    }
    return $reply
}
# Function to Verify Cleanup
Function VerifyCleanup
{
	Param(
        [string]$svr
    )
    $reply = "true"
    $disk = ([wmi]"\\$svr\root\cimv2:Win32_logicalDisk.DeviceID='$global:workingDrive'")    
    $totalFreeSpace = [math]::Round(($disk.FreeSpace/1GB),2)
    $global:postCleanupSize = $totalFreeSpace
    if ($totalFreeSpace -le $global:thresholdInGB){
        $reply = "false"
    }
    return $reply
}
Try{
    if($caller -eq "PreCleanup"){
        $result = ValidateCleanup -svr $ci_name
    }
    else{
        $result = VerifyCleanup -svr $ci_name
    }
    if ($result -eq 'true'){
        # Disk space within threshold limit
        WriteLog "Execution completed"
        return "true"
    }
    else{
        # Disk space not within threshold limit
        WriteLog "Execution completed"
        return "false"
    }
    #Write-Host $diskSpace
}
Catch{
    WriteLog "Execution completed"
    return "Error"
}