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
    @State private var isExpandedAllSeas: Bool = false


    var body: some View {
        VStack{

            Label("Sameera's Pixel", systemImage: "iphone.gen3")
                .font(.title3)
            Text("Connected")

            Spacer()
            PhoneView()
            Spacer()


        }
        .frame(minWidth: 240, minHeight: 450)
            .safeAreaInset(edge: .bottom) {
                VStack{
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
                    .padding(.bottom, 20)
                }
            }
        }
    }
