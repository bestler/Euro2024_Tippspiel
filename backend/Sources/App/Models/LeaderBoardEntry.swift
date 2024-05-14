//
//  GlobalLeaderboard.swift
//
//
//  Created by Simon Bestler on 23.04.24.
//

import Foundation
import Fluent
import Vapor
import FluentPostgresDriver

final class LeaderBoardEntry: Model, Content {

    static let schema = "leaderboard"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "rank")
    var rank: Int

    @Field(key: "name")
    var name: String

    @Field(key: "total_points")
    var points: Int

    @Field(key: "row")
    var row: Int

    @Field(key: "isfriend")
    var isfriend: Bool

    @Parent(key: "id")
    var user: User

    

    static func getGlobalLeaderboardForUser(id: UUID, db: Database) async throws -> [LeaderBoardEntry] {
        
        var result: [LeaderBoardEntry] = []

        if let sqldb = db as? SQLDatabase {
            let queryString = #"SELECT * FROM leaderBoardforuser('\#(id.uuidString)')"#
            let query = SQLQueryString(queryString)
            result = try await sqldb.raw(query).all(decoding: LeaderBoardEntry.self)
        }

        return result
    }

    static func refetchGlobalLeaderboardForUser(id: UUID, refetchParams: RefetchLeaderBoardDTO, db: Database) async throws -> [LeaderBoardEntry]{


        var result: [LeaderBoardEntry] = []

        if let sqldb = db as? SQLDatabase {
            let queryString = #"SELECT * FROM refetchLeaderBoardForUser('\#(id)', \#(refetchParams.numTopRows), \#(refetchParams.lowerBound), \#(refetchParams.upperBound))"#
            let query = SQLQueryString(queryString)
            result = try await sqldb.raw(query).all(decoding: LeaderBoardEntry.self)
        }

        return result

    }


    static func getCommunityLeaderBoardForUser(userId: UUID, communityId: UUID, db: Database) async throws -> [LeaderBoardEntry] {

        var result: [LeaderBoardEntry] = []

        if let sqldb = db as? SQLDatabase {
            let queryString = #"select * FROM communityleaderboard('\#(userId.uuidString)', '\#(communityId.uuidString)')"#
            let query = SQLQueryString(queryString)
            result = try await sqldb.raw(query).all(decoding: LeaderBoardEntry.self)
        }

        return result

    }

    static func refetchCommunityLeaderboardForUser(userId: UUID, communityId : UUID, refetchParams: RefetchLeaderBoardDTO, db: Database) async throws -> [LeaderBoardEntry] {


        var result: [LeaderBoardEntry] = []

        if let sqldb = db as? SQLDatabase {
            let queryString = #"SELECT * FROM refetchcommunityleaderboard('\#(userId)', '\#(communityId)', \#(refetchParams.numTopRows), \#(refetchParams.lowerBound), \#(refetchParams.upperBound))"#
            let query = SQLQueryString(queryString)
            result = try await sqldb.raw(query).all(decoding: LeaderBoardEntry.self)
        }

        return result

    }

}

struct LeaderboardDTO: Content {

    let items: [LeaderBoardEntry]
    let totalCount: Int

}

struct RefetchLeaderBoardDTO: Content {

    let numTopRows: Int
    let lowerBound: Int
    let upperBound: Int

    init() {
        self.numTopRows = 0
        self.lowerBound = 0
        self.upperBound = 0
    }

}
