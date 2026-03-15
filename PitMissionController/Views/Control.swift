//
//  CartController.swift
//  PitMissionController
//
//  Created by Quincy D on 8/2/25.
//

import SwiftUI

struct Control: View {
    let buttonInteraction: (() -> Void)?
    
    init(buttonInteraction: (() -> Void)? = nil) {
        _ = BluetoothCentralManager.shared
        _ = socket
        self.buttonInteraction = buttonInteraction
    }
    
    @State private var showNewListPopover = false
    
    var body: some View {
        HStack(spacing: 80) {
            VStack(spacing: 20) {
                Text("Left")
                    .font(.system(size: 40, weight: .medium, design: .default))
                    .padding(.bottom)
                ControlButton(title: "Screensaver", action: CartStates.Screensaver, screen: .left, buttonInteraction: buttonInteraction)
                ControlButton(title: "Sponsors", action: CartStates.Sponsors, screen: .left, buttonInteraction: buttonInteraction)
                ControlButton(title: "Twitch", action: CartStates.Twitch, screen: .left, buttonInteraction: buttonInteraction)
                ControlButton(title: "YouTube", action: CartStates.YouTube, screen: .left, buttonInteraction: buttonInteraction)
            }
            VStack(spacing: 20) {
                Text("Right")
                    .font(.system(size: 40, weight: .medium, design: .default))
                    .padding(.bottom)
                ControlButton(title: "Screensaver", action: CartStates.Screensaver, screen: .right, buttonInteraction: buttonInteraction)
                ControlButton(title: "Sponsors", action: CartStates.Sponsors, screen: .right, buttonInteraction: buttonInteraction)
                ControlButton(title: "Twitch", action: CartStates.Twitch, screen: .right, buttonInteraction: buttonInteraction)
                ControlButton(title: "YouTube", action: CartStates.YouTube, screen: .right, buttonInteraction: buttonInteraction)
            }
            VStack(spacing: 20) {
                Text("Sign")
                    .font(.system(size: 40, weight: .medium, design: .default))
                    .padding(.bottom)
                ControlButton(title: "Screensaver", action: SignStates.Screensaver, screen: .sign, buttonInteraction: buttonInteraction)
                ControlButton(title: "Match Board", action: SignStates.MatchBoard, screen: .sign, buttonInteraction: buttonInteraction)
            }
            VStack(spacing: 20) {
                Text("Controller")
                    .font(.system(size: 40, weight: .medium, design: .default))
                    .padding(.bottom)
                ControlButton(title: "Screensaver", action: ControllerSleepStates.Screensaver, screen: .controller, buttonInteraction: buttonInteraction)
                ControlButton(title: "Match Board", action: ControllerSleepStates.MatchBoard, screen: .controller, popoverControl: $showNewListPopover, buttonInteraction: buttonInteraction)
            }
        }
        .sheet(isPresented: $showNewListPopover) {
            TextFieldPopover(isPresented: $showNewListPopover)
        }
    }
}

#Preview {
    Control()
}
