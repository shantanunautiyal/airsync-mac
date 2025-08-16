import SwiftUI

/// A compact SwiftUI view that lists current file transfers tracked in `AppState.transfers`.
/// Displays name, direction, progress bar, byte counters and status.
struct TransfersView: View {
    @ObservedObject private var appState = AppState.shared

    private var sessions: [AppState.FileTransferSession] {
        Array(appState.transfers.values).sorted { $0.startedAt > $1.startedAt }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if sessions.isEmpty {
                VStack {
                    Spacer()
                    Text("No active transfers")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(sessions) { session in
                        TransferRow(session: session)
                            .padding(.vertical, 6)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .frame(minWidth: 360, minHeight: 160)
    }
}

private struct TransferRow: View {
    let session: AppState.FileTransferSession

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: session.direction == .incoming ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .foregroundColor(session.direction == .incoming ? .blue : .green)
                .font(.title2)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(session.name)
                        .font(.headline)
                        .lineLimit(1)
                    Spacer()
                    Text(statusText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                ProgressView(value: session.progress)
                    .progressViewStyle(LinearProgressViewStyle())

                HStack {
                    Text(bytesText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.0f%%", session.progress * 100))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var bytesText: String {
        if session.size == 0 { return "--" }
        return "\(formatBytes(session.bytesTransferred)) / \(formatBytes(session.size))"
    }

    private var statusText: String {
        switch session.status {
        case .inProgress:
            return "In progress"
        case .completed(let verified):
            if let v = verified {
                return v ? "Completed ✓" : "Completed (checksum mismatch)"
            } else {
                return "Completed"
            }
        case .failed(let reason):
            return "Failed: \(reason)"
        }
    }

    private func formatBytes(_ bytes: Int) -> String {
        let b = Double(bytes)
        if b < 1024 { return "\(bytes) B" }
        let kb = b / 1024
        if kb < 1024 { return String(format: "%.1f KB", kb) }
        let mb = kb / 1024
        if mb < 1024 { return String(format: "%.1f MB", mb) }
        let gb = mb / 1024
        return String(format: "%.1f GB", gb)
    }
}