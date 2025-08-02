from starlette.websockets import WebSocket
WebSocket.__init__.__defaults__ = (None, None, None, None, None, None, None, False)

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import os

from communicationBuilder import CartLEndpoint, CartREndpoint, MissionControllerEndpoint
from communicationBus import communicationBus

app = FastAPI()

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