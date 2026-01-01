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

## Project structure:
```
azure-functions/
├── 1-Function-App-Creation-And-Basic-Triggers
│   ├── functions
│   ├── img
│   ├── README.md
│   ├── scripts
│   └── terraform
├── 2-Data-Integration-With-Bindings
│   ├── functions
│   ├── img
│   ├── README.md
│   ├── scripts
│   └── terraform
├── 3-Event-Driven-Data-Processing
│   ├── functions
│   ├── img
│   ├── items
│   ├── README.md
│   ├── scripts
│   └── terraform
├── Additional-Resources
│   ├── CLI-COMMANDS.md
│   └── QA.md
└── README.md
```

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
**Syllabus Coverage:** Create and configure Azure Functions app. Implement triggers (data operations, timers, webhooks).
Learn storage requirements for stateful triggers, cold starts, and the differences between trigger types.

**Implementation:**
* **Infrastructure provisioning:** Function App, App Service Plan (Consumption), Storage Account, and Application Insights with Terraform.
* **HTTP-triggered function:** Synchronous real-time request/response patterns.
* **Timer-triggered function** Scheduled function execution using CRON expressions.
* **Webhook-triggered function:** Event notification receiver with fire-and-forget pattern for external system integration.
* **Function-level security:** Authorization configuration with access keys  (`Anonymous`, `Function` and `Admin` levels). 
* **Access key management:** Key retrieval and rotation via Azure CLI.

**Technologies:** Azure Functions (Consumption plan), HTTP triggers, Timer triggers, Application Insights  

**Architecture Pattern:** Request-response and scheduled execution

---

## 2. Iteration - Data Integration with Bindings 
**Syllabus Coverage:** Implement input and output bindings. 

**Implementation:**
* **Cosmos DB input binding:** Document retrieval by partition key through declarative binding.
* **Cosmos DB output binding:** Document serialization and upsert without explicit SDK calls.  
* **Blob Storage output binding:** Binary data archival through binding expression.
* **Table Storage output binding:** Structured data insertion for query statistics tracking.
* **Service Bus output binding:** Message publishing to queues for asynchronous processing.
* Binding expressions and connection string configuration.

**Technologies:** Cosmos DB (SQL API), Azure Blob Storage, Azure Table Storage, Azure Service Bus, binding expressions.

**Architecture Pattern:** Declarative data integration through function bindings. 

---

## 3. Iteration - Event-Driven Data Processing

**Syllabus Coverage:** Implement data operation triggers and chain functions using bindings and triggers.
Learn about Azure Function built-in error handling and retry policies.

**Implementation:**
* **Blob trigger function:** Image upload processing with validation. 
* **Cosmos DB trigger:** Change Feed monitoring for real-time document change.
* **Event Grid trigger:** Event subscriptions with CloudEvents schema for cross-service coordination.
* **Event Grid output binding:** Event publishing with type-based routing to multiple subscribers.
* **Function chaining:** Blob &rarr; Cosmos DB &rarr; Event Grid &rarr; parallel subscriber execution.
* **Fan-out pattern:** Single event triggering multiple downstream functions (admin notification, catalog update, price history record).
* **Retry policies:** Event Grid automatic retry with exponential backoff and dead letter queues.

**Technologies:** Azure Event Grid, Cosmos DB Change Feed, CloudEvents v1.0, Blob/Table Storage bindings.

**Architecture Pattern:** Event-driven architecture with pub/sub messaging and idempotent operations.

---

❗ In this guide we will use the Azure function Python V2 programming model, which uses a decorator-based approach.❗
You can read more about the differences and implementation using both the V1 and V2 model here:  
[Azure Functions Python developer guide](https://learn.microsoft.com/en-us/azure/azure-functions/functions-reference-python?tabs=get-started%2Casgi%2Capplication-level&pivots=python-mode-decorators)

## 💎Golden tidbit, how to test functions locally: 
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
    "EventGridTopicEndpoint": YOUR_EVENT_GRID_TOPIC_ENDPOINT,
    "EventGridTopicKey": YOUR_EVENT_GRID_TOPIC_KEY,
  },
}
```

All these connection strings are easily obtained through the azure portal, but even EASIER is it to add these to the `output.tf` file and simply using the Terraform CLI.

Thank you for checking out this guide, and a shout-out to my lovely wife. It was not easy, we had our ups and downs, but we made it.  
You always knew there was something special about me.