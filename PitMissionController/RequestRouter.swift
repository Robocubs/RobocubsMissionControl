//
//  RequestRouter.swift
//  PitMissionController
//
//  Created by Quincy D on 8/4/25.
//

import Foundation

public func routeRequest(_ data: String) {
    do {
        print("Inital Route Request: \(data)")
        guard let jsonData = try? JSONSerialization.jsonObject(with: Data(data.utf8), options: []),
              let dict = jsonData as? [String: Any],
              let type = dict["type"] as? String else {
            print("Failed to read type")
            return
        }
        
        switch type {
        case "matchPackage":
            print("Switch Okay: \(data)")
            let result = try JSONDecoder().decode(mainPayload<[matchPackage]>.self, from: Data(data.utf8))
            MatchStore.shared.matches = result.data
            BluetoothCentralManager.shared.sendData(Data(data.utf8))
        case "confirm":
            let message = try JSONDecoder().decode(mainPayload<String>.self, from: Data(data.utf8))
            print("Received text message: \(message.data)")
        default:
            print("Unknown type: \(type)")
        }
    } catch {
        print("Failed to decode JSON: \(error)")
    }
}
