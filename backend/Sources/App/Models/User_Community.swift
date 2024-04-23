//
//  CommunityUser.swift
//
//
//  Created by Simon Bestler on 22.04.24.
//

import Foundation
import Vapor
import Fluent

final class User_Community: Model, Content {
    

    static let schema = "user_community"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "user_id")
    var user: User

    @Parent(key: "community_id")
    var community: Community




}
