# websocket_handlers.py
import asyncio
from starlette.endpoints import WebSocketEndpoint
from CartInformationDisplays.tba import getMatches
from communicationBus import communicationBus

class CartLEndpoint(WebSocketEndpoint):
    encoding = "json"
    
    async def on_connect(self, websocket):
        await websocket.accept()
        if communicationBus.cartL:
            try:
                await communicationBus.cartL.close()
            except:
                pass
        communicationBus.cartL = websocket
        print("CartL connected")
    
    async def on_disconnect(self, websocket, close_code):
        communicationBus.cartL = None
        print("CartL disconnected")
    
    async def on_receive(self, websocket, data):
        print(f"CartL received: {data}")

class CartREndpoint(WebSocketEndpoint):
    encoding = "json"
    
    async def on_connect(self, websocket):
        await websocket.accept()
        if communicationBus.cartR:
            try:
                await communicationBus.cartR.close()
            except:
                pass
        communicationBus.cartR = websocket
        print("CartR connected")
    
    async def on_disconnect(self, websocket, close_code):
        communicationBus.cartR = None
        print("CartR disconnected")
    
    async def on_receive(self, websocket, data):
        print(f"CartR received: {data}")

class MissionControllerEndpoint(WebSocketEndpoint):
    encoding = "json"
    
    async def on_connect(self, websocket):
        await websocket.accept()
        if communicationBus.missionController:
            try:
                await communicationBus.missionController.close()
            except:
                pass
        communicationBus.missionController = websocket
        print("MissionController connected")
        matches = getMatches(fresh=True)
        if matches != []:
            asyncio.run(communicationBus.sendMissionController({"type": "matches", "data": matches}))
    
    async def on_disconnect(self, websocket, close_code):
        communicationBus.missionController = None
        print("MissionController disconnected")
    
    async def on_receive(self, websocket, data):
        await communicationBus.recieveMissionController(data)
        print(f"MissionController received: {data}")