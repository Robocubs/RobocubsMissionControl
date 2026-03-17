import asyncio
import logging
from typing import Dict, Any, Optional

logger = logging.getLogger(__name__)

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
    
    async def sendL(self, message: Dict[str, Any]):
        if self.cartL:
            await self.cartL.send_json(message)
            logger.info(f"Sent to CartL: {message}")
        else:
            logger.info("CartL not connected")

    async def sendR(self, message: Dict[str, Any]):
        if self.cartR:
            await self.cartR.send_json(message)
            logger.info(f"Sent to CartR: {message}")
        else:
            logger.info("CartR not connected")
    
    async def sendMissionController(self, message: Dict[str, Any]):
        if self.missionController:
            await self.missionController.send_json(message)
            logger.info(f"Sent to MissionController: {message}")
        else:
            logger.info("MissionController not connected")
    
    async def recieveMissionController(self, data: Dict[str, Any]):
        try:
            msg_type = data.get("type")

            if msg_type == "state" or msg_type == "stateL" or msg_type == "stateR":
                # Send to both carts
                await self.sendL(data)
                await self.sendR(data)
                # Confirm success
                await self.sendMissionController({"type": "confirm", "data": "true"})
            elif msg_type == "youtubeLUpdate":
                self.youtubeL = data.get("data")
                await self.sendL({"type": "youtubeLUpdate", "data": data.get("data")})
                await self.sendMissionController({"type": "confirm", "data": "true"})
            elif msg_type == "youtubeRUpdate":
                self.youtubeR = data.get("data")
                await self.sendR({"type": "youtubeRUpdate", "data": data.get("data")})
                await self.sendMissionController({"type": "confirm", "data": "true"})
            elif msg_type == "twitchLUpdate":
                self.twitchL = data.get("data")
                await self.sendL({"type": "twitchLUpdate", "data": data.get("data")})
                await self.sendMissionController({"type": "confirm", "data": "true"})
            elif msg_type == "twitchRUpdate":
                self.twitchR = data.get("data")
                await self.sendR({"type": "twitchRUpdate", "data": data.get("data")})
                await self.sendMissionController({"type": "confirm", "data": "true"})
            elif msg_type == "matchCode":
                self.matchCode = data.get("data")
                await self.sendMissionController({"type": "confirm", "data": "true"})
            else:
                logger.info(f"Unknown command type: {msg_type}")
                await self.sendMissionController({"type": "confirm", "data": "false"})
        except Exception as e:
            logger.error(f"Error handling command: {e}")
            await self.sendMissionController({"type": "confirm", "data": "false"})

# Global communication bus
communicationBus = CommunicationBus()