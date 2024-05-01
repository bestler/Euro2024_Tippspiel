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
    func getLeaderboard(req: Request) async throws -> GlobalLeaderboardDTO {

        let totalCount = try await GlobalLeaderboardEntry.query(on: req.db).count()
        let entries = try await GlobalLeaderboardEntry.query(on: req.db).all()
        let leaderBoardDTO = GlobalLeaderboardDTO(items: entries, totalCount: totalCount)

        return leaderBoardDTO
    }


    @Sendable
    func getLeaderboardForUser(req: Request) async throws -> GlobalLeaderboardDTO {


        let totalCount = try await GlobalLeaderboardEntry.query(on: req.db).count()
        guard let userId = UUID(uuidString: req.parameters.get("user_id")!) else { throw Abort(.notFound) }
        let entries = try await GlobalLeaderboardEntry.getDefaultForUser(id: userId, db: req.db)
        let leaderBoardDTO = GlobalLeaderboardDTO(items: entries, totalCount: totalCount)

        return leaderBoardDTO

    }

    @Sendable
    func refetchLeaderBoardForUser(req: Request) async throws -> GlobalLeaderboardDTO {

        let totalCount = try await GlobalLeaderboardEntry.query(on: req.db).count()
        guard let userId = UUID(uuidString: req.parameters.get("user_id")!) else { throw Abort(.notFound) }
        var refetchParams = RefetchGlobalLeaderBoardDTO()

        do {
            refetchParams = try req.query.decode(RefetchGlobalLeaderBoardDTO.self)
        } catch {
            throw Abort(.badRequest)
        }

        let entries = try await GlobalLeaderboardEntry.refetchForUser(id: userId, refetchParams: refetchParams, db: req.db)
        let leaderBoardDTO = GlobalLeaderboardDTO(items: entries, totalCount: totalCount)

        return leaderBoardDTO

    }


    @Sendable
    func searchForUser(req: Request) async throws -> [GlobalLeaderboardEntry] {
        
        guard var username = req.parameters.get("user_name") else { throw Abort(.notFound) }
        username = username.lowercased()
        let entries = try await GlobalLeaderboardEntry.query(on: req.db).filter(\.$name ~~ username).all()

        return entries

    }


}
