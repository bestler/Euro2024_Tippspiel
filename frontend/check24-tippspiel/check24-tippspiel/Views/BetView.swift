//
//  BetView.swift
//  check24-tippspiel
//
//  Created by Simon Bestler on 14.04.24.
//

import SwiftUI

struct BetView: View {

    @State private var betVM = BetVM()

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Form {
                    ForEach($betVM.bets) { $bet in
                        BetRow(bet: $bet)
                    }
                    Section(header: Text("")) {
                        EmptyView()
                    }
                    .padding(.bottom, 25)
                }
                Button {
                    do {
                        try betVM.saveBets()
                    } catch {
                        print(error)
                    }
                } label: {
                    Text("Save")
                        .bold()
                        .padding()
                        .background(.ultraThinMaterial)
                        .foregroundColor(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(radius: 4, x: 0, y:4)
                }
                .padding()
                .navigationTitle("Bets")
                .navigationBarTitleDisplayMode(/*@START_MENU_TOKEN@*/.automatic/*@END_MENU_TOKEN@*/)
            }
            .onAppear {
                do {
                    try betVM.loadBets()
                }
                catch {
                    print(error)
                }
            }
        }

    }


}



#Preview {
    BetView()
}
