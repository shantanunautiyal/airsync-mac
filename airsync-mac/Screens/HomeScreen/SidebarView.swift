//
//  SidebarView.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-28.
//

import SwiftUI


struct SidebarView: View {
    var action: () -> Void = {}
    @State private var isExpandedAllSeas: Bool = false

    var body: some View {
        VStack{
            Spacer()
            PhoneView()
            Spacer()
        }
        .frame(minWidth: 270, minHeight: 400)
        .safeAreaInset(edge: .bottom) {
            VStack{
                HStack{

                    GlassButtonView(
                        label: "Disconnect",
                        systemImage: "xmark",
                        action: action
                    )
                }
                .padding(.bottom, 20)
            }
        }
    }
}

#Preview {
    SidebarView()
}
