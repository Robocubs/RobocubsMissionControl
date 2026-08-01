import asyncio
import logging
from typing import Dict, Any, Optional

logger = logging.getLogger(__name__)

# Message types that are sent at status-report frequency (currently 2Hz per
# cart, once local video lands). Logging these at INFO would flood the
# journal forever, so they're excluded from the per-send log line.
_QUIET_TYPES = {"localVideoStatus", "localVideoLStatus", "localVideoRStatus"}

class CommunicationBus:
    def __init__(self):
        self.cartL: Optional[Any] = None
        self.cartR: Optional[Any] = None
        self.missionController: Optional[Any] = None
        self.youtubeL: Optional[str] = None
        self.twitchL: Optional[str] = None
        self.youtubeR: Optional[str] = None
        self.twitchR: Optional[str] = None
        self.matchCode: Optional[str] = None
        # Local video: last-selected media id per side, and the last status
        # report received from each cart (used to replay resume state).
        self.localVideoL: Optional[str] = None
        self.localVideoR: Optional[str] = None
        self.statusL: Optional[Dict[str, Any]] = None
        self.statusR: Optional[Dict[str, Any]] = None
        # Cached cart view state, so a cart reload can be replayed back to
        # where it was instead of falling back to the screensaver.
        self.stateL: Optional[str] = None
        self.stateR: Optional[str] = None

    async def sendL(self, message: Dict[str, Any]):
        if self.cartL:
            try:
                await self.cartL.send_json(message)
            except Exception as e:
                logger.warning(f"Failed to send to CartL, dropping socket: {e}")
                self.cartL = None
                return
            if message.get("type") not in _QUIET_TYPES:
                logger.info(f"Sent to CartL: {message}")
        else:
            logger.info("CartL not connected")

    async def sendR(self, message: Dict[str, Any]):
        if self.cartR:
            try:
                await self.cartR.send_json(message)
            except Exception as e:
                logger.warning(f"Failed to send to CartR, dropping socket: {e}")
                self.cartR = None
                return
            if message.get("type") not in _QUIET_TYPES:
                logger.info(f"Sent to CartR: {message}")
        else:
            logger.info("CartR not connected")

    async def sendMissionController(self, message: Dict[str, Any]):
        if self.missionController:
            try:
                await self.missionController.send_json(message)
            except Exception as e:
                logger.warning(f"Failed to send to MissionController, dropping socket: {e}")
                self.missionController = None
                return
            if message.get("type") not in _QUIET_TYPES:
                logger.info(f"Sent to MissionController: {message}")
        else:
            logger.info("MissionController not connected")

    async def recieveMissionController(self, data: Dict[str, Any]):
        try:
            msg_type = data.get("type")

            if msg_type == "state" or msg_type == "stateL" or msg_type == "stateR":
                # Cache so a cart reconnect can be replayed back to this state.
                if msg_type in ("state", "stateL"):
                    self.stateL = data.get("data")
                if msg_type in ("state", "stateR"):
                    self.stateR = data.get("data")
                # Send to both carts
                await self.sendL(data)
                await self.sendR(data)
                # Confirm success
                await self.sendMissionController({"type": "confirm", "data": "true"})
            elif msg_type == "youtubeLUpdate":
                self.youtubeL = data.get("data")
                await self.sendL({"type": "youtubeUpdate", "data": data.get("data")})
                await self.sendMissionController({"type": "confirm", "data": "true"})
            elif msg_type == "youtubeRUpdate":
                self.youtubeR = data.get("data")
                await self.sendR({"type": "youtubeUpdate", "data": data.get("data")})
                await self.sendMissionController({"type": "confirm", "data": "true"})
            elif msg_type == "twitchLUpdate":
                self.twitchL = data.get("data")
                await self.sendL({"type": "twitchUpdate", "data": data.get("data")})
                await self.sendMissionController({"type": "confirm", "data": "true"})
            elif msg_type == "twitchRUpdate":
                self.twitchR = data.get("data")
                await self.sendR({"type": "twitchUpdate", "data": data.get("data")})
                await self.sendMissionController({"type": "confirm", "data": "true"})
            elif msg_type == "matchCode":
                self.matchCode = data.get("data")
                await self.sendMissionController({"type": "confirm", "data": "true"})
            elif msg_type == "localVideoLUpdate":
                self.localVideoL = data.get("data")
                await self.sendL({"type": "localVideoUpdate", "data": self.mediaDescriptor(self.localVideoL)})
                await self.sendMissionController({"type": "confirm", "data": "true"})
            elif msg_type == "localVideoRUpdate":
                self.localVideoR = data.get("data")
                await self.sendR({"type": "localVideoUpdate", "data": self.mediaDescriptor(self.localVideoR)})
                await self.sendMissionController({"type": "confirm", "data": "true"})
            elif msg_type == "localVideoLCommand":
                # No confirm here on purpose: transport commands (and the
                # scrubber especially) fire fast enough that acking every one
                # would flood the controller with confirm traffic for no benefit.
                await self.sendL({"type": "localVideoCommand", "data": data.get("data")})
            elif msg_type == "localVideoRCommand":
                await self.sendR({"type": "localVideoCommand", "data": data.get("data")})
            elif msg_type == "localVideoLibraryRequest":
                await self.pushLibrary()
            elif msg_type == "localVideoDelete":
                from mediaLibrary import deleteMedia
                deleteMedia(data.get("data"))
                await self.pushLibrary()
                await self.sendMissionController({"type": "confirm", "data": "true"})
            else:
                logger.info(f"Unknown command type: {msg_type}")
                await self.sendMissionController({"type": "confirm", "data": "false"})
        except Exception as e:
            logger.error(f"Error handling command: {e}")
            await self.sendMissionController({"type": "confirm", "data": "false"})

    async def recieveCart(self, side: str, data: Dict[str, Any]):
        """Handle a message sent from a cart browser back to the server.

        Today this is only local-video status reports, forwarded on to the
        mission controller so its scrubber/play-state can track reality.
        """
        if data.get("type") == "localVideoStatus":
            status = data.get("data")
            if side == "L":
                self.statusL = status
            else:
                self.statusR = status
            await self.sendMissionController({"type": f"localVideo{side}Status", "data": status})
        else:
            logger.info(f"Cart{side} received: {data}")

    async def pushLibrary(self):
        from mediaLibrary import listMedia
        await self.sendMissionController({"type": "localVideoLibrary", "data": listMedia()})

    def mediaDescriptor(self, mediaId: Optional[str]) -> Optional[Dict[str, Any]]:
        if not mediaId:
            return None
        from mediaLibrary import readMeta
        meta = readMeta(mediaId)
        if meta is None:
            return None
        return {
            "id": mediaId,
            "url": f"/media/{mediaId}.mp4",
            "name": meta.get("name", mediaId),
            "duration": meta.get("duration", 0),
        }

# Global communication bus
communicationBus = CommunicationBus()