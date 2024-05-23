//
//  LeaderBoardEntry.swift
//  check24-tippspiel
//
//  Created by Simon Bestler on 23.04.24.
//

import Foundation

struct LeaderboardEntry: Identifiable, Codable {

    let id: UUID
    let rank: Int
    let name: String
    let points: Int
    let row: Int
    let isfriend: Bool?
}


