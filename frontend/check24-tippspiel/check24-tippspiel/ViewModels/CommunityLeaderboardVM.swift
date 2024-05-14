//
//  CommunityVM.swift
//  check24-tippspiel
//
//  Created by Simon Bestler on 22.04.24.
//

import Foundation

@Observable
class CommunityLeaderboardVM: LeaderboardVM {


    var communities: [Community]
    var selectedCommunity: Community? {
        didSet {
            if let selectedCommunity {
                updateURLS(newCommunity: selectedCommunity.id.uuidString)
                loadEntries()
            }
        }
    }

    override init() {
        self.communities = []
        super.init()
        self.refetchURL = "http://localhost:8080/communities/0/leaderboard/92ffea16-848c-45fc-887b-7a713203caf9"
        self.loadURL = "http://localhost:8080/communities/0/leaderboard/92ffea16-848c-45fc-887b-7a713203caf9"
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
                self.selectedCommunity = self.communities.first

            } catch {
                print(error)
            }

        }
        task.resume()

    }

    func updateURLS(newCommunity: String) {
        //TODO: Real user
        self.refetchURL = "http://localhost:8080/communities/\(newCommunity)/leaderboard/92ffea16-848c-45fc-887b-7a713203caf9"
        self.loadURL = "http://localhost:8080/communities/\(newCommunity)/leaderboard/92ffea16-848c-45fc-887b-7a713203caf9"
    }


}
