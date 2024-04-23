//
//  CommunityController.swift
//
//
//  Created by Simon Bestler on 22.04.24.
//

import Foundation
import Vapor
import Fluent

struct CommunityController: RouteCollection {

    func boot(routes: any RoutesBuilder) throws {
        let community_routes = routes.grouped("communities")
        
        community_routes.get(use: getAll)
        community_routes.post("create", use: create)

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

}
