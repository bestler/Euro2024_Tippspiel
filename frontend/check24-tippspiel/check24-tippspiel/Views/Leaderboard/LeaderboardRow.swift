//
//  GlobalLeaderboardRow.swift
//  check24-tippspiel
//
//  Created by Simon Bestler on 01.05.24.
//

import SwiftUI

struct LeaderboardRow: View {

    let entry: LeaderboardEntry

    var body: some View {
        HStack() {
            Text(String(entry.rank))
                .bold()
            Spacer()
            Text(entry.name)
            Spacer()
            Text(String(entry.points))
        }
    }
}

#Preview {
    LeaderboardRow(entry: LeaderboardEntry(id: UUID(), rank: 1, name: "Simon", points: 100, row: 1, isfriend: false))
}
