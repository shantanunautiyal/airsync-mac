//
//  DeviceNameView.swift
//  AirSync
//
//  Created by Sameera Sandakelum on 2025-09-20.
//

import SwiftUI

struct DeviceNameView: View {
    @Binding var deviceName: String
    let macDevice = DeviceTypeUtil.deviceTypeDescription()


    var body: some View {
        HStack{
            Image(systemName: "macbook")
                .font(.system(size: 30))
                .padding(.trailing, 8)

            VStack {
                HStack {
                    Label("Rename your \(macDevice)", systemImage: "pencil")
                    Spacer()
                }
                TextField("Device Name", text: $deviceName)
            }
        }
        .padding()
    }
}
