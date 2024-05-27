//
//  CommunityLeaderBoardView.swift
//  check24-tippspiel
//
//  Created by Simon Bestler on 22.04.24.
//

import SwiftUI

struct CommunityLeaderBoardView: View {

    @State private var selectedCommunity: Community?
    @State private var showJoinCreateSheet = false

    @State var communityVM = CommunityLeaderboardVM()


    var body: some View {
        NavigationStack {
            VStack {
                if communityVM.communities.isEmpty {
                    Spacer()
                    Text("You are not in a community!😢")
                        .font(.title2)
                    Button(action: {
                        showJoinCreateSheet = true
                    }, label: {
                        Label("Create or Join a Community", systemImage: "plus.circle")
                            .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                            .labelStyle(.titleOnly)
                    })
                    .buttonStyle(BorderedButtonStyle())
                    Spacer()
                } else {
                    Picker("Community", selection: $communityVM.selectedCommunity) {
                        ForEach(communityVM.communities) { community in
                            Text(community.name).tag(Optional(community))
                        }
                    }
                    LeaderboardView(communityLeaderboardBM: $communityVM)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .onAppear{
                if communityVM.communities.isEmpty {
                    communityVM.loadCommunities()
                }
            }
            .refreshable {
                communityVM.handleRefresh()
            }
            .sheet(isPresented: $showJoinCreateSheet, onDismiss: {
                communityVM.loadCommunities()
            }, content: {
                CreateJoinCommunityView()
            })
            Spacer()
            .navigationTitle("Community")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        showJoinCreateSheet = true
                    }, label: {
                        Label("Create or Join", systemImage: "plus")
                            .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                            .labelStyle(.iconOnly)
                    })
                }
            }
        }
        .background(Color(UIColor.systemGroupedBackground))

    }
}

#Preview {
    CommunityLeaderBoardView()
}
