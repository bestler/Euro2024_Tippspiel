import Vapor
import PostgresKit
import Fluent

func routes(_ app: Application) throws {
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

    // Create a new user
    app.post("user") { req async throws -> User in
        let user = try req.content.decode(User.self)
        user.created_at = Date()
        try await user.create(on: req.db)
        return user
    }


}
