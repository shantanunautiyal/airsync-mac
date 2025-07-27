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
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.blue)
                        .frame(width: 300, height: 300)
                        .padding(.bottom, 20)


                    HStack{

                        Text("Scan from your phone")

                        Spacer()

                        Button{
                            //                    isShowingSafariView = true
                        } label: {
                            Label("Connect", systemImage: "paperplane.fill")
                        }
                        .buttonStyle(.glass)
                        .controlSize(.large)
                    }
                }
                .padding()

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
                .frame(minWidth: 300)
            }
            .navigationTitle("AirSync")
            .navigationSubtitle("Connect an Android")
            .padding()

          }
    }
}

#Preview {
    ScanView()
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
