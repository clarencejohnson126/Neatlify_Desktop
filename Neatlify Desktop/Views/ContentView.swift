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
    @ObservedObject var viewModel: OrganizationViewModel

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
                            // Summary card
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "doc.on.doc.fill")
                                        .foregroundColor(.neatlifyGreen)
                                    Text("Files to organize: \(plan.totalFiles)")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.neatlifyDark)
                                }

                                Text(plan.categorySummary)
                                    .font(.body)
                                    .foregroundColor(.neatlifyDark.opacity(0.8))
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.neatlifyDark, lineWidth: 2)
                            )

                            // Credits card
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "sparkles")
                                        .foregroundColor(.neatlifyYellow)
                                    Text("Credits")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.neatlifyDark)
                                }

                                if pricing.isFreeTrialEligible {
                                    HStack(spacing: 8) {
                                        Image(systemName: "gift.fill")
                                            .foregroundColor(.neatlifyGreen)
                                        Text("FREE TRIAL")
                                            .font(.subheadline)
                                            .fontWeight(.black)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .background(Color.neatlifyGreen)
                                            .cornerRadius(6)
                                    }
                                    Text("This cleanup is free (up to 100 files)")
                                        .font(.subheadline)
                                        .foregroundColor(.neatlifyDark.opacity(0.6))
                                } else {
                                    HStack {
                                        Text("\(pricing.totalFiles)")
                                            .font(.system(size: 32, weight: .black))
                                            .foregroundColor(.neatlifyGreen)
                                        Text("credits will be used")
                                            .font(.subheadline)
                                            .foregroundColor(.neatlifyDark.opacity(0.7))
                                    }

                                    Text("Remaining after: \(pricing.creditsAvailable - pricing.totalFiles) credits")
                                        .font(.caption)
                                        .foregroundColor(.neatlifyDark.opacity(0.5))
                                }
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.neatlifyYellow.opacity(0.2))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.neatlifyDark, lineWidth: 2)
                            )

                            // Destination info
                            HStack {
                                Image(systemName: "arrow.right.circle.fill")
                                    .foregroundColor(.neatlifyDark.opacity(0.5))
                                Text("Files will be moved to: Organized_[timestamp]/")
                                    .font(.caption)
                                    .foregroundColor(.neatlifyDark.opacity(0.5))
                            }
                        }
                        .padding()
                    }
                    .frame(maxHeight: 400)

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

                        Button(action: {
                            Task {
                                await viewModel.executeOrganization()
                            }
                        }) {
                            HStack {
                                Image(systemName: pricing.isFreeTrialEligible ? "gift.fill" : "sparkles")
                                Text(pricing.isFreeTrialEligible ? "Start Free Trial" : "Organize Now")
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
