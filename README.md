# SOP-SCRIPT/CODE to handle case of LogicalDiskFreeSpaceislow

FOLDER STRUCTURE:

D:\TAO\<AIR-ID>\
	|
	|- IAFramework.ps1
	|- Validator.ps1
	|- Error_LogicalDiskFreeSpaceislow_MMDDYYYY.ps1
	|- Warning_LogicalDiskFreeSpaceislow_MMDDYYYY.ps1
	|
	|-external
	|	|
	|	|-Tao_Error_Customization.txt
	|	|-Tao_Warning_Customization.txt
	|	|-Additional custom scripts goes here.
	|
	|-Log
		|
		|-Execution Log file goes hare.

FILE DETAILS:

1. Error_LogicalDiskFreeSpaceislow_MMDDYYYY.ps1:
    This script is maintained by Application Support Team.
    The framework (Template) is provided by IA capability team.
    Script is called when incident's severity is 2 (Error).
    
2. Warning_LogicalDiskFreeSpaceislow_MMDDYYYY.ps1
    This script is maintained by Application Support Team.
    The framework (Template) is provided by IA capability team.
    Script is called when incident's severity is 1 (Warning).

3. IAFramework.ps1
    This script is maintained by IA Capability Team.
    This is caller/Manager script - coordinated calls between other scripts
    
4. Validator.ps1
    This script is maintained by IA Capability Team.
    This script is validator script; called twice before and after remediation.
    It is called by its caller caller/manager script.
    
5. .\external\Tao_Error_Customization.txt
	This script is maintained by application Team. 
	Application Team can set flag values to either True\False, which will impact cleanup options 
	in Error_LogicalDiskFreeSpaceislow_MMDDYYYY.ps1 script.
	
	Find more details in Configuration update Guideline section.
	
5. .\external\Tao_Warning_Customization.txt
	This script is maintained by application Team. 
	Application Team can set flag values to either True\False, which will impact cleanup options 
	in Warning_LogicalDiskFreeSpaceislow_MMDDYYYY.ps1 script.
	
	Find more details in Configuration update Guideline section.
	
CONFIGURATION UPDATE GUIDELINES
	Default values of flags:
		flagRecycleBin		True
		flagWinTemp			True
		flagUserTemp		True
		flagEDScripts		True
		flagCustomFolder	False
		flagCustomScripts	False
		
	1. Application Team can set flag values to either True\False, which will impact cleanup options in 
	2. Error_LogicalDiskFreeSpaceislow_MMDDYYYY.ps1 script.
	3. If flagCustomFolder is set to True, Custom Folder list provided in customfolders*$ will be cleaned up.
	4. If flagCustomScripts is set to True, Any powershell script (extension .ps1) placed under external** 
	   folder will be executed.



* Values for customfolders should be separated by comma(,) and there should be double backslash(\\) in the absolute path.
		"customfolders":["D:\\Taotest\\","D:\\Taotest1\\"]
$ Be cautious of which folder path is placed in customfolders, as it might delete unintended folder\files.
** Any Powershell Script placed under "TAO\<AIR-ID>\external" will be executed(if flagCustomScripts is True) at 
  the end of all the execution.
  
  
*************************************************************************************************************************
