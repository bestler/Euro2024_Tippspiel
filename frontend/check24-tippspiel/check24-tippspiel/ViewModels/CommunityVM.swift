//
//  CommunityVM.swift
//  check24-tippspiel
//
//  Created by Simon Bestler on 22.04.24.
//

import Foundation

@Observable
class CommunityVM {


    var communities: [Community]
    var selectedCommunity: Community?


    var createCommunityName = ""
    var joinCommunityName = ""

    init(communitys: [Community]) {
        self.communities = communitys
    }

    init() {
        self.communities = []
    }


    func loadCommunities() {

        let url = URL(string: "http://localhost:8080/users/92ffea16-848c-45fc-887b-7a713203caf9/communities")!
        let request = URLRequest(url: url)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in

            let statusCode = (response as! HTTPURLResponse).statusCode

            guard statusCode == 200 && data != nil else {
                print("Error with statusCode \(statusCode)")
                return
            }

            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601

                let decodedData = try decoder.decode([Community].self, from: data!)
                self.communities = decodedData

            } catch {
                print(error)
            }

        }

        task.resume()

    }

    func createCommunity() {

        let url = URL(string: "http://localhost:8080/communities/create")!
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

        let url = URL(string: "http://localhost:8080/users/92ffea16-848c-45fc-887b-7a713203caf9/joinCommunityByName/\(joinCommunityName)")!
        print(url.absoluteString)
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
