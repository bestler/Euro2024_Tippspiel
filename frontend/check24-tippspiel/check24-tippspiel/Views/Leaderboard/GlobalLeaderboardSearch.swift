//
//  GlobalLeaderboardSearch.swift
//  check24-tippspiel
//
//  Created by Simon Bestler on 01.05.24.
//

import SwiftUI

struct GlobalLeaderboardSearch: View {

    @State private var searchText = ""
    @State private var entries = [GlobalLeaderboardEntry]()

    var body: some View {

        NavigationStack {
            List {
                if entries.count > 0 {
                    HStack {
                        Text("Rank")
                            .bold()
                        Spacer()
                        Text("Name")
                            .bold()
                        Spacer()
                        Text("Points")
                            .bold()
                    }
                }
                ForEach(entries) { entry in
                    GlobalLeaderboardRow(entry: entry)
                }
            }
            .searchable(text: $searchText)
            .navigationTitle("Search for Users")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onSubmit(of: .search) {
            searchOnLeaderboard()
        }
    }


    private func searchOnLeaderboard() {
        let url = URL(string: "http://localhost:8080/globalleaderboard/search/\(searchText)")!
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
                self.entries = decodedData
                print(decodedData)
            } catch {
                print(error)
            }

        }


        task.resume()
    }
}

#Preview {
    GlobalLeaderboardSearch()
}
