//
//  DashboardView.swift
//  check24-tippspiel
//
//  Created by Simon Bestler on 20.05.24.
//

import SwiftUI

struct DashboardView: View {

    @State private var dashboardVM = DashbaordVM()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if let match = dashboardVM.upcomingMatch {
                        DashboardUpcomingView(match: match)
                            .frame(maxWidth: .infinity)
                    }
                } header: {
                    Text("Up Next")
                }

                Section {
                    if let standing = dashboardVM.standing {
                        DashboardStandingView(standing: standing)
                            .frame(maxWidth: .infinity)
                    }
                } header: {
                    Text("Global Standing")
                }
                ForEach(Array(dashboardVM.leaderBoardDict.keys).sorted(), id: \.self) { name in
                    Section {

                        DashboardLeaderboardView(communityName: name, entries: dashboardVM.leaderBoardDict[name] ?? [])
                    } header: {
                        Text(name)
                    }
                }
            }
            .navigationTitle("Hello, \(dashboardVM.username)!")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            dashboardVM.getUser()
            dashboardVM.loadUpcoming()
            dashboardVM.loadStanding()
            dashboardVM.loadLeaderboards()
        }
    }
}

#Preview {
    DashboardView()
}
