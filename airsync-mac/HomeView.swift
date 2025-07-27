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
            VStack{

                PhoneView()


            }
            .padding()
            .safeAreaInset(edge: .bottom) {
                HStack{
                    Button{
                        isDisconnected = true
                        //                    isShowingSafariView = true
                    } label: {
                        Label("Disconnect", systemImage: "xmark")
                    }
                    .buttonStyle(.glass)
                    .controlSize(.large)

                    Button{
                        //                    isShowingSafariView = true
                    } label: {
                        Label("Disconnect", systemImage: "plus")
                    }
                    .buttonStyle(.glass)
                    .labelStyle(.iconOnly)
                    .controlSize(.large)
                }
                .controlSize(.small)
//                .labelStyle(.iconOnly)
            }
        } detail: {
                VStack{
                    HStack{
                        Label("Notifications", systemImage: "bell.badge.fill")
                            .font(.title2)

                        Spacer()

                        Button{
                            //                    isShowingSafariView = true
                        } label: {
                            Label("Dismiss All", systemImage: "xmark")
                        }
                        .buttonStyle(.glass)
                        .labelStyle(.iconOnly)
                        .controlSize(.large)
                        .help("Dismiss All")
                    }
                    .padding()

                        List{
                            NotificationView()
                            NotificationView()
                            NotificationView()
                            NotificationView()
                            NotificationView()
                            NotificationView()
                            NotificationView()
                            NotificationView()
                            NotificationView()
                            NotificationView()
                            NotificationView()
                            NotificationView()
                            NotificationView()
                            NotificationView()
                            NotificationView()
                            NotificationView()
                            NotificationView()
                            NotificationView()
                            NotificationView()
                            NotificationView()
                            NotificationView()
                            NotificationView()
                            NotificationView()
                            NotificationView()
                            NotificationView()
                            NotificationView()
                            NotificationView()
                            NotificationView()
                        }


                }
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


struct NotificationView: View {
    var body: some View {
        ZStack{
            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .cornerRadius(20)
                .frame(maxHeight: 75)

            HStack{
                Image(systemName: "app.badge")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 25, height: 25)
                    .padding(3)

                VStack{
                    HStack{
                        Text("WhatsApp")
                            .font(.default)

                        Spacer()
                    }

                    HStack{
                        Text("You've got a new message")

                        Spacer()
                    }
                }
            }
            .padding()
        }
        .swipeActions(edge: .leading) {
            Button {
//                store.toggleUnread(message)
            } label: {
                    Label("Unread", systemImage: "envelope.badge")
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
//                store.delete(message)
            } label: {
                Label("Delete", systemImage: "trash")
            }
            Button {
//                store.flag(message)
            } label: {
                Label("Flag", systemImage: "flag")
            }
        }
        .listRowSeparator(.hidden)
    }
}
