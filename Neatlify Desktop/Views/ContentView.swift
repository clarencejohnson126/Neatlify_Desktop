//
//  ContentView.swift
//  Neatlify
//
//  Main app container view
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
                Task {
                    await organizationViewModel.startOrganization(userMessage: userMessage)
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
    var body: some View {
        HStack {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundColor(.blue)

            Text("Neatlify")
                .font(.title2)
                .fontWeight(.semibold)

            Spacer()

            Button(action: {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }) {
                Image(systemName: "gear")
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(",", modifiers: .command)
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct PreviewSheet: View {
    @ObservedObject var viewModel: OrganizationViewModel

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Organization Plan")
                    .font(.title)
                    .fontWeight(.bold)

                if let plan = viewModel.organizationPlan, let pricing = viewModel.pricingInfo {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("I'll organize \(plan.totalFiles) files into these categories:")
                                .font(.headline)

                            Text(plan.categorySummary)
                                .font(.body)
                                .padding()
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(8)

                            // Credits information
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "creditcard")
                                    Text("Credits")
                                        .font(.headline)
                                }

                                if pricing.isFreeTrialEligible {
                                    HStack {
                                        Image(systemName: "gift.fill")
                                            .foregroundColor(.green)
                                        Text("Free Trial")
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.green)
                                    }
                                    Text("This cleanup is free (up to 100 files)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("\(pricing.totalFiles) credits will be used")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)

                                    Text("Remaining after: \(pricing.creditsAvailable - pricing.totalFiles) credits")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)

                            Text("Files will be moved to: \(plan.sourceFolder.path)/Organized_[timestamp]/")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                    .frame(maxHeight: 500)

                    HStack(spacing: 16) {
                        Button("Cancel") {
                            viewModel.cancelOrganization()
                        }
                        .keyboardShortcut(.escape)

                        Button(pricing.isFreeTrialEligible ? "Start Free Trial" : "Use \(pricing.totalFiles) Credits") {
                            Task {
                                await viewModel.executeOrganization()
                            }
                        }
                        .keyboardShortcut(.return)
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .padding(32)
            .frame(width: 650)
            .background(Color(NSColor.windowBackgroundColor))
            .cornerRadius(16)
            .shadow(radius: 20)
        }
    }
}
