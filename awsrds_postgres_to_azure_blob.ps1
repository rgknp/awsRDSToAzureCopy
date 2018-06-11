# Set variables with your own values
$resourceGroupName = "<Resource Group Name>"
$dataFactoryName = "<Azure Data Factory Name>" # must be globally unquie
$dataFactoryRegion = "East US" # Change to your Azure regoin of choice
$storageAccountName = "<Azure Storage Account Name>"
$storageAccountKey = "<Azure Storage Account Key>"
#$sourceBlobPath = "<Azure blob container name>/<Azure blob input folder name>" # example: adftutorial/input
$sinkBlobPath = "<ADF Sink Blob path>" # example: adftutorial/output
$pipelineName = "<ADF PIpeline Name>"
$selfHostedIntegrationRuntimeName = "<ADF Self Hosted Integration Run Time Name>"

# Create a Self-hosted integration runtime
# Set-AzureRmDataFactoryV2IntegrationRuntime -ResourceGroupName $resourceGroupName -DataFactoryName $dataFactoryName -Name $selfHostedIntegrationRuntimeName -Type SelfHosted -Description "<Decribe your Integration Runtime>"

# Download and install self-hosted integration runtime (on local machine).

# Retrieve authentication key and register self-hosted integration runtime with the key.
# Get-AzureRmDataFactoryV2IntegrationRuntimeKey -ResourceGroupName $resourceGroupName -DataFactoryName $dataFactoryName -Name $selfHostedIntegrationRuntimeName

# Create a resource group
# New-AzureRmResourceGroup -Name $resourceGroupName -Location $dataFactoryRegion

# Create a data factory
# $df = Set-AzureRmDataFactoryV2 -ResourceGroupName $resourceGroupName -Location $dataFactoryRegion -Name $dataFactoryName 

# Create an AWS RDS Postgres linked service in the data factory

## JSON definition of the Postgres linked service. 
$PostgresLinkedServiceDefinition = @"
{
    "name": "PostgreSqlLinkedService",
    "properties": {
        "type": "PostgreSql",
        "typeProperties": {
            "server": "<AWS RDS Postgres Server Name>",
            "database": "<AWS RDS Postgres Database Name>",
            "username": "<AWS RDS Postgres DB User name>",
            "password": {
                "type": "SecureString",
                "value": "<AWS RDS Postgres DB Password>"
            }
        },
    }
}
"@

## IMPORTANT: stores the JSON definition in a file that will be used by the Set-AzureRmDataFactoryV2LinkedService command. 
$PostgresLinkedServiceDefinition | Out-File C:\<Your local desktop path>\PostgresLinkedService.json

## Creates a linked service in the data factory
Set-AzureRmDataFactoryV2LinkedService -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -Name "<ADF Linked Service Name1>" -File "C:\<Your local desktop path>\PostgresLinkedService.json"

# Create an Postgres dataset in the data factory

## JSON definition of the dataset
$datasetDefiniton = @"
{
    "name": "PostgreSQLDataset",
    "properties":
    {
        "type": "RelationalTable",
        "linkedServiceName": {
            "referenceName": "<ADF Linked Service Name1>",
            "type": "LinkedServiceReference"
        },
        "typeProperties": {}
    }
}
"@

## IMPORTANT: store the JSON definition in a file that will be used by the Set-AzureRmDataFactoryV2Dataset command. 
$datasetDefiniton | Out-File C:\<Your local desktop path>\PostgresDataset.json

## Create a dataset in the data factory
Set-AzureRmDataFactoryV2Dataset -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -Name "PostgresDataset" -File "C:\<Your local desktop path>\PostgresDataset.json"

# Create an Azure Storage linked service in the data factory

## JSON definition of the linked service. 
$storageLinkedServiceDefinition = @"
{
    "name": "AzureStorageLinkedService",
    "properties": {
        "type": "AzureStorage",
        "typeProperties": {
            "connectionString": {
                "value": "DefaultEndpointsProtocol=https;AccountName=$storageAccountName;AccountKey=$storageAccountKey",
                "type": "SecureString"
            }
        }
    }
}
"@

## IMPORTANT: stores the JSON definition in a file that will be used by the Set-AzureRmDataFactoryV2LinkedService command. 
$storageLinkedServiceDefinition | Out-File C:\<Your local desktop path>\StorageLinkedService.json

## Creates a linked service in the data factory
Set-AzureRmDataFactoryV2LinkedService -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -Name "AzureStorageLinkedService" -File "C:\<Your local desktop path>\StorageLinkedService.json"

# Create an Azure Blob dataset in the data factory

