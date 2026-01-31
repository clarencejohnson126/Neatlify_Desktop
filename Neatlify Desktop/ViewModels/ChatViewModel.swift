//
//  ChatViewModel.swift
//  Neatlify
//
//  Chat interface view model
//

import Foundation
import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isProcessing: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""

    private let apiService = ClaudeAPIService()

    init() {
        // Add welcome message
        addWelcomeMessage()
    }

    private func addWelcomeMessage() {
        let welcomeText = """
        Welcome to Neatlify! I can help you organize your files using AI.

        Try saying:
        • "Organize my Downloads by construction trade"
        • "Sort my vacation photos by location"
        • "Group my receipts by vendor"

        What would you like to organize?
        """

        let welcomeMessage = ChatMessage(
            role: .assistant,
            content: welcomeText
        )

        messages.append(welcomeMessage)
    }

    func sendMessage() async {
        let userMessage = inputText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !userMessage.isEmpty else { return }

        // Add user message
        let message = ChatMessage(role: .user, content: userMessage)
        messages.append(message)

        // Clear input
        inputText = ""

        // Add loading indicator
        let loadingMessage = ChatMessage(
            id: UUID(),
            role: .assistant,
            content: "Thinking...",
            isLoading: true
        )
        messages.append(loadingMessage)

        isProcessing = true

        do {
            // Check if this is an organization request
            if isOrganizationRequest(userMessage) {
                // Remove loading message
                messages.removeLast()

                // Create assistant response indicating we're starting
                let startMessage = ChatMessage(
                    role: .assistant,
                    content: "I'll help you organize those files. Let me analyze your request..."
                )
                messages.append(startMessage)

                // Notify parent view to start organization - include conversation history for context
                NotificationCenter.default.post(
                    name: .startOrganization,
                    object: nil,
                    userInfo: [
                        "message": userMessage,
                        "conversationHistory": messages  // Pass full conversation for context
                    ]
                )
            } else {
                // Regular chat message
                let response = try await apiService.sendMessage(userMessage, conversationHistory: messages)

                // Remove loading message
                messages.removeLast()

                // Add response
                let responseMessage = ChatMessage(
                    role: .assistant,
                    content: response
                )
                messages.append(responseMessage)
            }
        } catch {
            // Remove loading message
            if let lastMessage = messages.last, lastMessage.isLoading {
                messages.removeLast()
            }

            // Show error
            handleError(error)
        }

        isProcessing = false
    }

    func addSystemMessage(_ content: String) {
        let message = ChatMessage(
            role: .assistant,
            content: content
        )
        messages.append(message)
    }

    private func isOrganizationRequest(_ message: String) -> Bool {
        let keywords = [
            // English - organization actions
            "organize", "sort", "group", "categorize", "arrange",
            "clean", "tidy", "order", "separate", "classify",
            "move", "rename", "scan", "find and move", "put into folders",
            // English - file references with actions
            "my files", "my photos", "my documents", "my downloads",
            "my desktop", "my pictures", "my screenshots",
            // German
            "organisiere", "organisier", "sortiere", "sortier",
            "gruppiere", "gruppier", "ordne", "räume", "aufräumen",
            "verschiebe", "verschieben", "umbenennen"
        ]

        let lowercased = message.lowercased()

        // Check for direct keyword match
        if keywords.contains(where: { lowercased.contains($0) }) {
            return true
        }

        // Check for file-related phrases combined with action words
        let fileWords = ["file", "photo", "image", "document", "pdf", "screenshot", "picture", "folder"]
        let actionWords = ["find", "move", "put", "into", "create", "make"]

        let hasFileWord = fileWords.contains { lowercased.contains($0) }
        let hasActionWord = actionWords.contains { lowercased.contains($0) }

        return hasFileWord && hasActionWord
    }

    private func handleError(_ error: Error) {
        Logger.shared.error("Chat error", error: error)

        errorMessage = error.localizedDescription
        showError = true

        let errorChatMessage = ChatMessage(
            role: .assistant,
            content: "I encountered an error: \(error.localizedDescription)\n\nPlease try again."
        )
        messages.append(errorChatMessage)
    }

    func clearMessages() {
        messages.removeAll()
        addWelcomeMessage()
    }
}

extension Notification.Name {
    static let startOrganization = Notification.Name("startOrganization")
}
