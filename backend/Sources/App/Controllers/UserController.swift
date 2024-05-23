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
        user.get(":id", "communities", use: getCommunities)
        
        user.post(":user_id", "addFriend", ":friend_id", use: addFriend)
        user.post(":user_id", "joinCommunity", ":community_id", use: joinCommunity)
        user.post(":user_id", "joinCommunityByName", ":community_name", use: joinCommunityByName)

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

        guard let sqlDB = req.db as? SQLDatabase else {
            throw Abort(.internalServerError, reason: "DB Error")
        }
        try await Utilities.refreshMaterialiedView(viewName: "leaderboard", db: sqlDB)

        return user
    }


    private func createBetsForNewUser(userID: UUID, db: Database) async throws {
        if let postgres = db as? PostgresDatabase {
            _ = try await postgres.simpleQuery("CALL createBetsForUser('\(userID.uuidString)')").get()
        }
    }

    
    @Sendable
    func joinCommunity(req: Request) async throws -> HTTPStatus {

        guard let user_id = req.parameters.get("user_id") else { throw Abort(.notFound) }
        guard let community_id = req.parameters.get("community_id") else { throw Abort(.notFound) }

        let community_uuid = UUID(uuidString: community_id)!
        let user_uuid = UUID(uuidString: user_id)!

        let userCommunity = User_Community()
        userCommunity.$user.id = user_uuid
        userCommunity.$community.id = community_uuid


        try await userCommunity.save(on: req.db)

        guard let sqlDB = req.db as? SQLDatabase else {
            throw Abort(.internalServerError, reason: "DB Error")
        }
        try await Utilities.refreshMaterialiedView(viewName: "community_view", db: sqlDB)


        return .ok
    }


    @Sendable 
    func joinCommunityByName(req: Request) async throws -> HTTPStatus {

        guard let user_id = req.parameters.get("user_id") else { throw Abort(.notFound) }
        guard let community_name = req.parameters.get("community_name") else { throw Abort(.notFound) }

        let community = try await Community.query(on: req.db)
            .filter(\.$name == community_name)
            .first()

        guard let community  else { throw Abort(.notFound) }

        let user_uuid = UUID(uuidString: user_id)!

        let userCommunity = User_Community()
        userCommunity.$user.id = user_uuid
        userCommunity.$community.id = community.id!

        try await userCommunity.save(on: req.db)

        guard let sqlDB = req.db as? SQLDatabase else {
            throw Abort(.internalServerError, reason: "DB Error")
        }
        try await Utilities.refreshMaterialiedView(viewName: "community_view", db: sqlDB)

        return .ok
    }

    @Sendable
    func getCommunities(req: Request) async throws -> [Community] {

        guard let id = UUID(uuidString: req.parameters.get("id")!) else { throw Abort(.notFound) }

        let user_community = try await User_Community.query(on: req.db)
            .filter(\.$user.$id == id)
            .with(\.$community)
            .all()

        return user_community.map{return $0.community}

    }

    @Sendable
    func addFriend(req: Request) async throws -> User_Friend {

        guard let user_id = req.parameters.get("user_id") else { throw Abort(.notFound) }
        guard let friend_id = req.parameters.get("friend_id") else { throw Abort(.notFound) }

        guard let user_uuid = UUID(uuidString: user_id), let friend_uuid = UUID(uuidString: friend_id) else {throw Abort(.custom(code: 500, reasonPhrase: "No UUID provided"))}

        let user_friend = User_Friend()

        user_friend.$user.id = user_uuid
        user_friend.$friend.id = friend_uuid

        try await user_friend.create(on: req.db)

        return user_friend

    }

}
