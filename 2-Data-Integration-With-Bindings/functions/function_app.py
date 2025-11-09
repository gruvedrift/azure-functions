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
def get_hero_information(req: func.HttpRequest, hero_information: func.DocumentList) -> func.HttpResponse:
    """
    Simple GET endpoint that retrieves user preferences from Cosmos DB, using input binding decorator.
    req parameter is REQUIRED, as it is part of the function signature passed to the Function Handler!!!
    Take[0] element in DocumentList and transform -> JSON
    """
    logging.info("Function triggerd by request!")

    if hero_information:
        return func.HttpResponse(
            body=hero_information[0].to_json(),
            mimetype="application/json",
            status_code=200,
        )
    else:
        return func.HttpResponse(
            body="Hero not found!",
            status_code=404,
        )
