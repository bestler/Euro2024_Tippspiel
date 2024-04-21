//
//  Bet.swift
//  check24-tippspiel
//
//  Created by Simon Bestler on 14.04.24.
//

import Foundation

struct Bet: Codable, Identifiable {

    var id: UUID
    var match: Match
    var goals_home: Int?
    var goals_away: Int?
    var created_at: Date
    var modified_at: Date?
    var points: Int

    init(id: UUID, match: Match, goals_home: Int? = nil, goals_away: Int? = nil, created_at: Date, modified_at: Date? = nil, points: Int) {
        self.id = id
        self.match = match
        self.goals_home = goals_home
        self.goals_away = goals_away
        self.created_at = created_at
        self.modified_at = modified_at
        self.points = points
    }


}
