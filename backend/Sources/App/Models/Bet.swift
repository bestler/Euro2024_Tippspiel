//
//  Bet.swift
//  
//
//  Created by Simon Bestler on 14.04.24.
//

import Foundation
import Fluent
import Vapor

final class Bet: Model, Content{

    static let schema = "Bets"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "user_id")
    var user: User

    @Parent(key: "match_id")
    var match: Match

    @Field(key: "goals_home")
    var goals_home: Int?

    @Field(key: "goals_away")
    var goals_away: Int?

    @Field(key: "created_at")
    var created_at: Date

    @Field(key: "modified_at")
    var modified_at: Date?

    @Field(key: "points")
    var points: Int

}
