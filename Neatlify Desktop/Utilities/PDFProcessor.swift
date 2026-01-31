//
//  PDFProcessor.swift
//  Neatlify
//
//  PDF text extraction and rendering for Claude API
//

import Foundation
import PDFKit
import AppKit

class PDFProcessor {
    // Extract text from PDF (for text-based PDFs)
    static func extractText(from url: URL, maxPages: Int = 10) -> String? {
        guard let document = PDFDocument(url: url) else {
            return nil
        }

        let pageCount = min(document.pageCount, maxPages)
        var fullText = ""

        for i in 0..<pageCount {
            guard let page = document.page(at: i),
                  let pageText = page.string else {
                continue
            }
            fullText += pageText + "\n\n"
        }

        return fullText.isEmpty ? nil : fullText
    }

    // Render PDF page as image (for scanned PDFs)
    static func renderAsImage(from url: URL, page pageIndex: Int = 0) throws -> Data? {
        guard let document = PDFDocument(url: url),
              pageIndex < document.pageCount,
              let page = document.page(at: pageIndex) else {
            throw ProcessingError.invalidPDF
        }

        let pageBounds = page.bounds(for: .mediaBox)

        // Scale to reasonable size (max 1024px width)
        let scale: CGFloat = min(1024 / pageBounds.width, 2.0)
        let scaledSize = NSSize(
            width: pageBounds.width * scale,
            height: pageBounds.height * scale
        )

        let image = NSImage(size: scaledSize)
        image.lockFocus()

        NSGraphicsContext.current?.imageInterpolation = .high

        // Fill with white background
        NSColor.white.setFill()
        NSRect(origin: .zero, size: scaledSize).fill()

        // Transform and render PDF page
        if let context = NSGraphicsContext.current?.cgContext {
            context.scaleBy(x: scale, y: scale)
            page.draw(with: .mediaBox, to: context)
        }

        image.unlockFocus()

        // Convert to JPEG data
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.8]) else {
            throw ProcessingError.renderingFailed
        }

        return jpegData
    }

    // Detect if PDF is text-based or image-based
    static func isTextBased(url: URL) -> Bool {
        guard let document = PDFDocument(url: url),
              let firstPage = document.page(at: 0),
              let text = firstPage.string else {
            return false
        }

        // If text content is more than 50 characters, consider it text-based
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleanText.count > 50
    }

    // Get PDF page count
    static func getPageCount(url: URL) -> Int {
        guard let document = PDFDocument(url: url) else {
            return 0
        }
        return document.pageCount
    }

    // Extract text from all pages and encode as JSON for Claude
    static func prepareForAnalysis(url: URL, maxPages: Int = 10) -> String? {
        if isTextBased(url: url) {
            return extractText(from: url, maxPages: maxPages)
        }
        return nil
    }

    enum ProcessingError: LocalizedError {
        case invalidPDF
        case renderingFailed
        case extractionFailed

        var errorDescription: String? {
            switch self {
            case .invalidPDF:
                return "Unable to load PDF file"
            case .renderingFailed:
                return "Failed to render PDF as image"
            case .extractionFailed:
                return "Failed to extract text from PDF"
            }
        }
    }
}
