import json

import azure.functions as func
from datetime import datetime
import logging

app = func.FunctionApp()


# HTTP Trigger Function
@app.function_name(name="GreetFunction")
@app.route(route="greet", auth_level=func.AuthLevel.ANONYMOUS, methods=["GET"])  # Anonymous = Anyone can call
def greet(req: func.HttpRequest) -> func.HttpResponse:
    """
        Simple HTTP triggered greet function that returns a response body
    """
    logging.info("GreetFunction triggered")
    name = req.params.get("name")

    if name:
        return func.HttpResponse(f"Howdy, {name}!")
    else:
        return func.HttpResponse("Welcome, stranger")


# Timer Trigger Function
@app.function_name(name="TimedChronoFunction")
@app.schedule(schedule="0 */5 * * * *", arg_name="timer", run_on_startup=True)
def tell_time(timer: func.TimerRequest) -> None:
    """
        Runs every 5 minutes (for testing) and logs a greeting
    """
    logging.info("Timer triggered!")
    if timer.past_due:
        logging.warning("Timer is past due!")

    current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    logging.info(f"The time is: {current_time}")


# Webook Trigger Function
@app.function_name(name="WebHookFunction")
@app.route(route="webhook/invoke", auth_level=func.AuthLevel.ANONYMOUS, methods=["POST"])
def webhook_invoker(req: func.HttpRequest) -> func.HttpResponse:
    """
        Simple webhook that received notification
    """
    logging.info("Webhook received invocation!")

    try:
        payload = req.get_json()
        spell = payload.get('spell', 'sun strike')
        logging.info(f'Spell: {spell}')
    except:
        logging.warning("Invalid JSON!")

    return func.HttpResponse("OK", status_code=200)


# Function that requires key
@app.function_name(name="ProtectedFunction")
@app.route(route="protected", auth_level=func.AuthLevel.FUNCTION, methods=["POST"])
def protected_function(req: func.HttpRequest) -> func.HttpResponse:
    """
        Protected function, that requires a function key
    """
    logging.info("Protected function called - authentication successful")
    try:
        payload = req.get_json()
        user = payload.get("user")
        operation = payload.get("operation")

        if not user or not operation:
            return func.HttpResponse(
                json.dumps({"error": "Missing user or operation"}),
                status_code=400,
                mimetype="application/json"
            )
        logging.info(f'Performing {operation} on user {user}!')

        result = {
            "status": "success",
            "message": f"Action {operation} performed on user: {user}",
            "timestamp": datetime.now().isoformat(),
            "authenticated": True
        }
        return func.HttpResponse(
            json.dumps(result, indent=2),
            status_code=200,
            mimetype="application/json"
        )
    except:
        return func.HttpResponse(
            json.dumps({"error": "Invalid JSON"}),
            status_code=400,
            mimetype="application/json"
        )
