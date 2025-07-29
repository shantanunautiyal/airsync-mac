//
//  HomeView.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-27.
//

import SwiftUI



struct HomeView: View {
    @ObservedObject var appState = AppState.shared
    @State private var isDisconnected: Bool = false

    var body: some View {
        NavigationSplitView {
            VStack {
                if let device = appState.device {
//                    HStack{
//                        // Picker with only 1 device (for now)
//                        Picker("", selection: .constant(device)) {
//                            Label(device.name, systemImage: "iphone.gen3")
//                                .tag(device)
//                        }
//                        .pickerStyle(.menu)
//                    }
//                    .padding()

                    Spacer()
                    SidebarView()
                    Spacer()
                    
                } else {
                    // Show QR scanner if no device
                    ScannerView()
                }
            }
            .frame(minWidth: 270)
            .navigationTitle("Devices")

        } detail: {
            AppContentView()
        }
        .navigationTitle(appState.device?.name ?? "AirSync")
        .sheet(isPresented: $isDisconnected) {
            ScanView()
        }
    }
}



#Preview {
    HomeView()
}


#Preview {
    HomeView()
}
