import asyncio
import logging
from typing import Dict, Any, Optional

logger = logging.getLogger(__name__)

class CommunicationBus:
    def __init__(self):
        self.cartL: Optional[Any] = None
        self.cartR: Optional[Any] = None
        self.missionController: Optional[Any] = None
    
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
            if data.get("type") == "state" or data.get("type") == "stateL" or data.get("type") == "stateR":
                # Send to both carts
                await self.sendL(data)
                await self.sendR(data)
                # Confirm success
                await self.sendMissionController({"type": "confirm", "data": "true"})
        except Exception as e:
            logger.info(f"Error handling command: {e}")
            await self.sendMissionController({"type": "confirm", "data": "false"})

# Global communication bus
communicationBus = CommunicationBus()