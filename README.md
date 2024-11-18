# Hackathon Bootstrapper

This is a simple script to bootstrap a new hackathon project on Azure.

## Resources Created

The `bootstrap.bicep` file creates the following resources:

- Application Insights
- Azure Event Hubs
- Azure Machine Learning Workspace and Compute Instances
- Azure OpenAI Service
- Computer Vision
- Container Registry
- Cosmos DB
- Form Recognizer
- Functions App
- Key Vault
- Log Analytics Workspace
- Resource Group
- Search Service
- Speech Service
- Storage Account
- Web App

These resources provide a comprehensive environment to kickstart your hackathon project on Azure.

## Prerequisites

- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- [PowerShell 7](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.4)

## Usage

- Login to your Azure account:

```powershell
az login
```

- Run the script:

```powershell
.\bootstrap.ps1 -SubscriptionId <subscription-id> -ResourceGroupName <resource-group-name> -Location <location> -HackathonName <hackathon-name> -HackathonTeamsFile <hackathon-teams-file> -UseResourceGroupLocation <$true | $false>
```

| Parameter | Description |
| --- | --- |
| SubscriptionId | The subscription ID where the resources will be created. |
| ResourceGroupName | The name of the resource group where the resources will be created. |
| Location | The location where the resources will be created. |
| HackathonName | The name of the hackathon. |
| HackathonTeamsFile | The path to the csv file containing the teams participating in the hackathon. The file should have the following columns: `name`, `objectId`. |
| UseResourceGroupLocation | Use the location of the resource group. |
