//
//  CreateJoinCommunityView.swift
//  check24-tippspiel
//
//  Created by Simon Bestler on 22.04.24.
//

import SwiftUI

struct CreateJoinCommunityView: View {

    @Binding var communityVM: CommunityVM
    @Environment(\.dismiss) private var dismiss


    var body: some View {
        NavigationStack {
            Form {
                Section(
                    header: Text("Create Community"),
                    footer: Text("Create a new community. Share the name with you friends. Have fun together!")) {
                        TextField("Community name", text: $communityVM.createCommunityName)
                    Button("Create", action: {
                        communityVM.createCommunity()
                        dismiss()
                    })
                }
                Section(
                    header: Text("Join Community"),
                    footer: Text("Join a community to see results from your friends and compare your results!")){
                        TextField("Community Name", text: $communityVM.joinCommunityName)
                        Button("Join", action: {
                            communityVM.joinCommunity()
                            dismiss()
                        })
                    }

            }
                .navigationTitle("Create or Join Community")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar{
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: {

                        }, label: {
                            Label("Close", systemImage: "plus")
                                .labelStyle(.titleOnly)
                        })
                    }
                }
        }

    }
}

#Preview {
    CreateJoinCommunityView(communityVM: .constant(CommunityVM()))
}
