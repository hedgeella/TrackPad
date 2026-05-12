import SwiftUI

@main
struct TrackPadApp: App {
    @StateObject private var documentManager = DocumentManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(documentManager)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .defaultSize(width: 1200, height: 800)
        .commands {
            // File menu
            CommandGroup(replacing: .newItem) {
                Button("New Notebook") {
                    NotificationCenter.default.post(name: .newDocument, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)

                Button("Open...") {
                    NotificationCenter.default.post(name: .openDocument, object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)

                Button("Save") {
                    NotificationCenter.default.post(name: .saveDocument, object: nil)
                }
                .keyboardShortcut("s", modifiers: .command)

                Divider()

                Button("Export as PDF...") {
                    NotificationCenter.default.post(name: .exportDocument, object: nil)
                }
                .keyboardShortcut("e", modifiers: .command)
            }

            // Edit menu (Undo/Redo)
            CommandGroup(replacing: .undoRedo) {
                Button("Undo") {
                    NotificationCenter.default.post(name: .undoStroke, object: nil)
                }
                .keyboardShortcut("z", modifiers: .command)

                Button("Redo") {
                    NotificationCenter.default.post(name: .redoStroke, object: nil)
                }
                .keyboardShortcut("z", modifiers: [.command, .shift])
            }

            // View menu
            CommandGroup(after: .toolbar) {
                Button("Reset Zoom") {
                    NotificationCenter.default.post(name: .resetZoom, object: nil)
                }
                .keyboardShortcut("0", modifiers: .command)
            }

            // Tools menu
            CommandMenu("Tools") {
                Button("Pen") {
                    NotificationCenter.default.post(name: .selectTool, object: DrawingToolType.pen)
                }
                .keyboardShortcut("1", modifiers: .command)

                Button("Highlighter") {
                    NotificationCenter.default.post(name: .selectTool, object: DrawingToolType.highlighter)
                }
                .keyboardShortcut("2", modifiers: .command)

                Button("Eraser") {
                    NotificationCenter.default.post(name: .selectTool, object: DrawingToolType.eraser)
                }
                .keyboardShortcut("3", modifiers: .command)

                Button("Lasso") {
                    NotificationCenter.default.post(name: .selectTool, object: DrawingToolType.lasso)
                }
                .keyboardShortcut("4", modifiers: .command)
            }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let newDocument = Notification.Name("newDocument")
    static let openDocument = Notification.Name("openDocument")
    static let saveDocument = Notification.Name("saveDocument")
    static let exportDocument = Notification.Name("exportDocument")
    static let undoStroke = Notification.Name("undoStroke")
    static let redoStroke = Notification.Name("redoStroke")
    static let resetZoom = Notification.Name("resetZoom")
    static let selectTool = Notification.Name("selectTool")
}
