//
//  StateStructures.swift
//  RobocubsMissionControl
//
//  Created by Quincy D on 8/18/25.
//

import Foundation
import Combine

protocol DisplayState: CustomStringConvertible, Equatable {}

public enum CartStates: String, DisplayState {
    case Sponsors = "sponsors"
    case YouTube = "youtube"
    case Twitch = "twitch"
    case Screensaver = "screensaver"
    
    public var description: String {
        switch self {
        case .Sponsors: return "sponsors"
        case .YouTube: return "youtube"
        case .Twitch: return "twitch"
        case .Screensaver: return "screensaver"
        }
    }
}

public enum SignStates: String, DisplayState, Decodable, Encodable {
    case MatchBoard = "matchboard"
    case Screensaver = "screensaver"
    
    public var description: String {
        switch self {
        case .MatchBoard: return "matchboard"
        case .Screensaver: return "screensaver"
        }
    }
}

public enum ControllerSleepStates: String, DisplayState {
    case MatchBoard = "matchboard"
    case Screensaver = "screensaver"
    
    public var description: String {
        switch self {
        case .MatchBoard: return "matchboard"
        case .Screensaver: return "screensaver"
        }
    }
}
