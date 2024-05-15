//
//  JoinCommunityVM.swift
//  check24-tippspiel
//
//  Created by Simon Bestler on 13.05.24.
//

import Foundation

@Observable
class JoinCommunityVM {


    var createCommunityName = ""
    var joinCommunityName = ""

    init() {
    }



    func createCommunity() {

        var components = Settings.getBaseURLComponents()
        components.path = "/communities/create"
        let url = components.url!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let community = Community(id: UUID(), created_at: Date(), name: createCommunityName)

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let encodedData = try encoder.encode(community)
            request.httpBody = encodedData
        } catch {
            print(error)
        }

        let task = URLSession.shared.dataTask(with: request){ data, response, error in

            let statusCode = (response as! HTTPURLResponse).statusCode

            guard statusCode == 200 && data != nil else {
                print("Error with statusCode \(statusCode)")
                return
            }
            print("Success")
        }

        task.resume()

    }

    func joinCommunity() {
        
        guard let userID = Settings.getUserID() else {return}

        var components = Settings.getBaseURLComponents()
        components.path = "/users/\(userID)/joinCommunityByName/\(joinCommunityName)"
        let url = components.url!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let task = URLSession.shared.dataTask(with: request){ data, response, error in

            let statusCode = (response as! HTTPURLResponse).statusCode

            guard statusCode == 200 && data != nil else {
                print("Error with statusCode \(statusCode)")
                return
            }
            print("Success")
        }

        task.resume()
    }

}
