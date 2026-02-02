//
//  ContentView.swift
//  Neatlify
//
//  Main app container view - Matching landing page design
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var userSession: UserSession
    @StateObject private var chatViewModel = ChatViewModel()
    @StateObject private var organizationViewModel = OrganizationViewModel()
    @State private var showOnboarding = false
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            // Background matching landing page
            Color.neatlifyBg.ignoresSafeArea()

            // Main content
            VStack(spacing: 0) {
                // Header
                HeaderView()

                // Chat interface
                ChatView(viewModel: chatViewModel)

                // Progress view (shown when organizing)
                if organizationViewModel.isOrganizing {
                    ProgressOverlayView(viewModel: organizationViewModel)
                }
            }

            // Preview sheet
            if organizationViewModel.showPreview {
                PreviewSheet(viewModel: organizationViewModel)
                    .environmentObject(userSession)
            }
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView(isPresented: $showOnboarding)
                .environmentObject(userSession)
        }
        .sheet(isPresented: Binding(
            get: { showPaywall || organizationViewModel.showPaywall },
            set: { newValue in
                showPaywall = newValue
                organizationViewModel.showPaywall = newValue
            }
        )) {
            PaywallView(isPresented: Binding(
                get: { showPaywall || organizationViewModel.showPaywall },
                set: { newValue in
                    showPaywall = newValue
                    organizationViewModel.showPaywall = newValue
                }
            ))
                .environmentObject(userSession)
        }
        .onAppear {
            checkOnboarding()
            setupOrganizationListener()
            setupPaywallListener()
        }
        .alert("Error", isPresented: $organizationViewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(organizationViewModel.errorMessage)
        }
    }

    private func checkOnboarding() {
        if !userSession.hasCompletedOnboarding {
            showOnboarding = true
        }
    }

    private func setupOrganizationListener() {
        NotificationCenter.default.addObserver(
            forName: .startOrganization,
            object: nil,
            queue: .main
        ) { notification in
            if let userMessage = notification.userInfo?["message"] as? String {
                // Extract conversation history for context memory
                let conversationHistory = notification.userInfo?["conversationHistory"] as? [ChatMessage] ?? []

                Task {
                    await organizationViewModel.startOrganization(
                        userMessage: userMessage,
                        conversationHistory: conversationHistory
                    )
                }
            }
        }
    }

    private func setupPaywallListener() {
        NotificationCenter.default.addObserver(
            forName: .showPaywall,
            object: nil,
            queue: .main
        ) { _ in
            showPaywall = true
        }
    }
}

struct HeaderView: View {
    @EnvironmentObject var userSession: UserSession

    var body: some View {
        HStack(spacing: 12) {
            // Logo matching landing page
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.neatlifyGreen)
                    .frame(width: 36, height: 36)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.neatlifyDark, lineWidth: 2)
                    )
                Text("N")
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(.white)
            }

            Text("Neatlify")
                .font(.system(size: 22, weight: .black))
                .foregroundColor(.neatlifyDark)

            Spacer()

            // Credits badge
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .foregroundColor(.neatlifyYellow)
                Text("\(userSession.fileCredits)")
                    .fontWeight(.bold)
                    .foregroundColor(.neatlifyDark)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.neatlifyYellow.opacity(0.2))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.neatlifyDark, lineWidth: 2)
            )

            // Settings button
            Button(action: {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }) {
                Image(systemName: "gear")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.neatlifyDark)
                    .frame(width: 36, height: 36)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.neatlifyDark, lineWidth: 2)
                    )
            }
            .buttonStyle(.plain)
            .keyboardShortcut(",", modifiers: .command)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.neatlifyBg)
        .overlay(
            Rectangle()
                .frame(height: 2)
                .foregroundColor(Color.neatlifyDark.opacity(0.1)),
            alignment: .bottom
        )
    }
}

struct PreviewSheet: View {
    @EnvironmentObject var userSession: UserSession
    @ObservedObject var viewModel: OrganizationViewModel

