//
//  RequestRouter.swift
//  PitMissionController
//
//  Created by Quincy D on 8/4/25.
//

import Foundation

public func routeRequest(_ data: Data) {
    do {
        guard let jsonData = try? JSONSerialization.jsonObject(with: data, options: []),
              let dict = jsonData as? [String: Any],
              let type = dict["type"] as? String else {
            print("Failed to read type")
            return
        }
        
        switch type {
        case "matchPackage":
            BluetoothCentralManager.shared.sendData(data)
        case "confirm":
            let message = try JSONDecoder().decode(mainPayload<String>.self, from: data)
            print("Received text message: \(message.data)")
        default:
            print("Unknown type: \(type)")
        }
    } catch {
        print("Failed to decode JSON: \(error)")
    }
}
