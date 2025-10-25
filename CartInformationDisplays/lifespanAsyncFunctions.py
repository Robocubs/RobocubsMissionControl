import logging
import asyncio
from communicationBus import communicationBus
from tba import getMatches

logger = logging.getLogger(__name__)

async def matchUpdate():
    while True:
        matches = await getMatches()
        if matches != []:
            await communicationBus.sendMissionController({"type": "matchPackage", "data": matches})
        await asyncio.sleep(10)