//
//  MenubarView.swift
//  AirSync
//
//  Created by Sameera Sandakelum on 2025-08-08.
//

import SwiftUI

struct MenubarView: View {
    @Environment(\.openWindow) var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AirSync")
                .font(.headline)
                .padding(.bottom, 4)

            HStack{
                Button("Open App") {
                    openWindow(id: "main")
                }
            }
        }
        .padding()
        .frame(width: 250)
    }
}

#Preview {
    MenubarView()
}
