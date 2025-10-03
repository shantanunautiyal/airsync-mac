import SwiftUI
import CoreBluetooth

struct HealthView: View {
    @StateObject private var healthManager = HealthDataManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            // Health Data from Android (Health Connect)
            HStack {
                Label("Health", systemImage: "heart.fill")
                    .font(.headline)
                Spacer()
                Button(action: {
                    AppState.shared.requestHealthData()
                }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)

            // Health Stats
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    healthCard(
                        title: "Heart Rate",
                        value: "\(healthManager.healthData.heartRate)",
                        unit: "BPM",
                        icon: "heart.fill"
                    )

                    healthCard(
                        title: "Steps",
                        value: "\(healthManager.healthData.steps)",
                        unit: "steps",
                        icon: "figure.walk"
                    )

                    healthCard(
                        title: "Calories",
                        value: "\(healthManager.healthData.calories)",
                        unit: "kcal",
                        icon: "flame.fill"
                    )

                    healthCard(
                        title: "Distance",
                        value: String(format: "%.1f", healthManager.healthData.distance),
                        unit: "km",
                        icon: "figure.hiking"
                    )

                    healthCard(
                        title: "Sleep",
                        value: String(format: "%.1f", healthManager.healthData.sleepHours),
                        unit: "hours",
                        icon: "bed.double.fill"
                    )
                }
                .padding()
            }
        }
    }
    
    private func healthCard(title: String, value: String, unit: String, icon: String) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.system(.title, design: .rounded))
                .fontWeight(.semibold)
            
            Text(unit)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    HealthView()
}
