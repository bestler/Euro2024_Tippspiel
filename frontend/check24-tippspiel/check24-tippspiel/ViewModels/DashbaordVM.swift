//
//  DashbaordVM.swift
//  check24-tippspiel
//
//  Created by Simon Bestler on 22.05.24.
//

import Foundation

@Observable
class DashbaordVM {


    var userID: UUID?
    private var user: User?
    var leaderBoardDict: [String:[LeaderboardEntry]]
    var upcomingMatch: Match?
    var standing: LeaderboardEntry?
    var username: String? {
        if let user {
            return user.name
        } else {
            return nil
        }
    }

    init() {
        self.userID = Settings.getUserID()
        self.leaderBoardDict = [String:[LeaderboardEntry]]()
    }

    func loadUpcoming() {

        var components = Settings.getBaseURLComponents()
        components.path = "/dashboard/upcoming"

        let request = URLRequest(url: components.url!)
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
                self.upcomingMatch = try decoder.decode(Match.self, from: data!)

            } catch {
                print(error)
            }
        }
        task.resume()
    }

    func loadStanding() {

        var components = Settings.getBaseURLComponents()

        guard let userID else {return}
        components.path = "/dashboard/standing/\(userID)"

        let request = URLRequest(url: components.url!)
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
                self.standing = try decoder.decode(LeaderboardEntry.self, from: data!)

            } catch {
                print(error)
            }
        }
        task.resume()
    }

    func loadLeaderboards() {

        var components = Settings.getBaseURLComponents()
        guard let userID else {return}
        components.path = "/dashboard/leaderboards/\(userID)"

        let request = URLRequest(url: components.url!)
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
                self.leaderBoardDict = try decoder.decode([String:[LeaderboardEntry]].self, from: data!)

            } catch {
                print(error)
            }
        }
        task.resume()

    }


    func getUser() {

        var components = Settings.getBaseURLComponents()
        guard let userID = Settings.getUserID() else {return}
        self.userID = userID
        components.path = "/users/\(userID)"

        let request = URLRequest(url: components.url!)
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
                self.user = try decoder.decode(User.self, from: data!)

            } catch {
                print(error)
            }
        }
        task.resume()

    }


}
