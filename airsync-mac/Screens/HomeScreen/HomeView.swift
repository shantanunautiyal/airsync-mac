//
//  HomeView.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-27.
//

import SwiftUI

enum DeviceIdentifier: String, CaseIterable, Identifiable, Hashable {
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
            VStack {
                Picker("Device", selection: $selectedDevice) {
                    ForEach(DeviceIdentifier.allCases) { tab in
                        Label(tab.rawValue, systemImage: tab.icon)
                            .tag(tab)
                    }
                }
                .pickerStyle(.automatic)
                .padding()

                // Show the preview in the sidebar
                switch selectedDevice {
                case .pixel, .galaxy:
                    SidebarView(action: {
                        isDisconnected = true
                    })
                case .add:
                    ScannerView()
                }
            }
            .frame(minWidth: 270)
            .navigationTitle("Devices")

        } detail: {
            AppContentView()
        }
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
