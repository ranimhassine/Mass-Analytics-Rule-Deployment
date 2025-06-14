<#
    .DESCRIPTION
        You can leverage this script to create multiple scheduled analytics rules from the analytics rules templates on github https://github.com/Azure/Azure-Sentinel/tree/master/Detections.

    .PARAMETER subscriptionId
        Specify the subscriptionID GUID where your Sentinel Workspace Resides
    .PARAMETER resourceGroupName
        Specify the Resource Group Name where your Sentinel Workspace Resides
    .PARAMETER workspaceName
        Specify the Sentinel Workspace Name
    .PARAMETER githubToken
        Specify the GitHub Access Personal Access Token you created. Refer to the steps in [] to configure this token correctly.
    .PARAMETER apiVersion
        Optionally you can specify the API version of the Microsoft.SecurityInsights/alertRules endpoint
    .PARAMETER name
        Optionally you can enter the name of an Analytic Rule to Filter on. This parameter supports the -like operator for filtering
    .PARAMETER severity
        Optionally you can enter one or more rule severities separated by commas to filter rule templates on
    .PARAMETER detectionFolderName
        Optionally you can enter one or more child folders under https://github.com/Azure/Azure-Sentinel/tree/master/Detections separated by commas to filter rule templates on
    .PARAMETER techniques
        Optionally you can enter one or more techniques separated by commas to filter rule templates on
    .PARAMETER tactics
        Optionally you can enter one or more tactics separated by commas to filter rule templates on
    .PARAMETER dataConnector
        Optionally you can enter one or more dataConnector names separated by commas to filter rule templates on
    .PARAMETER dataType
        Optionally you can enter one or more data type names separated by commas to filter rule templates on. Data Type names refer to the table names in Sentinel
    .PARAMETER queryFilter
        Optionally you can enter one or more strings separated by commas to filter the query in the rule templates on. A common example is to filter based on tables names
    .PARAMETER tag
        Optionally you can enter one or more tag names separated by commas to filter rule templates on
     .PARAMETER enable
        Optionally you set the enable parameter to false to create rules but not enable them by default
    .PARAMETER reportOnly
        Optionally you can specify the reportOnly parameter to only report on what templates will be created
    .PARAMETER selectUI
        Optionally you can specify the selectUI parameter to show a UI to further select specific rules to import

    .EXAMPLE
        Create rules from all templates
        $rules = .\create-scheduledRuleFromTemplate.ps1 -subscriptionId 'ada06e68-375e-4564-be3a-c6cacebf41c5' -resourceGroupName 'sentinel-prd' -workspaceName 'sentinel-prd' -githubToken 'ghp_ECgzFoyPsbSKrFB2pTrEEOUmy4P0Rb3yd'
    .EXAMPLE
        Create rules from all templates in a disabled state
        $rules = .\create-scheduledRuleFromTemplate.ps1 -subscriptionId 'ada06e68-375e-4564-be3a-c6cacebf41c5' -resourceGroupName 'sentinel-prd' -workspaceName 'sentinel-prd' -githubToken 'ghp_ECgzFoyPsbSKrFB2pTrEEOUmy4P0Rb3yd' -enabled $false
    .EXAMPLE
        Create rules from all templates with "TI map" in the name
        $rules = .\create-scheduledRuleFromTemplate.ps1 -subscriptionId 'ada06e68-375e-4564-be3a-c6cacebf41c5' -resourceGroupName 'sentinel-prd' -workspaceName 'sentinel-prd' -githubToken 'ghp_ECgzFoyPsbSKrFB2pTrEEOUmy4P0Rb3yd' -name '*TI map*
    .EXAMPLE
        The below example will open an out-grid UI where you can further select specific rules to import
        $rules = .\create-scheduledRuleFromTemplate.ps1 -subscriptionId 'ada06e68-375e-4564-be3a-c6cacebf41c5' -resourceGroupName 'sentinel-prd' -workspaceName 'sentinel-prd' -githubToken 'ghp_ECgzFoyPsbSKrFoK5B2pOUmy4P0Rb3yd' -selectUI
    .EXAMPLE
        Filter by detection or solution child folder Name.
        $rules = .\create-scheduledRuleFromTemplate.ps1 -subscriptionId 'ada06e68-375e-4564-be3a-c6cacebf41c5' -resourceGroupName 'sentinel-prd' -workspaceName 'sentinel-prd' -githubToken 'ghp_ECgzFoyPsbSKrFoK5B2EOUmy4P0Rb3yd' -detectionFolderName 'ASimAuthentication','ASimProcess'
    .EXAMPLE
        Filter by severity of alert rule templates
        $rules = .\create-scheduledRuleFromTemplate.ps1 -subscriptionId 'ada06e68-375e-4564-be3a-c6cacebf41c5' -resourceGroupName 'sentinel-prd' -workspaceName 'sentinel-prd' -githubToken 'ghp_ECgzFoyPsbSKrFoK5B2pOUmy4P0Rb3yd' -severity 'High','Medium'
    .EXAMPLE
        Filter by severity and tactic of alert rule templates
        $rules = .\create-scheduledRuleFromTemplate.ps1 -subscriptionId 'ada06e68-375e-4564-be3a-c6cacebf41c5' -resourceGroupName 'sentinel-prd' -workspaceName 'sentinel-prd' -githubToken 'ghp_ECgzFoyPsbSKrFoK5B2pOUmy4P0Rb3yd' -severity 'High','Medium' -tactic 'CredentialAccess'
    .EXAMPLE
        Run in report only mode
        $rules = .\create-scheduledRuleFromTemplate.ps1 -subscriptionId 'ada06e68-375e-4564-be3a-c6cacebf41c5' -resourceGroupName 'sentinel-prd' -workspaceName 'sentinel-prd' -detectionFolderName 'ASimAuthentication','ASimProcess' -githubToken 'ghp_ECgzFoyPsbSKrFoK5B2pOUmy4P0Rb3yd' -reportOnly
        
        $rules | Select name, severity, tactics, techniques, requiredDataConnectors, templateURL
    .NOTES
        Author: seanstark-ms
        Website: https://starkonsec.medium.com/
        Link to GitHub Source: https://github.com/seanstark/sentinel-tools/tree/main/analytics_rules
        Requires PowerShell Version 7.0 and above
        Requires PowerShell Modules: 'PowerShellForGitHub', 'Az.Accounts', 'Az.SecurityInsights', 'powershell-yaml'
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$subscriptionId, 

    [Parameter(Mandatory=$true)]
    [string]$resourceGroupName, 

    [Parameter(Mandatory=$true)]
    [string]$workspaceName, 

    [Parameter(Mandatory=$true,
    HelpMessage='Specifiy your GitHub personal access token that has public_repo to the Microsoft Azure Organization')]
    [string]$githubToken, 

    [Parameter(Mandatory=$false,
    HelpMessage='Specifiy the API version of the Microsoft.SecurityInsights/alertRules endpoint')]
    [string]$apiVersion = '2021-10-01-preview',

    [Parameter(Mandatory=$false,
    HelpMessage='Enter a name to filter on')]
    [string]$name,

    [Parameter(Mandatory=$false,
    HelpMessage='Enter one or more rule severities separated by commas to filter on')]
    [string[]]$severity,

    [Parameter(Mandatory=$false,
    HelpMessage='Enter one or more detection child folder names separated by commas to filter on')]
    [string[]]$detectionFolderName,

    [Parameter(Mandatory=$false,
    HelpMessage='Enter one or more techniques separated by commas to filter on')]
    [string[]]$techniques,

    [Parameter(Mandatory=$false,
    HelpMessage='Enter one or more tactics separated by commas to filter on')]
    [string[]]$tactics,

    [Parameter(Mandatory=$false,
    HelpMessage='Enter one or more dataconnector names separated by commas to filter on')]
    [string[]]$dataConnector,

    [Parameter(Mandatory=$false,
    HelpMessage='Enter one or more dataconnector names separated by commas to filter on')]
    [string[]]$dataType,

    [Parameter(Mandatory=$false,
    HelpMessage='Enter one or more dataconnector names separated by commas to filter on')]
    [string[]]$queryFilter,

    [Parameter(Mandatory=$false,
    HelpMessage='Enter one or more tag names separated by commas to filter on')]
    [string[]]$tag,

    [Parameter(Mandatory=$false,
    HelpMessage='Specify if the rule will be created in an enabled state. By default this is set to true')]
    [boolean]$enable = $true,

    [Parameter(Mandatory=$false,
    HelpMessage='Specify if you only want to report on alert rule templates that will be enabled')]
    [switch]$reportOnly,

    [Parameter(Mandatory=$false,
    HelpMessage='Open a UI to further select which Analytics Rules you want to import')]
    [switch]$selectUI
)

