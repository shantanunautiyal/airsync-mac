//
//  SettingsPlusView.swift
//  AirSync
//
//  Created by Sameera Sandakelum on 2025-08-04.
//

import SwiftUI

struct SettingsPlusView: View {
    @ObservedObject var appState = AppState.shared
    
    @State private var licenseKey: String = ""
    @State private var isCheckingLicense = false
    @State private var licenseValid: Bool? = nil

    @State private var isExpanded: Bool = false
    @State private var isLicenseVisible = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("AirSync+", systemImage: "key")
                Spacer()
                if appState.isPlus {
                    Button("Unregister", systemImage: "key.slash", action: {
                        appState.licenseDetails = nil
                        appState.isPlus = false
                    })
                    .buttonStyle(.plain)
                }
            }
            .padding()

            if !appState.isPlus {
                TextField("Enter license key", text: $licenseKey)
                    .textFieldStyle(.roundedBorder)
                    .disabled(isCheckingLicense)

                HStack{
                    GlassButtonView(
                        label: "Check License",
                        systemImage: "checkmark.seal",
                        action: {
                            Task {
                                isCheckingLicense = true
                                licenseValid = nil
                                let result = try? await checkLicenseKeyValidity(
                                    key: licenseKey,
                                    save: true
                                )
                                licenseValid = result ?? false
                                isCheckingLicense = false
                            }
                        }
                    )
                    .disabled(
                        licenseKey.isEmpty || isCheckingLicense
                    )


                    if isCheckingLicense {
                        ProgressView()
                            .scaleEffect(0.6)
                    } else if let valid = licenseValid {
                        Image(systemName: valid ? "checkmark.circle.fill" : "xmark.octagon.fill")
                            .foregroundColor(valid ? .green : .red)
                            .transition(.scale)
                    }

                    GlassButtonView(
                        label: "Get AirSync+",
                        systemImage: "link",
                        action: {
                            if let url = URL(string: "https://airsync.sameerasw.com") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                    )

                    Spacer()
                }
            }

            if let details = appState.licenseDetails {
                VStack(alignment: .leading, spacing: 8) {
                    HStack{
                        Text("License Info")
                            .font(.headline)
                            .padding(.bottom, 4)

                        Spacer()

                        Text("Thank you <3")
                            .font(.subheadline)
                            .padding(.bottom, 4)
                    }

                    Divider()

                    HStack {
                        Label("Email", systemImage: "envelope")
                        Spacer()
                        Text(details.email)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Label("Product", systemImage: "shippingbox")
                        Spacer()
                        Text(details.productName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Label("Order #", systemImage: "number")
                        Spacer()
                        Text("\(details.orderNumber)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Label("Purchaser ID", systemImage: "person.fill")
                        Spacer()
                        Text(details.purchaserID)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Label("License Key", systemImage: "key")
                        Spacer()
                        Group {
                            if isLicenseVisible {
                                Text(details.key)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .textSelection(.enabled)
                            } else {
                                Text(String(repeating: "•", count: max(6, min(details.key.count, 12))))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .onTapGesture {
                            withAnimation {
                                isLicenseVisible.toggle()
                            }
                        }
                    }

                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(10)
                .transition(.opacity.combined(with: .move(edge: .top)))
                .animation(.easeInOut(duration: 0.3), value: appState.licenseDetails)

                if (appState.licenseDetails?.key != nil && !appState.isPlus){
                    Label("License invalid, expired or network error", systemImage: "xmark.circle")
                        .foregroundColor(.red)
                }
            }

        }


        DisclosureGroup(isExpanded: $isExpanded) {
            Text(
                            """
Keeps me inspired to continue and maybe even to publish to the Apple app store and google play store. Think of it as a little donation to keep this project alive and evolving.
That said, I know not everyone who wants the full experience can afford it. If that’s you, please don’t hesitate to reach out. 😊

The source code is available on GitHub, and you're more than welcome to build with all Plus features free—for personal use which also opens for contributions which is a win win!.
As a thank-you for supporting the app, AirSync+ unlocks some nice extras: media controls, synced widgets, low battery alerts, wireless ADB, and more to come as I keep adding new features.

Enjoy the app!
(っ◕‿◕)っ
"""
            )
            .font(.footnote)
            .multilineTextAlignment(.leading)
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
        } label: {
            Text("Why plus?")
                .font(.subheadline)
                .bold()
        }
        .padding(.horizontal)
        .focusEffectDisabled()

    }
}

#Preview {
    SettingsPlusView()
}
