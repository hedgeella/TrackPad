import Foundation
import AppKit

/// Core drawing engine that manages rendering strokes onto the canvas.
class DrawingEngine {

    /// Renders all strokes for a page onto the given graphics context.
    static func render(page: Page, in context: CGContext, size: CGSize) {
        renderBackground(style: page.backgroundStyle, in: context, size: size)

        NSGraphicsContext.saveGraphicsState()
        let nsContext = NSGraphicsContext(cgContext: context, flipped: false)
        NSGraphicsContext.current = nsContext

        for stroke in page.strokes {
            renderStroke(stroke)
        }

        NSGraphicsContext.restoreGraphicsState()
    }

    /// Renders a single stroke using NSBezierPath.
    static func renderStroke(_ stroke: Stroke) {
        guard !stroke.points.isEmpty else { return }

        let color = stroke.color.nsColor.withAlphaComponent(stroke.opacity)
        color.setStroke()
        color.setFill()

        if stroke.points.count == 1 {
            let point = stroke.points[0]
            let r = max(stroke.lineWidth * point.pressure / 2, 0.5)
            let rect = NSRect(x: point.x - r, y: point.y - r, width: r * 2, height: r * 2)
            let dot = NSBezierPath(ovalIn: rect)
            dot.fill()
            return
        }

        drawVariableWidthStroke(stroke)
    }

    /// Draws a stroke with variable width based on pressure at each point.
    private static func drawVariableWidthStroke(_ stroke: Stroke) {
        let points = stroke.points
        guard points.count >= 2 else { return }

        for i in 0..<(points.count - 1) {
            let p0 = points[i]
            let p1 = points[i + 1]

            let avgPressure = (p0.pressure + p1.pressure) / 2.0
            let width = max(stroke.lineWidth * avgPressure, 0.5)

            let segmentPath = NSBezierPath()
            segmentPath.move(to: p0.location)

            if i + 2 < points.count {
                let p2 = points[i + 1]
                let midPoint = CGPoint(
                    x: (p1.x + p2.x) / 2,
                    y: (p1.y + p2.y) / 2
                )
                segmentPath.curve(to: midPoint, controlPoint1: p1.location, controlPoint2: midPoint)
            } else {
                segmentPath.line(to: p1.location)
            }

            segmentPath.lineWidth = width
            segmentPath.lineCapStyle = .round
            segmentPath.lineJoinStyle = .round
            segmentPath.stroke()
        }
    }

    /// Renders the page background pattern.
    static func renderBackground(style: BackgroundStyle, in context: CGContext, size: CGSize) {
        context.setFillColor(NSColor.white.cgColor)
        context.fill(CGRect(origin: .zero, size: size))

        let lineColor = NSColor.systemGray.withAlphaComponent(0.3).cgColor
        context.setStrokeColor(lineColor)
        context.setLineWidth(0.5)

        switch style {
        case .blank:
            break

        case .lined:
            let spacing: CGFloat = 28
            var y = spacing * 3
            while y < size.height {
                context.move(to: CGPoint(x: 40, y: y))
                context.addLine(to: CGPoint(x: size.width - 40, y: y))
                y += spacing
            }
            context.strokePath()

            // Red margin line
            context.setStrokeColor(NSColor.systemRed.withAlphaComponent(0.3).cgColor)
            context.setLineWidth(1.0)
            context.move(to: CGPoint(x: 72, y: 0))
            context.addLine(to: CGPoint(x: 72, y: size.height))
            context.strokePath()

        case .grid:
            let spacing: CGFloat = 24
            var x: CGFloat = spacing
            while x < size.width {
                context.move(to: CGPoint(x: x, y: 0))
                context.addLine(to: CGPoint(x: x, y: size.height))
                x += spacing
            }
            var y: CGFloat = spacing
            while y < size.height {
                context.move(to: CGPoint(x: 0, y: y))
                context.addLine(to: CGPoint(x: size.width, y: y))
                y += spacing
            }
            context.strokePath()

        case .dotGrid:
            let spacing: CGFloat = 24
            let dotRadius: CGFloat = 1.5
            context.setFillColor(lineColor)
            var x: CGFloat = spacing
            while x < size.width {
                var y: CGFloat = spacing
                while y < size.height {
                    context.fillEllipse(in: CGRect(
                        x: x - dotRadius,
                        y: y - dotRadius,
                        width: dotRadius * 2,
                        height: dotRadius * 2
                    ))
                    y += spacing
                }
                x += spacing
            }
        }
    }

    /// Generates a thumbnail image of a page.
    static func generateThumbnail(for page: Page, size: CGSize, targetSize: CGSize) -> NSImage {
        let image = NSImage(size: targetSize)
        image.lockFocus()

        guard let context = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return image
        }

        let scaleX = targetSize.width / size.width
        let scaleY = targetSize.height / size.height
        let scale = min(scaleX, scaleY)
        context.scaleBy(x: scale, y: scale)

        render(page: page, in: context, size: size)

        image.unlockFocus()
        return image
    }

    /// Performs erasing — removes strokes that intersect with the eraser path.
    static func eraseStrokes(in strokes: inout [Stroke], at point: CGPoint, radius: CGFloat) {
        strokes.removeAll { stroke in
            stroke.points.contains { strokePoint in
                let dx = strokePoint.x - point.x
                let dy = strokePoint.y - point.y
                return sqrt(dx * dx + dy * dy) < radius
            }
        }
    }
}
