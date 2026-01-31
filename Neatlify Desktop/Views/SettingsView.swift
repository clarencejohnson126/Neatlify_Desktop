//
//  SettingsView.swift
//  Neatlify
//
//  App settings and preferences
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var userSession: UserSession

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            SubscriptionSettingsView()
                .environmentObject(userSession)
                .tabItem {
                    Label("Subscription", systemImage: "creditcard")
                }

            AboutSettingsView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 500, height: 400)
    }
}

struct GeneralSettingsView: View {
    @AppStorage("confirmBeforeMoving") private var confirmBeforeMoving = true
    @AppStorage("includeSubfolders") private var includeSubfolders = false

    var body: some View {
        Form {
            Section {
                Toggle("Confirm before moving files", isOn: $confirmBeforeMoving)
                Toggle("Include subfolders when scanning", isOn: $includeSubfolders)
            } header: {
                Text("Organization")
            }

            Section {
                Button("Clear Operation History") {
                    FileService.shared.clearOldHistory(olderThan: 0)
                }
            } header: {
                Text("Maintenance")
            }
        }
        .padding()
    }
}

struct SubscriptionSettingsView: View {
    @EnvironmentObject var userSession: UserSession
    @State private var showVerifySheet = false
    @State private var showLinkSheet = false
    @State private var isSyncing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Account section
            VStack(alignment: .leading, spacing: 8) {
                Text("Account")
                    .font(.headline)

                if userSession.isAccountLinked {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(userSession.userEmail ?? "Linked")
                            .font(.subheadline)
                        Spacer()
                        Button("Unlink") {
                            userSession.unlinkAccount()
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                    }
                    .padding(8)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                } else {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Link your account to sync credits")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Button("Link Account") {
                        showLinkSheet = true
                    }
                    .buttonStyle(.bordered)
                }
            }

            Divider()

            // Credits section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Credits")
                        .font(.headline)
                    Spacer()
                    if userSession.isAccountLinked {
                        Button(action: {
                            isSyncing = true
                            Task {
                                await userSession.syncCreditsFromServer()
                                await MainActor.run {
                                    isSyncing = false
                                }
                            }
                        }) {
                            if isSyncing {
                                ProgressView()
                                    .scaleEffect(0.7)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                        }
                        .buttonStyle(.borderless)
                        .disabled(isSyncing)
                    }
                }

                HStack(alignment: .firstTextBaseline) {
                    Text("\(userSession.fileCredits)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.blue)

                    Text("files remaining")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }

                if !userSession.hasUsedFreeCleanup && !userSession.isAccountLinked {
                    HStack {
                        Image(systemName: "gift.fill")
                            .foregroundColor(.green)
                        Text("Free trial available (100 files)")
                            .foregroundColor(.green)
                    }
                    .font(.subheadline)
                }
            }

            Divider()

            // Usage stats
            VStack(alignment: .leading, spacing: 8) {
                Text("Usage Statistics")
                    .font(.headline)

                HStack {
                    Text("Total cleanups:")
                    Spacer()
                    Text("\(userSession.totalCleanupsPerformed)")
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("Files organized:")
                    Spacer()
                    Text("\(userSession.totalFilesProcessed)")
                        .fontWeight(.semibold)
                }

                if let lastDate = userSession.lastCleanupDate {
                    HStack {
                        Text("Last cleanup:")
                        Spacer()
                        Text(lastDate, style: .date)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .font(.body)

            Divider()

            // Purchase buttons
            VStack(alignment: .leading, spacing: 12) {
                Button("Buy More Credits") {
                    NotificationCenter.default.post(name: .showPaywall, object: nil)
                }
                .buttonStyle(.borderedProminent)

                Button("Already Paid? Verify Payment") {
                    showVerifySheet = true
                }
                .buttonStyle(.bordered)
                .font(.caption)
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .sheet(isPresented: $showVerifySheet) {
            VerifyPaymentView(userSession: userSession, isPresented: $showVerifySheet)
        }
        .sheet(isPresented: $showLinkSheet) {
            LinkAccountView(userSession: userSession, isPresented: $showLinkSheet)
        }
    }
}

struct LinkAccountView: View {
    @ObservedObject var userSession: UserSession
    @Binding var isPresented: Bool
    @State private var emailInput = ""
    @State private var isLinking = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var showSuccess = false
    @State private var creditsFound = 0

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "person.badge.key.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)

                Text("Link Your Account")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Enter the email you used on neatlify.com")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Instructions
            VStack(alignment: .leading, spacing: 8) {
                Text("Your credits are stored on our server.")
                Text("Link your account to sync them here.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Email input
            TextField("Email address", text: $emailInput)
                .textFieldStyle(.roundedBorder)
                .textContentType(.emailAddress)

            // Link button
            Button(action: linkAccount) {
                if isLinking {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text("Link & Sync Credits")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(emailInput.isEmpty || isLinking || !isValidEmail(emailInput))

            Button("Cancel") {
                isPresented = false
            }
            .foregroundColor(.secondary)
        }
        .padding(32)
        .frame(width: 400)
        .alert("Linking Failed", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Account Linked!", isPresented: $showSuccess) {
            Button("OK") {
                isPresented = false
            }
        } message: {
            Text("Found \(creditsFound) credits on your account!")
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    private func linkAccount() {
        let email = emailInput.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        isLinking = true

        Task {
            do {
                // Try to get credits from server to verify account exists
                let credits = try await SupabaseService.shared.getCredits(userEmail: email)

                await MainActor.run {
                    isLinking = false

                    // Link the account
                    userSession.linkAccount(email: email)
                    userSession.fileCredits = credits

                    creditsFound = credits
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isLinking = false

                    // Check if it's a "user not found" error
                    if error.localizedDescription.contains("not found") {
                        errorMessage = "No account found with this email. Please sign up at neatlify.com first."
                    } else {
                        errorMessage = "Could not connect to server. Please check your internet connection."
                    }
                    showError = true
                }
            }
        }
    }
}

struct VerifyPaymentView: View {
    @ObservedObject var userSession: UserSession
    @Binding var isPresented: Bool
    @State private var sessionIdInput = ""
    @State private var isVerifying = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var showSuccess = false
    @State private var creditsAdded = 0

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)

                Text("Verify Payment")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Paste your Stripe checkout session ID")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Instructions
            VStack(alignment: .leading, spacing: 8) {
                Text("After payment, you received a confirmation.")
                Text("The session ID looks like: cs_test_xxx...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Input field
            TextField("Session ID (cs_test_...)", text: $sessionIdInput)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))

            // Verify button
            Button(action: verifyPayment) {
                if isVerifying {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text("Verify & Add Credits")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(sessionIdInput.isEmpty || isVerifying)

            Button("Cancel") {
                isPresented = false
            }
            .foregroundColor(.secondary)
        }
        .padding(32)
        .frame(width: 400)
        .alert("Verification Failed", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Payment Verified!", isPresented: $showSuccess) {
            Button("OK") {
                isPresented = false
            }
        } message: {
            Text("\(creditsAdded) credits have been added to your account!")
        }
    }

    private func verifyPayment() {
        // Clean up input - extract session ID if full URL pasted
        var sessionId = sessionIdInput.trimmingCharacters(in: .whitespacesAndNewlines)

        // If user pasted a URL, extract the session_id parameter
        if sessionId.contains("session_id=") {
            if let range = sessionId.range(of: "session_id=") {
                sessionId = String(sessionId[range.upperBound...])
                if let endRange = sessionId.range(of: "&") {
                    sessionId = String(sessionId[..<endRange.lowerBound])
                }
            }
        }

        // Validate format
        guard sessionId.hasPrefix("cs_") else {
            errorMessage = "Invalid session ID. It should start with 'cs_'"
            showError = true
            return
        }

        isVerifying = true

        Task {
            do {
                let result = try await StripeService.shared.verifyCheckoutSession(sessionId)

                await MainActor.run {
                    isVerifying = false

                    switch result {
                    case .success(let credits):
                        userSession.fileCredits += credits
                        userSession.save()
                        creditsAdded = credits
                        showSuccess = true

                    case .notPaid:
                        errorMessage = "This payment hasn't been completed yet."
                        showError = true

                    case .alreadyUsed:
                        errorMessage = "This payment has already been activated."
                        showError = true

                    case .unknownProduct:
                        errorMessage = "Couldn't determine credits for this purchase. Contact support."
                        showError = true
                    }
                }
            } catch {
                await MainActor.run {
                    isVerifying = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

struct AboutSettingsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("Neatlify")
                .font(.title)
                .fontWeight(.bold)

            Text("Version 1.0.0")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Organize your files with AI")
                .font(.body)

            Divider()

            VStack(spacing: 8) {
                Link("Privacy Policy", destination: URL(string: "https://neatlify.com/privacy")!)
                Link("Terms of Service", destination: URL(string: "https://neatlify.com/terms")!)
                Link("Support", destination: URL(string: "https://neatlify.com/support")!)
            }
            .font(.caption)

            Spacer()
        }
        .padding()
    }
}

extension Notification.Name {
    static let showPaywall = Notification.Name("showPaywall")
}
