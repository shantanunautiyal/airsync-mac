//
//  ModernHealthView.swift
//  airsync-mac
//
//  Liquid glass health view with activity rings and gradient cards
//

import SwiftUI

struct HealthView: View {
    @ObservedObject private var manager = LiveNotificationManager.shared
    @State private var selectedDate = Date()
    @State private var isLoadingData = false
    @State private var animateRings = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Glass Date Picker Header
            HStack(spacing: 12) {
                Button(action: { changeDate(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .medium))
                        .frame(width: 30, height: 30)
                        .background(Color.primary.opacity(0.06), in: Circle())
                }
                .buttonStyle(.plain)
                .help("Previous Day")
                
                DatePicker(
                    "",
                    selection: $selectedDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
                .labelsHidden()
                .onChange(of: selectedDate) { _, newDate in
                    requestHealthData(for: newDate)
                }
                
                Button(action: { changeDate(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .frame(width: 30, height: 30)
                        .background(Color.primary.opacity(0.06), in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(Calendar.current.isDateInToday(selectedDate))
                .opacity(Calendar.current.isDateInToday(selectedDate) ? 0.3 : 1.0)
                .help("Next Day")
                
                Spacer()
                
                if !Calendar.current.isDateInToday(selectedDate) {
                    Button("Today") { selectedDate = Date() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                }
                
                Button(action: { requestHealthData(for: selectedDate) }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14))
                        .rotationEffect(.degrees(isLoadingData ? 360 : 0))
                        .animation(isLoadingData ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isLoadingData)
                }
                .buttonStyle(.plain)
                .help("Refresh")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .glassBoxIfAvailable(radius: 0)
            
            // Health Data Content
            ScrollView {
                let cachedSummary = manager.cachedHealthSummary(for: selectedDate)
                let fallbackSummary: HealthSummary? = {
                    if let hs = manager.healthSummary, isSameDay(hs.date, selectedDate) { return hs }
                    return nil
                }()
                let summary: HealthSummary? = cachedSummary ?? fallbackSummary
                
                if let summary = summary {
                    VStack(spacing: 18) {
                        // Activity Rings Card
                        ActivityRingsCard(summary: summary, animate: animateRings)
                            .onAppear { withAnimation(.easeOut(duration: 1.2)) { animateRings = true } }
                        
                        // Metric Cards Grid
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 12) {
                            // Heart Rate
                            GlassMetricCard(
                                icon: "heart.fill",
                                title: "Heart Rate",
                                value: summary.heartRateAvg != nil ? "\(summary.heartRateAvg!)" : "--",
                                unit: "bpm",
                                detail: heartRateRange(summary),
                                accentColor: Color(hex: "E53935"),
                                gradientColors: [Color(hex: "E53935"), Color(hex: "FF7043")]
                            )
                            
                            // Sleep
                            GlassMetricCard(
                                icon: "bed.double.fill",
                                title: "Sleep",
                                value: sleepValue(summary),
                                unit: sleepUnit(summary),
                                detail: nil,
                                accentColor: Color(hex: "7E57C2"),
                                gradientColors: [Color(hex: "7E57C2"), Color(hex: "B388FF")]
                            )
                            
                            // Distance
                            GlassMetricCard(
                                icon: "location.fill",
                                title: "Distance",
                                value: summary.distance != nil ? String(format: "%.2f", summary.distance!) : "--",
                                unit: "km",
                                detail: nil,
                                accentColor: Color(hex: "43A047"),
                                gradientColors: [Color(hex: "43A047"), Color(hex: "66BB6A")]
                            )
                            
                            // Floors
                            GlassMetricCard(
                                icon: "stairs",
                                title: "Floors",
                                value: summary.floorsClimbed != nil ? "\(summary.floorsClimbed!)" : "--",
                                unit: "climbed",
                                detail: nil,
                                accentColor: Color(hex: "8D6E63"),
                                gradientColors: [Color(hex: "8D6E63"), Color(hex: "BCAAA4")]
                            )
                            
                            // Hydration
                            GlassMetricCard(
                                icon: "drop.circle.fill",
                                title: "Hydration",
                                value: summary.hydration != nil ? String(format: "%.1f", summary.hydration!) : "--",
                                unit: "L",
                                detail: nil,
                                accentColor: Color(hex: "039BE5"),
                                gradientColors: [Color(hex: "039BE5"), Color(hex: "4FC3F7")]
                            )
                            
                            // Weight
                            GlassMetricCard(
                                icon: "scalemass.fill",
                                title: "Weight",
                                value: summary.weight != nil ? String(format: "%.1f", summary.weight!) : "--",
                                unit: "kg",
                                detail: nil,
                                accentColor: Color(hex: "5C6BC0"),
                                gradientColors: [Color(hex: "5C6BC0"), Color(hex: "9FA8DA")]
                            )
                        }
                        
                        // Vitals Section
                        if hasVitals(summary) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Vitals")
                                    .font(.headline)
                                    .padding(.top, 4)
                                
                                if let rhr = summary.restingHeartRate {
                                    GlassVitalRow(icon: "heart.text.square.fill", label: "Resting HR", value: "\(rhr) bpm", color: .pink)
                                }
                                if let sys = summary.bloodPressureSystolic, let dia = summary.bloodPressureDiastolic {
                                    GlassVitalRow(icon: "heart.circle.fill", label: "Blood Pressure", value: "\(sys)/\(dia) mmHg", color: .red)
                                }
                                if let o2 = summary.oxygenSaturation, o2 > 0 {
                                    GlassVitalRow(icon: "lungs.fill", label: "SpO2", value: String(format: "%.1f%%", o2), color: .mint)
                                }
                                if let temp = summary.bodyTemperature, temp > 0 {
                                    GlassVitalRow(icon: "thermometer.medium", label: "Temperature", value: String(format: "%.1f°C", temp), color: .orange)
                                }
                                if let glu = summary.bloodGlucose, glu > 0 {
                                    GlassVitalRow(icon: "drop.fill", label: "Glucose", value: String(format: "%.1f mg/dL", glu), color: .purple)
                                }
                                if let vo2 = summary.vo2Max, vo2 > 0 {
                                    GlassVitalRow(icon: "figure.strengthtraining.traditional", label: "VO2 Max", value: String(format: "%.1f", vo2), color: .teal)
                                }
                            }
                        }
                    }
                    .padding()
                } else {
                    VStack(spacing: 16) {
                        if isLoadingData {
                            ProgressView()
                                .scaleEffect(1.5)
                                .padding()
                            Text("Loading health data...")
                                .foregroundColor(.secondary)
                        } else {
                            // Placeholder rings
                            ActivityRingsCard(summary: nil, animate: false)
                            
                            Text("No health data for \(formatDate(selectedDate))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding()
                        }
                    }
                    .padding()
                }
                
                Spacer(minLength: 100)
            }
        }
        .onAppear {
            selectedDate = Date()
            requestHealthData(for: selectedDate)
        }
    }
    
    // MARK: - Helpers
    
    private func changeDate(by days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) {
            selectedDate = newDate
        }
    }
    
