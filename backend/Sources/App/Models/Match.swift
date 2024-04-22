//
//  File.swift
//  
//
//  Created by Simon Bestler on 14.04.24.
//

import Foundation
import Fluent
import Vapor

final class Match: Model, Content {

    static let schema = "matches"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "team_home_name")
    var team_home_name: String

    @Field(key: "team_away_name")
    var team_away_name: String

    @Field(key: "game_starts_at")
    var game_starts_at: Date

    @Field(key: "team_home_goals")
    var team_home_goals: Int?

    @Field(key: "team_away_goals")
    var team_away_goals: Int?

    @Children(for: \.$match)
    var bets: [Bet]

    var dateHumanReadable: String {
        return game_starts_at.formatted()
    }

}
