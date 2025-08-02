import asyncio
import uvicorn
from communicationEngine import cartLSend, app
import threading

def cli_loop():
    while True:
        userInput = input("Enter something: ")
        asyncio.run(cartLSend({"type": "state", "data": userInput}))

if __name__ == "__main__":
    cliThread = threading.Thread(target=cli_loop, daemon=True)
    cliThread.start()
    uvicorn.run(app, host="0.0.0.0", port=8010)