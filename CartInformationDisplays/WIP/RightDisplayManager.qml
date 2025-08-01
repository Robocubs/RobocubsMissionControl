import QtQuick
import QtQuick.Window
import QtQuick.Controls

import "./templates" as Templates

ApplicationWindow {
    id: window
    visible: true
    title: "Right Display - Robocubs Mission Control"

//    Templates.Sponsors {
//        slidesURL: "https://docs.google.com/presentation/d/e/2PACX-1vSToCZ6ksw75RaUtXSaVFaWlWYgFRwob0FOeRamLQrt9g-T5YBKuiYFoHSFrLfyPtXXAe8V3kbjpl86/embed?start=true&loop=true&delayms=3000&rm=minimal"
//    }

    Templates.TwitchEmbed {
        twitchChannel: "bobross"
    }
}