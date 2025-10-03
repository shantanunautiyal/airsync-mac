import SwiftUI

struct NavigationTabView: View {
    let tab: AppState.Tab
    let isSelected: Bool
    
    var body: some View {
        // Icon-only rounded tab (Apple glass-like). Text hidden, shown as tooltip via help().
        Image(systemName: tab.icon)
            .imageScale(.large)
            .frame(width: 22, height: 22)
            .padding(.horizontal, 12)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 1000, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.18) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 1000, style: .continuous)
                    .stroke(isSelected ? Color.accentColor.opacity(0.25) : Color.clear, lineWidth: isSelected ? 1 : 0)
            )
            .help(tab.rawValue.replacingOccurrences(of: ".tab", with: "").capitalized)
    }
}

#Preview {
    NavigationTabView(tab: .notifications, isSelected: true)
}