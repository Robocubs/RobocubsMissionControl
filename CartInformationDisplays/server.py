from flask import Flask, send_file
import os

currentDirectory = os.path.dirname(os.path.abspath(__file__))

app = Flask(__name__)

dashboardL = os.path.join(currentDirectory, "dashboardL.html")
dashboardR = os.path.join(currentDirectory, "dashboardR.html")

@app.route('/hello')
def hello():
    return "Hello, World!"

def runApp():
    app.run(host='0.0.0.0', port=8082)

if __name__ == "__main__":
    runApp()