#Requires -Version 7.0

# Check for required modules
$requiredModules = 'PowerShellForGitHub', 'Az.Accounts', 'Az.SecurityInsights', 'powershell-yaml'
$availableModules = Get-Module -ListAvailable -Name $requiredModules
$modulesToInstall = $requiredModules | where-object {$_ -notin $availableModules.Name}
ForEach ($module in $modulesToInstall){
    Write-Host "Installing Missing PowerShell Module: $module" -ForegroundColor Yellow
    Install-Module $module -force
}

# Sentinel GitHub Repo URI and Analytic Rule Root Path
$sentinelGitHuburi = 'https://github.com/Azure/Azure-Sentinel'
$sentinelGitHubPaths = 'Detections','Solutions'

#Setup GitHubAuthentication
[pscredential]$gitHubCred = New-Object System.Management.Automation.PSCredential ('dummy', $(ConvertTo-SecureString $githubToken -AsPlainText -Force))
Set-GitHubConfiguration -DisableLogging -DisableTelemetry
Set-GitHubAuthentication -Credential $gitHubCred

# Auth to Azure
If(!(Get-AzContext)){
    Write-Host ('Connecting to Azure Subscription: {0}' -f $subscriptionId) -ForegroundColor Yellow
    Connect-AzAccount -Subscription $subscriptionId | Out-Null
}