    private func requestHealthData(for date: Date) {
        isLoadingData = true
        animateRings = false
        _ = manager.getHealthSummary(for: date)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.isLoadingData = false
            withAnimation(.easeOut(duration: 1.2)) { self.animateRings = true }
        }
    }
    
    private func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        Calendar.current.isDate(date1, inSameDayAs: date2)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func sleepValue(_ s: HealthSummary) -> String {
        guard let dur = s.sleepDuration, dur > 0 else { return "--" }
        return "\(dur / 60)h \(dur % 60)m"
    }
    
    private func sleepUnit(_ s: HealthSummary) -> String {
        guard let dur = s.sleepDuration, dur > 0 else { return "hours" }
        return "of 8h"
    }
    
    private func heartRateRange(_ s: HealthSummary) -> String? {
        guard let min = s.heartRateMin, let max = s.heartRateMax, min > 0 && max > 0 else { return nil }
        return "\(min)–\(max)"
    }
    
    private func hasVitals(_ s: HealthSummary) -> Bool {
        s.restingHeartRate != nil ||
        (s.bloodPressureSystolic != nil && s.bloodPressureDiastolic != nil) ||
        (s.oxygenSaturation != nil && (s.oxygenSaturation ?? 0) > 0) ||
        (s.bodyTemperature != nil && (s.bodyTemperature ?? 0) > 0) ||
        (s.bloodGlucose != nil && (s.bloodGlucose ?? 0) > 0) ||
        (s.vo2Max != nil && (s.vo2Max ?? 0) > 0)
    }
}

