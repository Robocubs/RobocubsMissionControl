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
    var isPaused = false
    
    init(timeout: TimeInterval = 15) {
        self.timeout = timeout
        startTimer()
    }
    
    func userInteracted() {
        guard !isPaused else { return }
        startTimer()
        showOverlay = false
    }
    
    func pause() {
        isPaused = true
        cancellable?.cancel()
    }
    
    func resume() {
        isPaused = false
        startTimer()
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
    
    @State private var blackOpacity: Double = 0
    @State private var showingOverlay: Bool = false
    @State private var isFading: Bool = false
    @State private var transitionTask: Task<Void, Never>? = nil

    var body: some View {
        ZStack {
            if showingOverlay {
                Group {
                    switch state.controllerSleep {
                    case .MatchBoard:
                        MatchBoard(buttonInteraction: overlayManager.userInteracted)
                    case .Screensaver:
                        Screensaver(buttonInteraction: overlayManager.userInteracted)
                    }
                }
            } else {
                Control(
                    onPopoverOpen: overlayManager.pause,
                    onPopoverClose: overlayManager.resume
                )
            }

            // Black fade layer
            Color.black
                .opacity(blackOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // Full-screen tap interceptor — active for the entire duration of any transition.
            // Tapping during an outgoing fade cancels it and snaps back.
            if isFading {
                Color.clear
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        overlayManager.userInteracted()
                    }
            }
        }
        .statusBar(hidden: true)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            if !socket.isConnected {
                socket.connect()
            }
        }
        .onChange(of: overlayManager.showOverlay) { _, show in
            transitionTask?.cancel()
            if show {
                transitionTask = Task {
                    isFading = true
                    // Fade out control
                    withAnimation(.easeInOut(duration: 0.6)) { blackOpacity = 1 }
                    try? await Task.sleep(for: .seconds(0.65))
                    guard !Task.isCancelled else {
                        // User tapped — snap back
                        withAnimation(.easeInOut(duration: 0.3)) { blackOpacity = 0 }
                        isFading = false
                        return
                    }
                    showingOverlay = true
                    // Fade in overlay
                    withAnimation(.easeInOut(duration: 0.6)) { blackOpacity = 0 }
                    try? await Task.sleep(for: .seconds(0.65))
                    isFading = false
                }
            } else {
                transitionTask = Task {
                    isFading = true
                    // Fade out overlay
                    withAnimation(.easeInOut(duration: 0.2)) { blackOpacity = 1 }
                    try? await Task.sleep(for: .seconds(0.25))
                    guard !Task.isCancelled else {
                        withAnimation(.easeInOut(duration: 0.2)) { blackOpacity = 0 }
                        isFading = false
                        return
                    }
                    showingOverlay = false
                    // Fade in control
                    withAnimation(.easeInOut(duration: 0.2)) { blackOpacity = 0 }
                    try? await Task.sleep(for: .seconds(0.25))
                    isFading = false
                }
            }
        }
    }
}

#Preview(traits: .landscapeLeft) {
    ViewController()
}
