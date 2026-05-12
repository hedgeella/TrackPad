import SwiftUI

/// Popover view for adjusting stroke width and other options.
struct StrokeOptionsView: View {
    @ObservedObject var toolState: DrawingToolState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stroke Width")
                .font(.headline)

            // Preset widths
            HStack(spacing: 8) {
                ForEach(DrawingToolState.presetLineWidths, id: \.self) { width in
                    Button(action: {
                        if toolState.currentTool == .eraser {
                            toolState.eraserWidth = width * 4
                        } else {
                            toolState.lineWidth = width
                        }
                    }) {
                        VStack(spacing: 4) {
                            Circle()
                                .fill(Color.primary)
                                .frame(width: max(width * 2, 4), height: max(width * 2, 4))

                            Text("\(Int(width))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 36, height: 44)
                        .background(
                            isWidthSelected(width)
                                ? Color.accentColor.opacity(0.2)
                                : Color.clear
                        )
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider()

            // Custom width slider
            VStack(alignment: .leading, spacing: 4) {
                Text("Custom Width: \(formattedWidth)")
                    .font(.subheadline)

                if toolState.currentTool == .eraser {
                    Slider(value: $toolState.eraserWidth, in: 5...100, step: 1)
                } else {
                    Slider(value: $toolState.lineWidth, in: 0.5...20, step: 0.5)
                }
            }

            // Preview
            strokePreview
        }
        .frame(width: 260)
    }

    private var formattedWidth: String {
        let width = toolState.currentTool == .eraser ? toolState.eraserWidth : toolState.lineWidth
        return String(format: "%.1f pt", width)
    }

    private func isWidthSelected(_ width: CGFloat) -> Bool {
        if toolState.currentTool == .eraser {
            return abs(toolState.eraserWidth - width * 4) < 0.5
        }
        return abs(toolState.lineWidth - width) < 0.01
    }

    private var strokePreview: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Preview")
                .font(.subheadline)
                .foregroundColor(.secondary)

            GeometryReader { geometry in
                Path { path in
                    let midY = geometry.size.height / 2
                    path.move(to: CGPoint(x: 10, y: midY))

                    // Draw a wavy line as preview
                    let steps = 20
                    for i in 1...steps {
                        let x = 10 + CGFloat(i) * (geometry.size.width - 20) / CGFloat(steps)
                        let y = midY + sin(CGFloat(i) * 0.8) * 8
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                .stroke(
                    Color(nsColor: toolState.currentColor),
                    style: SwiftUI.StrokeStyle(
                        lineWidth: toolState.currentLineWidth,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
            }
            .frame(height: 40)
            .background(Color.white)
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
            )
        }
    }
}
