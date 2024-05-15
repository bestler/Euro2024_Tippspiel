//
//  BetVM.swift
//  check24-tippspiel
//
//  Created by Simon Bestler on 15.04.24.
//

import Foundation

@Observable
class BetVM {
    
    var bets : [Bet]

    init(bets: [Bet]) {
        self.bets = bets
    }

    init() {
        self.bets = []
    }

    func loadBets() throws {

        var components = Settings.getBaseURLComponents()

        guard let userID = Settings.getUserID() else {return}
        components.path = "/users/\(userID)/bets"

        let url = components.url!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                print(error)
                return
            }
            let statusCode = (response as! HTTPURLResponse).statusCode

            if statusCode == 200 {

                if let data {
                    do {
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601
                        let decodedData = try decoder.decode([Bet].self, from: data)
                        self.bets = decodedData
                    } catch {
                        print(error)
                    }
                } else {
                    print("No fetched Data")
                }

            } else {
                print("FAILURE")
            }
        }
        task.resume()

    }

    func saveBets() throws {

        var components = Settings.getBaseURLComponents()

        guard let userID = Settings.getUserID() else {return}
        components.path = "/users/\(userID)/bets/update"

        var request = URLRequest(url: components.url!)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let decodedBets = try JSONEncoder().encode(self.bets)

        request.httpBody = decodedBets

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                print(error)
                return
            }
            let statusCode = (response as! HTTPURLResponse).statusCode

            if statusCode == 200 {

                print("Sucess")

            } else {
                print(statusCode)
                print("FAILURE")
            }
        }
        task.resume()



    }

}
