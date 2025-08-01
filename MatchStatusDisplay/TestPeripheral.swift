//
//  TestPeripheral.swift
//  MatchStatusDisplay
//
//  Created by Quincy D on 7/18/25.
//

import SwiftUI

struct TestPeripheral: View {
    @StateObject private var CBPeripheral = BluetoothPeripheralManager()
    
    @State private var numberInput = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Received Number:")
            Text(CBPeripheral.recievedNum)
                .font(.largeTitle)
                .padding()
            
            TextField("Send Number", text: $numberInput)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button("Send") {
                if let number = Int(numberInput) {
                    CBPeripheral.sendNumber(number)
                }
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
}

#Preview {
    TestPeripheral()
}
