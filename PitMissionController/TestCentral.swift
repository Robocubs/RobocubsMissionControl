//
//  TestCentral.swift
//  PitMissionController
//
//  Created by Quincy D on 7/18/25.
//

import SwiftUI

struct TestCentral: View {
    @StateObject private var CBManager = BluetoothCentralManager()
    
    @State private var numberInput = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Received Number:")
            Text(CBManager.receivedNum)
                .font(.largeTitle)
                .padding()

            TextField("Send Number", text: $numberInput)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button("Send") {
                if let number = Int(numberInput) {
                    CBManager.sendNumber(number)
                }
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }

    private func sendNumber() {
        guard let number = Int(numberInput) else { return }

        // This is where you define your sending logic
        let data = withUnsafeBytes(of: number.bigEndian, Array.init)

        // Example: Notify via peripheralManager (or use write if on central)
        // This is just placeholder — you'll need access to your Bluetooth manager somehow
        print("Would send number: \(number) as data: \(data)")
    }
}

#Preview {
    TestCentral()
}

