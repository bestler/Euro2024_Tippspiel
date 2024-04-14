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


    app.get { req async in
        "It works!"
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }

    // Get all users
    app.get("users") { req async throws in
        try await User.query(on: req.db).all()
    }

    //Get User by Name
    app.get("user", "name", ":name") { req async throws in
        let name = req.parameters.get("name")!
        let user = try await User.query(on: req.db).filter(\User.$name == name).all()
        return user
    }

    app.get("user", "name", ":name", "bets") { req async throws -> [Bet] in
        let name = req.parameters.get("name")!
        let user = try await User.query(on: req.db).filter(\User.$name == name).first()!
        let bets = try await user.$bets.get(on: req.db)
        return bets
    }

    // Create a new user
    app.post("user") { req async throws -> User in
        let user = try req.content.decode(User.self)
        user.created_at = Date()
        try await user.create(on: req.db)
        return user
    }

    //Get all matches
    app.get("matches") { req async throws in
        //try await Match.query(on: req.db).with(\.$bets).all()
        try await Match.query(on: req.db).all()
    }


}
