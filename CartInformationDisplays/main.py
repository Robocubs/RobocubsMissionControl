import asyncio
import logging
from contextlib import asynccontextmanager
import uvicorn
from app import app
from tba import getMatches
from communicationBus import communicationBus

logging.basicConfig(level=logging.INFO)

async def masterMatchDataSender():
    while True:
        matches = await getMatches()
        if matches != []:
            await communicationBus.sendMissionController({"type": "matchPackage", "data": matches})
        await asyncio.sleep(10) 

@asynccontextmanager
async def lifespan(app):
    task = asyncio.create_task(masterMatchDataSender())
    try:
        yield
    finally:
        task.cancel()
        await task

if __name__ == "__main__":
    app.lifespan = lifespan
    uvicorn.run(app, host="0.0.0.0", port=1701)