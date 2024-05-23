//
//  AdminController.swift
//
//
//  Created by Simon Bestler on 14.04.24.
//

import Foundation
import Vapor
import Fluent
import FluentPostgresDriver

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
        if let match_id = standing.id {
            try await updatePoints(match_id: match_id, db: req.db)
        }

        return try await index(req: req)
    }

    private func updatePoints(match_id: UUID, db: Database) async throws {
        if let postgres = db as? PostgresDatabase {
            _ = try await postgres.simpleQuery("CALL updatepointsbets('\(match_id.uuidString)')").get()
            try await Utilities.refreshMaterialiedView(viewName: "leaderboard", db: postgres as! SQLDatabase)
            try await Utilities.refreshMaterialiedView(viewName: "community_view", db: postgres as! SQLDatabase)
        }
    }

}

struct Standing: Content {
    var id: UUID?
    var team_home_goals: Int
    var team_away_goals: Int
}
