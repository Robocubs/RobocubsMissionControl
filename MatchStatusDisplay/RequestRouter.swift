//
//  RequestRouter.swift
//  MatchStatusDisplay
//
//  Created by Quincy D on 8/4/25.
//

import Foundation

public func routeRequest(_ messageData: Data) {
    do {
        guard let jsonData = try? JSONSerialization.jsonObject(with: messageData, options: []),
              let dict = jsonData as? [String: Any],
              let type = dict["type"] as? String else {
            print("Failed to read type")
            return
        }
        
        switch type {
        case "matchPackage":
            let result = try JSONDecoder().decode(mainPayload<[matchPackage]>.self, from: messageData)
            print("Decoded [MatchPackage]: \(result.data)")
            MatchStore.shared.matches = result.data
        case "stateSign":
            let result = try JSONDecoder().decode(mainPayload<SignStates>.self, from: messageData)
            print("Decoded [MatchPackage]: \(result.data)")
            sharedStates.sign = result.data
            
        default:
            print("Unknown type: \(type)")
        }
    } catch {
        print("Failed to decode JSON: \(error)")
    }
}
