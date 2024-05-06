//
//  GlobalLeaderboardRow.swift
//  check24-tippspiel
//
//  Created by Simon Bestler on 01.05.24.
//

import SwiftUI

struct GlobalLeaderboardRow: View {

    let entry: GlobalLeaderboardEntry

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
    GlobalLeaderboardRow(entry: GlobalLeaderboardEntry(id: UUID(), rank: 1, name: "Simon", points: 100, row: 1, isfriend: false))
}
