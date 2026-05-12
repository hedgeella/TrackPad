import Foundation
import AppKit
import UniformTypeIdentifiers

/// Handles exporting pages and documents as PDF or PNG.
class ExportManager {

    /// Exports a single page as a PDF.
    static func exportPageAsPDF(_ page: Page, size: CGSize) -> Data? {
        let pdfData = NSMutableData()
        var mediaBox = CGRect(origin: .zero, size: size)

        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            return nil
        }

        context.beginPage(mediaBox: &mediaBox)
        DrawingEngine.render(page: page, in: context, size: size)
        context.endPage()
        context.closePDF()

        return pdfData as Data
    }

    /// Exports all pages of a document as a single multi-page PDF.
    static func exportDocumentAsPDF(_ document: NotebookDocument, size: CGSize) -> Data? {
        let pdfData = NSMutableData()
        var mediaBox = CGRect(origin: .zero, size: size)

        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            return nil
        }

        for page in document.pages {
            context.beginPage(mediaBox: &mediaBox)
            DrawingEngine.render(page: page, in: context, size: size)
            context.endPage()
        }

        context.closePDF()
        return pdfData as Data
    }

    /// Exports a single page as a PNG image.
    static func exportPageAsPNG(_ page: Page, size: CGSize, scale: CGFloat = 2.0) -> Data? {
        let scaledSize = CGSize(width: size.width * scale, height: size.height * scale)

        guard let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(scaledSize.width),
            pixelsHigh: Int(scaledSize.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .calibratedRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else { return nil }

        let nsContext = NSGraphicsContext(bitmapImageRep: bitmapRep)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = nsContext

        guard let cgContext = nsContext?.cgContext else {
            NSGraphicsContext.restoreGraphicsState()
            return nil
        }

        cgContext.scaleBy(x: scale, y: scale)
        DrawingEngine.render(page: page, in: cgContext, size: size)

        NSGraphicsContext.restoreGraphicsState()

        return bitmapRep.representation(using: .png, properties: [:])
    }

    /// Presents a save panel and exports the document.
    static func showExportDialog(for document: NotebookDocument) {
        let panel = NSSavePanel()
        panel.title = "Export Notebook"
        panel.nameFieldStringValue = "\(document.title)"
        panel.allowedContentTypes = [.pdf, .png]
        panel.canCreateDirectories = true

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }

            let pageSize = Page.defaultSize

            if url.pathExtension.lowercased() == "pdf" {
                if let data = exportDocumentAsPDF(document, size: pageSize) {
                    try? data.write(to: url)
                }
            } else if url.pathExtension.lowercased() == "png" {
                if let data = exportPageAsPNG(document.currentPage, size: pageSize) {
                    try? data.write(to: url)
                }
            }
        }
    }
}
