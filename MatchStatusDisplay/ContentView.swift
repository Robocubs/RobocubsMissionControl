//
//  ContentView.swift
//  MatchStatusDisplay
//
//  Created by Quincy D on 7/14/25.
//

import SwiftUI

struct ContentView: View {    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            Image(.iPadProScreensaver)
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
