import SwiftUI

/// The main toolbar with drawing tools, color picker, and actions.
struct DrawingToolbar: View {
    @ObservedObject var toolState: DrawingToolState
    @ObservedObject var document: NotebookDocument
    var onUndo: () -> Void
    var onRedo: () -> Void
    var onClearPage: () -> Void
    var onExport: () -> Void
    var onAddPage: () -> Void

    @State private var showColorPopover = false
    @State private var showStrokeOptions = false
    @State private var showBackgroundPicker = false

    var body: some View {
        HStack(spacing: 4) {
            // Drawing tools
            toolButtons

            Divider()
                .frame(height: 24)
                .padding(.horizontal, 4)

            // Color button
            colorButton

            // Stroke width button
            strokeWidthButton

            Divider()
                .frame(height: 24)
                .padding(.horizontal, 4)

            // Undo/Redo
            undoRedoButtons

            Divider()
                .frame(height: 24)
                .padding(.horizontal, 4)

            // Page actions
            pageActions

            Spacer()

            // Document title
            TextField("Notebook Title", text: $document.title)
                .textFieldStyle(.plain)
                .font(.headline)
                .frame(maxWidth: 200)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private var toolButtons: some View {
        ForEach(DrawingToolType.allCases) { tool in
            Button(action: {
                toolState.currentTool = tool
            }) {
                Image(systemName: tool.iconName)
                    .font(.system(size: 16))
                    .frame(width: 32, height: 32)
                    .background(
                        toolState.currentTool == tool
                            ? Color.accentColor.opacity(0.2)
                            : Color.clear
                    )
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .help(tool.displayName)
        }
    }

    private var colorButton: some View {
        Button(action: { showColorPopover.toggle() }) {
            Circle()
                .fill(Color(nsColor: toolState.currentColor))
                .frame(width: 24, height: 24)
                .overlay(
                    Circle().stroke(Color.primary.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .help("Color")
        .popover(isPresented: $showColorPopover, arrowEdge: .bottom) {
            DrawingColorPicker(toolState: toolState)
                .padding()
        }
    }

    private var strokeWidthButton: some View {
        Button(action: { showStrokeOptions.toggle() }) {
            Image(systemName: "lineweight")
                .font(.system(size: 16))
                .frame(width: 32, height: 32)
        }
        .buttonStyle(.plain)
        .help("Stroke Width")
        .popover(isPresented: $showStrokeOptions, arrowEdge: .bottom) {
            StrokeOptionsView(toolState: toolState)
                .padding()
        }
    }

    private var undoRedoButtons: some View {
        HStack(spacing: 2) {
            Button(action: onUndo) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 14))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .help("Undo (⌘Z)")

            Button(action: onRedo) {
                Image(systemName: "arrow.uturn.forward")
                    .font(.system(size: 14))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .help("Redo (⇧⌘Z)")
        }
    }

    private var pageActions: some View {
        HStack(spacing: 2) {
            Button(action: onAddPage) {
                Image(systemName: "plus.rectangle")
                    .font(.system(size: 14))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .help("Add Page")

            Menu {
                ForEach(BackgroundStyle.allCases) { style in
                    Button(action: {
                        document.pages[document.currentPageIndex].backgroundStyle = style
                    }) {
                        Label(style.displayName, systemImage: style.iconName)
                    }
                }
            } label: {
                Image(systemName: "doc.badge.gearshape")
                    .font(.system(size: 14))
                    .frame(width: 28, height: 28)
            }
            .menuStyle(.borderlessButton)
            .frame(width: 28, height: 28)
            .help("Page Background")

            Button(action: onClearPage) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .help("Clear Page")

            Button(action: onExport) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 14))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .help("Export")
        }
    }
}
