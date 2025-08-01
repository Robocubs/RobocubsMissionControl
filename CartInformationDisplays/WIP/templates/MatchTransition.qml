import QtQuick

Item {
    anchors.fill: parent

    Rectangle {
        id: matchTransition
        height: parent.height
        width: 0
        y: 0
        x: parent.width
        color: "blue"
        z: 1

        SequentialAnimation {
            id: transitionAnimation
            running: false
            PropertyAnimation { target: matchTransition; property: "x"; from: parent.width; to: 0; duration: 400 }
            PropertyAnimation { target: matchTransition; property: "width"; from: 0; to: parent.width; duration: 400 }
        }
    }

    Component.onCompleted: transitionAnimation.start();
}