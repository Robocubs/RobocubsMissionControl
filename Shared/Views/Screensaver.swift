//
//  Screensaver.swift
//  PitMissionController
//
//  Created by Quincy D on 8/18/25.
//

import SwiftUI

struct Screensaver: View {
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            Image(.screensaver)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
    }
}

#Preview {
    Screensaver()
}
