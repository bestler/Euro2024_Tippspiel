//
//  User_Friend.swift
//
//
//  Created by Simon Bestler on 02.05.24.
//

import Foundation
import Vapor
import Fluent

final class User_Friend: Model, Content {

    static let schema = "friends"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "user_id")
    var user: User

    @Parent(key: "friend_id")
    var friend: User

}
