//
//  File.swift
//  
//
//  Created by Simon Bestler on 20.05.24.
//

import Foundation
import Vapor
import Fluent

struct DashboardController: RouteCollection {

    func boot(routes: any RoutesBuilder) throws {
        let dashboardRoutes = routes.grouped("dashboard")

        dashboardRoutes.get("upcoming", use: getUpcomingMatch)
        dashboardRoutes.get("leaderboards", ":user_id", use: getLeaderboardSneakPeeksForUser)
        dashboardRoutes.get("standing", ":user_id", use: getStanding)
    }

    @Sendable
    func getUpcomingMatch(req: Request) async throws -> Match {

        //subtract Game duration to show, also if a game is currently running
        let minDate = Calendar.current.date(byAdding: .minute, value: -105, to: Date())

        guard let minDate else {throw Abort(.custom(code: 500, reasonPhrase: "Error with time"))}

        let match = try await Match.query(on: req.db)
                                        .filter(\.$game_starts_at >= minDate)
                                        .sort(\.$game_starts_at)
                                        .first()

        if let match {
            return match
        } else {
            throw Abort(.custom(code: 500, reasonPhrase: "No match found"))
        }
    }

    @Sendable 
    func getLeaderboardSneakPeeksForUser(req: Request) async throws -> [String: [LeaderBoardEntry]] {

        var result = [String: [LeaderBoardEntry]]()

        guard let user_id = UUID(req.parameters.get("user_id")!) else { throw Abort(.notFound) }
        let user = try await User.query(on: req.db).filter(\.$id == user_id).with(\.$communities).first()
        guard let user else {throw Abort(.notFound)}

        for community in user.communities {
            let entries = try await LeaderBoardEntry.sneakPeekCommunityLeaderboardForUser(userId: user_id, communityId: community.id!, db: req.db)
            result[community.name] = entries
        }

        result["Global"] = try await LeaderBoardEntry.sneakPeekGlobalLeaderboardForUser(userId: user_id, db: req.db)

        return result

    }

    @Sendable
    func getStanding(req: Request) async throws -> LeaderBoardEntry {
        guard let user_id = UUID(req.parameters.get("user_id")!) else { throw Abort(.notFound) }

        let entry = try await LeaderBoardEntry.query(on: req.db)
            .field(\.$id)
            .field(\.$rank)
            .field(\.$name)
            .field(\.$points)
            .field(\.$row)
            .filter(\.$id == user_id)
            .first()

        if let entry {
            return entry
        } else {
            throw Abort(.notFound)
        }
    }


}
