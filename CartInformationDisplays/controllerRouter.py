import asyncio
import sharedState

def controllerRouter(data):
    try:
        if data["type"] == "state":
            if sharedState.cartL is not None:
                asyncio.run(sharedState.cartL.send_json(data))
            if sharedState.cartR is not None:
                asyncio.run(sharedState.cartR.send_json(data))

            asyncio.run(sharedState.missionController.send_json({"type": "confirm", "data": "true"}))
    except:
        asyncio.run(sharedState.missionController.send_json({"type": "confirm", "data": "false"}))

