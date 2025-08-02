//
//  CartController.swift
//  PitMissionController
//
//  Created by Quincy D on 8/2/25.
//

import SwiftUI

struct CartController: View {
    enum CartState {
        case Sponsors
        case Stream
    }
    
    @State private var currentState: CartState = .Sponsors
    
    var body: some View {
        Button(action: {
            currentState = .Sponsors
            socket.sendMessage(type: "state", data: "sponsors")
        }) {
            Text("Sponsors")
                .font(.title2)
                .foregroundColor(.white)
                .bold()
                .frame(width: 200, height: 100)
        }
        .background(currentState == .Sponsors ? Color.blue : Color.gray)
        .cornerRadius(50)
        
        Color.clear.frame(height: 30)
        
        Button(action: {
            currentState = .Stream
            socket.sendMessage(type: "state", data: "stream")
        }) {
            Text("Stream")
                .font(.title2)
                .foregroundColor(.white)
                .bold()
                .frame(width: 200, height: 100)
        }
        .background(currentState == .Stream ? Color.blue : Color.gray)
        .cornerRadius(50)
    }
}

#Preview {
    CartController()
}
