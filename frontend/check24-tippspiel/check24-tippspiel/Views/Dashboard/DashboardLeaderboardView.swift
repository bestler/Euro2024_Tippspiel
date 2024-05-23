//
//  DashboardLeaderboardView.swift
//  check24-tippspiel
//
//  Created by Simon Bestler on 22.05.24.
//

import SwiftUI

struct DashboardLeaderboardView: View {

    let communityName: String
    let entries: [LeaderboardEntry]

    var body: some View {
        List() {
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
            
            ForEach(entries){ entry in
                LeaderboardRow(entry: entry)
            }
        }
    }
}

#Preview {
    DashboardLeaderboardView(communityName: "Testcommunity", entries: [LeaderboardEntry(id: UUID(), rank: 1, name: "Simon", points: 25, row: 1, isfriend: nil)])
}
