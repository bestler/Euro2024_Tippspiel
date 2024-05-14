//
//  GlobalLeaderboardController.swift
//
//
//  Created by Simon Bestler on 23.04.24.
//

import Foundation
import Vapor
import Fluent


struct GlobalLeaderboardController: RouteCollection {

    func boot(routes: any RoutesBuilder) throws {
        
        let globalLeaderboardRoutes = routes.grouped("globalleaderboard")
        
        globalLeaderboardRoutes.get(use: getLeaderboard)
        globalLeaderboardRoutes.get(":user_id", use: getLeaderboardForUser)
        globalLeaderboardRoutes.get(":user_id", "refetch", use: refetchLeaderBoardForUser)
        globalLeaderboardRoutes.get("search", ":user_name", use: searchForUser)
    }


    @Sendable
    func getLeaderboard(req: Request) async throws -> [LeaderBoardEntry] {

        return try await LeaderBoardEntry.query(on: req.db).all()
    }


    @Sendable
    func getLeaderboardForUser(req: Request) async throws -> [LeaderBoardEntry] {

        guard let userId = UUID(uuidString: req.parameters.get("user_id")!) else { throw Abort(.notFound) }
        let entries = try await LeaderBoardEntry.getGlobalLeaderboardForUser(id: userId, db: req.db)
        return entries

    }

    @Sendable
    func refetchLeaderBoardForUser(req: Request) async throws -> [LeaderBoardEntry] {

        guard let userId = UUID(uuidString: req.parameters.get("user_id")!) else { throw Abort(.notFound) }
        var refetchParams = RefetchLeaderBoardDTO()

        do {
            refetchParams = try req.query.decode(RefetchLeaderBoardDTO.self)
        } catch {
            throw Abort(.badRequest)
        }

        let entries = try await LeaderBoardEntry.refetchGlobalLeaderboardForUser(id: userId, refetchParams: refetchParams, db: req.db)
        return entries

    }


    @Sendable
    func searchForUser(req: Request) async throws -> [LeaderBoardEntry] {
        
        guard var username = req.parameters.get("user_name") else { throw Abort(.notFound) }
        username = username.lowercased()
        let entries = try await LeaderBoardEntry.query(on: req.db).filter(\.$name ~~ username).all()

        return entries

    }


}
