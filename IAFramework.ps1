<#
Summary: 
    IA Framework script to perform cleanup. 
    
Description: 
    This script is main script which executes SOP remediation script/s. Prior to performing Remediation it validates 
    whether disk cleanup is required. If required it executes disk cleanup script/s and again validates whether the 
    cleanup have freed up enough space to match threshold.

Parameters: 
    ci_name:             Name of VM.
                            (EX. "VW123456")
    issue_type:           Type of issue.
                            (Ex. "Logical Disk Free Space is low")
    remediation_retry:    Number of retry to take if cleanup doesn't create enough space to meet threshold.
                            (Ex. 2) Default : 2
    fqdn:                 Complete url of VM. 
                            (Ex. "VW123456.dir.svc.accenture.com")
    script_path:          Absolute path to Cleanup script file.
                            (Ex. "D:\SOP\")
    script_name:          Name of Remediation script. 
                            (Ex. "Warning_LogicalDiskFreeSpaceislow_03042020.ps1")
    retry:                Number of retries in case of error. 
                            (Ex. 2) Default : 2
    threshold:            Disk space threshold in percent.
                            (Ex. 30)
    writeToFile:          Flag for Creating log file.
                            (Values : True/False)
    waitInSec:            Wait time in seconds before each retries. 
                            (Ex. 10) Default : 10

Sample Call: .\IAFramework.ps1 "<VMNAME>" "Logical Disk Free Space is low" 2 "<VMNAME>.dir.svc.accenture.com" "C:\Users\<username>\source\PsScripts\SCOM_PS\" "Warning_LogicalDiskFreeSpaceislow_MMDDYYYY.ps1" 2 20 "True" 10
#>

Param(
    [Parameter(Mandatory = $true)]
    [string]$ci_name,
    [Parameter(Mandatory = $true)]
    [string]$issue_type,
    [Parameter(Mandatory = $true)]
    [int]$remediation_retry,
    [Parameter(Mandatory = $true)]
    $fqdn,
    [Parameter(Mandatory = $true)]
    $script_path,
    [Parameter(Mandatory = $true)]
    $script_name,
    [Parameter(Mandatory = $true)]
    $retry,
    [Parameter(Mandatory = $true)]
    $threshold,
    [Parameter(Mandatory = $true)]
    $writeToFile,
    [Parameter(Mandatory = $true)]
    $waitInSec
)
$global:thresholdInGB = $null
$global:preCleanupSize = $null
$global:postCleanupSize = $null
$global:workingDrive = ""
$ErrorActionPreference = 'SilentlyContinue'
$LogFolderPath =  $script_path + "\Log\"
$LogFilePath =  $script_path + "\Log\" + $ci_name +"_SOP_Log.txt"
$script_abs_path_prevalidation = $script_path + "\Validator.ps1"
$script_abs_path_remediation = $script_path + "\" + $script_name
$finalReply = ""


# Function to Write Output to Host/Log to file.
Function WriteLog{
Param (
    [string]$log
)
If(!(test-path $LogFolderPath)){
    New-Item -ItemType Directory -Force -Path $LogFolderPath | Out-Null
}
$log = "IAFramework : $log"
#write-Host $log -ForegroundColor Magenta 
if($writeToFile -eq "true"){
    Add-Content $LogFilePath $log
}
}

# Function to call validator script.
Function CallVarifier
{
Param (
    [string]$ci_name,
    [string]$threshold,
    [string]$caller
)
WriteLog "Calling Validator.ps1"
try{
    $result = Invoke-Expression "$script_abs_path_prevalidation $ci_name $threshold $writeToFile $LogFilePath $caller"
}
catch{
    WriteLog "Failed to execute Validator.ps1"
    $result = "An Error Occured, Please try again later."
}
Write-Output $result
}

# Function to perform CleanUp
Function CallSOPRemediation
{
Param (
    [string]$ci_name,
    [string]$script_path_remediation,
    [string]$script_path_prevalidation
)
WriteLog "Calling $script_name"
try{
    # Add Authentication to execute scripts on remote servers.
    # Need to create Runspace while connecting to remote servers.
    $result = Invoke-Expression "$script_path_remediation $writeToFile $LogFilePath"
}
catch{
    WriteLog "Failed to execute $script_name"
    $result = "error"
}
Write-Output $result
}

# Cleanup Retry if Remediation didn't work
Function RetryRemediation{
Param (
    [string]$ci_name,
    [string]$script_path_remediation,
    [string]$script_path_prevalidation
)
$status = "false"

WriteLog "RetryRemediation Started."
For ($retrySOP = 1; $retrySOP -le $remediation_retry; $retrySOP++){
    
$logVal = "Remediation Retry waiting for " + ($waitInSec) + " seconds"
WriteLog $logVal
Start-Sleep -s $waitInSec #Wait for few seconds(based on var value) before retrying.
$logVal = "Remediation Retry " + ($retrySOP)
WriteLog $logVal

$resultSOPRemediation1 = CallSOPRemediation -ci_name $ci_name -script_path_remediation $script_abs_path_remediation -script_path_prevalidation $script_abs_path_prevalidation
if($resultSOPRemediation1 -eq "true"){
    $resultValidator1 = CallVarifier -ci_name $ci_name -threshold $threshold -caller "PostCleanup"
    if($resultValidator1 -ne $null){
        if($resultValidator1 -eq "true"){
            $status = "true"
            WriteLog "Remediation successful after retry."
        }
    }
}
}
WriteLog "RetryRemediation Completed."
$status
}

# Main Function to Monitor all other functions
function StartProcessing{
$counterV1 = 1
$counterR = 1
$counterV = 1
$flagVerifier = "false"
$flagSOP = "false"
$flagValidator = "false"

if($writeToFile -eq "true"){
    New-item $LogFilePath -Force | Out-Null
    WriteLog "Execution Started"
}
    

For ($counterV1=1; $counterV1 -le $retry){
    if($flagVerifier = "false"){
    # Call Validator to ensure if Disk Space is below Threshold
    $resultVerifier = CallVarifier -ci_name $ci_name -threshold $threshold -caller "PreCleanup" #"40"
    if($resultVerifier -eq "false"){
        $flagVerifier = "true"
        for ($counterR=1; $counterR -le $retry){
            if($flagSOP -eq "false"){
                $counterR = $counterR + 1
                # Call Cleanup Script
                $resultSOPRemediation = CallSOPRemediation -ci_name $ci_name -script_path_remediation $script_abs_path_remediation -script_path_prevalidation $script_abs_path_prevalidation
                if($resultSOPRemediation -eq "true"){
                    $flagSOP = $resultSOPRemediation
                    for ($counterV=1; $counterV -le $retry){
                        if($flagValidator -eq "false"){
                            $counterV = $counterV + 1
                            $resultValidator = CallVarifier -ci_name $ci_name -threshold $threshold -caller "PostCleanup"
                    
                            if($resultValidator -ne $null){
                                $flagValidator = "true"
                                if($resultValidator -eq "true"){
                                    $logVal = "Execution completed, Cleanup Successful."
                                    WriteLog $logVal #Disk Cleanup successful
                                }
                                else{
                                    # Retry Remediation
                                    $resultSOPRemediationRetry = RetryRemediation -ci_name $ci_name -script_path_remediation $script_abs_path_remediation -script_path_prevalidation $script_abs_path_prevalidation
                                    if($resultSOPRemediationRetry -eq "true"){
                                        $logVal = "Execution completed. Cleanup Successful after retry." 
                                        WriteLog $logVal #Disk cleanup successful
                                    }
                                    else{
                                        $logVal = "Execution completed, Manual Remeditiation required."
                                        WriteLog $logVal #Disk cleanup not successful
                                    }
                                }
                                #$finalReply = Get-Content $LogFilePath
                                $finalReply = $logVal
                                return $finalReply
                            }
                            else{
                                if($counterV -gt $retry){
                                    $flagValidator = "true"
                                    exit
                                }
                                $logVal = "Execution completed, cleanup done"
                                WriteLog $logVal
                                #$finalReply = Get-Content $LogFilePath
                                $finalReply = $logVal
                                return $finalReply
                            }
                            if($flagValidator -eq "true"){
                                exit
                            }
                        }
                    }
                }
                else{
                    if($counterR -gt $retry){
                        $logVal = "Error occured! Retry Later."
                        WriteLog $logVal
                        WriteLog "false"
                        $flagSOP = "true"
                        $finalReply = $logVal
                        return $finalReply
                        exit
                    }
                }
            } #end if
            #exit    
        }
    }
    else{
        $counterV1 = $counterV1 + 1
        if($resultVerifier -eq "true"){
            $flagVerifier = "true"
            $logVal = "Execution completed, No Remediation Required."
            WriteLog $logVal
            #$finalReply = Get-Content $LogFilePath
            $finalReply = $logVal
            
            WriteLog "true"
            return $finalReply #Adequate Space in Disk
        }
        else{
            $logVal = "Error occured! Retry Later."
            WriteLog $logVal
            #$finalReply = Get-Content $LogFilePath
            $finalReply = $logVal
            WriteLog "error"
            $finalReply  # Network/any error
        }
    }  
}  
} #end ForLoop

} #end StartProcessing


# Call Function to start Remediation Process
$result = StartProcessing
if($result -notmatch "No Remediation Required"){
    $msgSuccess = "Disk Cleanup was successful using TAO (Touchless Auto-Healing Orchastration)"
    $msgFail = "Disk Cleanup had failed using TAO (Touchless Auto-Healing Orchastration)"
    $newline = "`r`n"
    $preSpace = "Before Cleanup Disk Space: " + (&{If($preCleanupSize -ne $null) {$preCleanupSize} Else {"..."}})
    $postSpace = "New Free Disk Space: " + (&{If($postCleanupSize -ne $null) {$postCleanupSize} Else {"..."}})
    if($result -match "Successful"){
        $result = "$msgSuccess$newline$result$newline$preSpace$newline$postSpace"
    }
    else{
        $result = "$msgFail$newline$result$newline$preSpace$newline$postSpace"    
    }
    #$result1 =  $result | Select-Object -Skip 1
}
$result

#Write-Output "Remediation Performed Successfully"