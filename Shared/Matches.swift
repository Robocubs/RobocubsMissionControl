//
//  Matches.swift
//  MatchStatusDisplay
//
//  Created by Quincy D on 8/3/25.
//

import Foundation
import Combine

class MatchStore: ObservableObject {
    static let shared = MatchStore()
    @Published var matches: [matchPackage] = []
    
//    init() {
//        self.matches = [
//            matchPackage(matchId: "Q23", red: ["1", "12", "123"], blue: ["9679", "12", "1"], time: 1754174298, win: "true", rp: 5),
//        ]
//    }
}
