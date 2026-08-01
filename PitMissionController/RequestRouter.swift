//
//  RequestRouter.swift
//  PitMissionController
//
//  Created by Quincy D on 8/4/25.
//

import Foundation

// Message types sent at status-report frequency (2Hz per cart once a local
// video is playing). Excluded from the line-13 print below so the console
// doesn't flood the moment a video starts playing.
private let quietRouteTypes: Set<String> = ["localVideoLStatus", "localVideoRStatus"]

public func routeRequest(_ data: String) {
    do {
        guard let jsonData = try? JSONSerialization.jsonObject(with: Data(data.utf8), options: []),
              let dict = jsonData as? [String: Any],
              let type = dict["type"] as? String else {
            print("Failed to read type")
            return
        }

        if !quietRouteTypes.contains(type) {
            print("Inital Route Request: \(data)")
        }

        switch type {
        case "matchPackage":
            print("Switch Okay: \(data)")
            let result = try JSONDecoder().decode(mainPayload<[matchPackage]>.self, from: Data(data.utf8))
            DispatchQueue.main.async {
                MatchStore.shared.matches = result.data
            }
            BluetoothCentralManager.shared.sendData(Data(data.utf8))
        case "confirm":
            let message = try JSONDecoder().decode(mainPayload<String>.self, from: Data(data.utf8))
            print("Received text message: \(message.data)")
        case "twitchLUpdate", "twitchRUpdate", "youtubeLUpdate", "youtubeRUpdate",
             "matchBoard", "matchCode", "localVideoLUpdate", "localVideoRUpdate":
            let message = try JSONDecoder().decode(mainPayload<String>.self, from: Data(data.utf8))
            DispatchQueue.main.async {
                PopoverCache.shared.set(message.data, for: message.type)
                if message.type == "localVideoLUpdate" {
                    mediaStore.selectedL = message.data.isEmpty ? nil : message.data
                } else if message.type == "localVideoRUpdate" {
                    mediaStore.selectedR = message.data.isEmpty ? nil : message.data
                }
            }
        case "localVideoLibrary":
            let message = try JSONDecoder().decode(mainPayload<[MediaItem]>.self, from: Data(data.utf8))
            DispatchQueue.main.async {
                mediaStore.library = message.data
            }
        case "localVideoLStatus":
            let message = try JSONDecoder().decode(mainPayload<PlaybackStatus>.self, from: Data(data.utf8))
            DispatchQueue.main.async {
                mediaStore.statusL = message.data
            }
        case "localVideoRStatus":
            let message = try JSONDecoder().decode(mainPayload<PlaybackStatus>.self, from: Data(data.utf8))
            DispatchQueue.main.async {
                mediaStore.statusR = message.data
            }
        default:
            print("Unknown type: \(type)")
        }
    } catch {
        print("Failed to decode JSON: \(error)")
    }
}
