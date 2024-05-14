//
//  CommunityController.swift
//
//
//  Created by Simon Bestler on 22.04.24.
//

import Foundation
import Vapor
import Fluent
import FluentPostgresDriver

struct CommunityController: RouteCollection {

    func boot(routes: any RoutesBuilder) throws {
        let community_routes = routes.grouped("communities")

        community_routes.get(use: getAll)
        community_routes.post("create", use: create)
        community_routes.get(":community_id", "leaderboard", ":user_id", use: getLeaderboard)
        community_routes.get(":community_id", "refetchLeaderboard", ":user_id", use: refetchLeaderboard)
    }


    @Sendable
    func getAll(req: Request) async throws -> [Community] {
        return try await Community.query(on: req.db).all()
    }


    @Sendable
    func create(req: Request) async throws -> Community {
        let community = try req.content.decode(Community.self)

        community.created_at = Date()

        try await community.create(on: req.db)
        return community
	
    }

    @Sendable
    func getLeaderboard(req: Request) async throws -> [LeaderBoardEntry] {

        guard let userId = UUID(uuidString: req.parameters.get("user_id")!) else { throw Abort(.notFound) }
        guard let communityId = UUID(uuidString: req.parameters.get("community_id")!) else { throw Abort(.notFound) }

        let result = try await LeaderBoardEntry.getCommunityLeaderBoardForUser(userId: userId, communityId: communityId, db: req.db)
        return result
    }

    @Sendable
    func refetchLeaderboard(req: Request) async throws -> [LeaderBoardEntry] {

        guard let userId = UUID(uuidString: req.parameters.get("user_id")!) else { throw Abort(.notFound) }
        guard let communityId = UUID(uuidString: req.parameters.get("community_id")!) else { throw Abort(.notFound) }

        var refetchParams = RefetchLeaderBoardDTO()

        do {
            refetchParams = try req.query.decode(RefetchLeaderBoardDTO.self)
        } catch {
            throw Abort(.badRequest)
        }

        let result = try await LeaderBoardEntry.refetchCommunityLeaderboardForUser(userId: userId, communityId: communityId, refetchParams: refetchParams, db: req.db)

        return result

    }


}
