//
//  File.swift
//  
//
//  Created by Simon Bestler on 14.04.24.
//

import Foundation
import Vapor
import Fluent
import FluentPostgresDriver

struct UserController: RouteCollection {

    func boot(routes: any RoutesBuilder) throws {
        let user = routes.grouped("users")
        user.get(use: getAll)
        user.get(":id", use: getUser)
        user.get( "validate",":name", use: validate)
        user.get(":id", "bets", use: getBets)
        user.post(use: create)
    }

    @Sendable
    func getAll(req: Request) async throws -> [User] {
        return try await User.query(on: req.db).all()
    }

    @Sendable
    func getUser(req: Request) async throws -> User {


        guard let id = UUID(uuidString: req.parameters.get("id")!) else { throw Abort(.notFound) }
        let user = try await User.query(on: req.db).filter(\User.$id == id).first()

        if let user {
            return user
        } else {
            throw Abort(.notFound)
        }
    }

    @Sendable
    func validate(req: Request) async throws -> User {

        guard let name = req.parameters.get("name") else { throw Abort(.notFound) }
        let user = try await User.query(on: req.db).filter(\User.$name == name).first()

        if let user {
            return user
        } else {
            throw Abort(.notFound)
        }

    }

    @Sendable
    func getBets(req: Request) async throws -> [Bet] {

        guard let id = UUID(uuidString: req.parameters.get("id")!) else { throw Abort(.notFound) }
        guard let user = try await User.query(on: req.db).filter(\User.$id == id).first() else { throw Abort(.notFound)}
        let bets = try await user.$bets.query(on: req.db)
            .with(\.$match)
            .join(Match.self, on: \Bet.$match.$id == \Match.$id)
            .sort(Match.self, \.$game_starts_at).all()
        return bets

    }

    @Sendable
    func create(req: Request) async throws -> User {
        let user = try req.content.decode(User.self)
        user.created_at = Date()
        try await user.create(on: req.db)
        try await createBetsForNewUser(userID: user.requireID(), db: req.db)
        return user
    }


    private func createBetsForNewUser(userID: UUID, db: Database) async throws {
        if let postgres = db as? PostgresDatabase {
            _ = try await postgres.simpleQuery("CALL createBetsForUser('\(userID.uuidString)')").get()
        }
    }



}
