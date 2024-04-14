import Vapor
import Fluent
import FluentPostgresDriver
import Leaf

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    // register routes

    //Configure DB
    let configuration = try! SQLPostgresConfiguration(url: "postgresql://admin:admin@localhost/check24_tippsspiel")
    app.databases.use(.postgres(configuration: configuration), as: .psql)
    
    //Leaf for HTML Admin Panel
    app.views.use(.leaf)

    try routes(app)
}
