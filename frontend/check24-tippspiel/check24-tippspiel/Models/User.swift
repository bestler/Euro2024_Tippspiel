//
//  User.swift
//  check24-tippspiel
//
//  Created by Simon Bestler on 13.04.24.
//

import Foundation

struct User: Codable {

    let id: UUID?
    let name: String
    let created_at: Date?

    init(id: UUID?, name: String, created_at: Date?) {
        self.id = id
        self.name = name
        self.created_at = created_at
    }

    init(name: String) {
        self.name = name
        self.id = nil
        self.created_at = nil
    }

}
