//
//  Model.swift
//
//
//  Created by Simon Bestler on 13.04.24.
//

import Foundation
import Fluent
import Vapor

final class User: Model, Content {

    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "created_at")
    var created_at: Date?

    @Children(for: \.$user)
    var bets: [Bet]

    @Siblings(through: User_Community.self, from: \.$user, to: \.$community)
    var communities: [Community]

    init() {}


    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }


}
