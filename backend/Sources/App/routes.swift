import Vapor
import PostgresKit
import Fluent

func routes(_ app: Application) throws {

    /*
    app.get("admin"){ req async throws -> View in

        return try await req.view.render("admin", ["name": "Leaf"])
    }
     */

    try app.register(collection: AdminController())
    try app.register(collection: UserController())
    try app.register(collection: BetController())
    try app.register(collection: CommunityController())
    try app.register(collection: GlobalLeaderboardController())
    try app.register(collection: DashboardController())


    app.get { req async in
        "It works!"
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }


    //Get all matches
    app.get("matches") { req async throws in
        //try await Match.query(on: req.db).with(\.$bets).all()
        try await Match.query(on: req.db).all()
    }


}
