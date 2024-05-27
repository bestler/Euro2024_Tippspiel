//
//  LeaderboardVM.swift
//  check24-tippspiel
//
//  Created by Simon Bestler on 23.04.24.
//

import Foundation

@Observable
class LeaderboardVM {

    var userID: UUID?
    var selectedPaginationSize: Int
    var showMoreButtonUp: Bool
    var showMoreButtonDown: Bool
    var rowOfUser: Int?
    var curUp: Int?
    var curDown: Int
    var lastRow: Int?
    var leaderBoardEntries = [LeaderboardEntry]()
    var loadURL: String
    var refetchURL: String

    init() {
        userID = Settings.getUserID()

        var loadComponents = Settings.getBaseURLComponents()
        loadComponents.path = "/globalleaderboard/\(Settings.getUserID()?.uuidString ?? "")"

        var refetchComponents = Settings.getBaseURLComponents()
        refetchComponents.path = "/globalleaderboard/\(Settings.getUserID()?.uuidString ?? "")/refetch"

        self.loadURL = loadComponents.url!.absoluteString
        self.refetchURL = refetchComponents.url!.absoluteString
        self.showMoreButtonUp = false
        self.showMoreButtonDown = false
        self.selectedPaginationSize = 10
        self.leaderBoardEntries = []
        self.curDown = 3
    }

    func loadEntries() {
        
        //Necessary, because if User logged in for the first time, userID is not correctly set because class is initialized before UserID is set in UserDefaults
        if userID == nil {
            updatePath()
        }

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

                let decodedData = try decoder.decode([LeaderboardEntry].self, from: data!)
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

                let decodedData = try decoder.decode([LeaderboardEntry].self, from: data!)
                self.processLoadedEntries(entries: decodedData)
                self.evaluatePossiblePosUpDown()

            } catch {
                print(error)
            }

        }

        task.resume()

    }

    func addFriend(friendId: UUID) {

        guard friendId != userID else {return}

        var components = Settings.getBaseURLComponents()
        components.path = "/users/\(userID?.uuidString ?? "")/addFriend/\(friendId)"
        let url = components.url!
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
        guard let curUp = curUp else {
            showMoreButtonUp = false
            showMoreButtonDown = false
            return
        }

        // Special case where curUp is exactly 1 more than curDown
        if curUp == curDown + 1 {
            showMoreButtonUp = false
            showMoreButtonDown = false
            return
        }

        // General case
        showMoreButtonUp = curUp > curDown
        showMoreButtonDown = curDown < curUp
    }


    func findUserRow(entries: [LeaderboardEntry]) {

        for entry in entries {
            if entry.id == userID {
                rowOfUser = entry.row
                curUp = entry.row
            }
        }
    }

    func processLoadedEntries (entries: [LeaderboardEntry]){

        leaderBoardEntries = entries
        //Array is sorted, so last element is last row
        if leaderBoardEntries.count > 0 {
            lastRow = leaderBoardEntries[leaderBoardEntries.count - 1].row
        }
    }

    func updatePath() {
        self.userID = Settings.getUserID()
        var loadComponents = Settings.getBaseURLComponents()
        loadComponents.path = "/globalleaderboard/\(Settings.getUserID()?.uuidString ?? "")"

        var refetchComponents = Settings.getBaseURLComponents()
        refetchComponents.path = "/globalleaderboard/\(Settings.getUserID()?.uuidString ?? "")/refetch"

        self.loadURL = loadComponents.url!.absoluteString
        self.refetchURL = refetchComponents.url!.absoluteString
    }

    func handleRefresh() {
        curDown = 3
        curUp = rowOfUser
        loadEntries()
    }

}
