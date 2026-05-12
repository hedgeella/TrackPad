import Foundation
import AppKit

/// Delegate protocol for receiving trackpad drawing input.
protocol TrackpadInputDelegate: AnyObject {
    func trackpadDidBeginStroke(at point: CGPoint, pressure: CGFloat)
    func trackpadDidMoveStroke(to point: CGPoint, pressure: CGFloat)
    func trackpadDidEndStroke(at point: CGPoint, pressure: CGFloat)
    func trackpadDidCancelStroke()
}

/// Handles trackpad input and converts touch events into drawing coordinates.
///
/// Uses NSEvent's pressure API and multi-touch tracking to enable
/// the trackpad to function as a pressure-sensitive drawing surface.
/// The trackpad area is mapped to the visible canvas region.
class TrackpadInputHandler {
    weak var delegate: TrackpadInputDelegate?

    /// Whether drawing mode is active (trackpad acts as drawing tablet).
    var isDrawingModeActive: Bool = true

    /// The canvas size to map trackpad coordinates onto.
    var canvasSize: CGSize = Page.defaultSize

    /// The visible rect of the canvas (for mapping coordinates).
    var visibleCanvasRect: CGRect = CGRect(origin: .zero, size: Page.defaultSize)

    /// Minimum distance between points to register a new point (reduces noise).
    var minimumPointDistance: CGFloat = 1.0

    /// Last recorded point for distance filtering.
    private var lastPoint: CGPoint?

    /// Whether a stroke is currently in progress.
    private(set) var isStrokeInProgress: Bool = false

    /// Processes an NSEvent for trackpad pressure drawing.
    func handleMouseDown(_ event: NSEvent, in view: NSView) {
        guard isDrawingModeActive else { return }

        let locationInView = view.convert(event.locationInWindow, from: nil)
        let pressure = extractPressure(from: event)

        lastPoint = locationInView
        isStrokeInProgress = true
        delegate?.trackpadDidBeginStroke(at: locationInView, pressure: pressure)
    }

    func handleMouseDragged(_ event: NSEvent, in view: NSView) {
        guard isDrawingModeActive, isStrokeInProgress else { return }

        let locationInView = view.convert(event.locationInWindow, from: nil)
        let pressure = extractPressure(from: event)

        if let last = lastPoint {
            let dx = locationInView.x - last.x
            let dy = locationInView.y - last.y
            let distance = sqrt(dx * dx + dy * dy)
            guard distance >= minimumPointDistance else { return }
        }

        lastPoint = locationInView
        delegate?.trackpadDidMoveStroke(to: locationInView, pressure: pressure)
    }

    func handleMouseUp(_ event: NSEvent, in view: NSView) {
        guard isDrawingModeActive, isStrokeInProgress else { return }

        let locationInView = view.convert(event.locationInWindow, from: nil)
        let pressure = extractPressure(from: event)

        isStrokeInProgress = false
        lastPoint = nil
        delegate?.trackpadDidEndStroke(at: locationInView, pressure: pressure)
    }

    /// Processes trackpad pressure events for force-sensitive drawing.
    func handlePressureChange(_ event: NSEvent, in view: NSView) {
        guard isDrawingModeActive, isStrokeInProgress else { return }
        // Pressure change events update the current stroke's pressure dynamically.
        // The pressure value is already captured in mouse events on Force Touch trackpads.
    }

    /// Extracts pressure from the event, falling back to a default for non-Force Touch.
    private func extractPressure(from event: NSEvent) -> CGFloat {
        // NSEvent.pressure works with Force Touch trackpads (2015+).
        // Returns 0.0-1.0 for stage 1, and can go up to ~1.0+ for stage 2.
        let rawPressure = CGFloat(event.pressure)

        if rawPressure > 0 {
            // Normalize: use a curve so light touch still draws visibly
            return max(0.2, min(rawPressure, 1.0))
        }

        // Fallback for trackpads without Force Touch
        return 0.5
    }

    /// Maps a point from trackpad coordinates to canvas coordinates.
    func mapToCanvas(_ point: CGPoint, viewSize: CGSize) -> CGPoint {
        let scaleX = visibleCanvasRect.width / viewSize.width
        let scaleY = visibleCanvasRect.height / viewSize.height

        return CGPoint(
            x: visibleCanvasRect.origin.x + point.x * scaleX,
            y: visibleCanvasRect.origin.y + point.y * scaleY
        )
    }

    func cancelStroke() {
        isStrokeInProgress = false
        lastPoint = nil
        delegate?.trackpadDidCancelStroke()
    }
}
