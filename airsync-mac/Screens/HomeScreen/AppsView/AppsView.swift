//
//  AppsView.swift
//  AirSync
//
//  Created by Sameera Sandakelum on 2025-08-07.
//

import SwiftUI

struct AppsView: View {
    @State private var packageToLaunch: String = ""
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                TextField("Package name (e.g., com.whatsapp)", text: $packageToLaunch)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 320)
                Button {
                    let pkg = packageToLaunch.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !pkg.isEmpty else { return }
                    AppState.shared.requestLaunchApp(package: pkg)
                } label: {
                    Label("Launch", systemImage: "play")
                }
                .keyboardShortcut(.return, modifiers: [])
                Spacer()
            }
            .padding(.horizontal)

            AppGridView()
        }
    }
}

#Preview {
    AppsView()
}
