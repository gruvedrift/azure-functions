# Azure Functions 

This project was created as a **hands-on-practice** for preparing for the az-204 exam. It demonstrates how to use azure functions.

Additional exam relevant questions are included in QA file

### Requirements:
- Azure subscription
- Terraform
- Python
- Bash 
- Azure Functions Core Tool (For locally testing Azure Functions)

### Prerequisite Knowledge:
- Basic understanding of cloud computing concepts.
- Basic understanding of Terraform or other IAC tools.
- Basic Python knowledge.
- Basic Database knowledge.
- Familiarity with command-line interfaces (bash/PowerShell).
- Basic Azure knowledge about Storage Accounts.

### Each Iteration contains:


## Conceptual introduction
Azure Functions represents the serverless compute paradigm, where you focus entirely on writing code while Azure handles all infrastructure concerns.

Functions excel at event-driven scenarios where code needs to execute in response to specific triggers like HTTP requests, timer schedules, or data changes. 
Unlike traditional web applications that runs continuously, functions execute only when triggered, making them extremely cost-effective for intermittent or 
unpredictable workloads. 

## Business Value Proposition

The serverless model changes how one would think about application architecture and costs. Traditional applications require provisioning servers for handling peak
capacity to maintain performance. This means that you often pay for idle resources during low-traffic periods. Functions operate on a consumption based model, where 
you only pay for actual execution time, measured in milliseconds.

This pricing model particularly benefits applications with sporadic usage patterns. A function which processes uploaded images might execute hundreds of times during 
business hours but remain completely idle during nighttime and weekends. With a traditional hosting approach, you would pay for 24/7 server capacity, while with Azure Functions, 
you pay only for those active processing moments / compute time.


---

## 1. Iteration - Function App Creation and Basic Triggers:

* **Create and configure Azure Function Apps** - Provision Function Apps, App Service Plans, Storage Accounts, and Application Insights using Terraform.
* **Implement HTTP-triggered functions** - Build interactive endpoints responding to user requests with real-time responses.
* **Create timer-triggered functions** - Configure scheduled execution using CRON expressions for automated tasks.
* **Add webhook-triggered functions** - Implement event notification receivers following a *fire-and-forget* pattern for external system integration.
* **Configure function-level security** - Implement authentication with access keys (`ANONYMOUS`, `FUNCTION` and `ADMIN` levels) and manage key rotation via Azure CLI.
* **Understand trigger execution patterns** - Learn storage requirements for stateful triggers, cold starts, and the differences between trigger types.

---

## 2. Iteration - Data Integration with Bindings 
- TODO
---

## 3. Iteration - Event-Driven Data Processing 
- TODO
---


#### Additional notes: 


### TODO info about why every azure function needs a Storage Account

## How the Storage Account relates to Azure Functions
The Storage Account is a vital part of Azure Functions. It is 100% needed, and it stores: 
1. **Function code** (in a blob container called `azure-webjob-hosts`)
2. **Function secrets and keys** (encrypted)
3. **Execution logs** (for monitoring)
4. **Queue/Blob/Table trigger metadata**
5. **Durable function state** (for function pipelines)


❗ In this guide we will use the Azure function Python V2 programming model, which uses a decorator-based approach.❗
You can read more about the differences and implementation using both the V1 and V2 model here:  
[Azure Functions Python developer guide](https://learn.microsoft.com/en-us/azure/azure-functions/functions-reference-python?tabs=get-started%2Casgi%2Capplication-level&pivots=python-mode-decorators)

#### How to test functions locally: 
A very smart school boy approach is to test your functions locally before pushing them to Azure. You can run any function with the `azure-functions-core-tools`.
```bash
brew tap azure/functions
brew install azure-functions-core-tools@4
```
After installing, run command `func start` from your working directory, and voilà, you can now test and debug your Azure function from your local computer.

If you would like to do testing from your local machine &rarr; real Azure resources, you can add a `local.settings.json` file to your `/functions` directory.  
Within it, you can place connection strings / authentication strings to any Azure resource. For example:
```json
{
  "IsEncrypted": false,
  "Values": {
    "FUNCTIONS_WORKER_RUNTIME": "python",
    "CosmosDbConnectionString": YOUR_COSMOS_DB_CONNECTION_STRING,
    "AzureWebJobsStorage": YOUR_STORAGE_ACCOUNT_PRIMARY_CONNECTION_STRING,
    "ServiceBusConnection": YOUR_SERVICE_BUS_CONNECTION_STRING, 
  },
  "ConnectionStrings": {}
}
```

All these connection strings are easily obtained through the azure portal, but even EASIER is it to add these to the `output.tf` file and simply using the Terraform CLI: 
```hcl
terraform ouput cosmos_db_connection_string 
```

Thank you for checking out this guide, and a shout-out to my lovely wife. It was not easy, we had our ups and downs, but we made it.  
You always knew there was something special about me.