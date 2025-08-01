import asyncio
import uvicorn
from communicationEngine import cartLSend, app
import threading

def startServer():
    uvicorn.run(app, host="0.0.0.0", port=8010)

def main():
    while True:
        userInput = input("Enter something: ")
        asyncio.run(cartLSend({"type": "state", "data": userInput}))


if __name__ == "__main__":
    serverThread = threading.Thread(target=startServer)
    serverThread.start()
    main()