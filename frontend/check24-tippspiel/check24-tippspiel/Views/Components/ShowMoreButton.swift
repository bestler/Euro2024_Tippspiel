//
//  ShowMoreButton.swift
//  check24-tippspiel
//
//  Created by Simon Bestler on 08.05.24.
//

import SwiftUI

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

#Preview {
    ShowMoreButton(isUp: true, action: {print($0)})
}
