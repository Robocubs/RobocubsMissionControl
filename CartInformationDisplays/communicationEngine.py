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
from sharedState import cartL, cartR, missionController

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
        
        if cartL is not None:
            try:
                await cartL.close()
            except:
                pass
        
        cartL = websocket
        print("CartL connected successfully")
    
    async def on_disconnect(self, websocket, close_code):
        print("CartL disconnected")
        cartL = None
        
    async def on_receive(self, websocket, data):
        print(f"CartL received: {data}")

class CartREndpoint(WebSocketEndpoint):
    encoding = "json"
    
    async def on_connect(self, websocket):
        print("CartR connect attempt - accepting without origin check")
        await websocket.accept()
        
        if cartR is not None:
            try:
                await cartR.close()
            except:
                pass
        
        cartR = websocket
        print("CartR connected successfully")
    
    async def on_disconnect(self, websocket, close_code):
        print("CartR disconnected")
        cartR = None
        
    async def on_receive(self, websocket, data):
        print(f"CartR received: {data}")

class MissionController(WebSocketEndpoint):
    encoding = "json"
    
    async def on_connect(self, websocket):
        print("MissionController connect attempt - accepting without origin check")
        await websocket.accept()
        
        if missionController is not None:
            try:
                await missionController.close()
            except:
                pass

        missionController = websocket
        print("MissionController connected successfully")

    async def on_disconnect(self, websocket, close_code):
        print("MissionController disconnected")
        missionController = None

    async def on_receive(self, websocket, data):
        controllerRouter(data)
        print(f"MissionController received: {data}")

# Replace the @app.websocket decorators with these:
app.add_websocket_route("/cartL", CartLEndpoint)
app.add_websocket_route("/cartR", CartREndpoint)
app.add_websocket_route("/missionControl", MissionController)

async def cartLSend(message: dict):
    if cartL is not None:
        await cartL.send_json(message)
        print(f"Sent to CartL: {message}")
    else:
        print("CartL not connected - cannot send message")

async def cartRSend(message: dict):
    if cartR is not None:
        await cartR.send_json(message)
        print(f"Sent to CartR: {message}")
    else:
        print("CartR not connected - cannot send message")

async def missionControlSend(message: dict):
    if missionController is not None:
        await missionController.send_json(message)
        print(f"Sent to MissionController: {message}")
    else:
        print("MissionController not connected - cannot send message")
