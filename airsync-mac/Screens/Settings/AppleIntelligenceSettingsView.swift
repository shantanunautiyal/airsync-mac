//
//  AppleIntelligenceSettingsView.swift
//  AirSync
//
//  Created by Sameera Sandakelum on 2026-06-05.
//

import SwiftUI

struct AppleIntelligenceSettingsView: View {
    @ObservedObject var appState = AppState.shared
    @ObservedObject var openRouterCoach = OpenRouterHealthCoach.shared
    
    @State private var showApiKey: Bool = false
    @State private var isTestingConnection: Bool = false
    @State private var testResult: Result<String, Error>? = nil
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // MARK: - OpenRouter AI Add-on (Cross-Platform / All macOS versions)
                headerSection(title: "OpenRouter AI Add-on", icon: "sparkles")
                
                VStack(alignment: .leading, spacing: 14) {
                    // Main Toggle
                    Toggle(isOn: $openRouterCoach.isEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("AI Health & Fitness Coach")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Get personalized fitness suggestions, workout advice, and recovery guidance using free AI models.")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .toggleStyle(.switch)
                    
                    if openRouterCoach.isEnabled {
                        Divider()
                            .padding(.vertical, 4)
                        
                        // Zero cost banner
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "sparkles")
                                .foregroundStyle(Color.accentColor)
                                .font(.system(size: 14))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("100% Free AI Models")
                                    .font(.system(size: 12, weight: .bold))
                                Text("Restricted to OpenRouter ':free' tier models only. No credit card or paid balance required.")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(10)
                        .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                        
                        // API Key Input
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("OpenRouter API Key")
                                    .font(.system(size: 12, weight: .medium))
                                Spacer()
                                Link(destination: URL(string: "https://openrouter.ai/keys")!) {
                                    HStack(spacing: 4) {
                                        Text("Get free API key")
                                            .font(.system(size: 11))
                                        Image(systemName: "arrow.up.right")
                                            .font(.system(size: 9))
                                    }
                                }
                            }
                            
                            HStack {
                                if showApiKey {
                                    TextField("sk-or-v1-...", text: $openRouterCoach.apiKey)
                                        .textFieldStyle(.roundedBorder)
                                } else {
                                    SecureField("sk-or-v1-...", text: $openRouterCoach.apiKey)
                                        .textFieldStyle(.roundedBorder)
                                }
                                
                                Button(action: { showApiKey.toggle() }) {
                                    Image(systemName: showApiKey ? "eye.slash" : "eye")
                                        .font(.system(size: 13))
                                        .frame(width: 24, height: 24)
                                }
                                .buttonStyle(.plain)
                                .help(showApiKey ? "Hide Key" : "Show Key")
                            }
                        }
                        
                        // Free Model Picker
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Free AI Model (Zero Cost)")
                                    .font(.system(size: 12, weight: .medium))
                                Spacer()
                                Button(action: {
                                    Task {
                                        await openRouterCoach.fetchLiveFreeModels()
                                    }
                                }) {
                                    HStack(spacing: 4) {
                                        if openRouterCoach.isLoadingModels {
                                            ProgressView()
                                                .controlSize(.small)
                                        } else {
                                            Image(systemName: "arrow.clockwise")
                                                .font(.system(size: 10))
                                        }
                                        Text("Fetch Live Models")
                                            .font(.system(size: 10))
                                    }
                                }
                                .buttonStyle(.borderless)
                                .disabled(openRouterCoach.isLoadingModels)
                            }
                            
                            Picker("", selection: $openRouterCoach.selectedModel) {
                                ForEach(openRouterCoach.availableModels) { model in
                                    Text("\(model.displayName) – \(model.provider)")
                                        .tag(model.id)
                                }
                            }
                            .labelsHidden()
                            
                            if let selected = openRouterCoach.availableModels.first(where: { $0.id == openRouterCoach.selectedModel }) {
                                Text(selected.description)
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 2)
                            }
                        }
                        
                        // Test Connection Button & Status
                        HStack(spacing: 12) {
                            Button(action: {
                                isTestingConnection = true
                                testResult = nil
                                Task {
                                    let res = await openRouterCoach.testConnection(
                                        apiKey: openRouterCoach.apiKey,
                                        model: openRouterCoach.selectedModel
                                    )
                                    testResult = res
                                    isTestingConnection = false
                                }
                            }) {
                                HStack(spacing: 6) {
                                    if isTestingConnection {
                                        ProgressView()
                                            .controlSize(.small)
                                    } else {
                                        Image(systemName: "network")
                                    }
                                    Text(isTestingConnection ? "Testing..." : "Test Connection")
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(openRouterCoach.apiKey.isEmpty || isTestingConnection)
                            
                            if let result = testResult {
                                switch result {
                                case .success(let message):
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                        Text(message)
                                            .font(.system(size: 11))
                                            .foregroundStyle(.green)
                                    }
                                case .failure(let error):
                                    HStack(spacing: 4) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundStyle(.red)
                                        Text(error.localizedDescription)
                                            .font(.system(size: 11))
                                            .foregroundStyle(.red)
                                            .lineLimit(2)
                                    }
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.top, 4)
                    }
                }
                .padding()
                .glassBoxIfAvailable(radius: 18)
                
                // MARK: - Native Apple Intelligence (macOS 26+)
                if #available(macOS 26.0, *) {
                    headerSection(title: L("settings.appleIntelligence"), icon: "apple.logo")
                    VStack {
                        SettingsToggleView(
                            name: L("settings.notifications.ai.disableAll"),
                            icon: "sparkles.slash",
                            isOn: $appState.disableAllAIFeatures
                        )
                    }
                    .padding()
                    .glassBoxIfAvailable(radius: 18)
                    
                    if !appState.disableAllAIFeatures {
                        headerSection(title: "Notification summaries", icon: "doc.text.magnifyingglass")
                        VStack(spacing: 12) {
                            SettingsToggleView(
                                name: L("settings.notifications.ai.showToolbarButton"),
                                icon: "sparkles",
                                isOn: $appState.showAIToolbarButton
                            )
                            
                            SettingsToggleView(
                                name: L("settings.notifications.ai.includeSilent"),
                                icon: "bell.slash",
                                isOn: $appState.includeSilentInAIOption
                            )
                            
                            SettingsToggleView(
                                name: L("settings.notifications.ai.menubarSummary"),
                                icon: "menubar.arrow.up.rectangle",
                                isOn: $appState.enableMenubarAISummary
                            )
                            
                            SettingsToggleView(
                                name: L("settings.notifications.ai.autoMenubarSummary"),
                                icon: "sparkles.rectangle.stack",
                                isOn: $appState.autoMenubarSummary
                            )
                            .disabled(!appState.enableMenubarAISummary)
                            .opacity(appState.enableMenubarAISummary ? 1.0 : 0.5)
                        }
                        .padding()
                        .glassBoxIfAvailable(radius: 18)
                    }
                }
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private func headerSection(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(Color.accentColor)
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 8)
    }
}
