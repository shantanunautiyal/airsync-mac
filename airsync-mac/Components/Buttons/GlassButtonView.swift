import SwiftUI

struct GlassButtonView: View {
    var label: String
    var systemImage: String? = nil
    var image: String? = nil
    var iconOnly: Bool = false
    var size: ControlSize = .large
    var primary: Bool = false
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            labelContent
        }
        .controlSize(size)
        .modifier(LabelStyleModifier(iconOnly: iconOnly))
        .applyGlassButtonStyle(primary: primary)
    }

    @ViewBuilder
    private var labelContent: some View {
        if let systemImage {
            Label(label, systemImage: systemImage)
        } else if let image {
            Label(label, image: image)
        } else {
            Text(label)
        }
    }
}

// MARK: - Label Style Modifier

struct LabelStyleModifier: ViewModifier {
    var iconOnly: Bool

    func body(content: Content) -> some View {
        if iconOnly {
            content.labelStyle(IconOnlyLabelStyle())
        } else {
            content.labelStyle(TitleAndIconLabelStyle())
        }
    }
}

// MARK: - Button Style Extension

extension View {
    @ViewBuilder
    func applyGlassButtonStyle(primary: Bool) -> some View {
        if primary {
            self.glassPrimaryButtonIfAvailable()
        } else {
            self.glassButtonIfAvailable()
        }
    }
}


extension View {
    @ViewBuilder
    func glassButtonIfAvailable() -> some View {
        if #available(macOS 26.0, *) {
            self.buttonStyle(.glass)
        } else {
            self.buttonStyle(.plain)
        }
    }

    @ViewBuilder
    func glassPrimaryButtonIfAvailable() -> some View {
        if #available(macOS 26.0, *) {
            self.buttonStyle(.glassProminent)
        } else {
            self.buttonStyle(.borderedProminent)
        }
    }
}


// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        GlassButtonView(label: "Normal", systemImage: "xmark")
        GlassButtonView(label: "Primary", systemImage: "checkmark", primary: true)
    }
    .padding()
}
