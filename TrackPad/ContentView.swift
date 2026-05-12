import SwiftUI

/// Main application view combining sidebar, toolbar, and canvas.
struct ContentView: View {
    @EnvironmentObject var documentManager: DocumentManager
    @StateObject private var document = NotebookDocument()
    @StateObject private var toolState = DrawingToolState()

    @State private var showSidebar = true
    @State private var showWelcome = true
    @State private var drawingViewRef: TrackpadDrawingNSView?

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            DrawingToolbar(
                toolState: toolState,
                document: document,
                onUndo: { drawingViewRef?.undo() },
                onRedo: { drawingViewRef?.redo() },
                onClearPage: { document.clearCurrentPage() },
                onExport: { ExportManager.showExportDialog(for: document) },
                onAddPage: addPage
            )
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            // Main content
            HStack(spacing: 0) {
                if showSidebar {
                    SidebarView(
                        document: document,
                        onAddPage: addPage
                    )

                    Divider()
                }

                // Canvas
                CanvasViewWithRef(
                    document: document,
                    toolState: toolState,
                    drawingViewRef: $drawingViewRef
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: { showSidebar.toggle() }) {
                    Image(systemName: "sidebar.left")
                }
                .help(showSidebar ? "Hide Sidebar" : "Show Sidebar")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .newDocument)) { _ in
            newDocument()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openDocument)) { _ in
            openDocument()
        }
        .onReceive(NotificationCenter.default.publisher(for: .saveDocument)) { _ in
            saveDocument()
        }
        .onReceive(NotificationCenter.default.publisher(for: .exportDocument)) { _ in
            ExportManager.showExportDialog(for: document)
        }
        .onReceive(NotificationCenter.default.publisher(for: .undoStroke)) { _ in
            drawingViewRef?.undo()
        }
        .onReceive(NotificationCenter.default.publisher(for: .redoStroke)) { _ in
            drawingViewRef?.redo()
        }
        .onReceive(NotificationCenter.default.publisher(for: .resetZoom)) { _ in
            drawingViewRef?.resetZoom()
        }
        .onReceive(NotificationCenter.default.publisher(for: .selectTool)) { notification in
            if let tool = notification.object as? DrawingToolType {
                toolState.currentTool = tool
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }

    private func addPage() {
        document.addPage()
    }

    private func newDocument() {
        document.title = "Untitled Notebook"
        document.pages = [Page()]
        document.currentPageIndex = 0
    }

    private func openDocument() {
        if let loaded = documentManager.showOpenDialog() {
            document.title = loaded.title
            document.pages = loaded.pages
            document.currentPageIndex = loaded.currentPageIndex
        }
    }

    private func saveDocument() {
        try? documentManager.save(document)
    }
}

/// Wrapper to capture a reference to the NSView for undo/redo/zoom.
struct CanvasViewWithRef: NSViewRepresentable {
    @ObservedObject var document: NotebookDocument
    @ObservedObject var toolState: DrawingToolState
    @Binding var drawingViewRef: TrackpadDrawingNSView?

    func makeNSView(context: Context) -> TrackpadDrawingNSView {
        let view = TrackpadDrawingNSView()
        view.document = document
        view.toolState = toolState
        view.onStrokeCompleted = {}
        view.onNeedsDisplay = { view.needsDisplay = true }

        DispatchQueue.main.async {
            self.drawingViewRef = view
        }

        return view
    }

    func updateNSView(_ nsView: TrackpadDrawingNSView, context: Context) {
        nsView.document = document
        nsView.toolState = toolState
        nsView.needsDisplay = true
    }
}