#Set context to the subscriptionid
Set-AzContext -Subscription $subscriptionId -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | Out-Null

#Get the current Bearer Token
$azToken = (Get-AzAccessToken).Token

# Get all anlaytics rules from github
$detectionFolders = @()
ForEach ($sentinelGitHubPath in $sentinelGitHubPaths){
    If ($sentinelGitHubPath -like 'Solutions'){
        $solutions = Get-GitHubContent -Uri $sentinelGitHuburi -Path 'Solutions' -MediaType Object | Select -ExpandProperty entries | Where type -like 'dir' | Select name
        ForEach ($solution in $solutions.name){
            $detectionFolders += Get-GitHubContent -Uri $sentinelGitHuburi -Path "Solutions/$solution" -MediaType Object | Select -ExpandProperty entries | Where-Object {$_.type -like 'dir' -and $_.name -like 'Analytic Rules'} | Select @{Name = 'name'; Expression = {$solution}}, path
        }
    }else{
        $detectionFolders += Get-GitHubContent -Uri $sentinelGitHuburi -Path $sentinelGitHubPath -MediaType Object | Select -ExpandProperty entries | Where type -like 'dir' | Select name, path
    }
}

# Filter on specific detection folders if detectionFolderName parameter is defined
If($detectionFolderName){
    $detectionFolders = $detectionFolders | where name -in $detectionFolderName
}

# Get all created by template analytic rules in Sentinel
$existingRules = Get-AzSentinelAlertRule -resourceGroupName $resourceGroupName -workspaceName $workspaceName | Where-Object kind -like 'Scheduled'

# Iterate through each detection folder in github and build an array of psobjects of the yaml files
Write-Host 'Iterating through each detection folder to build an index of each analytic rule template. This will take a few minutes..' -ForegroundColor Yellow
$alertRuleTemplates = @()
ForEach ($detectionFolder in $($detectionFolders | Select -ExpandProperty path)){

    $yamlFiles = Get-GitHubContent -Uri $sentinelGitHuburi -Path $detectionFolder -MediaType Object | Select -ExpandProperty entries | Where name -Like '*.yaml'

    ForEach ($yamlFile in $yamlFiles){

        $alertRuleTemplate = ConvertFrom-Yaml (Invoke-RestMethod -uri $yamlFile.download_url)
        
        If ($alertRuleTemplate.kind -like 'Scheduled'){

            Write-Verbose ('Found Scheduled Rule Template: {0}, adding to index' -f $alertRuleTemplate.name)

            $alertRuleTemplates += ([PSCustomObject]@{
                id = $alertRuleTemplate.id
                name = $alertRuleTemplate.name
                kind = 'Scheduled'
                templateURL = $yamlFile.download_url
                templateFolder = $detectionFolder
                severity = $alertRuleTemplate.severity
                requiredDataConnectors = $alertRuleTemplate.requiredDataConnectors.connectorId -join ','
                techniques = $alertRuleTemplate.relevantTechniques -join ','
                tactics = $alertRuleTemplate.tactics -join ','
                properties = ($alertRuleTemplate | Select-object -ExcludeProperty name, id, kind)
            })
        }
    }
}

