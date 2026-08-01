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

        # Replay the last-known view state. Previously this cart reload/
        # reconnect silently dropped back to the screensaver until someone
        # re-tapped a button on the controller — this fixes that for every
        # view, not just local video.
        if communicationBus.stateL:
            await websocket.send_json({"type": "stateL", "data": communicationBus.stateL})

        # Resume local video where it left off: which file, and the last
        # position/paused/muted/loop this same cart reported before it
        # disconnected (a page reload drops all client-side JS state).
        if communicationBus.localVideoL:
            desc = communicationBus.mediaDescriptor(communicationBus.localVideoL)
            if desc:
                status = communicationBus.statusL or {}
                await websocket.send_json({
                    "type": "localVideoResume",
                    "data": {
                        **desc,
                        "position": status.get("position", 0),
                        "paused": status.get("paused", False),
                        "muted": status.get("muted", True),
                        "loop": status.get("loop", False),
                    },
                })

    async def on_disconnect(self, websocket, close_code):
        communicationBus.cartL = None
        logger.info("CartL disconnected")

    async def on_receive(self, websocket, data):
        await communicationBus.recieveCart("L", data)

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

        if communicationBus.stateR:
            await websocket.send_json({"type": "stateR", "data": communicationBus.stateR})

        if communicationBus.localVideoR:
            desc = communicationBus.mediaDescriptor(communicationBus.localVideoR)
            if desc:
                status = communicationBus.statusR or {}
                await websocket.send_json({
                    "type": "localVideoResume",
                    "data": {
                        **desc,
                        "position": status.get("position", 0),
                        "paused": status.get("paused", False),
                        "muted": status.get("muted", True),
                        "loop": status.get("loop", False),
                    },
                })

    async def on_disconnect(self, websocket, close_code):
        communicationBus.cartR = None
        logger.info("CartR disconnected")

    async def on_receive(self, websocket, data):
        await communicationBus.recieveCart("R", data)

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
        try:
            logger.info("Fetching matches on connect...")
            matches = await getMatches(event_code=communicationBus.matchCode, fresh=True)
            logger.info(f"Got matches: {matches}")
            if matches != []:
                await communicationBus.sendMissionController({"type": "matchPackage", "data": matches})
            else:
                logger.warning("No matches returned")
        except Exception as e:
            logger.error(f"Error fetching matches: {e}", exc_info=True)
            await communicationBus.sendMissionController({"type": "matchPackageError", "data": str(e)})

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

        # Send local video state: the library, which file (if any) is
        # selected per side, and the last known playback status per side —
        # so the iPad's transport controls reflect reality immediately
        # rather than a blank slate after the app reconnects.
        await communicationBus.pushLibrary()
        if communicationBus.localVideoL:
            await communicationBus.sendMissionController({"type": "localVideoLUpdate", "data": communicationBus.localVideoL})
        if communicationBus.localVideoR:
            await communicationBus.sendMissionController({"type": "localVideoRUpdate", "data": communicationBus.localVideoR})
        if communicationBus.statusL:
            await communicationBus.sendMissionController({"type": "localVideoLStatus", "data": communicationBus.statusL})
        if communicationBus.statusR:
            await communicationBus.sendMissionController({"type": "localVideoRStatus", "data": communicationBus.statusR})

    async def on_disconnect(self, websocket, close_code):
        communicationBus.missionController = None
        logger.info("MissionController disconnected")
    
    async def on_receive(self, websocket, data):
        await communicationBus.recieveMissionController(data)
        logger.info(f"MissionController received: {data}")