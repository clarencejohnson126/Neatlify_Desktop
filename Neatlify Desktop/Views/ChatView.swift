//
//  ChatView.swift
//  Neatlify
//
//  Chat interface view - Matching landing page design
//

import SwiftUI

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    @State private var scrollProxy: ScrollViewProxy?

    var body: some View {
        VStack(spacing: 0) {
            // Messages area
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Welcome message if no messages
                        if viewModel.messages.isEmpty {
                            WelcomeMessageView()
                        }

                        ForEach(viewModel.messages) { message in
                            MessageBubbleView(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(20)
                }
                .background(Color.neatlifyBg)
                .onAppear {
                    scrollProxy = proxy
                }
                .onChange(of: viewModel.messages.count) { _ in
                    scrollToBottom()
                }
            }

            // Input area with sketch style
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.neatlifyDark.opacity(0.1))
                    .frame(height: 2)

                // Quick action buttons (if no text entered)
                if viewModel.inputText.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Quick Actions")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.neatlifyDark.opacity(0.6))
                            .padding(.horizontal, 16)
                            .padding(.top, 12)

                        HStack(spacing: 10) {
                            QuickChatAction(
                                title: "By Date",
                                icon: "calendar",
                                action: { viewModel.inputText = "Organize files by date" }
                            )

                            QuickChatAction(
                                title: "By Type",
                                icon: "doc.fill",
                                action: { viewModel.inputText = "Organize files by type" }
                            )

                            QuickChatAction(
                                title: "Label Files",
                                icon: "tag.fill",
                                action: { viewModel.inputText = "Label my files with descriptive names" }
                            )

                            QuickChatAction(
                                title: "By Project",
                                icon: "folder.fill",
                                action: { viewModel.inputText = "Organize files by project" }
                            )
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                    }
                    .background(Color.neatlifyBg)
                }

                HStack(spacing: 12) {
                    // Text input field
                    HStack {
                        Image(systemName: "text.bubble")
                            .foregroundColor(.neatlifyDark.opacity(0.4))

                        TextField("Tell me how to organize your files...", text: $viewModel.inputText)
                            .textFieldStyle(.plain)
                            .font(.body)
                            .foregroundColor(.neatlifyDark)
                            .onSubmit {
                                sendMessage()
                            }
                            .disabled(viewModel.isProcessing)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.neatlifyDark, lineWidth: 2)
                    )

                    // Send button
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(viewModel.inputText.isEmpty || viewModel.isProcessing ? Color.neatlifyDark.opacity(0.3) : Color.neatlifyGreen)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.neatlifyDark, lineWidth: 2)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.inputText.isEmpty || viewModel.isProcessing)
                    .shadow(color: viewModel.inputText.isEmpty ? .clear : Color.neatlifyDark.opacity(0.2), radius: 0, x: 2, y: 2)
                }
                .padding(16)
                .background(Color.neatlifyBg)
            }
        }
    }

    private func sendMessage() {
        Task {
            await viewModel.sendMessage()
        }
    }

    private func scrollToBottom() {
        guard let lastMessage = viewModel.messages.last else { return }
        withAnimation {
            scrollProxy?.scrollTo(lastMessage.id, anchor: .bottom)
        }
    }
}

struct WelcomeMessageView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
                .frame(height: 40)

            // Logo
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.neatlifyGreen)
                    .frame(width: 80, height: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.neatlifyDark, lineWidth: 3)
                    )
                    .shadow(color: Color.neatlifyDark.opacity(0.2), radius: 0, x: 4, y: 4)
                Text("N")
                    .font(.system(size: 44, weight: .black))
                    .foregroundColor(.white)
            }

            Text("Hi! I'm Neatlify")
                .font(.system(size: 28, weight: .black))
                .foregroundColor(.neatlifyDark)

            Text("Tell me how you'd like to organize your files")
                .font(.body)
                .foregroundColor(.neatlifyDark.opacity(0.7))

            // Example prompts
            VStack(spacing: 12) {
                ExamplePromptButton(text: "Organize my Downloads folder by file type")
                ExamplePromptButton(text: "Sort photos by date taken")
                ExamplePromptButton(text: "Clean up my Desktop")
            }
            .padding(.top, 8)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

struct ExamplePromptButton: View {
    let text: String

    var body: some View {
        Button(action: {
            // This would populate the text field
        }) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.neatlifyYellow)
                Text(text)
                    .font(.subheadline)
                    .foregroundColor(.neatlifyDark.opacity(0.8))
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundColor(.neatlifyDark.opacity(0.4))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.neatlifyDark.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: 350)
    }
}

struct MessageBubbleView: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.role == .user {
                Spacer(minLength: 60)
            } else {
                // AI avatar
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.neatlifyGreen)
                        .frame(width: 32, height: 32)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.neatlifyDark, lineWidth: 2)
                        )
                    Text("N")
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(.white)
                }
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 6) {
                Text(message.content)
                    .font(.body)
                    .padding(14)
                    .background(bubbleBackground)
                    .foregroundColor(textColor)
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(borderColor, lineWidth: 2)
                    )
                    .textSelection(.enabled)

                if message.isLoading {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.neatlifyGreen)
                            .frame(width: 8, height: 8)
                            .opacity(0.6)
                        Circle()
                            .fill(Color.neatlifyGreen)
                            .frame(width: 8, height: 8)
                            .opacity(0.8)
                        Circle()
                            .fill(Color.neatlifyGreen)
                            .frame(width: 8, height: 8)
                    }
                    .padding(.leading, 8)
                } else {
                    Text(formatTimestamp(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.neatlifyDark.opacity(0.4))
                }
            }
            .frame(maxWidth: 500, alignment: message.role == .user ? .trailing : .leading)

            if message.role == .assistant {
                Spacer(minLength: 60)
            } else {
                // User avatar
                ZStack {
                    Circle()
                        .fill(Color.neatlifyYellow)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle()
                                .stroke(Color.neatlifyDark, lineWidth: 2)
                        )
                    Image(systemName: "person.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.neatlifyDark)
                }
            }
        }
    }

    private var bubbleBackground: Color {
        switch message.role {
        case .user:
            return Color.neatlifyGreen
        case .assistant:
            return Color.white
        }
    }

    private var borderColor: Color {
        return Color.neatlifyDark
    }

    private var textColor: Color {
        switch message.role {
        case .user:
            return .white
        case .assistant:
            return .neatlifyDark
        }
    }

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Quick Chat Action Button

struct QuickChatAction: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.neatlifyGreen)
                    .frame(height: 20)

                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.neatlifyDark)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(height: 70)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 8)
            .background(Color.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.neatlifyDark, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .help(title)
    }
}
