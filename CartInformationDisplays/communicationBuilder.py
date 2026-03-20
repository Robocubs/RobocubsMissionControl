import logging
from starlette.endpoints import WebSocketEndpoint
from tba import getMatches
from communicationBus import communicationBus
from sharedFunctions import buildMessagePackage

logger = logging.getLogger(__name__)

class CartLEndpoint(WebSocketEndpoint):
    encoding = "json"

    async def on_connect(self, websocket):
        await websocket.accept()
        if communicationBus.cartL:
            try:
                await communicationBus.cartL.close()
            except:
                pass
        communicationBus.cartL = websocket
        logger.info("CartL connected")

        # Send stored video URL if available
        if communicationBus.youtubeL:
            await websocket.send_json({"type": "youtubeUpdate", "data": communicationBus.youtubeL})
        if communicationBus.twitchL:
            await websocket.send_json({"type": "twitchUpdate", "data": communicationBus.twitchL})
    
    async def on_disconnect(self, websocket, close_code):
        communicationBus.cartL = None
        logger.info("CartL disconnected")
    
    async def on_receive(self, websocket, data):
        if data.get("type") == "state":
            communicationBus.screenStateL = data.get("data")
        else:
            logger.info(f"CartL received unknown type: {data.get('type')}")

class CartREndpoint(WebSocketEndpoint):
    encoding = "json"

    async def on_connect(self, websocket):
        await websocket.accept()
        if communicationBus.cartR:
            try:
                await communicationBus.cartR.close()
            except:
                pass
        communicationBus.cartR = websocket
        logger.info("CartR connected")

        # Send stored video URL if available
        if communicationBus.youtubeR:
            await websocket.send_json({"type": "youtubeUpdate", "data": communicationBus.youtubeR})
        if communicationBus.twitchR:
            await websocket.send_json({"type": "twitchUpdate", "data": communicationBus.twitchR})
    
    async def on_disconnect(self, websocket, close_code):
        communicationBus.cartR = None
        logger.info("CartR disconnected")
    
    async def on_receive(self, websocket, data):
        if data.get("type") == "state":
            communicationBus.screenStateR = data.get("data")
        else:
            logger.info(f"CartR received unknown type: {data.get('type')}")

class MissionControllerEndpoint(WebSocketEndpoint):
    encoding = "json"
    
    async def on_connect(self, websocket):
        await websocket.accept()
        if communicationBus.missionController:
            try:
                await communicationBus.missionController.close()
            except:
                pass
        communicationBus.missionController = websocket
        logger.info("MissionController connected")

        await _initialHandshake()
    
    async def on_disconnect(self, websocket, close_code):
        communicationBus.missionController = None
        logger.info("MissionController disconnected")
    
    async def on_receive(self, websocket, data):
        await communicationBus.recieveMissionController(data)
        logger.info(f"MissionController received: {data}")

async def _initialHandshake():
    matches = await getMatches(fresh=True)
    if matches != []:
        await communicationBus.sendMissionController({"type": "matchPackage", "data": matches})

    # Send cached video states
    if communicationBus.youtubeL:
        await communicationBus.sendMissionController({"type": "youtubeLUpdate", "data": communicationBus.youtubeL})
    else:
        await communicationBus.sendMissionController(buildMessagePackage("requestYoutubeL", None))
    
    if communicationBus.twitchL:
        await communicationBus.sendMissionController({"type": "twitchLUpdate", "data": communicationBus.twitchL})
    else:
        await communicationBus.sendMissionController(buildMessagePackage("requestTwitchL", None))

    if communicationBus.youtubeR:
        await communicationBus.sendMissionController({"type": "youtubeRUpdate", "data": communicationBus.youtubeR})
    else:
        await communicationBus.sendMissionController(buildMessagePackage("requestYoutubeR", None))
    
    if communicationBus.twitchR:
        await communicationBus.sendMissionController({"type": "twitchRUpdate", "data": communicationBus.twitchR})
    else:
        await communicationBus.sendMissionController(buildMessagePackage("requestTwitchR", None))

    # Send match code if available
    if communicationBus.matchCode:
        await communicationBus.sendMissionController({"type": "matchCode", "data": communicationBus.matchCode})
    else:
        await communicationBus.sendMissionController(buildMessagePackage("requestMatchCode", None))

    # Send current states
    if communicationBus.screenStateL:
        await communicationBus.sendMissionController(buildMessagePackage("stateL", communicationBus.screenStateL))
    else:
        await communicationBus.sendMissionController(buildMessagePackage("requestStateL", None))

    if communicationBus.screenStateR:
        await communicationBus.sendMissionController(buildMessagePackage("stateR", communicationBus.screenStateR))
    else:
        await communicationBus.sendMissionController(buildMessagePackage("requestStateR", None))
