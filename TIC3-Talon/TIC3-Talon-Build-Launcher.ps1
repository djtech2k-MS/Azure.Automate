<#   
.SYNOPSIS   
Script to deploy TIC 3.0 Connection to CISA TALON.  Powershell modules (Az.Accounts, Az.Resources), Az CLI, and Bicep must be installed with current version.  Script assumes all files are stored in the same directory.
    
.DESCRIPTION 
Script to deploy TIC 3.0 Connection to CISA TALON.  Powershell modules (Az.Accounts, Az.Resources), Az CLI, and Bicep must be installed with current version.  Script assumes all files are stored in the same directory.

.PARAMETER AADAppName
This parameter is for the Azure AD Application Name. The name must be unique. Default value is "My-Talon-Test-App".
.PARAMETER AADTenatID
This parameter is for the Azure AD Tenant ID where the app will be installed.
.PARAMETER CertPath
This parameter is for the path to the certificate to install in the AAD App. Cert must be ".cer" format.
.PARAMETER EvtHubName
This parameter is for the Event Hub name.
.PARAMETER RGName
This parameter is for the Resource Group name.
.PARAMETER Bicep
This parameter is for the path to the Bicep Template.
.PARAMETER AzureEnvironment
This parameter is for the Azure Environment.  Default is AzureCloud (Commercial).  For Azure USGov, use AzureUSGovernment.
.PARAMETER AzureSubID
This parameter is for the Azure Subscription ID.
.PARAMETER OutputFile
This parameter is for the output log for this script.  The default value is "./CDS-Log-Forwarding-CSSP.log".

.NOTES
Version: 1.0.1

You will need the current version of Powershell Modules (Az.Accounts, Az.Resources), Az CLI, and Bicep installed.

Script assumes the Resource Group specified already exists.

This script assumes that all other templates/files/scripts will be in the same directory.

Be sure to validate all parameters before running the script.

.EXAMPLE
	.\TIC3-Talon-Build-Launcher.ps1 -AADAppName "My-Talon-Test-App" -AzureSubID "My-Subscription-ID" -AADTenantID "My-AAD-Tenant-ID"

Description
-----------
This is an INCOMPLETE example of how to execute this script with command-line arguments.

Any parameter not specified will run with the default value as specified in the script.

This script assumes that all other templates/files/scripts will be in the same directory.

Be sure to validate all parameters before running the script.

Additional parameters can be sent to the Bicep template if desired.

#>

Param(
    [string]$AADAppName = "My-Talon-Test-App",
    [string]$AADTenantID = "My-AAD-Tenant-ID",
    [string]$CertPath = "C:\PATH-TO-CERT\MY-Certificate.cer",
    [string]$EvtHubName = "My-TALON-EventHub",
    [string]$RGName = "My-ResourceGroup",
    [string]$Bicep = "./TIC3-Talon-Build.bicep",
    [string]$AzureEnvironment = "AzureCloud",
    [string]$AzureSubID = "My-Azure-Subscription-ID",
    [string]$OutputFile = "./TIC3-Talon-Launcher.log"
)

Function Log {
    param(
        [string]$Out = "",
        [string]$MsgType = "Green"
    )
    $t = [System.DateTime]::Now.ToString("yyyy.MM.dd hh:mm:ss")
    set-variable -Name Now -Value $t -scope Script
    $Out = $Now +" ---- "+$Out
    $Out | add-content $Outputfile
    Write-Host $Out -ForegroundColor $MsgType
}

Function ErrorHandler($ErrMsg) {
    If ($ErrMsg){
        Log "Error Encountered" "Red"
        Log "Error Detail: $Error[0]" "Red"
        $Error.Clear()
    }
}

# Validate Cert Path
If (!(test-path $CertPath)){
    Log "Cert path is invalid" "Red"
    Log "Exiting Script" "Red"
    Read-Host "Press Any Key to Exit Script"
    Exit
}

# Install PS Modules
Try {
    Install-Module Az.Accounts
    Install-Module Az.Resources
} Catch {
    ErrorHandler $Error
    Log "Error Caught Installing PS Modules" "Red"
    Log "Exiting Script" "Red"
    Read-Host "Press Any Key to Exit Script"
    Exit
}

