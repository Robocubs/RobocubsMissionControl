import QtQuick
import QtWebEngine

Item {
    property url twitchChannel: ""
    anchors.fill: parent

    WebEngineView {
        anchors.fill: parent
        //url: "https://player.twitch.tv/?channel=" + twitchChannel + "&enableExtensions=false&muted=true&parent=twitch.tv&player=popout&quality=o&controls=false"
        // url: "chrome://gpu"
        url: "https://bitmovin.com/demos/drm"
    }
}