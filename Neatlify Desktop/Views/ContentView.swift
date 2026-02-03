//
//  ContentView.swift
//  Neatlify
//
//  Main app container with tab navigation
//

import SwiftUI

// MARK: - App Tab Enum

enum AppTab: String, CaseIterable {
    case chat = "Chat"
    case dashboard = "Dashboard"
    case history = "History"
    case shop = "Shop"
    case settings = "Settings"

    var systemImage: String {
        switch self {
        case .chat:
            return "message.fill"
        case .dashboard:
            return "chart.bar.fill"
        case .history:
            return "clock.fill"
        case .shop:
            return "bag.fill"
        case .settings:
            return "gear"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var userSession: UserSession
    @StateObject private var chatViewModel = ChatViewModel()
    @StateObject private var organizationViewModel = OrganizationViewModel()
    @State private var selectedTab: AppTab = .chat
    @State private var showOnboarding = false
    @State private var showPaywall = false
    @State private var showAccountMenu = false

    var body: some View {
        ZStack {
            // Background
            Color.neatlifyBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HeaderView(showAccountMenu: $showAccountMenu)

                // Top Tab Bar
                TopTabBar(selectedTab: $selectedTab)

                // Tab Content with animation
                Group {
                    switch selectedTab {
                    case .chat:
                        ChatView(viewModel: chatViewModel)
                            .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.95)), removal: .opacity))
                    case .dashboard:
                        DashboardTabView(selectedTab: $selectedTab)
                            .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.95)), removal: .opacity))
                    case .history:
                        HistoryTabView()
                            .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.95)), removal: .opacity))
                    case .shop:
                        ShopTabView(isPresented: $showPaywall)
                            .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.95)), removal: .opacity))
                    case .settings:
                        SettingsTabView()
                            .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.95)), removal: .opacity))
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: selectedTab)

                // Progress overlay (shown when organizing)
                if organizationViewModel.isOrganizing {
                    ProgressOverlayView(viewModel: organizationViewModel)
                }
            }

            // Account menu overlay
            if showAccountMenu {
                AccountMenuView(isOpen: $showAccountMenu)
                    .environmentObject(userSession)
            }

            // Preview sheet overlay
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
    @Binding var showAccountMenu: Bool

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
                showAccountMenu.toggle()
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

            // Menu popup positioned at top right
            VStack(alignment: .leading, spacing: 0) {
                // User Info Section
                VStack(alignment: .leading, spacing: 8) {
                    if let fullName = userSession.userFullName, !fullName.isEmpty {
                        Text(fullName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.neatlifyDark)
                    } else {
                        Text("Account")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.neatlifyDark)
                    }

                    if let email = userSession.userEmail {
                        Text(email)
                            .font(.caption)
                            .foregroundColor(.neatlifyDark.opacity(0.6))
                            .lineLimit(1)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.neatlifyYellow.opacity(0.1))

                Divider()
                    .frame(height: 2)
                    .background(Color.neatlifyDark)

                // Credits Section
                VStack(alignment: .leading, spacing: 6) {
                    Text("Available Credits")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.neatlifyDark.opacity(0.6))
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .foregroundColor(.neatlifyYellow)
                        Text("\(userSession.fileCredits) files")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.neatlifyDark)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()
                    .frame(height: 2)
                    .background(Color.neatlifyDark)

                // Sign Out Button
                Button(action: {
                    signOut()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.right.square")
                        Text("Sign Out")
                    }
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.neatlifyGreen)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                }
                .buttonStyle(.plain)
                .help("Sign out of your account")

                Spacer()
            }
            .frame(width: 240)
            .background(Color.neatlifyBg)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.neatlifyDark, lineWidth: 2)
            )
            .shadow(color: Color.neatlifyDark.opacity(0.2), radius: 10)
            .padding(12)
        }
    }

    private func signOut() {
        // Clear user session
        userSession.unlinkAccount()
        isOpen = false

        // Restart the app
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - Tab Navigation Components

struct TopTabBar: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                VStack(spacing: 0) {
                    HStack(spacing: 6) {
                        Image(systemName: tab.systemImage)
                            .scaleEffect(selectedTab == tab ? 1.2 : 1.0)
                        Text(tab.rawValue)
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .foregroundColor(selectedTab == tab ? .neatlifyDark : .neatlifyDark.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(selectedTab == tab ? Color.white : Color.clear)
                    .cornerRadius(selectedTab == tab ? 8 : 0)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.neatlifyDark, lineWidth: selectedTab == tab ? 2 : 0)
                    )
                    .animation(.easeInOut(duration: 0.2), value: selectedTab)

                    // Underline for active tab with animation
                    if selectedTab == tab {
                        Rectangle()
                            .fill(Color.neatlifyGreen)
                            .frame(height: 3)
                            .transition(.asymmetric(insertion: .scale, removal: .scale))
                    }
                }
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.neatlifyBg)
        .overlay(
            Rectangle()
                .frame(height: 2)
                .foregroundColor(Color.neatlifyDark.opacity(0.1)),
            alignment: .bottom
        )
    }
}

