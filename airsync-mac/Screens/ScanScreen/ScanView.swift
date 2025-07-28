//
//  ContentView.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-27.
//

import SwiftUI

struct ScanView: View {


    var body: some View {
        NavigationStack{
            HStack {

                VStack{
                    VStack{
                        HStack{
                            Label("Device Name", systemImage: "pencil")
                            Spacer()
                        }
                        TextField("Device Name", text: .constant("Sameera's macBook"))
                    }
                    .padding()

                    VStack{
                        HStack{
                            Label("Connect ADB", systemImage: "iphone")
                            Spacer()
                            Toggle("", isOn: .constant(false))
                                .toggleStyle(.switch)
                        }

                        HStack{
                            Label("Sync device status", systemImage: "battery.75percent")
                            Spacer()
                            Toggle("", isOn: .constant(true))
                                .toggleStyle(.switch)
                        }

                        HStack{
                            Label("Sync clipoboard", systemImage: "clipboard")
                            Spacer()
                            Toggle("", isOn: .constant(true))
                                .toggleStyle(.switch)
                        }
                    }
                    .padding()

                    VStack{
                        ConnectionInfoText(label: "IP Address", icon: "wifi", text: "192.168.100.1")
                        ConnectionInfoText(label: "Port", icon: "rectangle.connected.to.line.below", text: "5555")
                        ConnectionInfoText(label: "Key", icon: "key", text: "OIh7GG4")
                        ConnectionInfoText(label: "Plus features", icon: "plus.app", text: "Active")

                    }
                    .padding()

                    //                Spacer()
                }
                .frame(minWidth: 300)
            }
            .padding()

          }
    }
}

#Preview {
    ScanView()
}


struct ConnectionInfoText: View {
    var label: String
    var icon: String
    var text: String

    var body: some View {
        HStack{
            Label(label, systemImage: icon)
            Spacer()
            Text(text)
        }
        .padding(1)
    }
}
