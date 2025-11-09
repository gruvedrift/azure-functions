## Exam relevant questions for Azure Functions

> **Question 1:** What is the maximum execution timeout for Azure Functions on different hosting plans?  
> 
> **Answer 1:**  
> Consumption plan: 5 minutes (default) up to 10 minutes (configurable).  
> Premium and Dedicated plans: 30 minutes (default), unlimited (configurable). Durable Functions can run indefinitely by checkpointing state.
---
> **Question 2:**  Your function works locally but fails in Azure with authentication errors when accessing Key Vault. What's likely wrong?  
> 
> **Answer 2:** The Function App lacks proper managed identity configuration or the managed identity doesn't have appropriate access policies in Key Vault. Enable system-assigned managed identity and grant it necessary Key Vault permissions.
---
> **Question 3:**  You need to process Service Bus messages in order. How should you configure your function?  
> 
> **Answer 3:** Use Service Bus queue (not topic) with sessions enabled, configure the function binding with `isSessionsEnabled: true`, 
> and ensure the Function App runs on a single instance by setting `WEBSITE_MAX_DYNAMIC_APPLICATION_SCALE_OUT=1` for guaranteed order processing.
---
> **Question 4:**  What's the difference between input and output bindings in Azure Functions? 
> 
> **Answer 4:** Input bindings provide data to your function (e.g., reading from a database or queue). Output bindings send data from your function to external services (e.g., writing to storage or sending messages). 
> A function can have multiple of each type.
---
> **Question 5:**  Which hosting plan should you choose to eliminate cold start delays?  
> 
> **Answer 5:** Premium plan (EP1, EP2, EP3). Premium  plans maintain pre-warmed instances to eliminate cold start delays, while Consumption plans may experience cold starts when functions haven't executed recently.
---
> **Question 6:**  How do you configure a timer trigger to run every 5 minutes?  
> 
> **Answer 6:** Use the NCRONTAB expression: `0 */5 * * * * `. The  format is seconds, minutes, hours, day, month, day-of-week.
> This expression means "at second 0 of every 5th minute of every hour."
---
> **Question 7:** A pipeline-triggered function needs to return data from multiple Azure services. How should you structure this?  
> 
> **Answer 7:** Use input bindings to declaratively connect to services (e.g., Cosmos DB input binding, Blob storage input binding) rather than creating SDK clients in code. This simplifies configuration and connection management.
---
> **Question 8:**  What storage account features are required for Azure Functions?  
> 
> **Answer 8:** Functions require a general-purpose Azure Storage account (v1 or v2) that supports blobs, queues, and tables. 
> The storage account stores function code, manages trigger metadata, and provides internal coordination for the Functions runtime.
---
> **Question 9:**  You need to process blob uploads immediately when they occur. Which trigger should you use? 
> 
> **Answer 9:** Event Grid trigger, not Blob trigger. Blob triggers can have delays and may miss rapid file uploads. Event Grid triggers provide near real-time processing of blob events.
---
> **Question 10:**  How do you configure a function to process multiple message types from the same Service Bus topic?
> 
> **Answer 10:** Create separate functions for each message type, each with a Service Bus trigger configured for a different subscription.
> Use message properties or custom filters to route messages to appropriate subscriptions.
---
> **Question 11:**  Your function needs to write to multiple output destinations. How should you implement this? 
> 
> **Answer 11:** Use multiple
output bindings in the function definition. For
example, one function can have both a Cosmos DB output binding and a Service Bus output binding to write to both
services declaratively.
---
> **Question 12:**   What's the maximum number of function instances that can run concurrently on the Consumption plan? 
> 
> **Answer 12:** 200 instances per Function App on the Consumption  plan. Each instance can process multiple function executions concurrently, depending on the trigger type and function implementation.
---
> **Question 13:**  You need to coordinate multiple Azure Functions in a workflow. What should you use?
> 
> **Answer 13:** Durable Functions. They
provide stateful orchestration in a serverless
environment, allowing you to chain functions, implement fan-out/fan-in patterns, and handle human interaction scenarios.
---
> **Question 14:**  How do you secure an HTTP-triggered function?
> 
> **Answer 14:** Use authorization levels: Anonymous (no key), Function ( function-specific key), or Admin (master key). 
> For production, also consider Azure AD authentication, CORS configuration, and API Management integration.
---
> **Question 15:**  Your function processes large files and sometimes times out. What are your options?
> 
> **Answer 15:** Switch to Premium or Dedicated plan for longer timeout limits, implement asynchronous processing using queue triggers to decouple processing,
> or break large file processing into smaller chunks using Durable Functions.
---
> **Question 16:**  What happens when a function throws an unhandled exception?
> 
> **Answer 16:** The function execution fails, and the trigger mechanism determines retry behavior.
> Queue triggers retry automatically, HTTP triggers return an error response, and timer triggers log the error but continue on schedule.
---
> **Question 17:**  You need to share configuration between multiple functions in a Function App. How should you do this? 
> 
> **Answer 17:** Use  Application Settings in the Function App configuration. These become environment variables accessible to all functions in the app. For secrets, use Key Vault references in application settings.
---
> **Question 18:**  How do you implement dependency injection in Azure Functions?
> 
> **Answer 18:** Use the Startup class to register services with the built-in dependency injection container.
> Functions can then receive these services as constructor parameters (isolated model) or method parameters (in-process model).
---
> **Question 19:**  Your function needs to process messages only during business hours. How do you implement this?
> 
> **Answer 19:** Use a timer  trigger to enable/disable a queue-triggered function by modifying application settings, 
> or implement conditional logic within the function to ignore messages  outside business hours while still removing them from the queue.
---
> **Question 20:**  What's the difference between synchronous and asynchronous function execution patterns?
> 
> **Answer 20:** Synchronous (HTTP  triggers) wait for function completion and return responses directly.
> Asynchronous patterns (queue, blob, timer triggers) execute independently without returning responses to callers, ideal for background processing and event-driven architectures.