    // Check credits against live userSession (updates when credits sync)
    private var hasCredits: Bool {
        guard let pricing = viewModel.pricingInfo else { return false }
        return userSession.fileCredits >= pricing.totalFiles
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "folder.badge.gearshape")
                        .font(.system(size: 40))
                        .foregroundColor(.neatlifyGreen)

                    Text("Organization Plan")
                        .font(.system(size: 24, weight: .black))
                        .foregroundColor(.neatlifyDark)
                }

                if let plan = viewModel.organizationPlan, let pricing = viewModel.pricingInfo {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Files found card with sample names
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "doc.on.doc.fill")
                                        .foregroundColor(.neatlifyGreen)
                                    Text("Found \(pricing.totalFiles) files")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.neatlifyDark)
                                }

                                // Sample file names
                                if !pricing.sampleFileNames.isEmpty {
                                    VStack(alignment: .leading, spacing: 4) {
                                        ForEach(pricing.sampleFileNames, id: \.self) { name in
                                            HStack(spacing: 6) {
                                                Image(systemName: name.lowercased().hasSuffix(".pdf") ? "doc.fill" : "photo.fill")
                                                    .font(.caption)
                                                    .foregroundColor(.neatlifyDark.opacity(0.5))
                                                Text(name)
                                                    .font(.caption)
                                                    .foregroundColor(.neatlifyDark.opacity(0.7))
                                                    .lineLimit(1)
                                            }
                                        }
                                        if pricing.totalFiles > pricing.sampleFileNames.count {
                                            Text("... and \(pricing.totalFiles - pricing.sampleFileNames.count) more files")
                                                .font(.caption)
                                                .foregroundColor(.neatlifyDark.opacity(0.5))
                                                .italic()
                                        }
                                    }
                                    .padding(.leading, 4)
                                }
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.neatlifyDark, lineWidth: 2)
                            )

                            // Proposed folder structure
                            if !pricing.categoryCounts.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "folder.fill")
                                            .foregroundColor(.neatlifyGreen)
                                        Text("Proposed Folder Structure")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.neatlifyDark)
                                    }

                                    VStack(alignment: .leading, spacing: 6) {
                                        ForEach(pricing.categoryCounts.sorted(by: { $0.value > $1.value }), id: \.key) { category, count in
                                            HStack {
                                                Image(systemName: "folder.fill")
                                                    .font(.caption)
                                                    .foregroundColor(.neatlifyYellow)
                                                Text(category)
                                                    .font(.subheadline)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.neatlifyDark)
                                                Spacer()
                                                Text("\(count) files")
                                                    .font(.caption)
                                                    .foregroundColor(.neatlifyDark.opacity(0.6))
                                            }
                                        }
                                    }
                                    .padding(.leading, 4)
                                }
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.neatlifyGreen.opacity(0.1))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.neatlifyDark, lineWidth: 2)
                                )
                            } else if plan.mode == .label {
                                // Label mode preview
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "tag.fill")
                                            .foregroundColor(.neatlifyGreen)
                                        Text("Files will be renamed")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.neatlifyDark)
                                    }

                                    Text("AI will analyze each file and generate descriptive names based on content.")
                                        .font(.subheadline)
                                        .foregroundColor(.neatlifyDark.opacity(0.7))
                                }
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.neatlifyGreen.opacity(0.1))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.neatlifyDark, lineWidth: 2)
                                )
                            }

                            // Credits or Subscribe card
                            VStack(alignment: .leading, spacing: 12) {
                                if hasCredits {
                                    // User has credits
                                    HStack {
                                        Image(systemName: "sparkles")
                                            .foregroundColor(.neatlifyYellow)
                                        Text("Credits")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.neatlifyDark)
                                    }

                                    HStack {
                                        Text("\(pricing.totalFiles)")
                                            .font(.system(size: 32, weight: .black))
                                            .foregroundColor(.neatlifyGreen)
                                        Text("credits will be used")
                                            .font(.subheadline)
                                            .foregroundColor(.neatlifyDark.opacity(0.7))
                                    }

                                    Text("Remaining after: \(userSession.fileCredits - pricing.totalFiles) credits")
                                        .font(.caption)
                                        .foregroundColor(.neatlifyDark.opacity(0.5))
                                } else {
                                    // User needs more credits
                                    HStack {
                                        Image(systemName: "creditcard.fill")
                                            .foregroundColor(.neatlifyYellow)
                                        Text("Credits Required")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.neatlifyDark)
                                    }

                                    Text("Your files have been scanned and are ready to organize. Purchase credits to continue.")
                                        .font(.subheadline)
                                        .foregroundColor(.neatlifyDark.opacity(0.7))

                                    HStack(spacing: 16) {
                                        VStack(alignment: .leading) {
                                            Text("You have:")
                                                .font(.caption)
                                                .foregroundColor(.neatlifyDark.opacity(0.5))
                                            Text("\(userSession.fileCredits) credits")
                                                .font(.subheadline)
                                                .fontWeight(.bold)
                                                .foregroundColor(.neatlifyDark)
                                        }
                                        VStack(alignment: .leading) {
                                            Text("Need:")
                                                .font(.caption)
                                                .foregroundColor(.neatlifyDark.opacity(0.5))
                                            Text("\(pricing.totalFiles) credits")
                                                .font(.subheadline)
                                                .fontWeight(.bold)
                                                .foregroundColor(.neatlifyGreen)
                                        }
                                    }
                                }
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(hasCredits ? Color.neatlifyYellow.opacity(0.2) : Color.neatlifyGreen.opacity(0.15))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.neatlifyDark, lineWidth: 2)
                            )

                            // Destination info
                            if hasCredits {
                                HStack {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .foregroundColor(.neatlifyDark.opacity(0.5))
                                    Text("Files will be moved to: Organized_[timestamp]/")
                                        .font(.caption)
                                        .foregroundColor(.neatlifyDark.opacity(0.5))
                                }
                            }
                        }
                        .padding()
                    }
                    .frame(maxHeight: 450)

                    // Action buttons
                    HStack(spacing: 16) {
                        Button(action: {
                            viewModel.cancelOrganization()
                        }) {
                            Text("Cancel")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.neatlifyDark)
                                .frame(width: 120, height: 44)
                                .background(Color.white)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.neatlifyDark, lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                        .keyboardShortcut(.escape)

                        if hasCredits {
                            Button(action: {
                                Task {
                                    await viewModel.executeOrganization()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "sparkles")
                                    Text("Organize Now")
                                        .fontWeight(.bold)
                                }
                                .foregroundColor(.white)
                                .frame(width: 180, height: 44)
                                .background(Color.neatlifyGreen)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.neatlifyDark, lineWidth: 2)
                                )
                                .shadow(color: Color.neatlifyDark.opacity(0.2), radius: 0, x: 3, y: 3)
                            }
                            .buttonStyle(.plain)
                            .keyboardShortcut(.return)
                        } else {
                            Button(action: {
                                viewModel.showPaywall = true
                            }) {
                                HStack {
                                    Image(systemName: "creditcard.fill")
                                    Text("Subscribe")
                                        .fontWeight(.bold)
                                }
                                .foregroundColor(.white)
                                .frame(width: 180, height: 44)
                                .background(Color.neatlifyGreen)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.neatlifyDark, lineWidth: 2)
                                )
                                .shadow(color: Color.neatlifyDark.opacity(0.2), radius: 0, x: 3, y: 3)
                            }
                            .buttonStyle(.plain)
                            .keyboardShortcut(.return)
                        }
                    }
                }
            }
            .padding(32)
            .frame(width: 550)
            .background(Color.neatlifyBg)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.neatlifyDark, lineWidth: 3)
            )
            .shadow(color: Color.neatlifyDark.opacity(0.3), radius: 0, x: 6, y: 6)
        }
    }
}
