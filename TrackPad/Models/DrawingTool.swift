import Foundation
import AppKit

/// The types of drawing tools available.
enum DrawingToolType: String, Codable, CaseIterable, Identifiable {
    case pen
    case highlighter
    case eraser
    case lasso

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pen: return "Pen"
        case .highlighter: return "Highlighter"
        case .eraser: return "Eraser"
        case .lasso: return "Lasso"
        }
    }

    var iconName: String {
        switch self {
        case .pen: return "pencil"
        case .highlighter: return "highlighter"
        case .eraser: return "eraser"
        case .lasso: return "lasso"
        }
    }

    var defaultLineWidth: CGFloat {
        switch self {
        case .pen: return 2.0
        case .highlighter: return 15.0
        case .eraser: return 20.0
        case .lasso: return 1.0
        }
    }

    var defaultOpacity: CGFloat {
        switch self {
        case .pen: return 1.0
        case .highlighter: return 0.3
        case .eraser: return 1.0
        case .lasso: return 0.5
        }
    }
}

/// Represents the current state of a drawing tool with its settings.
class DrawingToolState: ObservableObject {
    @Published var currentTool: DrawingToolType = .pen
    @Published var penColor: NSColor = .black
    @Published var highlighterColor: NSColor = .yellow
    @Published var lineWidth: CGFloat = 2.0
    @Published var eraserWidth: CGFloat = 20.0

    /// Preset colors available for quick selection.
    static let presetColors: [NSColor] = [
        .black, .darkGray, .gray,
        .systemRed, .systemOrange, .systemYellow,
        .systemGreen, .systemTeal, .systemBlue,
        .systemIndigo, .systemPurple, .systemPink,
        .white
    ]

    /// Preset line widths.
    static let presetLineWidths: [CGFloat] = [1, 2, 3, 5, 8, 12]

    var currentColor: NSColor {
        switch currentTool {
        case .pen: return penColor
        case .highlighter: return highlighterColor
        case .eraser: return .white
        case .lasso: return .systemBlue
        }
    }

    var currentLineWidth: CGFloat {
        switch currentTool {
        case .eraser: return eraserWidth
        default: return lineWidth
        }
    }

    var currentOpacity: CGFloat {
        currentTool.defaultOpacity
    }
}
