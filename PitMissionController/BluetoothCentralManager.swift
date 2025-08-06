//
//  BluetoothCentralManager.swift
//  PitMissionController
//
//  Created by Quincy D on 7/18/25.
//

import Foundation
import CoreBluetooth
import Combine

class BluetoothCentralManager: NSObject, ObservableObject {
    static let shared = BluetoothCentralManager()
    private var centralManager: CBCentralManager!
    private var discoveredPeripheral: CBPeripheral?
    private var writableCharacteristic: CBCharacteristic?
    
    private let serviceUUID = CBUUID(string: "A12BBDA7-05D4-431B-B3B9-10846BA909FB")
    
    @Published var receivedNum: String = ""
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
}

extension BluetoothCentralManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Bluetooth Powered On")
            print("Scanning for Peripherals...")
            if !centralManager.isScanning {
                centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
            }
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
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        print("Discovered peripheral: \(peripheral.name ?? "Unknown")")
        
        centralManager.stopScan()
        discoveredPeripheral = peripheral
        discoveredPeripheral?.delegate = self
        centralManager.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.name ?? "Unknown")")
        peripheral.discoverServices([serviceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from peripheral: \(peripheral.name ?? "Unknown")")
            
        discoveredPeripheral = nil
        
        print("Resuming scan...")
        if !centralManager.isScanning {
            centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
        }
    }
    
    
//    func startConnectionMonitor() {
//        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
//            if self.discoveredPeripheral?.state != .connected {
//                print("Connection lost or not established — restarting scan.")
//                self.discoveredPeripheral = nil
//                self.centralManager.scanForPeripherals(withServices: [self.serviceUUID], options: nil)
//            } else {
//                self.startConnectionMonitor()
//            }
//        }
//    }
}

extension BluetoothCentralManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                print("Discovered service: \(service.uuid)")
                // Discover characteristics for the service
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                print("Discovered characteristic: \(characteristic.uuid)")
                if characteristic.properties.contains(.write) {
                    writableCharacteristic = characteristic
                }
                
                if characteristic.properties.contains(.notify) {
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            }
        }
    }
    
    
    func prepareData<T: Codable>(type: String, data: T) -> Data? {
        let payload = mainPayload(type: type, data: data)

        guard let encodedPayload = try? JSONEncoder().encode(payload) else {
            print("Failed to encode payload")
            return nil
        }

        return encodedPayload
    }

    
    func sendData(_ data: Data) {
        guard let peripheral = discoveredPeripheral,
              let characteristic = writableCharacteristic else {
            print("Peripheral or characteristic not ready")
            return
        }
        
        // Prefix the data with 4-byte length of package
        var length = UInt32(data.count).bigEndian
        let lengthData = Data(bytes: &length, count: 4)
        let fullData = lengthData + data

        let mtu = 20 // Max BLE payload size
        var offset = 0
        
        // Send data in packets
        while offset < fullData.count {
            let chunkSize = min(mtu, fullData.count - offset)
            let chunk = fullData.subdata(in: offset..<(offset + chunkSize))
            peripheral.writeValue(chunk, for: characteristic, type: .withResponse)
            print("Central sent chunk: \(chunk as NSData)")
            offset += chunkSize
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let data = characteristic.value {
            receivedNum = String(data: data, encoding: .utf8) ?? "Error"
            print("Received updated value: \(data)")
        }
    }
}
