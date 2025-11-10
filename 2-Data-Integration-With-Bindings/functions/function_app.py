from datetime import datetime
import json

import azure.functions as func
import logging

app = func.FunctionApp()


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