// MARK: - Tab Views

struct DashboardTabView: View {
    @EnvironmentObject var userSession: UserSession
    @Binding var selectedTab: AppTab

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Dashboard")
                        .font(.system(size: 28, weight: .black))
                        .foregroundColor(.neatlifyDark)
                    Text("Overview of your file organization activity")
                        .font(.subheadline)
                        .foregroundColor(.neatlifyDark.opacity(0.6))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 20)

                // Stats Grid (2x2)
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        // Credits Card
                        DashboardStatsCard(
                            title: "Credits",
                            value: "\(userSession.fileCredits)",
                            icon: "sparkles",
                            iconColor: .neatlifyYellow,
                            backgroundColor: Color.neatlifyYellow.opacity(0.1)
                        )

                        // Total Files Card
                        DashboardStatsCard(
                            title: "Files Organized",
                            value: "\(userSession.totalFilesProcessed)",
                            icon: "doc.fill",
                            iconColor: .neatlifyGreen,
                            backgroundColor: Color.neatlifyGreen.opacity(0.1)
                        )
                    }

                    HStack(spacing: 16) {
                        // Cleanups Card
                        DashboardStatsCard(
                            title: "Cleanups",
                            value: "\(userSession.totalCleanupsPerformed)",
                            icon: "checkmark.circle.fill",
                            iconColor: .neatlifyGreen,
                            backgroundColor: Color.neatlifyGreen.opacity(0.1)
                        )

                        // Last Activity Card
                        DashboardStatsCard(
                            title: "Last Activity",
                            value: userSession.lastCleanupDate.map { formatDate($0) } ?? "Never",
                            icon: "clock.fill",
                            iconColor: .neatlifyDark.opacity(0.6),
                            backgroundColor: Color.neatlifyBg
                        )
                    }
                }
                .padding(.horizontal, 20)

                // Quick Actions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Actions")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.neatlifyDark)
                        .padding(.horizontal, 20)

                    HStack(spacing: 12) {
                        QuickActionButton(
                            title: "Start Cleanup",
                            icon: "folder.badge.gearshape",
                            action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedTab = .chat
                                }
                            }
                        )

                        QuickActionButton(
                            title: "Buy Credits",
                            icon: "creditcard.fill",
                            action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedTab = .shop
                                }
                            }
                        )

                        QuickActionButton(
                            title: "View History",
                            icon: "clock.fill",
                            action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedTab = .history
                                }
                            }
                        )
                    }
                    .padding(.horizontal, 20)
                }

                // Recent Activity Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Activity")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.neatlifyDark)
                        .padding(.horizontal, 20)

                    if userSession.organizationHistory.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "inbox.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.neatlifyDark.opacity(0.3))
                            Text("No activity yet")
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.neatlifyDark.opacity(0.5))
                            Text("Start organizing files to see activity here")
                                .font(.caption)
                                .foregroundColor(.neatlifyDark.opacity(0.4))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.neatlifyDark, lineWidth: 2)
                        )
                        .padding(.horizontal, 20)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(userSession.organizationHistory.prefix(5)) { record in
                                HStack(spacing: 12) {
                                    // Status icon
                                    Image(systemName: record.status == .completed ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(record.status == .completed ? .neatlifyGreen : .neatlifyDark.opacity(0.4))
                                        .frame(width: 24)

                                    // Activity info
                                    VStack(alignment: .leading, spacing: 3) {
                                        HStack(spacing: 8) {
                                            Text(record.displayMode)
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.neatlifyDark)
                                                .lineLimit(1)

                                            Spacer()

                                            Text(record.timestamp, style: .time)
                                                .font(.caption2)
                                                .foregroundColor(.neatlifyDark.opacity(0.5))
                                        }

                                        Text(record.folderName)
                                            .font(.caption2)
                                            .foregroundColor(.neatlifyDark.opacity(0.6))
                                            .lineLimit(1)
                                    }

                                    // Credits badge
                                    if record.creditsUsed > 0 {
                                        Text("\(record.creditsUsed)")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.neatlifyYellow)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.neatlifyYellow.opacity(0.2))
                                            .cornerRadius(6)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.neatlifyDark, lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal, 20)

                        // View All button
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTab = .history
                            }
                        }) {
                            Text("View All History →")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.neatlifyGreen)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.neatlifyGreen, lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)
                    }
                }

                Spacer(minLength: 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.neatlifyBg)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Dashboard Components

