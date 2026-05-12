import AppKit
import SwiftUI

/// NSView subclass that captures trackpad input for drawing.
/// This is the core view that transforms the macOS trackpad into a drawing surface.
class TrackpadDrawingNSView: NSView, TrackpadInputDelegate {
    var document: NotebookDocument?
    var toolState: DrawingToolState?
    var onStrokeCompleted: (() -> Void)?
    var onNeedsDisplay: (() -> Void)?

    private let inputHandler = TrackpadInputHandler()
    private var currentStroke: Stroke?
    private var undoStack: [[Stroke]] = []
    private var redoStack: [[Stroke]] = []

    // Zoom & pan state
    var zoomScale: CGFloat = 1.0
    var panOffset: CGPoint = .zero

    override var acceptsFirstResponder: Bool { true }

    override init(frame: NSRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        inputHandler.delegate = self
        wantsLayer = true
        layer?.backgroundColor = NSColor.white.cgColor

        // Enable pressure events
        allowedTouchTypes = [.indirect]
    }

    override var isFlipped: Bool { true }

    // MARK: - Coordinate Conversion

    private func canvasPoint(from viewPoint: CGPoint) -> CGPoint {
        CGPoint(
            x: (viewPoint.x - panOffset.x) / zoomScale,
            y: (viewPoint.y - panOffset.y) / zoomScale
        )
    }

