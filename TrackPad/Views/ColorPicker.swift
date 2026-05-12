import SwiftUI

/// Color picker popover for selecting drawing colors.
struct DrawingColorPicker: View {
    @ObservedObject var toolState: DrawingToolState
    @State private var customColor: Color = .black

    private let columns = Array(repeating: GridItem(.fixed(32), spacing: 6), count: 5)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Colors")
                .font(.headline)

            // Preset colors grid
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(DrawingToolState.presetColors, id: \.self) { color in
                    colorSwatch(color)
                }
            }

            Divider()

            // System color picker for custom color
            HStack {
                Text("Custom:")
                    .font(.subheadline)
                ColorPicker("", selection: $customColor, supportsOpacity: false)
                    .labelsHidden()
                    .onChange(of: customColor) { newColor in
                        let nsColor = NSColor(newColor)
                        applyColor(nsColor)
                    }
            }
        }
        .frame(width: 200)
    }

    private func colorSwatch(_ color: NSColor) -> some View {
        Button(action: {
            applyColor(color)
        }) {
            Circle()
                .fill(Color(nsColor: color))
                .frame(width: 28, height: 28)
                .overlay(
                    Circle()
                        .stroke(isSelected(color) ? Color.accentColor : Color.primary.opacity(0.2), lineWidth: isSelected(color) ? 2 : 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func isSelected(_ color: NSColor) -> Bool {
        switch toolState.currentTool {
        case .pen: return colorsMatch(color, toolState.penColor)
        case .highlighter: return colorsMatch(color, toolState.highlighterColor)
        default: return false
        }
    }

    private func colorsMatch(_ a: NSColor, _ b: NSColor) -> Bool {
        guard let ac = a.usingColorSpace(.sRGB),
              let bc = b.usingColorSpace(.sRGB) else { return false }
        return abs(ac.redComponent - bc.redComponent) < 0.01
            && abs(ac.greenComponent - bc.greenComponent) < 0.01
            && abs(ac.blueComponent - bc.blueComponent) < 0.01
    }

    private func applyColor(_ color: NSColor) {
        switch toolState.currentTool {
        case .pen: toolState.penColor = color
        case .highlighter: toolState.highlighterColor = color
        default: break
        }
    }
}
