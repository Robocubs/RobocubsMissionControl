from starlette.websockets import WebSocket
WebSocket.__init__.__defaults__ = (None, None, None, None, None, None, None, False)
print("WebSocket origin check patch applied")

from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from starlette.endpoints import WebSocketEndpoint
from starlette.responses import Response as StarletteResponse
import httpx
import os

from controllerRouter import controllerRouter
import sharedState

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

class CartLEndpoint(WebSocketEndpoint):
    encoding = "json"
    
    async def on_connect(self, websocket):
        print("CartL connect attempt - accepting without origin check")
        await websocket.accept()
        
        if sharedState.cartL is not None:
            try:
                await sharedState.cartL.close()
            except:
                pass

        sharedState.cartL = websocket
        print("CartL connected successfully")
    
    async def on_disconnect(self, websocket, close_code):
        print("CartL disconnected")
        sharedState.cartL = None

    async def on_receive(self, websocket, data):
        print(f"CartL received: {data}")

class CartREndpoint(WebSocketEndpoint):
    encoding = "json"
    
    async def on_connect(self, websocket):
        print("CartR connect attempt - accepting without origin check")
        await websocket.accept()

        if sharedState.cartR is not None:
            try:
                await sharedState.cartR.close()
            except:
                pass

        sharedState.cartR = websocket
        print("CartR connected successfully")
    
    async def on_disconnect(self, websocket, close_code):
        print("CartR disconnected")
        sharedState.cartR = None
        
    async def on_receive(self, websocket, data):
        print(f"CartR received: {data}")

class MissionController(WebSocketEndpoint):
    encoding = "json"
    
    async def on_connect(self, websocket):
        print("MissionController connect attempt - accepting without origin check")
        await websocket.accept()

        if sharedState.missionController is not None:
            try:
                await sharedState.missionController.close()
            except:
                pass

        sharedState.missionController = websocket
        print("MissionController connected successfully")

    async def on_disconnect(self, websocket, close_code):
        print("MissionController disconnected")
        sharedState.missionController = None

    async def on_receive(self, websocket, data):
        await controllerRouter(data)
        print(f"MissionController received: {data}")

# Replace the @app.websocket decorators with these:
app.add_websocket_route("/cartL", CartLEndpoint)
app.add_websocket_route("/cartR", CartREndpoint)
app.add_websocket_route("/missionControl", MissionController)

async def cartLSend(message: dict):
    if sharedState.cartL is not None:
        await sharedState.cartL.send_json(message)
        print(f"Sent to CartL: {message}")
    else:
        print("CartL not connected - cannot send message")

async def cartRSend(message: dict):
    if sharedState.cartR is not None:
        await sharedState.cartR.send_json(message)
        print(f"Sent to CartR: {message}")
    else:
        print("CartR not connected - cannot send message")

async def missionControlSend(message: dict):
    if sharedState.missionController is not None:
        await sharedState.missionController.send_json(message)
        print(f"Sent to MissionController: {message}")
    else:
        print("MissionController not connected - cannot send message")
