import asyncio
import uvicorn
import threading
from app import app
from tba import getMatches
from communicationBus import communicationBus
import time

def threadMasterMatchDataSender():
    matches = getMatches()
    if matches != []:
        asyncio.run(communicationBus.sendMissionController({"type": "matches", "data": matches}))

    while True:
        time.sleep(10)
        matches = getMatches()
        if matches != []:
            asyncio.run(communicationBus.sendMissionController({"type": "matches", "data": matches}))

if __name__ == "__main__":
    masterMatchDataThread = threading.Thread(target=threadMasterMatchDataSender, daemon=True)
    masterMatchDataThread.start()
    uvicorn.run(app, host="0.0.0.0", port=1701)