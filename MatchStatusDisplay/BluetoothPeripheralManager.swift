//
//  BluetoothPeripheralManager.swift
//  MatchStatusDisplay
//
//  Created by Quincy D on 7/18/25.
//

import Foundation
import CoreBluetooth
import Combine

class BluetoothPeripheralManager: NSObject, ObservableObject {
    static let shared = BluetoothPeripheralManager()
    private var peripheralManager: CBPeripheralManager!
    private var transferCharacteristic: CBMutableCharacteristic!
    
    private let serviceUUID = CBUUID(string: "A12BBDA7-05D4-431B-B3B9-10846BA909FB")
    private let characteristicUUID = CBUUID(string: "3B06B2B0-DDAC-4A7F-AD9B-85C46CC32FCA")
    
    private var incomingBuffer = Data()
    
    override init() {
        super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
}

extension BluetoothPeripheralManager: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            print("Bluetooth Powered On")
            
            transferCharacteristic = CBMutableCharacteristic(
                type: characteristicUUID,
                properties: [.write, .notify],
                value: nil,
                permissions: [.writeable]
            )
            
            let service = CBMutableService(type: serviceUUID, primary: true)
            service.characteristics = [transferCharacteristic]
            
            peripheral.add(service)
            
            print("Starting Broadcast...")
            peripheralManager.startAdvertising([
                CBAdvertisementDataServiceUUIDsKey: [serviceUUID],
                CBAdvertisementDataLocalNameKey: "Match Status Display"
            ])
            
            print("Advertising service with UUID: \(serviceUUID)")
            return
        case .poweredOff:
            print("Bluetooth Powered Off")
            return
        case .resetting:
            print("Bluetooth Resetting")
            return
        case .unauthorized:
            print("Bluetooth Unauthorized")
            return
        case .unknown:
            print("Bluetooth Unknown")
            return
        case .unsupported:
            print("Bluetooth Unsupported")
            return
        @unknown default:
            print("Bluetooth Unknown")
            return
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error = error {
            print("Failed to Add Service: \(error)")
        } else {
            print("Service Added: \(service.uuid)")
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        // Reassemble message package
        for request in requests {
            if let data = request.value {
                incomingBuffer.append(data)
            }
            peripheralManager.respond(to: request, withResult: .success)
        }
        
        // Process all complete messages in the buffer
        while incomingBuffer.count >= 4 {
            let lengthData = incomingBuffer.prefix(4)
            let length = lengthData.withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
            if incomingBuffer.count >= 4 + Int(length) {
                let messageData = incomingBuffer.subdata(in: 4..<(4 + Int(length)))
                
                print("Received mainPayload: \(messageData)")
                
                routeRequest(messageData)
                
                incomingBuffer.removeSubrange(0..<(4 + Int(length)))
            } else {
                break // Not enough data yet
            }
        }
    }
    
    func sendNumber(_ number: Int) {
        guard let data = "\(number)".data(using: .utf8) else { return }

        let didSend = peripheralManager.updateValue(
            data,
            for: transferCharacteristic,
            onSubscribedCentrals: nil // nil = all subscribed centrals
        )

        if didSend {
            print("Peripheral sent: \(number)")
        } else {
            print("Peripheral failed to send (buffer full?)")
        }
    }
}

