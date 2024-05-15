//
//  BetController.swift
//
//
//  Created by Simon Bestler on 17.04.24.
//

import Foundation
import Vapor
import Fluent

struct BetController: RouteCollection {

    func boot(routes: any Vapor.RoutesBuilder) throws {
        let bets = routes.grouped("bets")
        bets.get(":id", use: getBet)
        bets.get(use: getAll)
        bets.put("update", use: update)
    }

    @Sendable
    func getAll(req: Request) async throws -> [Bet] {

        return try await Bet.query(on: req.db).all()

    }

    @Sendable
    func getBet(req: Request) async throws -> Bet {

        guard let id = UUID(uuidString: req.parameters.get("id")!) else { throw Abort(.notFound) }
        let bet = try await Bet.query(on: req.db).filter(\Bet.$id == id).first()
        guard let bet else {throw Abort(.notFound)}

        return bet

    }

    @Sendable
    func update(req: Request) async throws -> HTTPStatus {

        let updatedBets = try req.content.decode([UpdateBetDTO].self)

        for bet in updatedBets {
            let id = bet.id
            let dbBet = try await Bet.query(on: req.db)
                .filter(\.$id == id)
                .with(\.$match)
                .first()

            //Make sure that you can only update bets from games that did not already start
            if let dbBet, dbBet.match.game_starts_at > Date() {
                dbBet.goals_home = bet.goals_home
                dbBet.goals_away = bet.goals_away
                dbBet.modified_at = Date()
                try await dbBet.update(on: req.db)
            }
        }

        return .ok

    }

}
