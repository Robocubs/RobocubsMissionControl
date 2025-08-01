import QtQuick
import QtQuick.Window
import QtQuick.Controls

import "./templates" as Templates

ApplicationWindow {
    id: window
    visible: true
    title: "Left Display - Robocubs Mission Control"

    // Templates.Sponsors {
    //     slidesURL: "https://docs.google.com/presentation/d/e/2PACX-1vRkkyssQQCfxNXfz6p63vJQFkNowBuO5IQGxcVh7oHx7nSDiTy5q7LhW3oDdxhHp548xx8ZUKeW0umM/embed?start=true&loop=true&delayms=3000&rm=minimal"
    // }
    Templates.MatchTransition {}
}