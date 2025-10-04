import SwiftUI

struct CallsView: View {
    @ObservedObject private var appState = AppState.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Calls", systemImage: "phone.fill")
                    .font(.headline)
                Spacer()
                Button(action: { AppState.shared.requestCallLogs(limit: 100) }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)

            if appState.callLogs.isEmpty {
                VStack {
                    Spacer()
                    Label("No call logs", systemImage: "phone.badge.plus")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            } else {
                List(appState.callLogs) { call in
                    HStack {
                        Image(systemName: icon(for: call.type))
                            .foregroundColor(color(for: call.type))
                        VStack(alignment: .leading) {
                            Text(call.name ?? call.number)
                                .font(.body)
                                .lineLimit(1)
                            Text(detail(for: call))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .scrollContentBackground(.hidden)
                .background(.clear)
                .transition(.blurReplace)
                .listStyle(.sidebar)
            }
        }
        .onAppear {
            AppState.shared.requestCallLogs(limit: 100)
        }
    }

    private func icon(for type: String) -> String {
        switch type.lowercased() {
        case "incoming": return "phone.arrow.down.left"
        case "outgoing": return "phone.arrow.up.right"
        case "missed": return "phone.badge.exclamationmark"
        default: return "phone"
        }
    }

    private func color(for type: String) -> Color {
        switch type.lowercased() {
        case "incoming": return .green
        case "outgoing": return .blue
        case "missed": return .red
        default: return .primary
        }
    }

    private func detail(for call: CallLogEntry) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(call.timestamp) / 1000.0)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        let time = formatter.string(from: date)
        return "\(call.type.capitalized) • \(call.durationSeconds)s • \(time)"
    }
}

#Preview {
    CallsView()
}
