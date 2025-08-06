import asyncio
import uvicorn
import threading
from app import app
from tba import getMatches
from communicationBus import communicationBus
import time

def threadMasterMatchDataSender():
    while True:
        time.sleep(10)
        matches = getMatches()
        if matches != []:
            communicationBus.sendMissionController(matches)

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=1701)
    masterMatchDataThread = threading.Thread(target=threadMasterMatchDataSender
                                       )
    masterMatchDataThread.start()