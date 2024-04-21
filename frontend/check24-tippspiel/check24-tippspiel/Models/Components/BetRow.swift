//
//  BetRow.swift
//  check24-tippspiel
//
//  Created by Simon Bestler on 14.04.24.
//

import SwiftUI

struct BetRow: View {

    @Binding var bet: Bet


    var body: some View {

        Section(header: Text((bet.match.game_starts_at.formatted()))) {
            HStack {
                Text((bet.match.team_home_name) + " - " + (bet.match.team_away_name))
                Spacer()

                // Betting is only available until the game starts

                if bet.match.game_starts_at > Date() {
                    GoalInputTextField(goals: $bet.goals_home)
                    Text(":")
                    GoalInputTextField(goals: $bet.goals_away)
                } else {
                    GoalText(goals: bet.goals_home)
                    Text(":")
                    GoalText(goals: bet.goals_away)
                }

            }
        }
    }
}

struct GoalInputTextField: View {

    @Binding var goals: Int?

    var body: some View {

        TextField("-", value: $goals, format: .number)
            .textFieldStyle(.roundedBorder)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 50)

    }

}

struct GoalText: View {

    let goals: Int?

    var body: some View {

        Text(goals?.formatted() ?? "-")
            .multilineTextAlignment(.center)
            .frame(maxWidth: 50)
    }
}

#Preview {


    BetRow(bet: .constant(Bet(id: UUID(),
                              match: Match(id: UUID(),
                                           team_home_name: "Germany",
                                           team_away_name: "Ungarn",
                                           game_starts_at: Date(),
                                           team_home_goals: nil,
                                           team_away_goals: nil),
                              goals_home: 2,
                              goals_away: nil,
                              created_at: Date(),
                              points: 0)))
}
