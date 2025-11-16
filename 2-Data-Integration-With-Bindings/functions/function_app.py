from datetime import datetime
import json

import azure.functions as func
import logging

app = func.FunctionApp()


# Iteration 1:
@app.function_name(name="HeroInformation")
@app.route("hero-information/{heroId}", auth_level=func.AuthLevel.ANONYMOUS, methods=["GET"])
@app.cosmos_db_input(
    arg_name="hero_information",
    database_name="herodb",
    container_name="hero-information",
    connection="CosmosDbConnectionString",
    id="{heroId}",
    partition_key="{heroId}"
)
def get_hero_information(
        req: func.HttpRequest,
        hero_information: func.DocumentList,
) -> func.HttpResponse:
    """
    Simple GET endpoint that retrieves user preferences from Cosmos DB, using input binding decorator.
    req parameter is REQUIRED, as it is part of the function signature passed to the Function Handler!!!
    Take[0] element in DocumentList and transform -> JSON
    """
    logging.info("Function triggerd by request!")

    if hero_information:
        # Get hero data
        hero_data = json.loads(hero_information[0].to_json())
        return func.HttpResponse(
            body=json.dumps(hero_data, indent=2),
            mimetype="application/json",
            status_code=200,
        )
    else:
        return func.HttpResponse(
            body="Hero not found!",
            status_code=404,
        )


# Iteration 2:
@app.function_name(name="HeroInformationWithArchive")
@app.route("archive/hero-information/{heroId}", auth_level=func.AuthLevel.ANONYMOUS, methods=["GET"])
@app.cosmos_db_input(
    arg_name="document_list",
    database_name="herodb",
    container_name="hero-information",
    connection="CosmosDbConnectionString",
    id="{heroId}",
    partition_key="{heroId}"
)
@app.blob_output(
    arg_name="archive",
    path="hero-archive-audit/hero--{heroId}--{datetime}.json",  # Same as Blob Storage Container name
    connection="AzureWebJobsStorage"  # Default setup from azure
)
def get_hero_information_with_audit(
        req: func.HttpRequest,
        document_list: func.DocumentList,
        archive: func.Out[str],
) -> func.HttpResponse:
    """
    Similar function endpoint as above, however now with an output binding that writes audit to
    a Blob Storage container.
    """
    logging.info(f'Hero archive request for ID: {req.route_params.get("heroId")}')

    if not document_list:
        return func.HttpResponse(
            json.dumps({"error": "Hero not found!"}),
            status_code=404,
            mimetype="application/json",
        )
    # Get hero data
    hero_data = json.loads(document_list[0].to_json())

    # Create audit data
    archive_data = {
        "heroId": hero_data.get("id"),
        "heroName": hero_data.get("name"),
        "requestTime": datetime.utcnow().isoformat(),
        "data": hero_data
    }

    # Store audit to archive
    archive.set(json.dumps(archive_data, indent=2))
    logging.info(f'Hero {hero_data.get("name")} archived successfully')

    return func.HttpResponse(
        body=json.dumps(hero_data, indent=2),
        status_code=200,
        mimetype="application/json"
    )


# Iteration 3 + 4:
@app.function_name(name="HeroInformationWithAnalytics")
@app.route("analytics/hero-information/{heroId}", auth_level=func.AuthLevel.ANONYMOUS, methods=["GET"])
@app.cosmos_db_input(
    arg_name="document_list",
    database_name="herodb",
    container_name="hero-information",
    connection="CosmosDbConnectionString",
    id="{heroId}",
    partition_key="{heroId}",
)
@app.blob_output(
    arg_name="archive",
    path="hero-archive-audit/hero--{heroId}--{datetime}.json",
    connection="AzureWebJobsStorage",
)
@app.service_bus_queue_output(
    arg_name="analytics_queue",
    queue_name="hero-analytics-queue",
    connection="ServiceBusConnection",
)
def get_hero_with_analytics(
        req: func.HttpRequest,
        document_list: func.DocumentList,
        archive: func.Out[str],
        analytics_queue: func.Out[str],
) -> func.HttpResponse:
    """
    Function with Archive audit, Service Bus output binding, and CosmosDB input binding.
    """
    logging.info(f'Hero archive and analytics request for ID: {req.route_params.get("heroId")}')
    if not document_list:
        return func.HttpResponse(
            json.dumps({"error": "Hero not found!"}),
            status_code=404,
            mimetype="application/json",
        )

    # Get hero data
    hero_data = json.loads(document_list[0].to_json())

    # Create audit data
    archive_data = {
        "heroId": hero_data.get("id"),
        "heroName": hero_data.get("name"),
        "requestTime": datetime.utcnow().isoformat(),
        "data": hero_data
    }

    # Archive audit to blob
    archive.set(json.dumps(archive_data, indent=2))
    logging.info(f'Hero {hero_data.get("name")} archived successfully')

    # Create analytics event with relevant information
    analytics_event = {
        "eventType": "hero_queried",
        "heroId": hero_data['id'],
        "heroName": hero_data['name'],
        "timestamp": datetime.utcnow().isoformat(),
        "userAgent": req.headers.get('User-Agent'),
        "region": req.headers.get('X-Forwarded-For', 'unknown'),
    }

    # Push event to service buss
    analytics_queue.set(json.dumps(analytics_event))
    logging.info(f'Pushed analytics to Service Bus for hero:  {hero_data.get("name")} successfully!')

    # Return hero response
    return func.HttpResponse(
        body=json.dumps(hero_data, indent=2),
        status_code=200,
        mimetype="application/json"
    )


# Iteration 3 + 4 - Consumer function for processing analytics
@app.function_name(name="ProcessHeroAnalytics")
@app.service_bus_queue_trigger(
    arg_name="msg",
    queue_name="hero-analytics-queue",
    connection="ServiceBusConnection"
)
@app.table_output(
    arg_name="hero_stats",
    table_name="HeroQueryStatistics",
    connection="AzureWebJobsStorage"
)
def process_analytics(
        msg: func.ServiceBusMessage,
        hero_stats: func.Out[str],
):
    """
    Consumer function triggered by the Service Bus messages.
    Updates hero query statistics in Table storage.
    """
    event = json.loads(msg.get_body().decode('utf-8'))
    logging.info(f'Processing : {event["eventType"]} for {event["heroName"]}')

    # Create table entity (row in Table Storage)
    # Note: Table Storage does not auto-increment, so we can use the RowKey as unique identifier
    # For aggregation of statistics you would query all rows and count, or use a separate aggregation job.
    timestamp = event['timestamp'].replace(':', '-').replace('.', '-')  # Make timestamp URL-safe

    stats_entity = {
        "PartitionKey": "hero-stats",
        "RowKey": f"{event['heroId']}-{timestamp}",  # Unique row per event
        "HeroId": event['heroId'],
        "HeroName": event['heroName'],
        "LastQueried": event['timestamp'],
        "LastUserAgent": event.get('userAgent', 'unknown'),
        "LastRegion": event.get('region', 'unknown')
    }

    hero_stats.set(json.dumps(stats_entity))
    logging.info(f'Statistics updated for hero: {event["heroName"]}')