    // MARK: - Mouse/Trackpad Events

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        inputHandler.handleMouseDown(event, in: self)
    }

    override func mouseDragged(with event: NSEvent) {
        inputHandler.handleMouseDragged(event, in: self)
    }

    override func mouseUp(with event: NSEvent) {
        inputHandler.handleMouseUp(event, in: self)
    }

    override func pressureChange(with event: NSEvent) {
        inputHandler.handlePressureChange(event, in: self)
    }

    // MARK: - Gesture Events for Zoom/Pan

    override func magnify(with event: NSEvent) {
        let oldScale = zoomScale
        zoomScale = max(0.25, min(zoomScale + event.magnification, 5.0))

        // Zoom toward cursor position
        let location = convert(event.locationInWindow, from: nil)
        let scaleDelta = zoomScale / oldScale
        panOffset.x = location.x - (location.x - panOffset.x) * scaleDelta
        panOffset.y = location.y - (location.y - panOffset.y) * scaleDelta

        needsDisplay = true
        onNeedsDisplay?()
    }

    override func scrollWheel(with event: NSEvent) {
        if event.modifierFlags.contains(.command) {
            // Cmd+scroll = zoom
            let delta = event.scrollingDeltaY * 0.01
            let oldScale = zoomScale
            zoomScale = max(0.25, min(zoomScale + delta, 5.0))

            let location = convert(event.locationInWindow, from: nil)
            let scaleDelta = zoomScale / oldScale
            panOffset.x = location.x - (location.x - panOffset.x) * scaleDelta
            panOffset.y = location.y - (location.y - panOffset.y) * scaleDelta
        } else {
            // Regular scroll = pan
            panOffset.x += event.scrollingDeltaX
            panOffset.y += event.scrollingDeltaY
        }
        needsDisplay = true
        onNeedsDisplay?()
    }

    // MARK: - Keyboard Shortcuts

    override func keyDown(with event: NSEvent) {
        if event.modifierFlags.contains(.command) {
            switch event.charactersIgnoringModifiers {
            case "z":
                if event.modifierFlags.contains(.shift) {
                    redo()
                } else {
                    undo()
                }
                return
            case "0":
                resetZoom()
                return
            default:
                break
            }
        }
        super.keyDown(with: event)
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let context = NSGraphicsContext.current?.cgContext,
              let document = document else { return }

        let page = document.currentPage
        let pageSize = Page.defaultSize

        context.saveGState()
        context.translateBy(x: panOffset.x, y: panOffset.y)
        context.scaleBy(x: zoomScale, y: zoomScale)

        // Draw page shadow
        context.setShadow(offset: CGSize(width: 2, height: -2), blur: 8, color: NSColor.black.withAlphaComponent(0.2).cgColor)
        context.setFillColor(NSColor.white.cgColor)
        context.fill(CGRect(origin: .zero, size: pageSize))
        context.setShadow(offset: .zero, blur: 0)

        // Draw page background
        DrawingEngine.renderBackground(style: page.backgroundStyle, in: context, size: pageSize)

        // Save state and set up NSGraphicsContext for stroke rendering
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: true)

        // Draw completed strokes
        for stroke in page.strokes {
            DrawingEngine.renderStroke(stroke)
        }

        // Draw current in-progress stroke
        if let current = currentStroke {
            DrawingEngine.renderStroke(current)
        }

        NSGraphicsContext.restoreGraphicsState()
        context.restoreGState()
    }

    // MARK: - TrackpadInputDelegate

    func trackpadDidBeginStroke(at point: CGPoint, pressure: CGFloat) {
        guard let toolState = toolState, let document = document else { return }

        let canvasPt = canvasPoint(from: point)

        if toolState.currentTool == .eraser {
            saveUndoState()
            DrawingEngine.eraseStrokes(
                in: &document.pages[document.currentPageIndex].strokes,
                at: canvasPt,
                radius: toolState.eraserWidth / 2
            )
            needsDisplay = true
            onNeedsDisplay?()
            return
        }

        saveUndoState()

        currentStroke = Stroke(
            points: [StrokePoint(location: canvasPt, pressure: pressure)],
            color: CodableColor(nsColor: toolState.currentColor),
            lineWidth: toolState.currentLineWidth,
            tool: toolState.currentTool,
            opacity: toolState.currentOpacity
        )
        needsDisplay = true
    }

    func trackpadDidMoveStroke(to point: CGPoint, pressure: CGFloat) {
        guard let toolState = toolState else { return }

        let canvasPt = canvasPoint(from: point)

        if toolState.currentTool == .eraser {
            guard let document = document else { return }
            DrawingEngine.eraseStrokes(
                in: &document.pages[document.currentPageIndex].strokes,
                at: canvasPt,
                radius: toolState.eraserWidth / 2
            )
            needsDisplay = true
            onNeedsDisplay?()
            return
        }

        currentStroke?.points.append(StrokePoint(location: canvasPt, pressure: pressure))
        needsDisplay = true
    }

    func trackpadDidEndStroke(at point: CGPoint, pressure: CGFloat) {
        guard let toolState = toolState else { return }

        let canvasPt = canvasPoint(from: point)

        if toolState.currentTool == .eraser {
            onStrokeCompleted?()
            return
        }

        currentStroke?.points.append(StrokePoint(location: canvasPt, pressure: pressure))

        if let stroke = currentStroke {
            document?.addStroke(stroke)
        }

        currentStroke = nil
        needsDisplay = true
        onStrokeCompleted?()
        onNeedsDisplay?()
    }

    func trackpadDidCancelStroke() {
        currentStroke = nil
        needsDisplay = true
    }

    // MARK: - Undo/Redo

    private func saveUndoState() {
        guard let document = document else { return }
        undoStack.append(document.currentPage.strokes)
        redoStack.removeAll()
    }

    func undo() {
        guard let document = document, let previous = undoStack.popLast() else { return }
        redoStack.append(document.currentPage.strokes)
        document.pages[document.currentPageIndex].strokes = previous
        needsDisplay = true
        onNeedsDisplay?()
    }

    func redo() {
        guard let document = document, let next = redoStack.popLast() else { return }
        undoStack.append(document.currentPage.strokes)
        document.pages[document.currentPageIndex].strokes = next
        needsDisplay = true
        onNeedsDisplay?()
    }

    func resetZoom() {
        zoomScale = 1.0
        panOffset = .zero
        needsDisplay = true
        onNeedsDisplay?()
    }
}

/// SwiftUI wrapper for the trackpad drawing NSView.
struct TrackpadDrawingView: NSViewRepresentable {
    @ObservedObject var document: NotebookDocument
    @ObservedObject var toolState: DrawingToolState
    var onStrokeCompleted: () -> Void

    func makeNSView(context: Context) -> TrackpadDrawingNSView {
        let view = TrackpadDrawingNSView()
        view.document = document
        view.toolState = toolState
        view.onStrokeCompleted = onStrokeCompleted
        view.onNeedsDisplay = { view.needsDisplay = true }
        return view
    }

    func updateNSView(_ nsView: TrackpadDrawingNSView, context: Context) {
        nsView.document = document
        nsView.toolState = toolState
        nsView.onStrokeCompleted = onStrokeCompleted
        nsView.needsDisplay = true
    }
}
