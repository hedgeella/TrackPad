import SwiftUI

/// The main canvas area that hosts the drawing view and status display.
struct CanvasView: View {
    @ObservedObject var document: NotebookDocument
    @ObservedObject var toolState: DrawingToolState
    @State private var showPageBackground = false

    var body: some View {
        ZStack {
            Color(nsColor: .controlBackgroundColor)
                .ignoresSafeArea()

            TrackpadDrawingView(
                document: document,
                toolState: toolState,
                onStrokeCompleted: {
                    // Trigger UI update on stroke completion
                }
            )

            // Status overlay
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    statusBar
                }
            }
            .padding(8)
        }
    }

    private var statusBar: some View {
        HStack(spacing: 12) {
            Text("Page \(document.currentPageIndex + 1) of \(document.pages.count)")
                .font(.caption)
                .foregroundColor(.secondary)

            Divider()
                .frame(height: 12)

            Text("\(document.currentPage.strokes.count) strokes")
                .font(.caption)
                .foregroundColor(.secondary)

            Divider()
                .frame(height: 12)

            Text(toolState.currentTool.displayName)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}
