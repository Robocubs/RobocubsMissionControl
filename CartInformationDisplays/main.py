import asyncio
import uvicorn
import threading
from app import app
from tba import getMatchQueueInfo, getMatches
from communicationBus import communicationBus
import time

def threadMatchDataHandler():
    matches = getMatches(fresh=True)
    queue_info = getMatchQueueInfo(matches)
    last_match_queued = 0

    while True:
        time.sleep(10)
        matches = getMatches()
        # Match data was updated by TBA
        if matches != []:
            queue_info = getMatchQueueInfo(matches)
            asyncio.run(communicationBus.sendMissionController({"type": "matchPackage", "data": matches}))
        for q in queue_info:
            if q['time'] is not None:
                current_unix_time = int(time.time())
                if last_match_queued < q['matchId'] and q['time'] - current_unix_time <= 300 and q['time'] - current_unix_time > 0:
                    last_match_queued = q['matchId']
                    data = {
                        "color" : q['color'],
                        "position" : q['position'],
                        "matchId": q['matchId'],
                        }
                    asyncio.run(communicationBus.sendL({"type": "matchQueuePackage", "data": data}))
                    asyncio.run(communicationBus.sendR({"type": "matchQueuePackage", "data": data}))
            


if __name__ == "__main__":
    masterMatchDataThread = threading.Thread(target=threadMatchDataHandler, daemon=True)
    masterMatchDataThread.start()
    uvicorn.run(app, host="0.0.0.0", port=1701)