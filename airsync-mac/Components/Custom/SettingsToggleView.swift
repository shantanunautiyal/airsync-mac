//
//  SettingsToggleView.swift
//  AirSync
//
//  Created by Sameera Sandakelum on 2025-09-20.
//

import SwiftUI

struct SettingsToggleView: View {
    let name: String
    var icon: String? = nil
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            if icon != nil {
                Label(name, systemImage: icon!)
            } else {
                Text(name)
            }
            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
        }
    }
}