# Check Az CLI Install
Try {
    $CLI = Invoke-expression -Command "az version" -ErrorAction SilentlyContinue
    If ($CLI){
        Log "AZ Cli Installed...." "Green"
    } Else {
        Log "AZ Cli Missing" "Red"
        Log "Exiting Script" "Red"
        Read-Host "Press Any Key to Exit Script"
        Exit
   }
} Catch {
    ErrorHandler $Error
    Log "Error Caught Checking AZ Cli Install" "Red"
    Log "Exiting Script" "Red"
    Read-Host "Press Any Key to Exit Script"
    Exit
}

# Check Bicep Install
Try {
    $BicepInstalled = Invoke-expression -Command "bicep --version" -ErrorAction SilentlyContinue
    If ($BicepInstalled){
        Log "Bicep Installed...." "Green"
    } Else {
        Log "Bicep Missing" "Red"
        Log "Exiting Script" "Red"
        Read-Host "Press Any Key to Exit Script"
        Exit
   }
} Catch {
    ErrorHandler $Error
    Log "Error Caught Checking Bicep Install" "Red"
    Log "Exiting Script" "Red"
    Read-Host "Press Any Key to Exit Script"
    Exit
}

# Connect to Azure With Az Cmdlets
Try {
    #Connect to Appropriate Azure Environment
    Log "Connecting to Azure"
    Connect-AzAccount -Environment $AzureEnvironment
    #Attach to the Correct Subscription
    Log "Setting Azure Subscription Context"
    Set-AzContext -SubscriptionId $AzureSubID
} Catch {
    ErrorHandler $Error
    Log "Error Caught During Azure Connect and Subscription Context Setting" "Red"
    Log "Exiting Script" "Red"
    Read-Host "Press Any Key to Exit Script"
    Exit
}

# Check RG and Create If It Doesn't Exist
Try {
    $RGExists = Get-AzResourceGroup -Name $RGName
    If ($RGExists){
        Log "RG Exists...." "Green"
    } Else {
        Log "RG Missing....Exit Script and Create Manually, Then Re-Run Script." "Red"
        Log "Exiting Script" "Red"
        Read-Host "Press Any Key to Exit Script"
        Exit
   }
} Catch {
    ErrorHandler $Error
    Log "Error Caught Checking Resource Group" "Red"
    Log "Exiting Script" "Red"
    Read-Host "Press Any Key to Exit Script"
    Exit
}

# Connect to AAD With MS Graph Cmdlets
Try {
    # Connect to AAD and Create the AAD App If It Does Not Already Exist
    If ((!(Get-AzADServicePrincipal -DisplayName $AADAppName))){
        New-AzADServicePrincipal -displayname $AADAppName
        # Run a Loop Until Application Shows Up
        $Iteration = 0
        Do {$Iteration = $Iteration + 1 ; Log "Iteration: $Iteration" "Green" ; Start-Sleep -Seconds 10} Until (Get-AzADServicePrincipal -DisplayName $AADAppName)
        $App = (Get-AzADServicePrincipal -DisplayName $AADAppName)
        Log "AAD App Created: $($App.AppId)" "Green"
    } Else {
        $App = (Get-AzADServicePrincipal -DisplayName $AADAppName)
        Log "AAD App Created: $($App.AppId)" "Green"
    }
} Catch {
    ErrorHandler $Error
    Log "Error Caught Connecting to Graph and Grabbing/Creating the AAD App" "Red"
    Log "Exiting Script" "Red"
    Read-Host "Press Any Key to Exit Script"
    Exit
}

# Upload Certificate to AAD App
Try {
    # Upload Cert to AAD App
    Log "Checking App ID: $($App.AppId)" "Green"
    az login --scope https://graph.microsoft.com//.default
    az ad app credential reset --id $App.appId --cert `@$CertPath
} Catch {
    ErrorHandler $Error
    Log "Error Caught Doing Az Login and Cert Upload" "Red"
    Log "Exiting Script" "Red"
    Read-Host "Press Any Key to Exit Script"
    Exit
}

# Call Bicep Template
# Setup Hashtable for Bicep Params
$DeployParams = @{
    evtHubName = $EvtHubName
    principalId = $App.Id
}

# Run the Bicep Template
Try {
    New-AzResourceGroupDeployment -ResourceGroupName $RGName -TemplateFile $Bicep -TemplateParameterObject $DeployParams
} Catch {
    ErrorHandler $Error
    Log "Error Caught Launching Bicep Deployment" "Red"
    Log "Variables :: $RGNAME :: $Bicep :: $DeployParams"
    Log "Exiting Script" "Red"
    Read-Host "Press Any Key to Exit Script"
    Exit
}