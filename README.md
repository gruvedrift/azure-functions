# Azure Functions 

This project was created as a **hands-on-practice** for preparing for the az-204 exam. It demonstrates how to use azure functions.

Additional exam relevant questions are included in QA file

### Requirements:
- Azure subscription
- Terraform
- Python or Node? 
- TODO

### Prerequisite Knowledge:

- TODO 

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

### 1. Iteration - Function App Creation and Basic Triggers
- TODO 
---

### 2. Iteration - Data Integration with Bindings 
- TODO
---

### 3. Iteration - Event-Driven Data Processing 
- TODO
---


#### Additional notes: 
- Hosting plans: Consumption vs Premium vs App Service 
- Stack is : app function + app insights + storage account + log analytics workspace + app service plan

#### Add screenshots from udemy? 


### TODO info about why every azure function needs a Storage Account
### Move information out to top-level readme here?