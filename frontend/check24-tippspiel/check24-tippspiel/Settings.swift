//
//  Settings.swift
//  check24-tippspiel
//
//  Created by Simon Bestler on 14.05.24.
//

import Foundation

class Settings {

    static let baseURL = "http://localhost:8080/"

    static func getUserID() -> UUID? {

        let userID = UserDefaults.standard.object(forKey: "userID")
        guard let userID else {return nil}

        let userUUIDString = userID as? String

        guard let userUUIDString else {return nil}
        let id = UUID(uuidString: userUUIDString)
        
        return id

    }

    static func getBaseURLComponents() -> URLComponents {

        var components = URLComponents()
        components.scheme = "http"
        components.host = "localhost"
        components.port = 8080

        return components

    }



}
