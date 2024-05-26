//
//  MainView.swift
//  check24-tippspiel
//
//  Created by Simon Bestler on 15.04.24.
//

import SwiftUI

struct MainView: View {

    var dashboardView: DashboardView

    init() {

        // Check if a userID is already stored inside User Defaults
        let isUserLoggedIn = UserDefaults.standard.object(forKey: "userID") != nil


        self.dashboardView = DashboardView()

        // Show Login Screen, if User is not already signed-in

        if isUserLoggedIn {
            self._isShowLogin = State(wrappedValue: false)
        } else {
            self._isShowLogin = State(wrappedValue: true)
        }
    }

    @State private var isShowLogin: Bool

    var body: some View {
        TabView {
            dashboardView
                .tabItem {
                    Label("Dashboard", systemImage: "newspaper")
                }
            BetView()
                .tabItem {
                    Label("Bets", systemImage: "sportscourt")
                }
            GlobalLeaderboardView()
                .tabItem {
                    Label("Leaderboard", systemImage: "trophy")
                }
            CommunityLeaderBoardView()
                .tabItem {
                    Label("Community", systemImage: "person.3")
                }

        }.fullScreenCover(isPresented: $isShowLogin, onDismiss: {
            dashboardView.dashboardVM.getUser()
            dashboardView.dashboardVM.loadUpcoming()
            dashboardView.dashboardVM.loadStanding()
            dashboardView.dashboardVM.loadLeaderboards()
        }, content: {
            LoginView()
        }
        )

    }


}

#Preview {
    MainView()
}
