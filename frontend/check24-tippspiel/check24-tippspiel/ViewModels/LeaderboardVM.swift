//
//  LeaderboardVM.swift
//  check24-tippspiel
//
//  Created by Simon Bestler on 23.04.24.
//

import Foundation

@Observable
class LeaderboardVM {

    var selectedPaginationSize: Int = 10
    var showMoreBottonUp = false
    var showMoreButtonDown = false
    var rowOfUser : Int?
    var curUp: Int?
    var curDown = 3
    var lastRow: Int?
    var leaderBoardEntries = [GlobalLeaderboardEntry]()

    var loadURL = "http://localhost:8080/globalleaderboard/92ffea16-848c-45fc-887b-7a713203caf9"
    var refetchURL = "http://localhost:8080/globalleaderboard/92ffea16-848c-45fc-887b-7a713203caf9/refetch"

    func loadEntries() {

        let url = URL(string: loadURL)!
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

                let decodedData = try decoder.decode([GlobalLeaderboardEntry].self, from: data!)
                self.processLoadedEntries(entries: decodedData)
                self.findUserRow(entries: decodedData)
                self.evaluatePossiblePosUpDown()
            } catch {
                print(error)
            }
        }
        task.resume()
    }


    func handleShowMoreButton(isButtonPressedUp: Bool) {
        
        recalculateCursorPos(isButtonPressedUp: isButtonPressedUp)
        refetchData()
    }

    func refetchData() {
        var components = URLComponents(string: refetchURL)!

        components.queryItems = [
            URLQueryItem(name: "numTopRows", value: String(curDown)),
            URLQueryItem(name: "lowerBound", value: String(self.curUp!)),
            URLQueryItem(name: "upperBound", value: String(rowOfUser!))
        ]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

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

                let decodedData = try decoder.decode([GlobalLeaderboardEntry].self, from: data!)
                self.processLoadedEntries(entries: decodedData)
                self.evaluatePossiblePosUpDown()

            } catch {
                print(error)
            }

        }

        task.resume()

    }

    func addFriend(friendId: UUID) {

        //TODO: Check with actual logged in user
        guard friendId != UUID(uuidString: "92ffea16-848c-45fc-887b-7a713203caf9") else {return}

        let url = URL(string: "http://localhost:8080/users/92ffea16-848c-45fc-887b-7a713203caf9/addFriend/\(friendId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

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
            print("Friend added sucessfully")
        }
        task.resume()
    }

    func recalculateCursorPos(isButtonPressedUp: Bool) {
        guard rowOfUser != nil, curUp != nil else {return}

        if isButtonPressedUp {
            self.curUp! -= selectedPaginationSize
        } else {
            curDown += selectedPaginationSize
        }
    }


    func evaluatePossiblePosUpDown() {

        if let curUp, curUp > curDown + 1 {
            showMoreBottonUp = true
        } else {
            showMoreBottonUp = false
        }

        if let curUp, curDown < curUp - 1 {
            showMoreButtonDown = true
        } else {
            showMoreButtonDown = false
        }
    }

    func findUserRow(entries: [GlobalLeaderboardEntry]) {

        for entry in entries {
            if entry.id == UUID(uuidString: "92ffea16-848c-45fc-887b-7a713203caf9")! {
                rowOfUser = entry.row
                curUp = entry.row
            }
        }
    }

    func processLoadedEntries (entries: [GlobalLeaderboardEntry]){

        leaderBoardEntries = entries
        //Array is sorted, so last element is last row
        if leaderBoardEntries.count > 0 {
            lastRow = leaderBoardEntries[leaderBoardEntries.count - 1].row
        }
    }

}
