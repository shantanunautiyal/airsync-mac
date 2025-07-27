//
//  HomeView.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-27.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        HStack{
            VStack{
                HStack{
                    Label("Sameera's Pixel", systemImage: "macbook.and.iphone")
                        .font(.title2)

                    Spacer()
                }
                .padding()

                PhoneView()

                HStack{
                    Button{
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
            }
            .padding()

            VStack{
                HStack{
                    Label("Notifications", systemImage: "bell.badge.fill")
                        .font(.title2)

                    Spacer()
                }

                VStack{
                    NotificationView()
                    NotificationView()
                    NotificationView()
                    NotificationView()
                    Spacer()
                }


            }
            .padding()
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
    }
}
