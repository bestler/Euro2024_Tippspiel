//
//  GlobalLeaderboardView.swift
//  check24-tippspiel
//
//  Created by Simon Bestler on 23.04.24.
//

import SwiftUI

struct GlobalLeaderboardView: View {

    @State private var leaderboardVM = GlobalLeaderboardVM()
    @State private var showSearchScreen = false

    let paginationSizes = [1,2,5,10,25,50,100]

    var body: some View {

        NavigationStack {
            VStack {
                HStack {
                    Text("Pagination Size:")
                    Picker("Pagination", selection: $leaderboardVM.selectedPaginationSize){
                        ForEach(paginationSizes, id: \.self) {size in
                            Text(String(size)).tag(size)
                        }
                    }
                }
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

                    ForEach(leaderboardVM.leaderBoardEntries) { entry in

                        if entry.row == leaderboardVM.curUp && leaderboardVM.showMoreBottonUp {
                            ShowMoreButton(isUp: true, action: leaderboardVM.refetchData)
                        }

                        GlobalLeaderboardRow(entry: entry)
                            .onTapGesture {
                                leaderboardVM.addFriend(friendId: entry.id)
                            }
                            .listRowBackground(
                                BackgroundColor(entry: entry, rowUser: leaderboardVM.rowOfUser ?? -1, rowLast: leaderboardVM.lastRow ?? -1)
                            )

                        if entry.row == leaderboardVM.curDown && leaderboardVM.showMoreButtonDown {
                            ShowMoreButton(isUp: false, action: leaderboardVM.refetchData)
                        }
                    }
                }
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


struct ShowMoreButton: View {


    let isUp: Bool
    let action: (Bool) -> Void

    var body: some View {
        Button {
            action(isUp)
        } label: {
            if isUp {
                Image(systemName: "chevron.up")
                    .bold()
            } else {
                Image(systemName: "chevron.down")
                    .bold()
            }
        }
        .frame(maxWidth: .infinity)
    }

}

struct BackgroundColor: View {

    //TODO: Nicer colors
    let entry: GlobalLeaderboardEntry
    let rowUser: Int
    let rowLast: Int

    var body: some View {
        if entry.isfriend {
            Color.yellow
        } else if entry.row <= 3 {
            Color.green
        } else if entry.row == rowUser {
            Color.blue
        } else if entry.row == rowLast {
            Color.red
        } else {
            Color(uiColor: UIColor.secondarySystemGroupedBackground)
        }
    }
}


#Preview {
    GlobalLeaderboardView()
}
