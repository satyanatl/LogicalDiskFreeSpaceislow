# SOP-SCRIPT/CODE to handle case of LogicalDiskFreeSpaceislow
List of Files:

1. Error_LogicalDiskFreeSpaceislow_MMDDYYYY.ps1:
    Script is called when incident's severity is 2 (Error).
    Please repalce MMDDYYYY to actual date of deployment or onboarding
    
2. Warning_LogicalDiskFreeSpaceislow_MMDDYYYY.ps1
    Script is called when incident's severity is 3 (Warning).
    Please repalce MMDDYYYY to actual date of deployment or onboarding

3. IAFramework.ps1
    
4. Validator.ps1
    This script is validator script; called twice before and after remediation.
    It is called by its caller caller/manager script.
    
