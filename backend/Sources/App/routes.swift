import Vapor
import PostgresKit
import Fluent

func routes(_ app: Application) throws {

    try app.register(collection: AdminController())
    try app.register(collection: UserController())
    try app.register(collection: BetController())
    try app.register(collection: CommunityController())
    try app.register(collection: GlobalLeaderboardController())
    try app.register(collection: DashboardController())

}
