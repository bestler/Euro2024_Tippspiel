//
//  LeaderboardView.swift
//  check24-tippspiel
//
//  Created by Simon Bestler on 08.05.24.
//

import SwiftUI

struct LeaderboardView<LeaderBoardType>: View where LeaderBoardType: LeaderboardVM {

    @Binding var leaderboardVM: LeaderBoardType
    let paginationSizes = [1,2,5,10,25,50,100]

    init(leaderboardVM: Binding<LeaderBoardType>) {
        self._leaderboardVM = leaderboardVM
    }

    init(communityLeaderboardBM: Binding<LeaderBoardType>) {

        self._leaderboardVM = communityLeaderboardBM
    }


    var body: some View {
        NavigationStack {
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
                        ShowMoreButton(isUp: true, action: leaderboardVM.handleShowMoreButton)
                    }
                    
                    GlobalLeaderboardRow(entry: entry)
                        .onTapGesture {
                            leaderboardVM.addFriend(friendId: entry.id)
                        }
                        .listRowBackground(
                            BackgroundColor(entry: entry, rowUser: leaderboardVM.rowOfUser ?? -1, rowLast: leaderboardVM.lastRow ?? -1)
                        )
                    
                    if entry.row == leaderboardVM.curDown && leaderboardVM.showMoreButtonDown {
                        ShowMoreButton(isUp: false, action: leaderboardVM.handleShowMoreButton)
                    }
                }
            }
        }
    }

    
}

#Preview {
    LeaderboardView(leaderboardVM: .constant(LeaderboardVM()))
}
