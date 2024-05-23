//
//  DashboardStandingView.swift
//  check24-tippspiel
//
//  Created by Simon Bestler on 22.05.24.
//

import SwiftUI

struct DashboardStandingView: View {

    let standing: LeaderboardEntry

    var body: some View {
        VStack {
            GeometryReader { geometry in
                HStack {
                    VStack {
                        Text("**\(standing.points)**")
                        Text("Points")
                    }
                    .frame(width: geometry.size.width * 0.5, height: geometry.size.height)
                    Divider()
                    VStack() {
                        Text("**\(standing.rank)**")
                        Text("Position")
                    }
                    .frame(width: geometry.size.width * 0.5, height: geometry.size.height)
                }
            }
        }
        .padding()
    }
}

#Preview {
    DashboardStandingView(standing: LeaderboardEntry(id: UUID(), rank: 1, name: "Simon", points: 50, row: 1, isfriend: nil))
}
