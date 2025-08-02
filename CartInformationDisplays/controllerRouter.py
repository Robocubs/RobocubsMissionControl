import asyncio
from communicationEngine import cartL, cartR, missionController

def controllerRouter(data):
    try:
        if data["type"] == "state":
            if cartL is not None:
                asyncio.run(cartL.send_json(data))
            if cartR is not None:
                asyncio.run(cartR.send_json(data))
            
            asyncio.run(missionController.send_json({"type": "confirm", "data": "true"}))
    except:
        asyncio.run(missionController.send_json({"type": "confirm", "data": "false"}))

