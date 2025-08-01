import os


os.environ["QTWEBENGINE_CHROMIUM_FLAGS"] = (
    '--enable-widevine-cdm '
    '--widevine-path=/Applications/Google Chrome.app/Contents/Frameworks/Google Chrome Framework.framework/Versions/138.0.7204.169/Libraries/WidevineCdm/_platform_specific/mac_arm64/libwidevinecdm.dylib'
)

from PySide6.QtCore import QObject, Slot, Property, Signal
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine


# Simple backend logic class
# class MyLogic(QObject):
#     counterChanged = Signal()

#     def __init__(self):
#         super().__init__()
#         self._counter = 0

#     @Property(int, notify=counterChanged)
#     def counter(self):
#         return self._counter

#     @Slot()
#     def increment(self):
#         self._counter += 1
#         self.counterChanged.emit()

# Expose backend to QML
# logic = MyLogic()
# engine.rootContext().setContextProperty("logic", logic)

currentDirectory = os.path.dirname(os.path.abspath(__file__))

app = QGuiApplication([])

from PySide6.QtWebEngineCore import QWebEngineProfile
profile = QWebEngineProfile.defaultProfile()
print("User-Agent:", profile.httpUserAgent())

screens = app.screens()
for i, screen in enumerate(screens):
    print(f"Screen {i}: {screen.name()}, geometry: {screen.geometry()}")
if len(screens) < 2:
    print("Error: Less than two displays detected.")
    exit(-1)

# First display
engine1 = QQmlApplicationEngine()
engine1.load(os.path.join(currentDirectory, "LeftDisplayManager.qml"))
if not engine1.rootObjects():
    print("Error: Failed to load QML for display 1.")
    exit(-1)
window1 = engine1.rootObjects()[0]
window1.setScreen(screens[1])
window1.setGeometry(screens[1].geometry())
window1.showFullScreen()

# Second display
engine2 = QQmlApplicationEngine()
engine2.load(os.path.join(currentDirectory, "RightDisplayManager.qml"))
if not engine2.rootObjects():
    print("Error: Failed to load QML for display 2.")
    exit(-1)
window2 = engine2.rootObjects()[0]
window2.setScreen(screens[2])
window2.setGeometry(screens[2].geometry())
window2.showFullScreen()

app.exec()