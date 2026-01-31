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
    private let model = "claude-sonnet-4-20250514"
    private let apiVersion = "2023-06-01"

    init(apiKey: String = APIKeyManager.getAPIKey()) {
        self.apiKey = apiKey
    }

    // System prompt for chat - tells Claude it's inside the Neatlify app
    private let chatSystemPrompt = """
    You are the AI assistant inside Neatlify, a macOS desktop application for organizing files.

    IMPORTANT: You ARE part of a desktop app that CAN access and organize files on the user's Mac.
    When users ask to organize, sort, move, rename, or categorize files, you SHOULD help them.

    How it works:
    1. User describes what they want to organize (e.g., "organize my Downloads by file type")
    2. You confirm and the app will ask them to select a folder
    3. The app scans files, uses AI vision to analyze images/PDFs
    4. Files are moved into categorized subfolders

    For organization requests, respond enthusiastically and confirm what you'll do.
    Guide users to be specific about:
    - Which folder to organize
    - How to categorize (by type, date, content, project, client, etc.)

    You can help with:
    - Organizing files by type, date, content, or custom criteria
    - Analyzing images to categorize them (construction trades, projects, etc.)
    - Reading PDFs to sort documents by topic or client
    - Any file organization task

    Keep responses concise and action-oriented. This is a productivity app.
    """

    // MARK: - Chat Methods

    // Send chat message to Claude
    func sendMessage(_ message: String, conversationHistory: [ChatMessage] = []) async throws -> String {
        let messages = buildMessages(from: conversationHistory, newMessage: message)

        let request = ClaudeRequestWithSystem(
            model: model,
            maxTokens: 4096,
            system: chatSystemPrompt,
            messages: messages
        )

        let response = try await makeRequestWithSystem(request)
        Logger.shared.logAPICall("sendMessage", tokensUsed: response.usage.outputTokens)

        return response.content.first?.text ?? ""
    }

    // MARK: - Agent SDK Pattern for Intent Parsing

    // Parse user intent using structured outputs (Agent SDK pattern)
    func parseIntent(_ message: String) async throws -> OrganizationIntent {
        let systemPrompt = """
        You are an expert file organization assistant for a macOS app called Neatlify.

        Your job is to extract the user's intent for organizing files and suggest optimal categories.

        The app CAN access and organize files on the user's Mac. You are part of the application.

        Always extract:
        1. Which folder to organize (Desktop, Downloads, Documents, or a custom path)
        2. What criteria to organize by (file type, date, project, client, topic, etc.)
        3. Suggested categories based on what the user wants

        CRITICAL - Be smart about number of categories:

        SINGLE FOLDER REQUEST (return ONLY 1 category, NO "other"):
        - If user says "put all X files in a folder called Y" → return ONLY ["Y"]
        - If user says "move these into Y" → return ONLY ["Y"]
        - If user says "organize into Y folder" → return ONLY ["Y"]
        - If user specifies an explicit single destination folder name, use ONLY that name
        - Do NOT add "other" or "uncategorized" when user wants a single folder

        MULTI-CATEGORY REQUEST (return 5-8 categories including "other"):
        - If user says "organize by file type" → return ["images", "documents", "videos", "archives", "other"]
        - If user says "sort by construction trade" → return ["electrician", "plumber", "carpenter", "hvac", "other"]
        - If user says "categorize by client" → return ["Client A", "Client B", "other"]
        - Only include "other" as fallback when doing multi-category organization

        Examples:
        - "Put all screenshots in Screenshots Final" → criteria: "single folder", categories: ["Screenshots Final"]
        - "Move these photos into My Photos" → criteria: "single folder", categories: ["My Photos"]
        - "Organize by file type" → criteria: "file type", categories: ["images", "documents", "videos", "archives", "other"]
        """

        let tool = IntentExtractionTool(
            name: "extract_organization_intent",
            description: "Extract the user's file organization intent including folder, criteria, and suggested categories",
            inputSchema: IntentExtractionInput.schema
        )

        let request = ClaudeToolRequest(
            model: model,
            maxTokens: 1024,
            system: systemPrompt,
            messages: [
                ClaudeMessage(role: "user", content: [.text(message)])
            ],
            tools: [tool],
            toolChoice: ClaudeToolRequest.ToolChoice(type: "tool", name: "extract_organization_intent")
        )

        let response = try await makeToolRequest(request)

        // Log all content for debugging
        Logger.shared.debug("API Response content count: \(response.content.count)")
        for (index, content) in response.content.enumerated() {
            switch content {
            case .text(let text):
                Logger.shared.debug("Content[\(index)]: text = \(text)")
            case .toolUse(let data):
                Logger.shared.debug("Content[\(index)]: tool_use = \(data.name)")
            }
        }

        // Parse tool use from response
        guard let toolUse = response.content.first(where: {
            if case .toolUse = $0 { return true }
            return false
        }) else {
            Logger.shared.error("No tool_use found in response. Content types: \(response.content.map { type(of: $0) })")
            throw APIError.invalidResponse
        }

        if case .toolUse(let toolData) = toolUse {
            Logger.shared.debug("Intent extraction tool response: \(toolData.input)")

            let jsonData = try JSONSerialization.data(withJSONObject: toolData.input)
            let intent = try JSONDecoder().decode(OrganizationIntent.self, from: jsonData)

            Logger.shared.info("✅ Intent parsed successfully: folder=\(intent.folder), criteria=\(intent.criteria), categories=\(intent.suggestedCategories.count)")

            return intent
        }

        throw APIError.invalidResponse
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

    private func makeRequest(_ request: ClaudeRequest, retryCount: Int = 0) async throws -> ClaudeResponse {
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

            // Handle rate limit with retry (429 error)
            if httpResponse.statusCode == 429 && retryCount < 3 {
                let delaySeconds = pow(2.0, Double(retryCount)) * 60.0 // 60s, 120s, 240s
                Logger.shared.info("Rate limited. Retrying in \(Int(delaySeconds)) seconds...")
                try await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
                return try await makeRequest(request, retryCount: retryCount + 1)
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

    private func makeRequestWithSystem(_ request: ClaudeRequestWithSystem, retryCount: Int = 0) async throws -> ClaudeResponse {
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

            if httpResponse.statusCode == 429 && retryCount < 3 {
                let delaySeconds = pow(2.0, Double(retryCount)) * 60.0
                Logger.shared.info("Rate limited. Retrying in \(Int(delaySeconds)) seconds...")
                try await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
                return try await makeRequestWithSystem(request, retryCount: retryCount + 1)
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

    // MARK: - Tool Request (Agent SDK Pattern)

    private func makeToolRequest(_ request: ClaudeToolRequest, retryCount: Int = 0) async throws -> ClaudeToolResponse {
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

            // Handle rate limit with retry (429 error)
            if httpResponse.statusCode == 429 && retryCount < 3 {
                let delaySeconds = pow(2.0, Double(retryCount)) * 60.0
                Logger.shared.info("Rate limited. Retrying in \(Int(delaySeconds)) seconds...")
                try await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
                return try await makeToolRequest(request, retryCount: retryCount + 1)
            }

            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }

        // Log raw response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            Logger.shared.debug("Raw API response: \(responseString.prefix(500))...")
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        do {
            let response = try decoder.decode(ClaudeToolResponse.self, from: data)
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

    private struct ClaudeRequestWithSystem: Codable {
        let model: String
        let maxTokens: Int
        let system: String
        let messages: [ClaudeMessage]
    }

    private struct ClaudeToolRequest: Codable {
        let model: String
        let maxTokens: Int
        let system: String
        let messages: [ClaudeMessage]
        let tools: [IntentExtractionTool]
        let toolChoice: ToolChoice?

        struct ToolChoice: Codable {
            let type: String
            let name: String?
        }
    }

    private struct IntentExtractionTool: Codable {
        let name: String
        let description: String
        let inputSchema: [String: Any]

        enum CodingKeys: String, CodingKey {
            case name, description
            case inputSchema = "input_schema"
        }

        init(name: String, description: String, inputSchema: [String: Any]) {
            self.name = name
            self.description = description
            self.inputSchema = inputSchema
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            name = try container.decode(String.self, forKey: .name)
            description = try container.decode(String.self, forKey: .description)

            let schemaData = try container.decode(AnyCodable.self, forKey: .inputSchema)
            if let dict = schemaData.value as? [String: Any] {
                inputSchema = dict
            } else {
                throw DecodingError.dataCorruptedError(forKey: .inputSchema, in: container, debugDescription: "Invalid schema")
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(name, forKey: .name)
            try container.encode(description, forKey: .description)

            // Encode inputSchema as JSON
            let jsonData = try JSONSerialization.data(withJSONObject: inputSchema)
            let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
            try container.encode(AnyCodable(jsonObject), forKey: .inputSchema)
        }
    }

    private struct IntentExtractionInput {
        static let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "folder": [
                    "type": "string",
                    "description": "The folder to organize (e.g., 'Desktop', 'Downloads', 'Documents')"
                ],
                "criteria": [
                    "type": "string",
                    "description": "What to organize by (e.g., 'file type', 'construction trade', 'client name', 'date')"
                ],
                "suggested_categories": [
                    "type": "array",
                    "items": ["type": "string"],
                    "description": "Categories for organization. For single-folder requests (user specifies one destination like 'put in X folder'), return ONLY that single category name. For multi-category organization (sort by type, trade, etc.), return 5-8 categories including 'other' as fallback."
                ]
            ],
            "required": ["folder", "criteria", "suggested_categories"]
        ]
    }

    private struct ClaudeToolResponse: Codable {
        let id: String
        let type: String
        let role: String
        let content: [ToolResponseContent]
        let model: String
        let stopReason: String?
        let usage: Usage

        struct Usage: Codable {
            let inputTokens: Int
            let outputTokens: Int
        }
    }

    private enum ToolResponseContent: Codable {
        case text(String)
        case toolUse(ToolUseData)

        struct ToolUseData: Codable {
            let id: String
            let name: String
            let input: [String: Any]

            enum CodingKeys: String, CodingKey {
                case id, name, input
            }

            init(id: String, name: String, input: [String: Any]) {
                self.id = id
                self.name = name
                self.input = input
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                id = try container.decode(String.self, forKey: .id)
                name = try container.decode(String.self, forKey: .name)

                // Decode input as dictionary
                let inputData = try container.decode(AnyCodable.self, forKey: .input)
                if let dict = inputData.value as? [String: Any] {
                    input = dict
                } else {
                    throw DecodingError.dataCorruptedError(forKey: .input, in: container, debugDescription: "Input is not a dictionary")
                }
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(id, forKey: .id)
                try container.encode(name, forKey: .name)
                try container.encode(AnyCodable(input), forKey: .input)
            }
        }

        enum CodingKeys: String, CodingKey {
            case type, text, id, name, input
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)

            switch type {
            case "text":
                let text = try container.decode(String.self, forKey: .text)
                self = .text(text)
            case "tool_use":
                let id = try container.decode(String.self, forKey: .id)
                let name = try container.decode(String.self, forKey: .name)
                let inputData = try container.decode(AnyCodable.self, forKey: .input)
                if let dict = inputData.value as? [String: Any] {
                    let toolData = ToolUseData(id: id, name: name, input: dict)
                    self = .toolUse(toolData)
                } else {
                    throw DecodingError.dataCorruptedError(forKey: .input, in: container, debugDescription: "Invalid tool use input")
                }
            default:
                throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown content type: \(type)")
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            switch self {
            case .text(let text):
                try container.encode("text", forKey: .type)
                try container.encode(text, forKey: .text)
            case .toolUse(let data):
                try container.encode("tool_use", forKey: .type)
                try container.encode(data.id, forKey: .id)
                try container.encode(data.name, forKey: .name)
                try container.encode(AnyCodable(data.input), forKey: .input)
            }
        }
    }

    // Helper for encoding/decoding Any
    private struct AnyCodable: Codable {
        let value: Any

        init(_ value: Any) {
            self.value = value
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()

            if let intValue = try? container.decode(Int.self) {
                value = intValue
            } else if let doubleValue = try? container.decode(Double.self) {
                value = doubleValue
            } else if let stringValue = try? container.decode(String.self) {
                value = stringValue
            } else if let boolValue = try? container.decode(Bool.self) {
                value = boolValue
            } else if let arrayValue = try? container.decode([AnyCodable].self) {
                value = arrayValue.map { $0.value }
            } else if let dictValue = try? container.decode([String: AnyCodable].self) {
                value = dictValue.mapValues { $0.value }
            } else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported type")
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()

            if let intValue = value as? Int {
                try container.encode(intValue)
            } else if let doubleValue = value as? Double {
                try container.encode(doubleValue)
            } else if let stringValue = value as? String {
                try container.encode(stringValue)
            } else if let boolValue = value as? Bool {
                try container.encode(boolValue)
            } else if let arrayValue = value as? [Any] {
                try container.encode(arrayValue.map { AnyCodable($0) })
            } else if let dictValue = value as? [String: Any] {
                try container.encode(dictValue.mapValues { AnyCodable($0) })
            } else {
                throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: container.codingPath, debugDescription: "Unsupported type"))
            }
        }
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
