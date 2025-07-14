//
//  ContentView.swift
//  PitMissionController
//
//  Created by Quincy D on 7/14/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            Image(.iPadAirScreensaver)
                .resizable()
                .scaledToFit()
                .ignoresSafeArea()
        }
        .statusBar(hidden: true)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
        }
    }
}

#Preview(traits: .landscapeLeft) {
    ContentView()
}
