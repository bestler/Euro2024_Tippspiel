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

        var components = Settings.getBaseURLComponents()

        guard let userID = Settings.getUserID() else {return}
        components.path = "/users/\(userID)/communities"

        let url = components.url!
        let request = URLRequest(url: url)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in


            var statusCode = 500
            if let response {
                statusCode = (response as! HTTPURLResponse).statusCode
            } else {
                return
            }
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

        guard let userID = Settings.getUserID() else {return}
        
        var loadComponents = Settings.getBaseURLComponents()
        loadComponents.path = "/communities/\(newCommunity)/leaderboard/\(userID)"

        var refetchComponents = Settings.getBaseURLComponents()
        refetchComponents.path = "/communities/\(newCommunity)/refetchLeaderboard/\(userID)"

        self.loadURL = loadComponents.url!.absoluteString
        self.refetchURL = refetchComponents.url!.absoluteString
    }

    override func handleRefresh() {
        loadCommunities()
        super.handleRefresh()
    }



}
