//
//  CreateJoinCommunityView.swift
//  check24-tippspiel
//
//  Created by Simon Bestler on 22.04.24.
//

import SwiftUI

struct CreateJoinCommunityView: View {

    @State private var joinCommunityVM = JoinCommunityVM()
    @Environment(\.dismiss) private var dismiss


    var body: some View {
        NavigationStack {
            Form {
                Section(
                    header: Text("Create Community"),
                    footer: Text("Create a new community. Share the name with you friends. Have fun together!")) {
                        TextField("Community name", text: $joinCommunityVM.createCommunityName)
                    Button("Create", action: {
                        joinCommunityVM.createCommunity()
                        dismiss()
                    })
                }
                Section(
                    header: Text("Join Community"),
                    footer: Text("Join a community to see results from your friends and compare your results!")){
                        TextField("Community Name", text: $joinCommunityVM.joinCommunityName)
                        Button("Join", action: {
                            joinCommunityVM.joinCommunity()
                            dismiss()
                        })
                    }

            }
                .navigationTitle("Create or Join Community")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar{
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: {
                            dismiss()
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
    CreateJoinCommunityView()
}
