//
//  ViewController.swift
//  MatchStatusDisplay
//
//  Created by Quincy D on 7/14/25.
//

import SwiftUI

struct ViewController: View {
    @ObservedObject var state = sharedStates
    
    init() {
        _ = BluetoothPeripheralManager.shared
    }
    
    var body: some View {
        Group {
            switch sharedStates.sign {
            case .MatchBoard:
                MatchBoard()
            case .Screensaver:
                Screensaver()
            }
        }
        .statusBar(hidden: true)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
        }
    }
}

#Preview(traits: .landscapeLeft) {
    ViewController()
}
