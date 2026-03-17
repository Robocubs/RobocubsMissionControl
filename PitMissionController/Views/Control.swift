//
//  CartController.swift
//  PitMissionController
//
//  Created by Quincy D on 8/2/25.
//

import SwiftUI

struct Control: View {
    let buttonInteraction: (() -> Void)?
    let onPopoverOpen: (() -> Void)?
    let onPopoverClose: (() -> Void)?
    
    init(buttonInteraction: (() -> Void)? = nil, onPopoverOpen: (() -> Void)? = nil, onPopoverClose: (() -> Void)? = nil) {
        self.buttonInteraction = buttonInteraction
        self.onPopoverOpen = onPopoverOpen
        self.onPopoverClose = onPopoverClose
    }
    
    @State private var twitchLPopover = false
    @State private var twitchRPopover = false
    @State private var youtubeLPopover = false
    @State private var youtubeRPopover = false
    @State private var matchCodePopover = false

    var anyPopoverOpen: Bool {
        twitchLPopover || twitchRPopover || youtubeLPopover || youtubeRPopover || matchCodePopover
    }

    var body: some View {
        HStack(spacing: 80) {
            VStack(spacing: 20) {
                Text("Left")
                    .font(.system(size: 40, weight: .medium, design: .default))
                    .padding(.bottom)
                ControlButton(title: "Screensaver", action: CartStates.Screensaver, screen: .left, buttonInteraction: buttonInteraction)
                ControlButton(title: "Sponsors", action: CartStates.Sponsors, screen: .left, buttonInteraction: buttonInteraction)
                ControlButton(title: "Twitch", action: CartStates.Twitch, screen: .left, popoverControl: $twitchLPopover, buttonInteraction: buttonInteraction)
                ControlButton(title: "YouTube", action: CartStates.YouTube, screen: .left, popoverControl: $youtubeLPopover, buttonInteraction: buttonInteraction)
            }
            VStack(spacing: 20) {
                Text("Right")
                    .font(.system(size: 40, weight: .medium, design: .default))
                    .padding(.bottom)
                ControlButton(title: "Screensaver", action: CartStates.Screensaver, screen: .right, buttonInteraction: buttonInteraction)
                ControlButton(title: "Sponsors", action: CartStates.Sponsors, screen: .right, buttonInteraction: buttonInteraction)
                ControlButton(title: "Twitch", action: CartStates.Twitch, screen: .right, popoverControl: $twitchRPopover, buttonInteraction: buttonInteraction)
                ControlButton(title: "YouTube", action: CartStates.YouTube, screen: .right, popoverControl: $youtubeRPopover, buttonInteraction: buttonInteraction)
            }
            VStack(spacing: 20) {
                Text("Sign")
                    .font(.system(size: 40, weight: .medium, design: .default))
                    .padding(.bottom)
                ControlButton(title: "Screensaver", action: SignStates.Screensaver, screen: .sign, buttonInteraction: buttonInteraction)
                ControlButton(title: "Match Board", action: SignStates.MatchBoard, screen: .sign, popoverControl: $matchCodePopover, buttonInteraction: buttonInteraction)
            }
            VStack(spacing: 20) {
                Text("Controller")
                    .font(.system(size: 40, weight: .medium, design: .default))
                    .padding(.bottom)
                ControlButton(title: "Screensaver", action: ControllerSleepStates.Screensaver, screen: .controller, buttonInteraction: buttonInteraction)
                ControlButton(title: "Match Board", action: ControllerSleepStates.MatchBoard, screen: .controller, popoverControl: $matchCodePopover, buttonInteraction: buttonInteraction)
            }
        }
        .sheet(isPresented: $twitchLPopover) {
            TextFieldPopover(title: "Twitch Stream Link", messageType: "twitchLUpdate", isPresented: $twitchLPopover)
        }
        .sheet(isPresented: $twitchRPopover) {
            TextFieldPopover(title: "Twitch Stream Link", messageType: "twitchRUpdate", isPresented: $twitchRPopover)
        }
        .sheet(isPresented: $youtubeLPopover) {
            TextFieldPopover(title: "YouTube Video Link", messageType: "youtubeLUpdate", isPresented: $youtubeLPopover)
        }
        .sheet(isPresented: $youtubeRPopover) {
            TextFieldPopover(title: "YouTube Video Link", messageType: "youtubeRUpdate", isPresented: $youtubeRPopover)
        }
        .sheet(isPresented: $matchCodePopover) {
            TextFieldPopover(title: "Match Code", messageType: "matchCode", isPresented: $matchCodePopover)
        }
        .onChange(of: anyPopoverOpen) { _, isOpen in
            if isOpen {
                onPopoverOpen?()
            } else {
                onPopoverClose?()
            }
        }
    }
}

#Preview {
    Control()
}
