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
    let macIcon = DeviceTypeUtil.deviceIconName()

    var body: some View {
        HStack{
            Image(systemName: macIcon)
                .font(.system(size: 40))
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
