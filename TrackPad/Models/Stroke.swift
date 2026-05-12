import Foundation
import AppKit

/// A single point in a stroke with position, pressure, and timestamp.
struct StrokePoint: Codable, Equatable {
    let x: CGFloat
    let y: CGFloat
    let pressure: CGFloat
    let timestamp: TimeInterval

    var location: CGPoint {
        CGPoint(x: x, y: y)
    }

    init(location: CGPoint, pressure: CGFloat, timestamp: TimeInterval = Date().timeIntervalSince1970) {
        self.x = location.x
        self.y = location.y
        self.pressure = pressure
        self.timestamp = timestamp
    }
}

/// Represents a complete drawn stroke on the canvas.
struct Stroke: Identifiable, Codable, Equatable {
    let id: UUID
    var points: [StrokePoint]
    var color: CodableColor
    var lineWidth: CGFloat
    var tool: DrawingToolType
    var opacity: CGFloat

    init(
        id: UUID = UUID(),
        points: [StrokePoint] = [],
        color: CodableColor = CodableColor(nsColor: .black),
        lineWidth: CGFloat = 2.0,
        tool: DrawingToolType = .pen,
        opacity: CGFloat = 1.0
    ) {
        self.id = id
        self.points = points
        self.color = color
        self.lineWidth = lineWidth
        self.tool = tool
        self.opacity = opacity
    }

    /// Generates a smooth Bezier path from the stroke points with pressure-sensitive width.
    func bezierPath() -> NSBezierPath {
        let path = NSBezierPath()
        guard points.count > 1 else {
            if let point = points.first {
                let r = max(lineWidth * point.pressure / 2, 0.5)
                path.appendOval(in: NSRect(
                    x: point.x - r,
                    y: point.y - r,
                    width: r * 2,
                    height: r * 2
                ))
            }
            return path
        }

        path.move(to: points[0].location)

        if points.count == 2 {
            path.line(to: points[1].location)
            path.lineWidth = lineWidth * ((points[0].pressure + points[1].pressure) / 2)
            return path
        }

        for i in 1..<points.count {
            let prev = points[i - 1]
            let curr = points[i]
            let midPoint = CGPoint(
                x: (prev.x + curr.x) / 2,
                y: (prev.y + curr.y) / 2
            )
            path.curve(to: midPoint, controlPoint1: prev.location, controlPoint2: midPoint)
        }

        if let last = points.last {
            path.line(to: last.location)
        }

        return path
    }

    /// Returns the average pressure for determining line width.
    var averagePressure: CGFloat {
        guard !points.isEmpty else { return 1.0 }
        return points.reduce(0) { $0 + $1.pressure } / CGFloat(points.count)
    }

    /// Returns the bounding rect for hit testing.
    var boundingRect: NSRect {
        guard !points.isEmpty else { return .zero }
        let xs = points.map { $0.x }
        let ys = points.map { $0.y }
        let minX = xs.min()! - lineWidth
        let minY = ys.min()! - lineWidth
        let maxX = xs.max()! + lineWidth
        let maxY = ys.max()! + lineWidth
        return NSRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}

/// A color wrapper that supports Codable.
struct CodableColor: Codable, Equatable {
    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat
    let alpha: CGFloat

    var nsColor: NSColor {
        NSColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    init(nsColor: NSColor) {
        let converted = nsColor.usingColorSpace(.sRGB) ?? nsColor
        self.red = converted.redComponent
        self.green = converted.greenComponent
        self.blue = converted.blueComponent
        self.alpha = converted.alphaComponent
    }

    init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
}
