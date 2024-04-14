//
//  Bets.swift
//  
//
//  Created by Simon Bestler on 14.04.24.
//

import Foundation
import Fluent
import Vapor

final class Bets: Model, Content {

    static let schema = "Bets"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "user_id")
    var user: User

}
