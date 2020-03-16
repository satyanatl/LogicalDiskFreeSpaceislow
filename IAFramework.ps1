<#
Summary: 
    IA Framework script to perform cleanup. 
    
Description: 
    This script is main script which executes SOP remediation script/s. Prior to performing Remediation it validates 
    whether disk cleanup is required. If required it executes disk cleanup script/s and again validates whether the 
    cleanup have freed up enough space to match threshold.

Parameters: 
    ci_name:             Name of VM.
                            (EX. "VW123434")
    issue_type:           Type of issue.
                            (Ex. "Logical Disk Free Space is low")
    remediation_retry:    Number of retry to take if cleanup doesn't create enough space to meet threshold.
                            (Ex. 2) Default : 2
    fqdn:                 Complete url of VM. 
                            (Ex. "VW123434.dir.svc.accenture.com")
    script_path:          Absolute path to Cleanup script file.
                            (Ex. "D:\SOP\")
    script_name:          Name of Remediation script. 
                            (Ex. "Warning_LogicalDiskFreeSpaceislow_03042020.PS1")
    retry:                Number of retries in case of error. 
                            (Ex. 2) Default : 2
    threshold:            Disk space threshold in percent.
                            (Ex. 30)
    writeToFile:          Flag for Creating log file.
                            (Values : True/False)
    waitInSec:            Wait time in seconds before each retries. 
                            (Ex. 10) Default : 10

Sample Call: .\IAFramework.ps1 "VRTVA25710" "Logical Disk Free Space is low" 2 "VRTVA25710.dir.svc.accenture.com" "C:\Users\kaushal.kumar.sharma\source\SCOM_PS\" "Warning_Logical Disk Free Space is low_03042020.PS1" 2 20 "True" 10
#>

Param(
    [Parameter(Mandatory = $true)]
    [string]$ci_name = "VRTVA25710",
    [Parameter(Mandatory = $true)]
    [string]$issue_type = "Logical Disk Free Space is low",
    [Parameter(Mandatory = $true)]
    [int]$remediation_retry = 2,
    [Parameter(Mandatory = $true)]
    $fqdn = "VRTVA25710.dir.svc.accenture.com",
    [Parameter(Mandatory = $true)]
    $script_path= "C:\Users\kaushal.kumar.sharma\source\SCOM_PS\",
    [Parameter(Mandatory = $true)]
    $script_name = "Warning_LogicalDiskFreeSpaceislow_03042020.PS1",
    [Parameter(Mandatory = $true)]
    $retry = 2,
    [Parameter(Mandatory = $true)]
    $threshold = 22,
    [Parameter(Mandatory = $true)]
    $writeToFile = "true",
    [Parameter(Mandatory = $true)]
    $waitInSec = 10
)
$LogFolderPath =  $script_path + "\Log\"
$LogFilePath =  $script_path + "\Log\" + $ci_name +"_SOP_Log.txt"
$script_abs_path_prevalidation = $script_path + "\Validator.ps1"
$script_abs_path_remediation = $script_path + "\" + $script_name
$finalReply = ""


# Function to Write Output to Host/ Log to file.
Function WriteLog{
    Param (
        [string]$log
    )
    If(!(test-path $LogFolderPath))
    {
        New-Item -ItemType Directory -Force -Path $LogFolderPath | Out-Null
    }
    
    write-Host $log -ForegroundColor Magenta 
    if($writeToFile -eq "true"){
        Add-Content $LogFilePath $log
    }
}
WriteLog "IAFramework.ps1 : Executing"

# Function to call validator script.
Function CallVarifier
{
    Param (
        [string]$ci_name,
        [string]$threshold
        )
        WriteLog "IAFramework.ps1 : Calling CallValidator.ps1"
        try{
            $result = Invoke-Expression "$script_abs_path_prevalidation $ci_name $threshold $writeToFile $LogFilePath"
        }
        catch{
            WriteLog "IAFramework.ps1 : Failed to execute CallValidator.ps1"
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
        WriteLog "IAFramework.ps1 : Calling SOPRemediation.ps1"
        try{
            # Add Authentication to execute scripts on remote servers.
            # Need to create Runspace while connecting to remote servers.
            $result = Invoke-Expression "$script_path_remediation $ci_name $writeToFile $LogFilePath"
        }
        catch{
            WriteLog "IAFramework.ps1 : Failed to execute SOPRemediation.ps1"
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

WriteLog "IAFramework.ps1 : RetryRemediation Started."
For ($retrySOP = 1; $retrySOP -le $remediation_retry; $retrySOP++){
    
    $logVal = "IAFramework.ps1 : Remediation Retry waiting for " + ($waitInSec) + " seconds"
    WriteLog $logVal
    Start-Sleep -s $waitInSec #Wait for few seconds(based on var value) before retrying.
    $logVal = "IAFramework.ps1 : Remediation Retry " + ($retrySOP)
    WriteLog $logVal

    $resultSOPRemediation1 = CallSOPRemediation -ci_name $ci_name -script_path_remediation $script_abs_path_remediation -script_path_prevalidation $script_abs_path_prevalidation
    if($resultSOPRemediation1 -eq "true"){
        $resultValidator1 = CallVarifier -ci_name $ci_name -threshold $threshold
        if($resultValidator1 -ne $null){
            if($resultValidator1 -eq "true"){
                $status = "true"
                WriteLog "IAFramework.ps1 : Remediation successful after retry."
            }
        }
    }
}
WriteLog "IAFramework.ps1 : RetryRemediation Completed."
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
        New-item $LogFilePath -Force    
    }
    
# Call Validator to ensure if Disk Space is below Threshold
   
For ($counterV1=1; $counterV1 -le $retry){
    if($flagVerifier = "false"){
    $resultVerifier = CallVarifier -ci_name $ci_name -threshold $threshold #"40"
    if($resultVerifier -eq "false"){
        $flagVerifier = "true"
        for ($counterR=1; $counterR -le $retry){
            if($flagSOP -eq "false"){
                $counterR = $counterR + 1
                $resultSOPRemediation = CallSOPRemediation -ci_name $ci_name -script_path_remediation $script_abs_path_remediation -script_path_prevalidation $script_abs_path_prevalidation
                if($resultSOPRemediation -eq "true"){
                    $flagSOP = $resultSOPRemediation
                    for ($counterV=1; $counterV -le $retry){
                        if($flagValidator -eq "false"){
                            $counterV = $counterV + 1
                            $resultValidator = CallVarifier -ci_name $ci_name -threshold $threshold
                    
                            if($resultValidator -ne $null){
                                $flagValidator = "true"
                                if($resultValidator -eq "true"){
                                    WriteLog "IAFramework.ps1 : Execution completed" #Disk Cleanup successful
                                }
                                else{
                                    # Retry Remediation
                                    
                                    $resultSOPRemediationRetry = RetryRemediation -ci_name $ci_name -script_path_remediation $script_abs_path_remediation -script_path_prevalidation $script_abs_path_prevalidation
                                    if($resultSOPRemediationRetry -eq "true"){
                                        WriteLog "IAFramework.ps1 : Execution completed. Remediation Successful."
                                        $finalReply = Get-Content $LogFilePath
                                        #$finalReply =  $finalReply1 | Select-Object -Skip 1
                                        #$finalReply = "IAFramework.ps1 : Execution completed. Remediation Successful."  #Disk Cleanup successful after retry
                                    }
                                    else{
                                        WriteLog "IAFramework.ps1 : Execution completed, Manual Remeditiation required."
                                        #$finalReply = "IAFramework.ps1 : Execution completed, Manual Remeditiation required."
                                        $finalReply = Get-Content $LogFilePath #Disk cleanup not successful
                                        
                                    }
                                    
                                }
                                WriteLog $resultValidator
                                Write-output $resultValidator
                            }
                            else{
                                if($counterV -gt $retry){
                                    $flagValidator = "true"
                                    exit
                                }
                                WriteLog "IAFramework.ps1 : Execution completed"
                                Write-output $resultValidator
                            }
                            if($flagValidator -eq "true"){
                                exit
                            }
                        }
                    }
                }
                else{
                    if($counterR -gt $retry){
                        WriteLog "IAFramework.ps1 : Error occured! Retry Later."
                        WriteLog "false"
                        return "false"
                        $flagSOP = "true"
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
            WriteLog "IAFramework.ps1 : Execution completed, No Remediation Required."
            #$finalReply = "IAFramework.ps1 : Execution completed, No Remediation Required."
            $finalReply = Get-Content $LogFilePath
            
            WriteLog "true"
            return $finalReply #Adequate Space in Disk
        }
        else{
            WriteLog "IAFramework.ps1 : Error occured! Retry Later."
            #$finalReply = "IAFramework.ps1 : Error occured! Retry Later."
            $finalReply = Get-Content $LogFilePath
            WriteLog "error"
            $finalReply  # Network/any error
        }
    }  
}  
} #end ForLoop

} #end StartProcessing


# Call Function to start Remediation Process
$result = StartProcessing | Select-Object -Skip 1
$result
#Write-Output "Remediation Performed Successfully"