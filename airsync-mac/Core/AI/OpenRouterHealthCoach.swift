//
//  OpenRouterHealthCoach.swift
//  AirSync
//
//  OpenRouter AI Health & Fitness Coach integration
//  Strictly enforces free-tier models (suffix ':free') to guarantee zero-cost usage.
//

import Foundation
import Combine

struct OpenRouterFreeModel: Identifiable, Hashable {
    let id: String
    let displayName: String
    let provider: String
    let description: String
}

@MainActor
final class OpenRouterHealthCoach: ObservableObject {
    static let shared = OpenRouterHealthCoach()

    static let defaultFreeModel = "openrouter/free"
    private static let apiUrl = URL(string: "https://openrouter.ai/api/v1/chat/completions")!
    private static let modelsUrl = URL(string: "https://openrouter.ai/api/v1/models")!

    // Curated high-performance free models verified on OpenRouter
    static let curatedFreeModels: [OpenRouterFreeModel] = [
        // OpenRouter Auto-Router
        OpenRouterFreeModel(
            id: "openrouter/free",
            displayName: "OpenRouter Free Router",
            provider: "OpenRouter",
            description: "Auto-routes to the best active, available free model on OpenRouter."
        ),

        // NVIDIA
        OpenRouterFreeModel(
            id: "nvidia/nemotron-3-ultra:free",
            displayName: "Nemotron 3 Ultra",
            provider: "NVIDIA",
            description: "Complex reasoning and long-context analysis."
        ),
        OpenRouterFreeModel(
            id: "nvidia/nemotron-3.5-lightning:free",
            displayName: "Nemotron 3.5 Lightning",
            provider: "NVIDIA",
            description: "Fast responses and high-throughput workloads."
        ),
        OpenRouterFreeModel(
            id: "nvidia/nemotron-3-super:free",
            displayName: "Nemotron 3 Super",
            provider: "NVIDIA",
            description: "Multi-step reasoning and agent workflows."
        ),
        OpenRouterFreeModel(
            id: "nvidia/nemotron-3-nano-omni:free",
            displayName: "Nemotron 3 Nano Omni",
            provider: "NVIDIA",
            description: "Multimodal analysis of text, images, audio and video."
        ),
        OpenRouterFreeModel(
            id: "nvidia/nemotron-3.5-super-vl:free",
            displayName: "Nemotron 3.5 Super VL",
            provider: "NVIDIA",
            description: "Visual understanding and document analysis."
        ),

        // Google
        OpenRouterFreeModel(
            id: "google/gemma-4-26b-a4b-it:free",
            displayName: "Gemma 4 26B A4B",
            provider: "Google",
            description: "Efficient reasoning and multimodal assistance."
        ),
        OpenRouterFreeModel(
            id: "google/gemma-4-31b-it:free",
            displayName: "Gemma 4 31B",
            provider: "Google",
            description: "Detailed explanations and general-purpose reasoning."
        ),

        // Poolside
        OpenRouterFreeModel(
            id: "poolside/laguna-s-2.1:free",
            displayName: "Laguna S 2.1",
            provider: "Poolside",
            description: "Coding, structured tasks and agentic workflows."
        ),
        OpenRouterFreeModel(
            id: "poolside/laguna-xs-2.1:free",
            displayName: "Laguna XS 2.1",
            provider: "Poolside",
            description: "Lightweight coding and tool-assisted tasks."
        ),

        // Dots Studio
        OpenRouterFreeModel(
            id: "dots-studio/dots3-note-preview:free",
            displayName: "Dots3-Note Preview",
            provider: "Dots Studio",
            description: "Reasoning, coding and long-context tasks."
        ),

        // Thinking Machines Lab
        OpenRouterFreeModel(
            id: "thinking-machines/inkling:free",
            displayName: "Inkling",
            provider: "Thinking Machines",
            description: "Multimodal reasoning and general assistance."
        ),
        OpenRouterFreeModel(
            id: "thinking-machines/inkling-small:free",
            displayName: "Inkling Small",
            provider: "Thinking Machines",
            description: "Efficient reasoning and multilingual chat."
        ),

        // Cohere
        OpenRouterFreeModel(
            id: "cohere/north-mini-code:free",
            displayName: "North Mini Code",
            provider: "Cohere",
            description: "Code generation and structured tool use."
        ),

        // Liquid AI
        OpenRouterFreeModel(
            id: "liquid/lfm2.5-2.6b:free",
            displayName: "LFM2.5 2.6B",
            provider: "Liquid AI",
            description: "Lightweight data extraction and summarization."
        ),

        // Fallbacks
        OpenRouterFreeModel(
            id: "meta-llama/llama-3.3-70b-instruct:free",
            displayName: "Llama 3.3 70B",
            provider: "Meta",
            description: "General-purpose instruction following."
        ),
        OpenRouterFreeModel(
            id: "deepseek/deepseek-r1:free",
            displayName: "DeepSeek R1",
            provider: "DeepSeek",
            description: "Analytical reasoning and problem solving."
        ),
        OpenRouterFreeModel(
            id: "qwen/qwen-2.5-72b-instruct:free",
            displayName: "Qwen 2.5 72B",
            provider: "Alibaba",
            description: "Instruction following and general assistance."
        ),
        OpenRouterFreeModel(
            id: "mistralai/mistral-small-24b-instruct-2501:free",
            displayName: "Mistral Small 24B",
            provider: "Mistral",
            description: "Concise responses and structured suggestions."
        ),
        OpenRouterFreeModel(
            id: "meta-llama/llama-3.1-8b-instruct:free",
            displayName: "Llama 3.1 8B",
            provider: "Meta",
            description: "Lightweight conversational responses."
        )
    ]

