//
//  GlobalLeaderboardView.swift
//  check24-tippspiel
//
//  Created by Simon Bestler on 23.04.24.
//

import SwiftUI

struct GlobalLeaderboardView: View {

    @State private var leaderboardVM = LeaderboardVM()
    @State private var showSearchScreen = false


    var body: some View {

        NavigationStack {
            VStack {
                LeaderboardView(leaderboardVM: $leaderboardVM)
                .sheet(isPresented: $showSearchScreen) {
                    GlobalLeaderboardSearch()
                }
                .navigationTitle("Leaderboard")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar{
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: {
                            showSearchScreen = true
                        }, label: {
                            Label("Search User", systemImage: "magnifyingglass")
                                .font(.title)
                                .labelStyle(.iconOnly)
                        })
                    }
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .onAppear {
                if leaderboardVM.leaderBoardEntries.count == 0 {
                    leaderboardVM.loadEntries()
                }
            }
        }
    }
}


struct BackgroundColor: View {

    let entry: GlobalLeaderboardEntry
    let rowUser: Int
    let rowLast: Int

    var body: some View {
        if entry.row == rowUser {
            Color("BackgroundBlue")
        } else if entry.isfriend {
            Color("BackgroundYellow")
        } else if entry.row <= 3 {
            Color("BackgroundGreen")
        } else if entry.row == rowLast {
            Color("BackgroundRed")
        } else {
            Color(uiColor: UIColor.secondarySystemGroupedBackground)
        }
    }
}


#Preview {
    GlobalLeaderboardView()
}
