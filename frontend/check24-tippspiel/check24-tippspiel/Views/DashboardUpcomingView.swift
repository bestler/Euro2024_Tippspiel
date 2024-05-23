//
//  DashboardUpcomingView.swift
//  check24-tippspiel
//
//  Created by Simon Bestler on 20.05.24.
//

import SwiftUI

struct DashboardUpcomingView: View {

    let match: Match

    var body: some View {
        
        VStack() {
            Text(match.game_starts_at.formatted())
                .fontWeight(.bold)
            Text("\(match.team_home_name) - \(match.team_away_name)")
        }

    }
}

#Preview {

    DashboardUpcomingView(match: Match(id: UUID(), team_home_name: "Deutschland", team_away_name: "Schottland", game_starts_at: Date(), team_home_goals: 2, team_away_goals: 0))
}
