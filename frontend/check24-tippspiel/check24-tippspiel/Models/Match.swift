//
//  Match.swift
//  check24-tippspiel
//
//  Created by Simon Bestler on 14.04.24.
//

import Foundation

struct Match: Codable {

    let id: UUID
    let team_home_name: String
    let team_away_name: String
    let game_starts_at: Date
    let team_home_goals: Int?
    let team_away_goals: Int?

}
