//
//  MessageStructures.swift
//  MatchStatusDisplay
//
//  Created by Quincy D on 8/3/25.
//

import Foundation

public struct mainPayload<T: Codable>: Codable {
    public let type: String
    public let data: T
}

public struct matchPackage: Codable, Identifiable {
    public let matchId: String
    public let red: Array<String>
    public let blue: Array<String>
    public let time: Double
    public var win: String?
    public var rp: Int?
    public var id: String { matchId }
}

public struct matchUpdate: Codable {
    public let matchId: String
    public let red: Array<Int>
    public let rp: Int?
}
