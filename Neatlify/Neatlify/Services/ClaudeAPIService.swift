//
//  ClaudeAPIService.swift
//  Neatlify
//
//  Claude API client for chat and vision analysis
//

import Foundation

class ClaudeAPIService {
    private let apiKey: String
    private let baseURL = "https://api.anthropic.com/v1/messages"
    private let model = "claude-3-5-sonnet-20241022"
    private let apiVersion = "2023-06-01"

    init(apiKey: String = APIKeyManager.getAPIKey()) {
        self.apiKey = apiKey
    }

    // MARK: - Chat Methods

    // Send chat message to Claude
    func sendMessage(_ message: String, conversationHistory: [ChatMessage] = []) async throws -> String {
        let messages = buildMessages(from: conversationHistory, newMessage: message)

        let request = ClaudeRequest(
            model: model,
            maxTokens: 4096,
            messages: messages
        )

        let response = try await makeRequest(request)
        Logger.shared.logAPICall("sendMessage", tokensUsed: response.usage.outputTokens)

        return response.content.first?.text ?? ""
    }

    // Parse user intent for organization
    func parseIntent(_ message: String) async throws -> OrganizationIntent {
        let intentPrompt = """
        Extract the categorization intent from this user request: "\(message)"

        Return ONLY valid JSON with this exact structure (no additional text):
        {
          "folder": "path or folder name",
          "criteria": "what to organize by",
          "suggested_categories": ["category1", "category2", "category3", "category4", "category5"]
        }

        Examples:
        - "organize my vacation photos by location" → {"folder": "Photos", "criteria": "location", "suggested_categories": ["Paris", "Tokyo", "Beach", "Mountains", "City", "Nature"]}
        - "sort downloads by construction trade" → {"folder": "Downloads", "criteria": "construction trade", "suggested_categories": ["electrician", "carpenter", "plumber", "hvac", "concrete", "roofing", "uncategorized"]}
        - "group design files by client" → {"folder": "Design", "criteria": "client", "suggested_categories": ["ClientA", "ClientB", "ClientC", "Personal", "Archive"]}

        IMPORTANT: Return ONLY the JSON object, no markdown formatting or additional text.
        """

        let response = try await sendMessage(intentPrompt)

        // Clean up response - remove markdown code blocks if present
        var cleanedResponse = response
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        Logger.shared.debug("Intent parsing response: \(cleanedResponse)")

        guard let data = cleanedResponse.data(using: .utf8),
              let intent = try? JSONDecoder().decode(OrganizationIntent.self, from: data) else {
            throw APIError.invalidResponse
        }

        return intent
    }

    // MARK: - Vision Methods

    // Analyze single image with Claude Vision
    func analyzeImage(_ imageData: String, prompt: String) async throws -> String {
        let messages = [
            ClaudeMessage(
                role: "user",
                content: [
                    .image(source: ImageSource(type: "base64", mediaType: "image/jpeg", data: imageData)),
                    .text(prompt)
                ]
            )
        ]

        let request = ClaudeRequest(
            model: model,
            maxTokens: 4096,
            messages: messages
        )

        let response = try await makeRequest(request)
        Logger.shared.logAPICall("analyzeImage", tokensUsed: response.usage.outputTokens)

        return response.content.first?.text ?? ""
    }

    // Batch analyze multiple images
    func analyzeImages(_ images: [(filename: String, base64: String)], criteria: String, categories: [String]) async throws -> [String: String] {
        let categoriesList = categories.joined(separator: ", ")

        let prompt = """
        Categorize these images according to: \(criteria)

        Available categories: \(categoriesList)

        For each image, analyze the content and assign the most appropriate category.
        If uncertain, use "uncategorized".

        Return ONLY valid JSON with this structure (no additional text):
        {
          "filename1.jpg": "category",
          "filename2.png": "category"
        }

        IMPORTANT: Return ONLY the JSON object, no markdown formatting or additional text.
        """

        // Build content array with all images and the prompt
        var contentItems: [ContentItem] = []

        for (filename, base64) in images {
            contentItems.append(.image(source: ImageSource(type: "base64", mediaType: "image/jpeg", data: base64)))
            contentItems.append(.text("Filename: \(filename)"))
        }

        contentItems.append(.text(prompt))

        let messages = [
            ClaudeMessage(role: "user", content: contentItems)
        ]

        let request = ClaudeRequest(
            model: model,
            maxTokens: 4096,
            messages: messages
        )

        let response = try await makeRequest(request)
        Logger.shared.logAPICall("analyzeImages", tokensUsed: response.usage.outputTokens)

        guard let responseText = response.content.first?.text else {
            throw APIError.invalidResponse
        }

        // Clean up response
        let cleanedResponse = responseText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        Logger.shared.debug("Image analysis response: \(cleanedResponse)")

        guard let data = cleanedResponse.data(using: .utf8),
              let result = try? JSONDecoder().decode([String: String].self, from: data) else {
            throw APIError.invalidResponse
        }

        return result
    }

