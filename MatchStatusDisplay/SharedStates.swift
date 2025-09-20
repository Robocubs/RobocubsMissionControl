//
//  StateStructures.swift
//  MatchStatusDisplay
//
//  Created by Quincy D on 8/18/25.
//

import Foundation
import Combine

public class SharedStates: ObservableObject {
    @Published var sign: SignStates = .Screensaver
}

public let sharedStates = SharedStates()
