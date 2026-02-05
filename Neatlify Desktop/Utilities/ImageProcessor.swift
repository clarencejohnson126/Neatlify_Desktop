//
//  ImageProcessor.swift
//  Neatlify
//
//  Image encoding and processing for Claude API
//

import Foundation
import AppKit

class ImageProcessor {
    // Maximum image width to reduce token usage
    static let maxImageWidth: CGFloat = 1024

    // Encode image to base64 for Claude API
    static func encodeImage(at url: URL) throws -> String {
        guard let image = NSImage(contentsOf: url) else {
            throw ProcessingError.invalidImage
        }

        // Resize if needed to reduce token usage
        let resizedImage = resize(image: image, maxWidth: maxImageWidth)

        // Convert to JPEG data (smaller than PNG)
        guard let tiffData = resizedImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.8]) else {
            throw ProcessingError.encodingFailed
        }

        return jpegData.base64EncodedString()
    }

    // Encode multiple images in batch, handling individual failures gracefully
    static func encodeImages(at urls: [URL]) async throws -> [(url: URL, base64: String)] {
        var encodedImages: [(url: URL, base64: String)] = []
        var failedImages: [String] = []

        await withTaskGroup(of: (URL, String?, String?).self) { group in
            for url in urls {
                group.addTask {
                    do {
                        let encoded = try encodeImage(at: url)
                        return (url, encoded, nil)
                    } catch {
                        Logger.shared.error("Failed to encode \(url.lastPathComponent): \(error)")
                        return (url, nil, url.lastPathComponent)
                    }
                }
            }

            for await result in group {
                let (url, encoded, failed) = result
                if let encoded = encoded {
                    encodedImages.append((url: url, base64: encoded))
                } else if let failed = failed {
                    failedImages.append(failed)
                }
            }
        }

        if !failedImages.isEmpty {
            Logger.shared.warning("\(failedImages.count) images failed encoding: \(failedImages.joined(separator: ", "))")
        }

        return encodedImages
    }

    // Resize image to reduce token usage
    private static func resize(image: NSImage, maxWidth: CGFloat) -> NSImage {
        let originalSize = image.size

        // If already smaller, return original
        if originalSize.width <= maxWidth {
            return image
        }

        // Calculate new size maintaining aspect ratio
        let scale = maxWidth / originalSize.width
        let newSize = NSSize(width: maxWidth, height: originalSize.height * scale)

        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: newSize),
                   from: NSRect(origin: .zero, size: originalSize),
                   operation: .copy,
                   fraction: 1.0)
        newImage.unlockFocus()

        return newImage
    }

    // Get image dimensions without fully loading
    static func getImageSize(at url: URL) -> NSSize? {
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? CGFloat,
              let height = properties[kCGImagePropertyPixelHeight] as? CGFloat else {
            return nil
        }
        return NSSize(width: width, height: height)
    }

    enum ProcessingError: LocalizedError {
        case invalidImage
        case encodingFailed
        case unsupportedFormat

        var errorDescription: String? {
            switch self {
            case .invalidImage:
                return "Unable to load image file"
            case .encodingFailed:
                return "Failed to encode image"
            case .unsupportedFormat:
                return "Unsupported image format"
            }
        }
    }
}
