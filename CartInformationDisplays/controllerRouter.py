# controllerRouter.py
import sharedState

async def controllerRouter(data):
    try:
        if data["type"] == "state":
            if sharedState.cartL is not None:
                await sharedState.cartL.send_json(data)
            if sharedState.cartR is not None:
                await sharedState.cartR.send_json(data)
            if sharedState.missionController is not None:
                await sharedState.missionController.send_json({"type": "confirm", "data": "true"})
    except:
        if sharedState.missionController is not None:
            await sharedState.missionController.send_json({"type": "confirm", "data": "false"})

