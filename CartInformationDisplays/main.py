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
from lifespanAsyncFunctions import mediaJanitor, matchUpdate
from mediaLibrary import FILES_DIR, ensureDirectories
from mediaRoutes import router as mediaRouter

logging.basicConfig(level=logging.INFO)

# media/ is gitignored, so it won't exist on a fresh checkout. This must run
# before the StaticFiles mount below: that raises at mount time if the
# directory is missing, which under systemd's Restart=always is a crash
# loop with no websocket left to recover through.
ensureDirectories()

@asynccontextmanager
async def lifespan(app: FastAPI):
    tasks = [asyncio.create_task(matchUpdate()), asyncio.create_task(mediaJanitor())]
    try:
        yield
    finally:
        for task in tasks:
            task.cancel()
        # return_exceptions=True: cancelling a task makes it raise
        # CancelledError, and `await`ing that directly (the original
        # single-task version of this) would propagate it right back out
        # of shutdown. gather() with this flag collects it instead.
        await asyncio.gather(*tasks, return_exceptions=True)

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

app.include_router(mediaRouter)
app.mount("/media", StaticFiles(directory=FILES_DIR), name="media")

app.add_websocket_route("/cartL", CartLEndpoint)
app.add_websocket_route("/cartR", CartREndpoint)
app.add_websocket_route("/missionController", MissionControllerEndpoint)

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=1701)