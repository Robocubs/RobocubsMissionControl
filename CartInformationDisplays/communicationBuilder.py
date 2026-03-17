import logging
from starlette.endpoints import WebSocketEndpoint
from tba import getMatches
from communicationBus import communicationBus

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
        logger.info(f"CartL received: {data}")

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
        logger.info(f"CartR received: {data}")

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

        # Init Data Send (on connect)
        matches = await getMatches(fresh=True)
        if matches != []:
            await communicationBus.sendMissionController({"type": "matchPackage", "data": matches})

        # Send cached video states
        if communicationBus.youtubeL:
            await communicationBus.sendMissionController({"type": "youtubeLUpdate", "data": communicationBus.youtubeL})
        if communicationBus.twitchL:
            await communicationBus.sendMissionController({"type": "twitchLUpdate", "data": communicationBus.twitchL})
        if communicationBus.youtubeR:
            await communicationBus.sendMissionController({"type": "youtubeRUpdate", "data": communicationBus.youtubeR})
        if communicationBus.twitchR:
            await communicationBus.sendMissionController({"type": "twitchRUpdate", "data": communicationBus.twitchR})

        # Send match code if available
        if communicationBus.matchCode:
            await communicationBus.sendMissionController({"type": "matchCode", "data": communicationBus.matchCode})
    
    async def on_disconnect(self, websocket, close_code):
        communicationBus.missionController = None
        logger.info("MissionController disconnected")
    
    async def on_receive(self, websocket, data):
        await communicationBus.recieveMissionController(data)
        logger.info(f"MissionController received: {data}")