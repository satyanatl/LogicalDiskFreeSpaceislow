# SOP-SCRIPT/CODE to handle case of LogicalDiskFreeSpaceislow
List of Files:

1. Error_LogicalDiskFreeSpaceislow_MMDDYYYY.ps1:
    This script is maintaned by Application Support Team.
    The framework (Template) is provided by IA capability team.
    Script is called when incident's severity is 2 (Error).
    Please repalce MMDDYYYY to actual date of deployment or onboarding
    Please update $customefolders="<COMMA SEPARATED FOLDER LIST>"
    
2. Warning_LogicalDiskFreeSpaceislow_MMDDYYYY.ps1
    This script is maintaned by Application Support Team.
    The framework (Template) is provided by IA capability team.
    Script is called when incident's severity is 1 (Warning).
    Please repalce MMDDYYYY to actual date of deployment or onboarding
    Please update $customefolders="<COMMA SEPARATED FOLDER LIST>"

3. IAFramework.ps1
    This script is maintained by IA Capability Team.
    This is caller/Manager script - cordinated calls between other scripts
    
4. Validator.ps1
    This script is maintained by IA Capability Team.
    This script is validator script; called twice before and after remediation.
    It is called by its caller caller/manager script.
    
