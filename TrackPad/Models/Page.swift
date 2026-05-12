import Foundation
import AppKit

/// Represents a single page in a notebook.
struct Page: Identifiable, Codable, Equatable {
    let id: UUID
    var strokes: [Stroke]
    var backgroundStyle: BackgroundStyle
    var title: String

    init(
        id: UUID = UUID(),
        strokes: [Stroke] = [],
        backgroundStyle: BackgroundStyle = .blank,
        title: String = "Untitled Page"
    ) {
        self.id = id
        self.strokes = strokes
        self.backgroundStyle = backgroundStyle
        self.title = title
    }

    static let defaultSize = CGSize(width: 800, height: 1100)
}

/// Background styles for a page.
enum BackgroundStyle: String, Codable, CaseIterable, Identifiable {
    case blank
    case lined
    case grid
    case dotGrid

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .blank: return "Blank"
        case .lined: return "Lined"
        case .grid: return "Grid"
        case .dotGrid: return "Dot Grid"
        }
    }

    var iconName: String {
        switch self {
        case .blank: return "doc"
        case .lined: return "text.alignleft"
        case .grid: return "grid"
        case .dotGrid: return "circle.grid.3x3"
        }
    }
}