## JSON definition of the dataset
$datasetDefiniton = @"
{
    "name": "BlobDataset",
    "properties": {
        "type": "AzureBlob",
        "structure": [
                {
                    "name": "col1",
                    "type": "Int32"
                },
                {
                    "name": "col2",
                    "type": "String"
                }
            ],
        "typeProperties": {
            "folderPath": {
                "value": "@{dataset().path}",
                "type": "Expression"
            },
            "format": {
                "type": "JsonFormat"
            }
        },
        "linkedServiceName": {
            "referenceName": "AzureStorageLinkedService",
            "type": "LinkedServiceReference"
        },
        "parameters": {
            "path": {
                "type": "String"
            }
        }
    }
}
"@

## IMPORTANT: store the JSON definition in a file that will be used by the Set-AzureRmDataFactoryV2Dataset command. 
$datasetDefiniton | Out-File C:\<Your local desktop path>\BlobDataset.json

## Create a dataset in the data factory
Set-AzureRmDataFactoryV2Dataset -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -Name "BlobDataset" -File "C:\<Your local desktop path>\BlobDataset.json"


# Create a pipeline in the data factory

## JSON definition of the pipeline
$pipelineDefinition = @"
{
    "name": "$pipelineName",
    "properties": {
        "activities":[
            {
                "name": "CopyFromPostgreSQL",
                "type": "Copy",
                "inputs": [
                    {
                        "referenceName": "PostgresDataset",
                        "type": "DatasetReference"
                    }
                ],
                "outputs": [
                    {
                        "referenceName": "BlobDataset",
                        "parameters": {
                            "path": "@pipeline().parameters.outputPath"
                        },
                        "type": "DatasetReference"
                    }
                ],
                "typeProperties": {
                    "source": {
                        "type": "RelationalSource",
                        "query": "SELECT * FROM \"public\".\"table1\""
                    },
                    "sink": {
                        "type": "BlobSink"
                    }
                }
            }
        ],
        "parameters": {
            "outputPath": {
                "type": "String"
            }
        }
    }
}
"@

## IMPORTANT: store the JSON definition in a file that will be used by the Set-AzureRmDataFactoryV2Pipeline command. 
$pipelineDefinition | Out-File C:\<Your local desktop path>\CopyPipeline.json

## Create a pipeline in the data factory
Set-AzureRmDataFactoryV2Pipeline -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -Name $pipelineName -File "C:\<Your local desktop path>\CopyPipeline.json"

# Create a pipeline run 

## JSON definition for pipeline parameters
$pipelineParameters = @"
{
    "outputPath": "$sinkBlobPath"
}
"@

<#$pipelineParameters = @"
{
    "inputPath": "$sourceBlobPath",
    "outputPath": "$sinkBlobPath"
}
"@#>

## IMPORTANT: store the JSON definition in a file that will be used by the Invoke-AzureRmDataFactoryV2Pipeline command. 
$pipelineParameters | Out-File C:\<Your local desktop path>\PipelineParameters.json

# Create a pipeline run by using parameters
$runId = Invoke-AzureRmDataFactoryV2Pipeline -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -PipelineName $pipelineName -ParameterFile C:\<Your local desktop path>\PipelineParameters.json

# Check the pipeline run status until it finishes the copy operation
while ($True) {
    $result = Get-AzureRmDataFactoryV2ActivityRun -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -PipelineRunId $runId -RunStartedAfter (Get-Date).AddMinutes(-30) -RunStartedBefore (Get-Date).AddMinutes(30)

    if (($result | Where-Object { $_.Status -eq "InProgress" } | Measure-Object).count -ne 0) {
        Write-Host "Pipeline run status: In Progress" -foregroundcolor "Yellow"
        Start-Sleep -Seconds 30
    }
    else {
        Write-Host "Pipeline '$pipelineName' run finished. Result:" -foregroundcolor "Yellow"
        $result
        break
    }
}

# Get the activity run details 
    $result = Get-AzureRmDataFactoryV2ActivityRun -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName `
        -PipelineRunId $runId `
        -RunStartedAfter (Get-Date).AddMinutes(-10) `
        -RunStartedBefore (Get-Date).AddMinutes(10) `
        -ErrorAction Stop

    $result

    if ($result.Status -eq "Succeeded") {`
        $result.Output -join "`r`n"`
    }`
    else {`
        $result.Error -join "`r`n"`
    }

# To remove the data factory from the resource gorup
# Remove-AzureRmDataFactoryV2 -Name $dataFactoryName -ResourceGroupName $resourceGroupName
# 
# To remove the whole resource group
# Remove-AzureRmResourceGroup  -Name $resourceGroupName