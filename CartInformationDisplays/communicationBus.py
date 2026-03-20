import asyncio
import logging
from typing import Dict, Any, Optional

logger = logging.getLogger(__name__)

class CommunicationBus:
    def __init__(self):
        # Connection references
        self.cartL: Optional[Any] = None
        self.cartR: Optional[Any] = None
        self.missionController: Optional[Any] = None

        # Cached states
        self.screenStateL: Optional[str] = None
        self.screenStateR: Optional[str] = None

        # Cached values
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
    
    async def recieveL(self, data: Dict[str, Any]):
      try:                                                            
          msg_type = data.get("type")
          if msg_type == "state":                                     
              self.screenStateL = data.get("data")
              logger.info(f"CartL state updated: {self.screenStateL}")
              await self.sendMissionController({"type": "stateL", "data": self.screenStateL})                         
      except Exception as e:                                          
          logger.info(f"Error handling CartL message: {e}")          
                  
    async def recieveR(self, data: Dict[str, Any]):                     
      try:
            msg_type = data.get("type")                                 
            if msg_type == "state":
                self.screenStateR = data.get("data")                    
                logger.info(f"CartR state updated: {self.screenStateR}")               
                await self.sendMissionController({"type": "stateR", "data": self.screenStateR})                         
      except Exception as e:                                          
          logger.info(f"Error handling CartR message: {e}")

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
            else:
                logger.info(f"Unknown command type: {msg_type}")
                await self.sendMissionController({"type": "confirm", "data": "false"})
        except Exception as e:
            logger.error(f"Error handling command: {e}")
            await self.sendMissionController({"type": "confirm", "data": "false"})

# Global communication bus
communicationBus = CommunicationBus()