//
//  StateStructures.swift
//  PitMissionController
//
//  Created by Quincy D on 8/9/25.
//

import Foundation
import Combine

public class SharedStates: ObservableObject {
    @Published var stateL: CartStates = .Screensaver
    @Published var stateR: CartStates = .Screensaver
    @Published var sign: SignStates = .Screensaver
    @Published var controllerSleep: ControllerSleepStates = .Screensaver
}

public let sharedStates = SharedStates()

/// In-memory cache for the last submitted value of each popover field, keyed by messageType.
/// Also updated when the server sends back a cached value on connect.
public class PopoverCache: ObservableObject {
    public static let shared = PopoverCache()
    @Published public var values: [String: String] = [:]

    public func set(_ value: String, for key: String) {
        values[key] = value
    }

    public func get(_ key: String) -> String {
        values[key] ?? ""
    }
}
