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
//            matchPackage(matchId: "Q24", red: ["1", "12", "123"], blue: ["9679", "12", "1"], time: 1754174298, win: "true", rp: 5),
//            matchPackage(matchId: "Q25", red: ["1", "12", "123"], blue: ["9679", "12", "1"], time: 1754174298, win: "true", rp: 5),
//            matchPackage(matchId: "Q26", red: ["1", "12", "123"], blue: ["9679", "12", "1"], time: 1754174298, win: "true", rp: 5),
//            matchPackage(matchId: "Q27", red: ["1", "12", "123"], blue: ["9679", "12", "1"], time: 1754174298, win: "true", rp: 5),
//            matchPackage(matchId: "Q28", red: ["1", "12", "123"], blue: ["9679", "12", "1"], time: 1754174298, win: "true", rp: 5),
//            matchPackage(matchId: "Q29", red: ["1", "12", "123"], blue: ["9679", "12", "1"], time: 1754174298, win: "true", rp: 5),
//            matchPackage(matchId: "Q30", red: ["1", "12", "123"], blue: ["9679", "12", "1"], time: 1754174298, win: "true", rp: 5),
//            matchPackage(matchId: "Q31", red: ["1", "12", "123"], blue: ["9679", "12", "1"], time: 1754174298, win: "true", rp: 5),
//            matchPackage(matchId: "Q32", red: ["1", "12", "123"], blue: ["9679", "12", "1"], time: 1754174298, win: "true", rp: 5),
//            matchPackage(matchId: "Q33", red: ["1", "12", "123"], blue: ["9679", "12", "1"], time: 1754174298, win: "true", rp: 5),
//            matchPackage(matchId: "Q34", red: ["1", "12", "123"], blue: ["9679", "12", "1"], time: 1754174298, win: "true", rp: 5),
//            matchPackage(matchId: "Q35", red: ["1", "12", "123"], blue: ["9679", "12", "1"], time: 1754174298, win: "true", rp: 5),
//            matchPackage(matchId: "Q36", red: ["1", "12", "123"], blue: ["9679", "12", "1"], time: 1754174298, win: "true", rp: 5),
//        ]
//    }
}
