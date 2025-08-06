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
}

//public let matches: [matchPackage] = [
//    matchPackage(matchId: "Q23", red: [1234, 5678, 9012], blue: [1234, 1701, 9012], time: 1754174298, win: true, rp: 5),
//    matchPackage(matchId: "Q45", red: [1701, 5678, 9012], blue: [1234, 5678, 9012], time: 1754174298, win: false, rp: 2),
//    matchPackage(matchId: "Q73", red: [1234, 5678, 9012], blue: [1234, 5678, 1701], time: 1754174298),
//    matchPackage(matchId: "Q21", red: [1234, 5678, 9012], blue: [1234, 1701, 9012], time: 1754174298, win: true, rp: 5),
//    matchPackage(matchId: "Q42", red: [1701, 5678, 9012], blue: [1234, 5678, 9012], time: 1754174298, win: false, rp: 2),
//    matchPackage(matchId: "Q74", red: [1234, 5678, 9012], blue: [1234, 5678, 1701], time: 1754174298),
//    matchPackage(matchId: "Q37", red: [1234, 5678, 9012], blue: [1234, 1701, 9012], time: 1754174298, win: true, rp: 5),
//    matchPackage(matchId: "Q98", red: [1701, 5678, 9012], blue: [1234, 5678, 9012], time: 1754174298, win: false, rp: 2),
//    matchPackage(matchId: "Q53", red: [1234, 5678, 9012], blue: [1234, 5678, 1701], time: 1754174298),
//    matchPackage(matchId: "Q12", red: [1234, 5678, 9012], blue: [1234, 1701, 9012], time: 1754174298, win: true, rp: 5),
//    matchPackage(matchId: "Q5", red: [1701, 5678, 9012], blue: [1234, 5678, 9012], time: 1754174298, win: false, rp: 2),
//    matchPackage(matchId: "Q78", red: [1234, 5678, 9012], blue: [1234, 5678, 1701], time: 1754174298),
//]