struct DashboardStatsCard: View {
    let title: String
    let value: String
    let icon: String
    let iconColor: Color
    let backgroundColor: Color
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(iconColor)
                    .frame(width: 40, height: 40)
                    .background(iconColor.opacity(0.2))
                    .cornerRadius(8)
                    .scaleEffect(isHovered ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isHovered)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.neatlifyDark.opacity(0.6))
                Text(value)
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(.neatlifyDark)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(backgroundColor)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.neatlifyDark, lineWidth: 2)
        )
        .onHover { hovering in
            isHovered = hovering
        }
        .shadow(color: Color.neatlifyDark.opacity(isHovered ? 0.15 : 0.05), radius: isHovered ? 8 : 4)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.neatlifyGreen)
                    .scaleEffect(isHovered ? 1.15 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isHovered)

                Text(title)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.neatlifyDark)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isHovered ? Color.neatlifyGreen.opacity(0.05) : Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.neatlifyGreen, lineWidth: 2)
            )
            .shadow(color: Color.neatlifyGreen.opacity(isHovered ? 0.3 : 0.1), radius: isHovered ? 8 : 4)
        }
        .buttonStyle(.plain)
        .help(title)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct HistoryTabView: View {
    @EnvironmentObject var userSession: UserSession
    @State private var selectedFilter: String = "All"
    @State private var searchText: String = ""

    var filteredHistory: [OrganizationRecord] {
        var results = userSession.organizationHistory

        // Filter by mode
        if selectedFilter != "All" {
            results = results.filter { $0.displayMode == selectedFilter }
        }

        // Filter by search text
        if !searchText.isEmpty {
            results = results.filter {
                $0.folderName.localizedCaseInsensitiveContains(searchText) ||
                $0.displayMode.localizedCaseInsensitiveContains(searchText)
            }
        }

        return results
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("History")
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(.neatlifyDark)
                Text("All your file organization activities")
                    .font(.subheadline)
                    .foregroundColor(.neatlifyDark.opacity(0.6))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            // Filter and Search Bar
            VStack(spacing: 12) {
                // Filter buttons
                HStack(spacing: 8) {
                    ForEach(["All", "Organized", "Labeled"], id: \.self) { filter in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedFilter = filter
                            }
                        }) {
                            Text(filter)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(selectedFilter == filter ? .white : .neatlifyDark)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedFilter == filter ? Color.neatlifyGreen : Color.white)
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.neatlifyDark, lineWidth: selectedFilter == filter ? 0 : 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()
                }

                // Search field
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.neatlifyDark.opacity(0.5))
                    TextField("Search history...", text: $searchText)
                        .textFieldStyle(.plain)
                        .foregroundColor(.neatlifyDark)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.neatlifyDark, lineWidth: 1)
                )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

            // Content
            if userSession.organizationHistory.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.neatlifyDark.opacity(0.2))
                    Text("No activity yet")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.neatlifyDark.opacity(0.5))
                    Text("Start organizing files to build your history")
                        .font(.caption)
                        .foregroundColor(.neatlifyDark.opacity(0.4))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.neatlifyBg)
            } else if filteredHistory.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.neatlifyDark.opacity(0.2))
                    Text("No results found")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.neatlifyDark.opacity(0.5))
                    Text("Try adjusting your search or filter")
                        .font(.caption)
                        .foregroundColor(.neatlifyDark.opacity(0.4))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.neatlifyBg)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        let groupedByDate = Dictionary(grouping: filteredHistory) { record in
                            Calendar.current.startOfDay(for: record.timestamp)
                        }

                        ForEach(groupedByDate.keys.sorted(by: >), id: \.self) { date in
                            VStack(alignment: .leading, spacing: 8) {
                                // Date header
                                Text(formatDateHeader(date))
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.neatlifyDark.opacity(0.6))
                                    .padding(.horizontal, 12)
                                    .padding(.top, 12)

                                // Records for this date
                                VStack(spacing: 8) {
                                    ForEach(groupedByDate[date] ?? []) { record in
                                        ActivityCard(record: record)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 12)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .background(Color.neatlifyBg)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.neatlifyBg)
    }

    private func formatDateHeader(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
}

