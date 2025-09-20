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
