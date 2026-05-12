import Foundation
import AppKit

/// Represents a complete notebook document containing multiple pages.
class NotebookDocument: ObservableObject, Identifiable, Codable {
    let id: UUID
    @Published var title: String
    @Published var pages: [Page]
    @Published var currentPageIndex: Int
    @Published var dateCreated: Date
    @Published var dateModified: Date

    enum CodingKeys: CodingKey {
        case id, title, pages, currentPageIndex, dateCreated, dateModified
    }

    init(
        id: UUID = UUID(),
        title: String = "Untitled Notebook",
        pages: [Page]? = nil,
        currentPageIndex: Int = 0
    ) {
        self.id = id
        self.title = title
        self.pages = pages ?? [Page()]
        self.currentPageIndex = currentPageIndex
        self.dateCreated = Date()
        self.dateModified = Date()
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        pages = try container.decode([Page].self, forKey: .pages)
        currentPageIndex = try container.decode(Int.self, forKey: .currentPageIndex)
        dateCreated = try container.decode(Date.self, forKey: .dateCreated)
        dateModified = try container.decode(Date.self, forKey: .dateModified)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(pages, forKey: .pages)
        try container.encode(currentPageIndex, forKey: .currentPageIndex)
        try container.encode(dateCreated, forKey: .dateCreated)
        try container.encode(dateModified, forKey: .dateModified)
    }

    var currentPage: Page {
        get { pages[currentPageIndex] }
        set {
            pages[currentPageIndex] = newValue
            dateModified = Date()
        }
    }

    func addPage(after index: Int? = nil) {
        let insertIndex = (index ?? currentPageIndex) + 1
        let newPage = Page(title: "Page \(pages.count + 1)")
        pages.insert(newPage, at: min(insertIndex, pages.count))
        currentPageIndex = min(insertIndex, pages.count - 1)
        dateModified = Date()
    }

    func deletePage(at index: Int) {
        guard pages.count > 1 else { return }
        pages.remove(at: index)
        if currentPageIndex >= pages.count {
            currentPageIndex = pages.count - 1
        }
        dateModified = Date()
    }

    func addStroke(_ stroke: Stroke) {
        pages[currentPageIndex].strokes.append(stroke)
        dateModified = Date()
    }

    func removeLastStroke() {
        guard !pages[currentPageIndex].strokes.isEmpty else { return }
        pages[currentPageIndex].strokes.removeLast()
        dateModified = Date()
    }

    func clearCurrentPage() {
        pages[currentPageIndex].strokes.removeAll()
        dateModified = Date()
    }
}
