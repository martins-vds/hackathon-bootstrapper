[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $SubscriptionId,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $ResourceGroupName,
    [Parameter(Mandatory = $true)]
    [ValidateSet('CanadaCentral', 'CanadaEast')]
    [string]
    $Location,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $HackathonName,
    [Parameter(Mandatory = $true)]
    [ValidateScript({
            if (-Not ($_ | Test-Path) ) {
                throw "File or folder does not exist"
            }

            if (-Not ($_ | Test-Path -PathType Leaf) ) {
                throw "The HackathonTeamsFile parameter must be a file. Folder paths are not allowed."
            }

            if ($_ -notmatch "(\.csv$)") {
                throw "The file specified in the HackathonTeamsFile parameter must be a csv file."
            }

            return $true 
        })]
    [System.IO.FileInfo]
    $HackathonTeamsFile,
    [switch]
    $UseResourceGroupLocation
)

# Pretty print the error output from a failed azure deployment
function PrettyPrintErrorOutput {
    param (
        [string]
        $Output
    )

    foreach ($detail in $Output.details) {
        Write-Host $detail.message -ForegroundColor Red

        if ($detail.details) {
            PrettyPrintErrorOutput -Output $detail
        }
    }
}

$ErrorActionPreference = "Stop"

function LoadTeamsCsv ($Path) {
    $content = Get-Content -Path $Path -Raw
    $header = $content | Select-Object -First 1 | ConvertFrom-Csv
    
    $columns = $header.PSObject.Properties | Select-Object -ExpandProperty Name

    if ($columns -notcontains "name" -or $columns -notcontains "objectId") {
        Write-Host $content
        throw "The HackathonTeamsFile must have the following columns: name, objectId"
    }

    $content | ConvertFrom-Csv
}

Write-Host "Setting subscription $SubscriptionId..."

az account set --subscription $SubscriptionId | Out-Null

Write-Host "Checking if resource group $ResourceGroupName exists..."
$rgExists = az group exists --name $ResourceGroupName

if ($rgExists) {
    Write-Host "Resource group $ResourceGroupName exists."
    if ($UseResourceGroupLocation) {
        $deploymentLocation = az group show --name $ResourceGroupName --query location -o tsv
    }
    else {
        $deploymentLocation = $Location
    }
}
else {
    Write-Host "Creating resource group $ResourceGroupName..."
    $deploymentLocation = $Location
    az group create --name $ResourceGroupName --location $deploymentLocation | Out-Null
}

Write-Host "Loading teams from $HackathonTeamsFile"

$hackathonTeams = LoadTeamsCsv -Path $HackathonTeamsFile.FullName

Write-Host "Retrieving team members..."

$hackathonTeamMembers = @()

foreach ($hackathonTeam in $hackathonTeams) {
    $hackathonTeamMembers += az ad group member list --group $hackathonTeam.objectId --query [].id -o tsv
}

$hackathonTeamMembers = $hackathonTeamMembers | Sort-Object -Unique

Write-Host "Deploying bootstrap template..."

$templateFile = "$PSScriptRoot\bootstrap.bicep"

$hackTeamsParam = $(ConvertTo-Json $($hackathonTeams | Select-Object -ExpandProperty objectId) -AsArray -Compress) -replace '"', '\"'
$hackComputeUsersParam = $(ConvertTo-Json $hackathonTeamMembers -AsArray -Compress) -replace '"', '\"'

$output = az deployment group create `
    --name hack-bootstrap-$((Get-Date).ToString("yyyyMMddHHmmss")) `
    --resource-group $ResourceGroupName `
    --template-file $templateFile `
    --parameters location=$deploymentLocation hackName=$HackathonName hackTeams="$hackTeamsParam" hackComputeUsers="$hackComputeUsersParam"

if ($LASTEXITCODE -eq 0) {
    Write-Host "Bootstrap deployment complete."
}
else {
    $outputErrors = $output | ConvertFrom-Json -AsHashtable -NoEnumerate -Depth 20
    PrettyPrintErrorOutput -Output $outputErrors.error
    Write-Error "Bootstrap deployment failed."
}