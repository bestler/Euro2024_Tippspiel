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

final class GlobalLeaderboardEntry: Model, Content {

    static let schema = "globalleaderboard"

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



    static func getDefaultForUser(id: UUID, db: Database) async throws -> [GlobalLeaderboardEntry] {
        
        var result: [GlobalLeaderboardEntry] = []

        if let sqldb = db as? SQLDatabase {
            let queryString = #"SELECT * FROM leaderBoardforuser('\#(id.uuidString)')"#
            let query = SQLQueryString(queryString)
            result = try await sqldb.raw(query).all(decoding: GlobalLeaderboardEntry.self)
        }

        return result
    }

    static func refetchForUser(id: UUID, refetchParams: RefetchGlobalLeaderBoardDTO, db: Database) async throws -> [GlobalLeaderboardEntry]{


        var result: [GlobalLeaderboardEntry] = []

        if let sqldb = db as? SQLDatabase {
            let queryString = #"SELECT * FROM refetchLeaderBoardForUser('\#(id)', \#(refetchParams.numTopRows), \#(refetchParams.lowerBound), \#(refetchParams.upperBound))"#
            let query = SQLQueryString(queryString)
            result = try await sqldb.raw(query).all(decoding: GlobalLeaderboardEntry.self)
        }

        return result

    }

}

struct GlobalLeaderboardDTO: Content {

    let items: [GlobalLeaderboardEntry]
    let totalCount: Int

}

struct RefetchGlobalLeaderBoardDTO: Content {

    let numTopRows: Int
    let lowerBound: Int
    let upperBound: Int

    init() {
        self.numTopRows = 0
        self.lowerBound = 0
        self.upperBound = 0
    }

}