    @Published var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: "openRouterEnabled") }
    }

    @Published var apiKey: String {
        didSet { UserDefaults.standard.set(apiKey.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "openRouterApiKey") }
    }

    @Published var selectedModel: String {
        didSet {
            let sanitized = OpenRouterHealthCoach.sanitizeModel(selectedModel)
            UserDefaults.standard.set(sanitized, forKey: "openRouterModel")
        }
    }

    @Published var availableModels: [OpenRouterFreeModel] = OpenRouterHealthCoach.curatedFreeModels
    @Published var isLoadingModels: Bool = false
    @Published var isLoading: Bool = false
    @Published var lastError: String? = nil
    @Published var cachedSuggestions: [String: String] = [:]

    private init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: "openRouterEnabled")
        self.apiKey = UserDefaults.standard.string(forKey: "openRouterApiKey") ?? ""
        let storedModel = UserDefaults.standard.string(forKey: "openRouterModel") ?? Self.defaultFreeModel
        self.selectedModel = Self.sanitizeModel(storedModel)

        if let cached = UserDefaults.standard.dictionary(forKey: "openRouterCachedSuggestions") as? [String: String] {
            self.cachedSuggestions = cached
        }
        
        Task {
            await fetchLiveFreeModels()
        }
    }

    /// Fetches live free models dynamically from https://openrouter.ai/api/v1/models
    func fetchLiveFreeModels() async {
        isLoadingModels = true
        defer { isLoadingModels = false }
        do {
            var request = URLRequest(url: Self.modelsUrl)
            request.timeoutInterval = 15
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let items = json["data"] as? [[String: Any]] {
                var dynamicModels: [OpenRouterFreeModel] = Self.curatedFreeModels
                let existingIds = Set(dynamicModels.map { $0.id.lowercased() })

                for item in items {
                    guard let id = item["id"] as? String else { continue }
                    let lowerId = id.lowercased()
                    let isFree = lowerId == "openrouter/free" || lowerId.hasSuffix("/free") || lowerId.hasSuffix(":free")
                    if isFree && !existingIds.contains(lowerId) {
                        let name = item["name"] as? String ?? id
                        let desc = item["description"] as? String ?? "Free model on OpenRouter."
                        let provider = id.components(separatedBy: "/").first?.capitalized ?? "OpenRouter"
                        dynamicModels.append(OpenRouterFreeModel(
                            id: id,
                            displayName: name,
                            provider: provider,
                            description: desc
                        ))
                    }
                }
                self.availableModels = dynamicModels
            }
        } catch {
            print("[OpenRouter] Failed to fetch live models: \(error.localizedDescription)")
        }
    }

    /// Enforces free model selection only (ends with :free, /free, or openrouter/free)
    static func sanitizeModel(_ model: String) -> String {
        let trimmed = model.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return defaultFreeModel }
        let lower = trimmed.lowercased()
        if lower == "openrouter/free" || lower.hasSuffix("/free") || lower.hasSuffix(":free") {
            return trimmed
        }
        return "\(trimmed):free"
    }

    /// Formats a date key for caching (YYYY-MM-DD)
    static func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    func cachedSuggestion(for date: Date) -> String? {
        cachedSuggestions[Self.dateKey(for: date)]
    }

    /// Tests the user's OpenRouter API key and selected free model
    func testConnection(apiKey: String, model: String) async -> Result<String, Error> {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            return .failure(NSError(domain: "OpenRouter", code: 400, userInfo: [NSLocalizedDescriptionKey: "API Key cannot be empty."]))
        }

        let verifiedModel = Self.sanitizeModel(model)

        var request = URLRequest(url: Self.apiUrl)
        request.httpMethod = "POST"
        request.setValue("Bearer \(trimmedKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("https://github.com/sameerasw/airsync", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("AirSync Health Mac", forHTTPHeaderField: "X-Title")
        request.timeoutInterval = 25

        let body: [String: Any] = [
            "model": verifiedModel,
            "messages": [
                ["role": "user", "content": "Hello! Confirm you are active and free to use."]
            ],
            "max_tokens": 20
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(NSError(domain: "OpenRouter", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid network response."]))
            }

            if httpResponse.statusCode != 200 {
                let errMsg: String
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorObj = json["error"] as? [String: Any],
                   let message = errorObj["message"] as? String {
                    errMsg = message
                } else {
                    errMsg = "HTTP \(httpResponse.statusCode)"
                }
                return .failure(NSError(domain: "OpenRouter", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errMsg]))
            }

            return .success("Connected successfully to \(verifiedModel)!")
        } catch {
            return .failure(error)
        }
    }

    /// Generates personalized health recommendations from HealthSummary
    func generateHealthSuggestions(summary: HealthSummary, date: Date) async -> Result<String, Error> {
        guard isEnabled else {
            return .failure(NSError(domain: "OpenRouter", code: 400, userInfo: [NSLocalizedDescriptionKey: "OpenRouter AI integration is disabled in Settings."]))
        }

        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            return .failure(NSError(domain: "OpenRouter", code: 400, userInfo: [NSLocalizedDescriptionKey: "OpenRouter API Key is not configured. Please set it in Settings."]))
        }

        let verifiedModel = Self.sanitizeModel(selectedModel)

        isLoading = true
        lastError = nil

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        let dateString = dateFormatter.string(from: date)

        var metricsText = "Health Data for \(dateString):\n"
        if let steps = summary.steps, steps > 0 {
            metricsText += "- Steps: \(steps) / 10,000 goal\n"
        } else {
            metricsText += "- Steps: No records\n"
        }

        if let calories = summary.calories, calories > 0 {
            metricsText += "- Active Calories Burned: \(calories) kcal / 500 kcal goal\n"
        } else {
            metricsText += "- Calories: No records\n"
        }

        if let active = summary.activeMinutes, active > 0 {
            metricsText += "- Active Minutes: \(active) min / 60 min goal\n"
        } else {
            metricsText += "- Active Minutes: No records\n"
        }

        if let dist = summary.distance, dist > 0 {
            metricsText += "- Distance: \(String(format: "%.2f km", dist))\n"
        }

        if let sleep = summary.sleepDuration, sleep > 0 {
            metricsText += "- Sleep Duration: \(sleep / 60)h \(sleep % 60)m\n"
        }

        if let hr = summary.heartRateAvg, hr > 0 {
            let minStr = summary.heartRateMin != nil ? "\(summary.heartRateMin!)" : "?"
            let maxStr = summary.heartRateMax != nil ? "\(summary.heartRateMax!)" : "?"
            metricsText += "- Heart Rate: Avg \(hr) bpm (Range: \(minStr)-\(maxStr) bpm)\n"
        }

        if let rhr = summary.restingHeartRate, rhr > 0 {
            metricsText += "- Resting Heart Rate: \(rhr) bpm\n"
        }

        if let floors = summary.floorsClimbed, floors > 0 {
            metricsText += "- Floors Climbed: \(floors)\n"
        }

        if let hydration = summary.hydration, hydration > 0 {
            metricsText += "- Hydration: \(String(format: "%.1f L", hydration))\n"
        }

        if let weight = summary.weight, weight > 0 {
            metricsText += "- Weight: \(String(format: "%.1f kg", weight))\n"
        }

        let systemPrompt = """
        You are an expert personal health, fitness, and recovery coach.
        Your role is to analyze health metrics synced from Health Connect and provide encouraging, practical, and scientifically sound advice.
        Format your response cleanly using bullet points:
        1. 📊 Daily Performance Summary (1-2 sentences highlighting key achievements or gaps)
        2. 💡 Recovery & Body Signals (insights on sleep, heart rate, or strain)
        3. 🎯 3 Actionable Suggestions (targeted recommendations for movement, hydration, or recovery for tomorrow)
        Keep the tone motivating, friendly, and concise. Avoid disclaimers.
        """

        var request = URLRequest(url: Self.apiUrl)
        request.httpMethod = "POST"
        request.setValue("Bearer \(trimmedKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("https://github.com/sameerasw/airsync", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("AirSync Health Mac Coach", forHTTPHeaderField: "X-Title")
        request.timeoutInterval = 45

        let body: [String: Any] = [
            "model": verifiedModel,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": metricsText]
            ],
            "temperature": 0.7,
            "max_tokens": 700
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                isLoading = false
                let err = NSError(domain: "OpenRouter", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid network response."])
                lastError = err.localizedDescription
                return .failure(err)
            }

            guard httpResponse.statusCode == 200 else {
                isLoading = false
                let errMsg: String
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorObj = json["error"] as? [String: Any],
                   let message = errorObj["message"] as? String {
                    errMsg = message
                } else {
                    errMsg = "HTTP \(httpResponse.statusCode)"
                }
                let err = NSError(domain: "OpenRouter", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errMsg])
                lastError = errMsg
                return .failure(err)
            }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                isLoading = false
                let err = NSError(domain: "OpenRouter", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to parse AI response."])
                lastError = err.localizedDescription
                return .failure(err)
            }

            let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
            let key = Self.dateKey(for: date)
            cachedSuggestions[key] = trimmedContent
            UserDefaults.standard.set(cachedSuggestions, forKey: "openRouterCachedSuggestions")

            isLoading = false
            return .success(trimmedContent)
        } catch {
            isLoading = false
            lastError = error.localizedDescription
            return .failure(error)
        }
    }
}