// MARK: - Shop Tab View

struct ShopTabView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var userSession: UserSession

    var body: some View {
        PaywallView(isPresented: $isPresented)
    }
}

// MARK: - Settings Tab View

struct SettingsTabView: View {
    var body: some View {
        SettingsView()
    }
}

// MARK: - Activity Card

struct ActivityCard: View {
    let record: OrganizationRecord
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                // Status icon with background
                Image(systemName: record.status == .completed ? "checkmark.circle.fill" :
                    record.status == .cancelled ? "xmark.circle.fill" : "exclamationmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(
                        record.status == .completed ? .neatlifyGreen :
                        record.status == .cancelled ? .neatlifyDark.opacity(0.3) : .neatlifyDark.opacity(0.5)
                    )
                    .frame(width: 32, height: 32)
                    .background(
                        record.status == .completed ? Color.neatlifyGreen.opacity(0.15) :
                        Color.neatlifyDark.opacity(0.05)
                    )
                    .cornerRadius(8)

                // Main info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(record.displayMode)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.neatlifyDark)

                        Spacer()

                        Text(record.timestamp, style: .time)
                            .font(.caption)
                            .foregroundColor(.neatlifyDark.opacity(0.5))
                    }

                    Text(record.folderName)
                        .font(.caption)
                        .foregroundColor(.neatlifyDark.opacity(0.6))
                        .lineLimit(1)
                }

                Spacer()

                // Status label
                Text(record.displayStatus)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(
                        record.status == .completed ? .neatlifyGreen :
                        record.status == .cancelled ? .neatlifyDark.opacity(0.4) : .neatlifyDark.opacity(0.5)
                    )
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        record.status == .completed ? Color.neatlifyGreen.opacity(0.1) :
                        Color.neatlifyDark.opacity(0.05)
                    )
                    .cornerRadius(4)
            }
            .padding(12)

            // Details row
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "doc.fill")
                        .font(.caption)
                        .foregroundColor(.neatlifyDark.opacity(0.5))
                    Text("\(record.filesProcessed) files")
                        .font(.caption)
                        .foregroundColor(.neatlifyDark.opacity(0.6))
                }

                if record.creditsUsed > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.caption)
                            .foregroundColor(.neatlifyYellow)
                        Text("\(record.creditsUsed) credits")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.neatlifyYellow)
                    }
                }

                if !record.categories.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "folder.fill")
                            .font(.caption)
                            .foregroundColor(.neatlifyDark.opacity(0.5))
                        Text("\(record.categories.count) categories")
                            .font(.caption)
                            .foregroundColor(.neatlifyDark.opacity(0.6))
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
            .background(Color.neatlifyBg)
        }
        .background(Color.white)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.neatlifyDark, lineWidth: 2)
        )
        .shadow(color: Color.neatlifyDark.opacity(isHovered ? 0.15 : 0.05), radius: isHovered ? 8 : 2)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .onHover { hovering in
            isHovered = hovering
        }
        .animation(.easeInOut(duration: 0.2), value: isHovered)
    }
}
