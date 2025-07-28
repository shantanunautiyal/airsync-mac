//
//  HomeView.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-27.
//

import SwiftUI

struct HomeView: View {
    @State var isDisconnected: Bool = false

    var body: some View {
            NavigationSplitView {
                SidebarView(action: {
                    isDisconnected = true
                })
        } detail: {
            AppContentView()
        }
        .navigationTitle("Sameera's Pixel")
        .navigationSubtitle("Connected")

        .sheet(isPresented: $isDisconnected){
            ScanView()
        }
    }
}

#Preview {
    HomeView()
}


struct SidebarView: View {
    var action: () -> Void = {}

    var body: some View {
        VStack{
            PhoneView()
        }
        .padding()
        .safeAreaInset(edge: .bottom) {
            HStack{

                GlassButtonView(
                    label: "Disconnect",
                    systemImage: "xmark",
                    action: action
                )

                GlassButtonView(
                    label: "Connect",
                    systemImage: "plus",
                    action: action
                )
                .labelStyle(.iconOnly)
            }
        }
    }
}
