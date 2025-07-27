//
//  ContentView.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-27.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        HStack {
            VStack{
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.blue)
                    .frame(width: 300, height: 300)

                Text("Scan from your phone")
                    .padding()
            }

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
                        Toggle("", isOn: .constant(true))
                            .toggleStyle(.switch)
                    }

                    HStack{
                        Label("Sync device status", systemImage: "battery.75percent")
                        Spacer()
                        Toggle("", isOn: .constant(true))
                            .toggleStyle(.switch)
                    }
                }
                .padding()

                VStack{
                    ConnectionInfoText()
                    ConnectionInfoText()
                    ConnectionInfoText()
                    ConnectionInfoText()
                }
                .padding()

//                Spacer()
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}


struct ConnectionInfoText: View {
    var body: some View {
        HStack{
            Label("IP Address", systemImage: "wifi")
            Spacer()
            Text("192.168.100.1")
        }
        .padding(1)
    }
}
