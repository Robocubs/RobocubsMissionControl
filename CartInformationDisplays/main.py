from starlette.websockets import WebSocket
WebSocket.__init__.__defaults__ = (None, None, None, None, None, None, None, False)

import asyncio
import logging
import mimetypes
from contextlib import asynccontextmanager
import uvicorn

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import os

from communicationBuilder import CartLEndpoint, CartREndpoint, MissionControllerEndpoint
from communicationBus import communicationBus, HLS_DIR_L, HLS_DIR_R
from lifespanAsyncFunctions import matchUpdate

logging.basicConfig(level=logging.INFO)

mimetypes.add_type("application/vnd.apple.mpegurl", ".m3u8")
mimetypes.add_type("video/mp2t", ".ts")

os.makedirs(HLS_DIR_L, exist_ok=True)
os.makedirs(HLS_DIR_R, exist_ok=True)

@asynccontextmanager
async def lifespan(app: FastAPI):
    task = asyncio.create_task(matchUpdate())
    # Auto-start FFmpeg for sides that default to localLivestream
    if communicationBus.stateL == "localLivestream" and communicationBus.livestreamL:
        await communicationBus._start_ffmpeg("L", communicationBus.livestreamL)
    if communicationBus.stateR == "localLivestream" and communicationBus.livestreamR:
        await communicationBus._start_ffmpeg("R", communicationBus.livestreamR)
    await asyncio.sleep(3)
    try:
        yield
    finally:
        task.cancel()
        await task
        await communicationBus._stop_ffmpeg("L")
        await communicationBus._stop_ffmpeg("R")

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
app.mount("/hls_L", StaticFiles(directory=HLS_DIR_L), name="hls_L")
app.mount("/hls_R", StaticFiles(directory=HLS_DIR_R), name="hls_R")

app.add_websocket_route("/cartL", CartLEndpoint)
app.add_websocket_route("/cartR", CartREndpoint)
app.add_websocket_route("/missionController", MissionControllerEndpoint)

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=1701)
