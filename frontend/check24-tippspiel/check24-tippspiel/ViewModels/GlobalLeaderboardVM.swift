//
//  GlobalLeaderboardVM.swift
//  check24-tippspiel
//
//  Created by Simon Bestler on 23.04.24.
//

import Foundation

@Observable
class GlobalLeaderboardVM {

    var selectedPaginationSize: Int = 10
    var showMoreBottonUp = false
    var showMoreButtonDown = false
    var rowOfUser : Int?
    var curUp: Int?
    var curDown = 3

    var leaderBoardEntries: [GlobalLeaderboardEntry]
    private var leaderboardEntriesDict: [Int:GlobalLeaderboardEntry]
    private var totalCount = 0


    init() {
        self.leaderboardEntriesDict = [:]
        self.leaderBoardEntries = []
    }



    func loadEntries() {

        let url = URL(string: "http://localhost:8080/globalleaderboard/45ec5e7e-93e7-4c7a-8b44-25591ef66840")!
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

                let decodedData = try decoder.decode(LeaderBoardDTO.self, from: data!)
                self.processLoadedEntries(entriesDTO: decodedData)
                self.findUserRow(entriesDTO: decodedData)
                self.evaluatePossiblePosUpDown()
            } catch {
                print(error)
            }

        }

        task.resume()

    }

    func refetchData(isButtonPressedUp: Bool) {

        guard rowOfUser != nil, curUp != nil else {return}

        if isButtonPressedUp {
            self.curUp! -= selectedPaginationSize
        } else {
            curDown += selectedPaginationSize
        }

        var components = URLComponents(string: "http://localhost:8080/globalleaderboard/45ec5e7e-93e7-4c7a-8b44-25591ef66840/refetch")!



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

                let decodedData = try decoder.decode(LeaderBoardDTO.self, from: data!)
                self.processLoadedEntries(entriesDTO: decodedData)
                self.evaluatePossiblePosUpDown()

            } catch {
                print(error)
            }

        }

        task.resume()
    }


    private func evaluatePossiblePosUpDown() {

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

    private func findUserRow(entriesDTO: LeaderBoardDTO) {
        for entry in entriesDTO.items {
            leaderboardEntriesDict[entry.row] = entry
            if entry.id == UUID(uuidString: "45ec5e7e-93e7-4c7a-8b44-25591ef66840")! {
                rowOfUser = entry.row
                curUp = entry.row
            }
        }

    }

    private func processLoadedEntries (entriesDTO: LeaderBoardDTO){

        leaderBoardEntries = entriesDTO.items
        totalCount = entriesDTO.totalCount
    }


}
