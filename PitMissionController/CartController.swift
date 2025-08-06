//
//  CartController.swift
//  PitMissionController
//
//  Created by Quincy D on 8/2/25.
//

import SwiftUI

struct CartController: View {
    private let matchesArray: [matchPackage] = [
        matchPackage(matchId: "Q23", red: [1234, 5678, 9012], blue: [1234, 1701, 9012], time: 1754174298, win: true, rp: 5),
        matchPackage(matchId: "Q45", red: [1701, 5678, 9012], blue: [1234, 5678, 9012], time: 1754174298, win: false, rp: 2),
        matchPackage(matchId: "Q73", red: [1234, 5678, 9012], blue: [1234, 5678, 1701], time: 1754174298),
        matchPackage(matchId: "Q21", red: [1234, 5678, 9012], blue: [1234, 1701, 9012], time: 1754174298, win: true, rp: 5),
        matchPackage(matchId: "Q42", red: [1701, 5678, 9012], blue: [1234, 5678, 9012], time: 1754174298, win: false, rp: 2),
        matchPackage(matchId: "Q74", red: [1234, 5678, 9012], blue: [1234, 5678, 1701], time: 1754174298),
        matchPackage(matchId: "Q37", red: [1234, 5678, 9012], blue: [1234, 1701, 9012], time: 1754174298, win: true, rp: 5),
        matchPackage(matchId: "Q98", red: [1701, 5678, 9012], blue: [1234, 5678, 9012], time: 1754174298, win: false, rp: 2),
        matchPackage(matchId: "Q53", red: [1234, 5678, 9012], blue: [1234, 5678, 1701], time: 1754174298),
        matchPackage(matchId: "Q12", red: [1234, 5678, 9012], blue: [1234, 1701, 9012], time: 1754174298, win: true, rp: 5),
        matchPackage(matchId: "Q5", red: [1701, 5678, 9012], blue: [1234, 5678, 9012], time: 1754174298, win: false, rp: 2),
        matchPackage(matchId: "Q78", red: [1234, 5678, 9012], blue: [1234, 5678, 1701], time: 1754174298),
    ]
    
    init() {
        _ = BluetoothCentralManager.shared
    }

    
    enum CartState {
        case Sponsors
        case Stream
    }
    
    @State private var currentState: CartState = .Sponsors
    
    var body: some View {
        Button(action: {
            currentState = .Sponsors
            socket.sendMessage(type: "state", data: "sponsors".data(using: .utf8)!)
        }) {
            Text("Sponsors")
                .font(.title2)
                .foregroundColor(.white)
                .bold()
                .frame(width: 300, height: 100)
        }
        .background(currentState == .Sponsors ? Color.blue : Color.gray)
        .cornerRadius(50)
        
        Color.clear.frame(height: 30)
        
        Button(action: {
            currentState = .Stream
            socket.sendMessage(type: "state", data: "currentMatch".data(using: .utf8)!)
        }) {
            Text("Current Match")
                .font(.title2)
                .foregroundColor(.white)
                .bold()
                .frame(width: 300, height: 100)
        }
        .background(currentState == .Stream ? Color.blue : Color.gray)
        .cornerRadius(50)
        
        Button(action: {
            guard let data = BluetoothCentralManager.shared.prepareData(type: "matchPackage", data: matchesArray) else {
                print("Failed to prepare data")
                return
            }
            BluetoothCentralManager.shared.sendData(data)
        }) {
            Text("Send Test")
                .font(.title2)
                .foregroundColor(.white)
                .bold()
                .frame(width: 300, height: 100)
        }
        .background(Color.yellow)
        .cornerRadius(50)
    }
}

#Preview {
    CartController()
}
