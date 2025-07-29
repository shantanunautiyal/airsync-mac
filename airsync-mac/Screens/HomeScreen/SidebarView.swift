//
//  SidebarView.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-28.
//

import SwiftUI


struct SidebarView: View {

    @ObservedObject var appState = AppState.shared
    @State private var isExpandedAllSeas: Bool = false

    var body: some View {
        VStack{
            if (appState.status != nil){
                DeviceStatusView()
                    .padding()
                    .background(.clear)
                    .glassEffect(in: .rect(cornerRadius: 20))
            }

            PhoneView()

        }
        .frame(minWidth: 270, minHeight: 400)
        .safeAreaInset(edge: .bottom) {
            VStack{
                HStack{
                    GlassButtonView(
                        label: "Disconnect",
                        systemImage: "xmark",
                        action: appState.disconnectDevice
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
