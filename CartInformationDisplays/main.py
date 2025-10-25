from starlette.websockets import WebSocket
WebSocket.__init__.__defaults__ = (None, None, None, None, None, None, None, False)

import asyncio
import logging
from contextlib import asynccontextmanager
import uvicorn

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import os

from communicationBuilder import CartLEndpoint, CartREndpoint, MissionControllerEndpoint
from communicationBus import communicationBus
from tba import getMatches

logging.basicConfig(level=logging.INFO)

async def masterMatchDataSender():
    logging.info("Hello")
    while True:
        logging.getLogger(__name__).info("Hello")
        matches = await getMatches()
        if matches != []:
            await communicationBus.sendMissionController({"type": "matchPackage", "data": matches})
        await asyncio.sleep(10)

@asynccontextmanager
async def lifespan(app: FastAPI):
    task = asyncio.create_task(masterMatchDataSender())
    try:
        yield
    finally:
        task.cancel()
        await task

app = FastAPI(lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

currentDirectory = os.path.dirname(os.path.abspath(__file__))
app.mount("/prod", StaticFiles(directory=os.path.join(currentDirectory, "frontend", "prod")), name="prod")

app.add_websocket_route("/cartL", CartLEndpoint)
app.add_websocket_route("/cartR", CartREndpoint)
app.add_websocket_route("/missionController", MissionControllerEndpoint)

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=1701)