# This function is used to dynamically create an inclusive filter set when multiple filter parameters are defined
function check-filterScript {
    param(
        [string]$filterToAdd
    )
    if ($filterScript){
        $newFilter = "$filterScript -and $filterToAdd"
    }else{
        $newFilter = $filterToAdd
    }
    [scriptblock]::Create($newFilter)
}

# This function is used to compare filter parameters with rule template properties that are an object "List" or Object[] type and contain multiple objects. 
# These are present in relevantTechniques, tactics, dataTypes, and requiredDataConnectors properties
function match-Lists {
    param(
        [string[]]$filterParameter,
        $list
    )
    $matched = $false

    if($list){
        $list | ForEach-Object{
            if ($_ -in $filterParameter){
                $matched = $true
            }
        }
    }

    $matched
}

# Build dynamic filters on rule severities, relevantTechniques, tactics, and data connectors if parameters are defined
$filterScript = $null
If($severity){
    $filterScript = check-filterScript -filterToAdd ('$_.properties.severity -in {0}' -f $severity)
}
If($name){
    $filterScript = check-filterScript -filterToAdd ('$_.name -like "{0}"' -f $name)
}
If($techniques){
    $filterScript = check-filterScript -filterToAdd ('$(match-Lists -filterParameter $techniques -list $_.properties.relevantTechniques) -eq $true')
}
If($tactics){
    $filterScript = check-filterScript -filterToAdd ('$(match-Lists -filterParameter $tactics -list $_.properties.tactics) -eq $true')
}
If($dataConnector){
    $filterScript = check-filterScript -filterToAdd ('$(match-Lists -filterParameter $dataConnector -list $_.properties.requiredDataConnectors.connectorId) -eq $true')
}
If($dataType){
    $filterScript = check-filterScript -filterToAdd ('$(match-Lists -filterParameter $dataType -list $_.properties.requiredDataConnectors.dataTypes) -eq $true')
}
If($queryFilter){
    $filterScript = check-filterScript -filterToAdd ('$($_.properties.query | Select-String $queryFilter) -ne $null')
}
If($tag){
    $filterScript = check-filterScript -filterToAdd ('$(match-Lists -filterParameter $tag -list $_.properties.tags) -eq $true')
}

#Filter templates based on defined filter parameters
If ($filterScript){
    Write-Verbose ('Filters that will be applied: {0}' -f $filterScript)
    $alertRuleTemplates = $alertRuleTemplates | where -FilterScript $filterScript
}

Write-Host ('Found a total of {0} Rule Templates from GitHub' -f $alertRuleTemplates.count) -ForegroundColor Cyan

# Find which rules need to be created that don't already exist
$rulesToCreate = $alertRuleTemplates | Where-object {$_.id -notin $existingRules.AlertRuleTemplateName -and $_.name -notin $existingRules.DisplayName}

#Open the selection UI to further select specific rules to import
if ($selectUI){
    Write-Host ('Opening UI for Rule Selection' -f $rulesToCreate.count) -ForegroundColor Cyan
    $rulesToCreate = $rulesToCreate | Out-GridView -PassThru -Title 'Select Rules to be Imported (For Multi-Select use CTRL)' | Select * 
}
 
Write-Host ('Found a total of {0} Rule Templates to Enable' -f $rulesToCreate.count) -ForegroundColor Cyan

If ($reportOnly){
    Write-Host 'Report Only Mode: Outputing rules that will be created' -ForegroundColor Yellow
    $rulesToCreate
}

