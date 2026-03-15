//
//  ViewController.swift
//  PitMissionController
//
//  Created by Quincy D on 7/14/25.
//

import SwiftUI
import Combine

class TimeoutManager: ObservableObject {
    @Published var showOverlay = false
    private var cancellable: AnyCancellable?
    private let timeout: TimeInterval
    
    init(timeout: TimeInterval = 10) {
        self.timeout = timeout
        startTimer()
    }
    
    func userInteracted() {
        startTimer()
        showOverlay = false
    }
    
    private func startTimer() {
        cancellable?.cancel()
        cancellable = Just(())
            .delay(for: .seconds(timeout), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                withAnimation {
                    self?.showOverlay = true
                }
            }
    }
}

struct ViewController: View {
    @StateObject private var overlayManager = TimeoutManager(timeout: 5)
    
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedObject var state = sharedStates
    
    var body: some View {
        ZStack {
            Control()
                .opacity(overlayManager.showOverlay ? 0 : 1)
                .animation(.easeIn(duration: overlayManager.showOverlay ? 1.5 : 0.2).delay(overlayManager.showOverlay ? 0 : 0.1), value: overlayManager.showOverlay)
            
            Group {
                switch state.controllerSleep {
                case .MatchBoard:
                    MatchBoard(buttonInteraction: overlayManager.userInteracted
                    )
                case .Screensaver:
                    Screensaver(buttonInteraction: overlayManager.userInteracted)
                }
            }
                .opacity(overlayManager.showOverlay ? 1 : 0)
                .animation(.easeIn(duration: overlayManager.showOverlay ? 1.5 : 0.2).delay(overlayManager.showOverlay ? 1.1 : 0), value: overlayManager.showOverlay)
        }
        .statusBar(hidden: true)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            if !socket.isConnected {
                socket.connect()
            }
        }
    }
}

#Preview(traits: .landscapeLeft) {
    ViewController()
}
