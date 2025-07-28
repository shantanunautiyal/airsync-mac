//
//  HomeView.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-27.
//

import SwiftUI

enum DeviceIdentifier: String, CaseIterable, Identifiable {
    case pixel = "Sameera's Pixel"
    case galaxy = "Sameera's Galaxy"
    case add = "Add"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .pixel: return "iphone.gen3"
        case .galaxy: return "iphone.gen1"
        case .add: return "plus"
        }
    }

}

struct HomeView: View {
    @State var isDisconnected: Bool = false
    @State private var selectedDevice: DeviceIdentifier = .pixel

    var body: some View {
            NavigationSplitView {
                Picker("Device", selection: $selectedDevice) {
                    ForEach(DeviceIdentifier.allCases) { tab in
                        Label(tab.rawValue, systemImage: tab.icon)
                            .labelStyle(.iconOnly)
                            .tag(tab)
                    }
                }
                .pickerStyle(.palette)

                ZStack {
                    switch selectedDevice {
                    case .pixel:
                        SidebarView(action: {
                            isDisconnected = true
                        })
                        .transition(.move(edge: .leading))

                    case .galaxy:
                        SidebarView(action: {
                            isDisconnected = true
                        })
                        .transition(.move(edge: .trailing))

                    case .add:
                        ScannerView()
                            .transition(.scale)
                    }

                }
                .animation(.easeInOut(duration: 0.3), value: selectedDevice)
        } detail: {
            AppContentView()
        }
        .navigationTitle(selectedDevice.id)
        .navigationSubtitle("Connected")

        .sheet(isPresented: $isDisconnected){
            ScanView()
        }
    }
}

#Preview {
    HomeView()
}
