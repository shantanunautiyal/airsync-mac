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
                    .frame(width: 200, height: 200)

                Spacer()

                VStack{
                    ConnectionInfoText()
                    ConnectionInfoText()
                    ConnectionInfoText()
                    ConnectionInfoText()
                }
            }

            VStack{
                VStack{
                    Label("Device Name", systemImage: "pencil")
                    TextField("Device Name", text: .constant("Sameera's macBook"))
                    HStack{
                        Label("Connect ADB", systemImage: "iphone")
                        Toggle("", isOn: .constant(true))
                            .toggleStyle(.switch)
                    }
                }
                .padding()
                Toggle("Sync devices status", isOn: .constant(true))
                    .toggleStyle(.switch)
                    .padding()
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
            Text("192.168.100.1")
        }
        .padding(1)
    }
}