    // Analyze text content (for PDFs)
    func analyzeText(_ texts: [(filename: String, content: String)], criteria: String, categories: [String]) async throws -> [String: String] {
        let categoriesList = categories.joined(separator: ", ")

        var filesDescription = ""
        for (filename, content) in texts {
            let preview = String(content.prefix(500)) // Limit to first 500 chars per file
            filesDescription += "\n\nFile: \(filename)\nContent: \(preview)"
        }

        let prompt = """
        Categorize these documents according to: \(criteria)

        Available categories: \(categoriesList)

        Files to categorize:
        \(filesDescription)

        For each file, analyze the content and assign the most appropriate category.
        If uncertain, use "uncategorized".

        Return ONLY valid JSON with this structure (no additional text):
        {
          "filename1.pdf": "category",
          "filename2.pdf": "category"
        }

        IMPORTANT: Return ONLY the JSON object, no markdown formatting or additional text.
        """

        let response = try await sendMessage(prompt)

        // Clean up response
        let cleanedResponse = response
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        Logger.shared.debug("Text analysis response: \(cleanedResponse)")

        guard let data = cleanedResponse.data(using: .utf8),
              let result = try? JSONDecoder().decode([String: String].self, from: data) else {
            throw APIError.invalidResponse
        }

        return result
    }

    // MARK: - Private Methods

    private func buildMessages(from history: [ChatMessage], newMessage: String) -> [ClaudeMessage] {
        var messages: [ClaudeMessage] = []

        // Add conversation history
        for message in history {
            messages.append(ClaudeMessage(
                role: message.role == .user ? "user" : "assistant",
                content: [.text(message.content)]
            ))
        }

        // Add new message
        messages.append(ClaudeMessage(
            role: "user",
            content: [.text(newMessage)]
        ))

        return messages
    }

    private func makeRequest(_ request: ClaudeRequest) async throws -> ClaudeResponse {
        guard let url = URL(string: baseURL) else {
            throw APIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        urlRequest.setValue("application/json", forHTTPHeaderField: "content-type")

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        urlRequest.httpBody = try encoder.encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            Logger.shared.error("API Error: Status \(httpResponse.statusCode)")
            if let errorBody = String(data: data, encoding: .utf8) {
                Logger.shared.error("Error body: \(errorBody)")
            }
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        do {
            let response = try decoder.decode(ClaudeResponse.self, from: data)
            return response
        } catch {
            Logger.shared.error("Decoding error", error: error)
            if let responseString = String(data: data, encoding: .utf8) {
                Logger.shared.debug("Response data: \(responseString)")
            }
            throw APIError.decodingError(error)
        }
    }

    // MARK: - Data Structures

    private struct ClaudeRequest: Codable {
        let model: String
        let maxTokens: Int
        let messages: [ClaudeMessage]
    }

    private struct ClaudeMessage: Codable {
        let role: String
        let content: [ContentItem]
    }

    private enum ContentItem: Codable {
        case text(String)
        case image(source: ImageSource)

        enum CodingKeys: String, CodingKey {
            case type
            case text
            case source
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)

            switch type {
            case "text":
                let text = try container.decode(String.self, forKey: .text)
                self = .text(text)
            case "image":
                let source = try container.decode(ImageSource.self, forKey: .source)
                self = .image(source: source)
            default:
                throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown content type")
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            switch self {
            case .text(let text):
                try container.encode("text", forKey: .type)
                try container.encode(text, forKey: .text)
            case .image(let source):
                try container.encode("image", forKey: .type)
                try container.encode(source, forKey: .source)
            }
        }
    }

    private struct ImageSource: Codable {
        let type: String
        let mediaType: String
        let data: String
    }

    private struct ClaudeResponse: Codable {
        let id: String
        let type: String
        let role: String
        let content: [ResponseContent]
        let model: String
        let stopReason: String?
        let usage: Usage

        struct ResponseContent: Codable {
            let type: String
            let text: String?
        }

        struct Usage: Codable {
            let inputTokens: Int
            let outputTokens: Int
        }
    }

    // MARK: - Errors

    enum APIError: LocalizedError {
        case invalidURL
        case invalidResponse
        case httpError(statusCode: Int)
        case decodingError(Error)

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid API URL"
            case .invalidResponse:
                return "Invalid response from Claude API"
            case .httpError(let statusCode):
                return "HTTP error: \(statusCode)"
            case .decodingError(let error):
                return "Failed to decode response: \(error.localizedDescription)"
            }
        }
    }
}
