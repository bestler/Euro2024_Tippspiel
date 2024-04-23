//
//  Community.swift
//  
//
//  Created by Simon Bestler on 22.04.24.
//

import Foundation
import Fluent
import Vapor

final class Community: Model, Content {

    static let schema = "communities"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "created_at")
    var created_at: Date?

    @Siblings(through: User_Community.self, from: \.$community, to: \.$user)
    var users: [User]

}
