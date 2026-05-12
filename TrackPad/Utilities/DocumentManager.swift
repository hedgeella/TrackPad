import Foundation
import AppKit

/// Manages saving and loading notebook documents to/from disk.
class DocumentManager: ObservableObject {
    @Published var recentDocuments: [DocumentMetadata] = []

    private let fileManager = FileManager.default

    /// Directory where documents are stored.
    var documentsDirectory: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let docsDir = appSupport.appendingPathComponent("TrackPad/Documents", isDirectory: true)
        try? fileManager.createDirectory(at: docsDir, withIntermediateDirectories: true)
        return docsDir
    }

    /// Saves a document to disk.
    func save(_ document: NotebookDocument) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted

        let data = try encoder.encode(document)
        let fileURL = documentsDirectory.appendingPathComponent("\(document.id.uuidString).trackpad")
        try data.write(to: fileURL)

        updateRecentDocuments()
    }

    /// Loads a document from disk.
    func load(id: UUID) throws -> NotebookDocument {
        let fileURL = documentsDirectory.appendingPathComponent("\(id.uuidString).trackpad")
        let data = try Data(contentsOf: fileURL)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode(NotebookDocument.self, from: data)
    }

    /// Lists all saved documents.
    func listDocuments() -> [DocumentMetadata] {
        guard let files = try? fileManager.contentsOfDirectory(
            at: documentsDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        return files
            .filter { $0.pathExtension == "trackpad" }
            .compactMap { url -> DocumentMetadata? in
                guard let data = try? Data(contentsOf: url),
                      let doc = try? JSONDecoder().decode(NotebookDocument.self, from: data) else {
                    return nil
                }
                let attrs = try? fileManager.attributesOfItem(atPath: url.path)
                let modDate = attrs?[.modificationDate] as? Date ?? Date()

                return DocumentMetadata(
                    id: doc.id,
                    title: doc.title,
                    pageCount: doc.pages.count,
                    dateModified: modDate
                )
            }
            .sorted { $0.dateModified > $1.dateModified }
    }

    /// Deletes a document from disk.
    func delete(id: UUID) throws {
        let fileURL = documentsDirectory.appendingPathComponent("\(id.uuidString).trackpad")
        try fileManager.removeItem(at: fileURL)
        updateRecentDocuments()
    }

    /// Presents an open panel to import a document.
    func showOpenDialog() -> NotebookDocument? {
        let panel = NSOpenPanel()
        panel.title = "Open Notebook"
        panel.allowedContentTypes = [.init(filenameExtension: "trackpad")!]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let url = panel.url else { return nil }

        guard let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(NotebookDocument.self, from: data)
    }

    private func updateRecentDocuments() {
        recentDocuments = listDocuments()
    }

    init() {
        updateRecentDocuments()
    }
}

/// Lightweight metadata for listing documents.
struct DocumentMetadata: Identifiable {
    let id: UUID
    let title: String
    let pageCount: Int
    let dateModified: Date

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: dateModified)
    }
}
