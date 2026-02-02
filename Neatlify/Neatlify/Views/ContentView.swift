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
    @State private var showAccountMenu = false

    var body: some View {
        ZStack {
            // Main content
            VStack(spacing: 0) {
                // Header
                HeaderView(showAccountMenu: $showAccountMenu)

                // Chat interface
                ChatView(viewModel: chatViewModel)

                // Progress view (shown when organizing)
                if organizationViewModel.isOrganizing {
                    ProgressOverlayView(viewModel: organizationViewModel)
                }
            }

            // Account menu
            if showAccountMenu {
                AccountMenuView(isOpen: $showAccountMenu)
                    .environmentObject(userSession)
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
        .sheet(isPresented: $showPaywall) {
            PaywallView(isPresented: $showPaywall)
                .environmentObject(userSession)
        }
        .onAppear {
            checkOnboarding()
            setupOrganizationListener()
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
                // Check if user can perform cleanup
                if userSession.canPerformCleanup() {
                    Task {
                        await organizationViewModel.startOrganization(userMessage: userMessage)
                    }
                } else {
                    // Show paywall
                    showPaywall = true
                }
            }
        }
    }
}

struct HeaderView: View {
    @EnvironmentObject var userSession: UserSession
    @Binding var showAccountMenu: Bool
    @State private var isHoveringSettings = false

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundColor(.blue)

            Text("Neatlify")
                .font(.title2)
                .fontWeight(.semibold)

            Spacer()

            // Credits display
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
                Text("\(userSession.creditsRemaining)")
                    .font(.body)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)

            // Settings button
            Button(action: {
                showAccountMenu.toggle()
            }) {
                Image(systemName: "gear")
                    .font(.title3)
                    .foregroundColor(.primary)
            }
            .buttonStyle(.plain)
            .help("Account Settings")
            .onHover { hovering in
                isHoveringSettings = hovering
            }
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHoveringSettings ? Color(NSColor.controlBackgroundColor) : Color.clear)
                    .padding(-4)
            )
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

                if let plan = viewModel.organizationPlan {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("I'll organize \(plan.totalFiles) files into these categories:")
                                .font(.headline)

                            Text(plan.categorySummary)
                                .font(.body)
                                .padding()
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(8)

                            Text("Files will be moved to: \(plan.sourceFolder.path)/Organized_[timestamp]/")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                    .frame(maxHeight: 400)

                    HStack(spacing: 16) {
                        Button("Cancel") {
                            viewModel.cancelOrganization()
                        }
                        .keyboardShortcut(.escape)

                        Button("Proceed") {
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
            .frame(width: 600)
            .background(Color(NSColor.windowBackgroundColor))
            .cornerRadius(16)
            .shadow(radius: 20)
        }
    }
}

struct AccountMenuView: View {
    @EnvironmentObject var userSession: UserSession
    @Binding var isOpen: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Dimmed background
            Color.black.opacity(0.2)
                .ignoresSafeArea()
                .onTapGesture {
                    isOpen = false
                }

            // Menu popup
            VStack(alignment: .leading, spacing: 0) {
                // User Info Section
                VStack(alignment: .leading, spacing: 8) {
                    if let fullName = userSession.fullName {
                        Text(fullName)
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    if let email = userSession.email {
                        Text(email)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.controlBackgroundColor))

                Divider()
                    .frame(height: 1)

                // Credits Section
                VStack(alignment: .leading, spacing: 6) {
                    Text("Available Credits")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("\(userSession.creditsRemaining) files")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()
                    .frame(height: 1)

                // Sign Out Button
                Button(action: {
                    signOut()
                }) {
                    HStack {
                        Image(systemName: "arrow.right.square")
                        Text("Sign Out")
                    }
                    .font(.body)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                }
                .buttonStyle(.plain)
                .help("Sign out of your account")

                Spacer()
            }
            .frame(width: 240)
            .background(Color(NSColor.windowBackgroundColor))
            .cornerRadius(8)
            .shadow(radius: 10)
            .padding(12)
        }
    }

    private func signOut() {
        // Clear user session
        let clearedSession = UserSession()
        clearedSession.save()

        // Relaunch app (or restart the session)
        NSApplication.shared.terminate(nil)
    }
}
