//
//  File.swift
//  
//
//  Created by Simon Bestler on 23.05.24.
//

import Foundation
import SQLKit

struct Utilities {

    static func refreshMaterialiedView(viewName: String, db: SQLDatabase) async throws {

        let queryString = "REFRESH MATERIALIZED VIEW \(viewName);"
        let query = SQLQueryString(queryString)
        try await db.raw(query).run()
    }

}
