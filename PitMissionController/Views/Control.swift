//
//  CartController.swift
//  PitMissionController
//
//  Created by Quincy D on 8/2/25.
//

import SwiftUI

struct Control: View {
    init() {
        _ = BluetoothCentralManager.shared
        _ = socket
    }
    
    var body: some View {
        HStack(spacing: 80) {
            VStack(spacing: 20) {
                Text("Left")
                    .font(.system(size: 40, weight: .medium, design: .default))
                    .padding(.bottom)
                ControlButton(title: "Screensaver", action: CartStates.Screensaver, screen: .left)
                ControlButton(title: "Sponsors", action: CartStates.Sponsors, screen: .left)
                ControlButton(title: "Twitch", action: CartStates.Twitch, screen: .left)
                ControlButton(title: "YouTube", action: CartStates.YouTube, screen: .left)
            }
            VStack(spacing: 20) {
                Text("Right")
                    .font(.system(size: 40, weight: .medium, design: .default))
                    .padding(.bottom)
                ControlButton(title: "Screensaver", action: CartStates.Screensaver, screen: .right)
                ControlButton(title: "Sponsors", action: CartStates.Sponsors, screen: .right)
                ControlButton(title: "Twitch", action: CartStates.Twitch, screen: .right)
                ControlButton(title: "YouTube", action: CartStates.YouTube, screen: .right)
            }
            VStack(spacing: 20) {
                Text("Sign")
                    .font(.system(size: 40, weight: .medium, design: .default))
                    .padding(.bottom)
                ControlButton(title: "Screensaver", action: SignStates.Screensaver, screen: .sign)
                ControlButton(title: "Match Board", action: SignStates.MatchBoard, screen: .sign)
            }
            VStack(spacing: 20) {
                Text("Controller")
                    .font(.system(size: 40, weight: .medium, design: .default))
                    .padding(.bottom)
                ControlButton(title: "Screensaver", action: ControllerSleepStates.Screensaver, screen: .controller)
                ControlButton(title: "Match Board", action: ControllerSleepStates.MatchBoard, screen: .controller)
            }
        }
    }
}

#Preview {
    Control()
}
