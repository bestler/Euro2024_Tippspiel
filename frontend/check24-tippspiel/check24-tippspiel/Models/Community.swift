//
//  Community.swift
//  check24-tippspiel
//
//  Created by Simon Bestler on 22.04.24.
//

import Foundation

struct Community: Codable, Identifiable, Hashable {

    let id: UUID
    let created_at: Date
    let name: String
}
