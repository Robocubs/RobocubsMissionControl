import QtQuick
import QtWebEngine

Item {
    property url slidesURL: ""
    anchors.fill: parent

    WebEngineView {
        anchors.fill: parent
        url: slidesURL
    }
}