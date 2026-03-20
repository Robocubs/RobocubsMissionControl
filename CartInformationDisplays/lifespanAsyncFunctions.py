import logging
import asyncio
from communicationBus import communicationBus
from tba import getMatches

logger = logging.getLogger(__name__)

async def matchUpdate():
    while True:
        try:
            if communicationBus.matchCode:
                matches = await getMatches(communicationBus.matchCode)
                if matches != []:
                    await communicationBus.sendMissionController({"type": "matchPackage", "data": matches})
        except Exception as e:
            logger.error(f"Error in matchUpdate iteration: {e}", exc_info=True)

        await asyncio.sleep(10)