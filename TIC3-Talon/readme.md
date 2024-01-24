The code in this section was created to automate the creation of the connection to the CISA, which is part of the TIC 3.0 Requirements 
(https://www.cisa.gov/resources-tools/programs/trusted-internet-connections-tic).  This automation is one piece of the process but can 
be used in conjunction with the documented CISA TIC 3.0 deployment process.


References
https://www.cisa.gov/resources-tools/programs/trusted-internet-connections-tic
https://learn.microsoft.com/en-us/azure/azure-government/compliance/compliance-tic

This powershell and bicep code will help automate the deployment of the resources needed to connect to CISA's TALON.  You will need to call the powershell script with the correct parameter values.  The powershell code will then call the bicep code.

Notes:  

You must already have your certificate before using this code.

The powershell script has help information so it can be viewed in your text editor or by using powershell help cmdlet Get-Help <scriptName>.

Please note that this code does require specific powershell modules, Azure CLI, and Bicep to be installed prior to executing.


Disclaimer:  
Microsoft provides this information to FCEB departments and agencies as part of a suggested configuration to facilitate participation in CISA’s CLAW and TALON capability. This suggested configuration is maintained by Microsoft and is subject to change.
