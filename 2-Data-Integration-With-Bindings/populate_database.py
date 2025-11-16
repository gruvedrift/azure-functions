from azure.cosmos import CosmosClient
import os

COSMOS_DB_CONNECTION_STRING = os.getenv("COSMOS_DB_CONNECTION_STRING")
COSMOS_DATABASE_NAME = os.getenv("COSMOS_DATABASE_NAME")
COSMOS_CONTAINER_NAME = os.getenv("COSMOS_CONTAINER_NAME")

client = CosmosClient.from_connection_string(COSMOS_DB_CONNECTION_STRING)
db = client.get_database_client(COSMOS_DATABASE_NAME)
container = db.get_container_client(COSMOS_CONTAINER_NAME)

heroes = [
    {
        "id": "1",
        "heroId": "1",
        "name": "Invoker",
        "attackType": "Ranged",
        "primaryAttribute": "Intelligence",
        "roles": ["Mid", "Nuker", "Disabler"],
        "difficulty": "Hard"
    },
    {
        "id": "2",
        "heroId": "2",
        "name": "Juggernaut",
        "attackType": "Melee",
        "primaryAttribute": "Agility",
        "roles": ["Carry", "Pusher"],
        "difficulty": "Medium"
    },
    {
        "id": "3",
        "heroId": "3",
        "name": "Axe",
        "attackType": "Melee",
        "primaryAttribute": "Strength",
        "roles": ["Initiator", "Durable"],
        "difficulty": "Easy"
    },
    {
        "id": "4",
        "heroId": "4",
        "name": "Crystal Maiden",
        "attackType": "Ranged",
        "primaryAttribute": "Intelligence",
        "roles": ["Support", "Disabler", "Nuker"],
        "difficulty": "Easy"
    },
    {
        "id": "5",
        "heroId": "5",
        "name": "Queen of Pain",
        "attackType": "Ranged",
        "primaryAttribute": "Intelligence",
        "roles": ["Mid", "Nuker", "Escape"],
        "difficulty": "Medium"
    },
    {
        "id": "6",
        "heroId": "6",
        "name": "Dragon Knight",
        "attackType": "Melee",
        "primaryAttribute": "Strength",
        "roles": ["Carry", "Pusher", "Durable", "Initiator"],
        "difficulty": "Easy"
    },
    {
        "id": "7",
        "heroId": "7",
        "name": "Leshrac",
        "attackType": "Ranged",
        "primaryAttribute": "Intelligence",
        "roles": ["Nuker", "Pusher", "Mid", "Disabler"],
        "difficulty": "Hard"
    }
]

for hero in heroes:
    container.upsert_item(hero)
    print(f'Inserted hero {hero["name"]}')
