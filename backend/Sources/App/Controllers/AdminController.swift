//
//  AdminController.swift
//
//
//  Created by Simon Bestler on 14.04.24.
//

import Foundation
import Vapor
import Fluent

struct AdminController: RouteCollection {

    func boot(routes: any Vapor.RoutesBuilder) throws {
        let admin = routes.grouped("admin")
        admin.get(use: index)
        admin.post("newStanding", use: saveCurrentStanding)
    }

    @Sendable
    func index(req: Request) async throws -> View {
        let matches = try await Match.query(on: req.db).sort(\.$game_starts_at).all()

        return try await req.view.render("admin", ["matches": matches])
    }

    @Sendable
    func saveCurrentStanding(req: Request) async throws -> View {
        let standing = try req.content.decode(Standing.self)
        try await Match.query(on: req.db)
            .set(\.$team_home_goals, to: standing.team_home_goals)
            .set(\.$team_away_goals, to: standing.team_away_goals)
            .filter(\.$id == standing.id!)
            .update()
        return try await index(req: req)
    }

}

struct Standing: Content {
    var id: UUID?
    var team_home_goals: Int
    var team_away_goals: Int
}