// MARK: - Activity Rings Card (Glass)

struct ActivityRingsCard: View {
    let summary: HealthSummary?
    let animate: Bool
    
    private var stepsProgress: Double {
        guard let s = summary?.steps, s > 0 else { return 0 }
        return min(Double(s) / 10000.0, 1.0)
    }
    
    private var caloriesProgress: Double {
        guard let c = summary?.calories, c > 0 else { return 0 }
        return min(Double(c) / 500.0, 1.0)
    }
    
    private var activeProgress: Double {
        guard let a = summary?.activeMinutes, a > 0 else { return 0 }
        return min(Double(a) / 60.0, 1.0)
    }
    
    var body: some View {
        HStack(spacing: 24) {
            // Concentric rings
            ZStack {
                ActivityRing(progress: animate ? stepsProgress : 0, color: Color(hex: "4FC3F7"), lineWidth: 14, size: 130)
                ActivityRing(progress: animate ? caloriesProgress : 0, color: Color(hex: "FF7043"), lineWidth: 14, size: 98)
                ActivityRing(progress: animate ? activeProgress : 0, color: Color(hex: "66BB6A"), lineWidth: 14, size: 66)
            }
            .frame(width: 140, height: 140)
            
            // Legends
            VStack(alignment: .leading, spacing: 14) {
                RingLegend(color: Color(hex: "4FC3F7"), label: "Steps", value: summary?.steps != nil ? "\(summary!.steps!)" : "--", target: "10,000")
                RingLegend(color: Color(hex: "FF7043"), label: "Calories", value: summary?.calories != nil ? "\(summary!.calories!)" : "--", target: "500 kcal")
                RingLegend(color: Color(hex: "66BB6A"), label: "Active", value: summary?.activeMinutes != nil ? "\(summary!.activeMinutes!)" : "--", target: "60 min")
            }
            
            Spacer()
        }
        .padding(20)
        .glassBoxIfAvailable(radius: 20)
    }
}

struct ActivityRing: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.12), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [color, color.opacity(0.6), color]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 1.2), value: progress)
        }
        .frame(width: size, height: size)
    }
}

struct RingLegend: View {
    let color: Color
    let label: String
    let value: String
    let target: String
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                
                Text("\(label) / \(target)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Glass Metric Card

struct GlassMetricCard: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
    let detail: String?
    let accentColor: Color
    let gradientColors: [Color]
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Icon with tinted glass background
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.12))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(accentColor)
            }
            
            Spacer()
            
            // Value
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let detail = detail {
                    Text(detail)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .frame(height: 140)
        .background(
            // Subtle gradient tint behind glass
            LinearGradient(
                colors: gradientColors.map { $0.opacity(0.08) },
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .glassBoxIfAvailable(radius: 16)
        .overlay(alignment: .bottomTrailing) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(14)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(accentColor.opacity(isHovered ? 0.2 : 0.08), lineWidth: 1)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .shadow(color: accentColor.opacity(isHovered ? 0.12 : 0), radius: 12, y: 4)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.2)) { isHovered = hovering }
        }
    }
}

// MARK: - Glass Vital Row

struct GlassVitalRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    @State private var isHovered = false
    
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 34, height: 34)
                
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
            }
            
            Text(label)
                .font(.body)
            
            Spacer()
            
            Text(value)
                .font(.system(.body, design: .rounded, weight: .semibold))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .glassBoxIfAvailable(radius: 12)
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.2)) { isHovered = hovering }
        }
    }
}