#Updated Yaml Trigger Operators Mapping
$triggerOperators = @{
    gt = 'GreaterThan'
    eq = 'Equal'
    lt = 'LessThan'    
    ne = 'NotEqual'
}

#ISO 8601 Time Converstion Function
Function ConvertFrom-YAMLTimeFormat {
    Param (
        [Parameter(Mandatory = $true)]
        [string]$timespan
    )

    if($timespan.contains("d"))
    {
        $result = "P$timespan".ToUpper()
    }
    if($timespan.contains("h"))
    {
        $result = "PT$timespan".ToUpper()
    }
    if($timespan.contains("m"))
    {
        $result = "PT$timespan".ToUpper()
    }
    $result
}

If ($reportOnly -eq $false){

    # Define Authorization headers for the Microsoft.SecurityInsights/alertRules API
    $headers = @{
        Authorization="Bearer $azToken"
    }

    # Create each rule from the template
    ForEach ($rule in $rulesToCreate){

        # Build an updated object for each yaml file to interact properly with the Microsoft.SecurityInsights/alertRules API endpoint.
        $newRuleGuid = (New-Guid).Guid
        $rule | Add-Member -NotePropertyName 'type' -NotePropertyValue 'Microsoft.SecurityInsights/alertRules' -Force
        $rule.properties | Add-Member -NotePropertyName 'templateVersion' -NotePropertyValue $rule.properties.version -Force
        $rule.properties| Add-Member -NotePropertyName 'alertRuleTemplateName' -NotePropertyValue $rule.id -Force
        $rule.properties| Add-Member -NotePropertyName 'suppressionDuration' -NotePropertyValue 'PT5H' -Force
        $rule.properties| Add-Member -NotePropertyName 'suppressionEnabled' -NotePropertyValue $false -Force
        $rule.properties| Add-Member -NotePropertyName 'displayName' -NotePropertyValue $rule.name -Force
        $rule.properties| Add-Member -NotePropertyName 'enabled' -NotePropertyValue $enable -Force
        $rule.properties.triggerOperator = $triggerOperators[$rule.properties.triggerOperator]
        $rule.properties.queryFrequency = ConvertFrom-YAMLTimeFormat $rule.properties.queryFrequency
        $rule.properties.queryPeriod = ConvertFrom-YAMLTimeFormat $rule.properties.queryPeriod
        $rule.name = $newRuleGuid
        $rule.id = "/subscriptions/$($subscriptionId)/resourceGroups/$($resourceGroupName)/providers/Microsoft.OperationalInsights/workspaces/$($workspaceName)/providers/Microsoft.SecurityInsights/alertRules/$($newRuleGuid)"

        Write-Host "Attempting to Create Rule: $($rule.properties.displayName)" -ForegroundColor Yellow

        # Create an Analytic Rule from the template using the rest API
        try{
            $uri = "https://management.azure.com/subscriptions/$($subscriptionId)/resourceGroups/$($resourceGroupName)/providers/Microsoft.OperationalInsights/workspaces/$($workspaceName)/providers/Microsoft.SecurityInsights/alertRules/$($newRuleGuid)?api-version=$($apiVersion)"
            $newRule = Invoke-RestMethod -Uri $uri -Headers $headers -Method Put -Body $($rule | ConvertTo-Json -Depth 5) -ContentType 'application/json'
        }catch{
            $outputErrorMessage = ($PSItem.ErrorDetails | ConvertFrom-Json).error.message
            $outputErrorCode = ($PSItem.ErrorDetails | ConvertFrom-Json).error.code
            Write-Host "Error Creating Rule: $outputErrorMessage" -ForegroundColor Red
        }finally{
            $outputObject = New-Object PSObject -Property @{
                ruleName = $rule.properties.displayName
                ruleid = $newRule.name
                ruletype = $newRule.kind
                created = If($outputErrorCode -or $outputErrorMessage){$false}else{$true}
                errorCode = $outputErrorCode
                errorMessage = $outputErrorMessage
                properties = ($newRule | Select-object -ExcludeProperty name, id, kind)
            }
        }
        $outputObject 
        #Cleanup rule and error variables
        Clear-Variable outputErrorMessage, outputErrorCode, outputObject -ErrorAction SilentlyContinue
        $error.Clear()
    }
}
