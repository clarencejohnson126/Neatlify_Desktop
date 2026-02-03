//
//  SettingsView.swift
//  Neatlify
//
//  App settings and preferences - Matching landing page design
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var userSession: UserSession

    var body: some View {
        ZStack {
            Color.neatlifyBg.ignoresSafeArea()

            TabView {
                GeneralSettingsView()
                    .tabItem {
                        Label("General", systemImage: "gear")
                    }

                SubscriptionSettingsView()
                    .environmentObject(userSession)
                    .tabItem {
                        Label("Credits", systemImage: "sparkles")
                    }

                AboutSettingsView()
                    .tabItem {
                        Label("About", systemImage: "info.circle")
                    }
            }
        }
        .frame(width: 520, height: 480)
    }
}

struct GeneralSettingsView: View {
    @AppStorage("confirmBeforeMoving") private var confirmBeforeMoving = true
    @AppStorage("includeSubfolders") private var includeSubfolders = false

    var body: some View {
        ZStack {
            Color.neatlifyBg.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                // Organization section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "folder.badge.gearshape")
                            .foregroundColor(.neatlifyGreen)
                        Text("Organization")
                            .font(.headline)
                            .fontWeight(.black)
                            .foregroundColor(.neatlifyDark)
                    }

                    VStack(spacing: 12) {
                        SettingsToggleRow(
                            title: "Confirm before moving files",
                            subtitle: "Show preview before organizing",
                            isOn: $confirmBeforeMoving
                        )

                        SettingsToggleRow(
                            title: "Include subfolders",
                            subtitle: "Scan nested folders when organizing",
                            isOn: $includeSubfolders
                        )
                    }
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.neatlifyDark, lineWidth: 2)
                )

                // Maintenance section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "wrench.and.screwdriver")
                            .foregroundColor(.neatlifyYellow)
                        Text("Maintenance")
                            .font(.headline)
                            .fontWeight(.black)
                            .foregroundColor(.neatlifyDark)
                    }

                    Button(action: {
                        FileService.shared.clearOldHistory(olderThan: 0)
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Clear Operation History")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.neatlifyRed)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.neatlifyRed.opacity(0.1))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.neatlifyDark, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.neatlifyDark, lineWidth: 2)
                )

                Spacer()
            }
            .padding(24)
        }
    }
}

struct SettingsToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.neatlifyDark)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.neatlifyDark.opacity(0.6))
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .tint(.neatlifyGreen)
        }
        .padding(12)
        .background(Color.neatlifyBg)
        .cornerRadius(8)
    }
}

struct SubscriptionSettingsView: View {
    @EnvironmentObject var userSession: UserSession
    @State private var showVerifySheet = false
    @State private var showLinkSheet = false
    @State private var isSyncing = false

    var body: some View {
        ZStack {
            Color.neatlifyBg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Credits display card
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "sparkles")
                                .font(.title2)
                                .foregroundColor(.neatlifyYellow)
                            Text("Your Credits")
                                .font(.headline)
                                .fontWeight(.black)
                                .foregroundColor(.neatlifyDark)
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
                                            .foregroundColor(.neatlifyGreen)
                                    }
                                }
                                .buttonStyle(.plain)
                                .disabled(isSyncing)
                            }
                        }

                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("\(userSession.fileCredits)")
                                .font(.system(size: 56, weight: .black))
                                .foregroundColor(.neatlifyGreen)

                            Text("files")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.neatlifyDark.opacity(0.6))
                        }

                        if !userSession.hasUsedFreeCleanup && !userSession.isAccountLinked {
                            HStack(spacing: 8) {
                                Image(systemName: "gift.fill")
                                    .foregroundColor(.neatlifyGreen)
                                Text("Free trial available!")
                                    .fontWeight(.bold)
                                    .foregroundColor(.neatlifyGreen)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.neatlifyGreen.opacity(0.15))
                            .cornerRadius(8)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(Color.neatlifyYellow.opacity(0.2))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.neatlifyDark, lineWidth: 2)
                    )

                    // Account section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "person.circle")
                                .foregroundColor(.neatlifyGreen)
                            Text("Account")
                                .font(.headline)
                                .fontWeight(.black)
                                .foregroundColor(.neatlifyDark)
                        }

                        if userSession.isAccountLinked {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.neatlifyGreen)
                                Text(userSession.userEmail ?? "Linked")
                                    .font(.subheadline)
                                    .foregroundColor(.neatlifyDark)
                                Spacer()
                                Button(action: {
                                    userSession.unlinkAccount()
                                }) {
                                    Text("Unlink")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.neatlifyRed)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(12)
                            .background(Color.neatlifyGreen.opacity(0.1))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.neatlifyDark, lineWidth: 2)
                            )
                        } else {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.neatlifyYellow)
                                    Text("Link to sync purchased credits")
                                        .font(.subheadline)
                                        .foregroundColor(.neatlifyDark.opacity(0.7))
                                }

                                Button(action: {
                                    showLinkSheet = true
                                }) {
                                    HStack {
                                        Image(systemName: "link")
                                        Text("Link Account")
                                            .fontWeight(.bold)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Color.neatlifyGreen)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.neatlifyDark, lineWidth: 2)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.neatlifyDark, lineWidth: 2)
                    )

                    // Usage stats
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "chart.bar")
                                .foregroundColor(.neatlifyYellow)
                            Text("Statistics")
                                .font(.headline)
                                .fontWeight(.black)
                                .foregroundColor(.neatlifyDark)
                        }

                        HStack {
                            StatsCard(
                                icon: "checkmark.circle",
                                value: "\(userSession.totalCleanupsPerformed)",
                                label: "Cleanups"
                            )
                            StatsCard(
                                icon: "doc.on.doc",
                                value: "\(userSession.totalFilesProcessed)",
                                label: "Files"
                            )
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.neatlifyDark, lineWidth: 2)
                    )

                    // Action buttons
                    HStack(spacing: 12) {
                        Button(action: {
                            NotificationCenter.default.post(name: .showPaywall, object: nil)
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Buy Credits")
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.neatlifyGreen)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.neatlifyDark, lineWidth: 2)
                            )
                            .shadow(color: Color.neatlifyDark.opacity(0.2), radius: 0, x: 3, y: 3)
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            showVerifySheet = true
                        }) {
                            HStack {
                                Image(systemName: "checkmark.shield")
                                Text("Verify")
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.neatlifyDark)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.neatlifyDark, lineWidth: 2)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(24)
            }
        }
        .sheet(isPresented: $showVerifySheet) {
            VerifyPaymentView(userSession: userSession, isPresented: $showVerifySheet)
        }
        .sheet(isPresented: $showLinkSheet) {
            LinkAccountView(userSession: userSession, isPresented: $showLinkSheet)
        }
    }
}

struct StatsCard: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundColor(.neatlifyGreen)
                Text(value)
                    .font(.title2)
                    .fontWeight(.black)
                    .foregroundColor(.neatlifyDark)
            }
            Text(label)
                .font(.caption)
                .foregroundColor(.neatlifyDark.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color.neatlifyBg)
        .cornerRadius(8)
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
        ZStack {
            Color.neatlifyBg.ignoresSafeArea()

            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.neatlifyGreen)
                            .frame(width: 70, height: 70)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.neatlifyDark, lineWidth: 3)
                            )
                            .shadow(color: Color.neatlifyDark.opacity(0.2), radius: 0, x: 4, y: 4)
                        Image(systemName: "link")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Text("Link Your Account")
                        .font(.system(size: 24, weight: .black))
                        .foregroundColor(.neatlifyDark)

                    Text("Enter the email you used on neatlify.com")
                        .font(.subheadline)
                        .foregroundColor(.neatlifyDark.opacity(0.6))
                }

                // Info card
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.neatlifyYellow)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Credits are synced from our server")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.neatlifyDark)
                        Text("Link to access your purchased credits")
                            .font(.caption)
                            .foregroundColor(.neatlifyDark.opacity(0.6))
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.neatlifyYellow.opacity(0.15))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.neatlifyDark, lineWidth: 2)
                )

                // Email input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email Address")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.neatlifyDark.opacity(0.6))

                    HStack {
                        Image(systemName: "envelope")
                            .foregroundColor(.neatlifyDark.opacity(0.4))
                        TextField("you@example.com", text: $emailInput)
                            .textFieldStyle(.plain)
                            .textContentType(.emailAddress)
                    }
                    .padding(14)
                    .background(Color.white)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.neatlifyDark, lineWidth: 2)
                    )
                }

                // Buttons
                VStack(spacing: 12) {
                    Button(action: linkAccount) {
                        HStack {
                            if isLinking {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "link.badge.plus")
                                Text("Link & Sync Credits")
                                    .fontWeight(.bold)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isValidEmail(emailInput) && !isLinking ? Color.neatlifyGreen : Color.neatlifyDark.opacity(0.3))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.neatlifyDark, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(emailInput.isEmpty || isLinking || !isValidEmail(emailInput))

                    Button(action: {
                        isPresented = false
                    }) {
                        Text("Cancel")
                            .fontWeight(.semibold)
                            .foregroundColor(.neatlifyDark.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(32)
        }
        .frame(width: 420, height: 480)
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
                let credits = try await SupabaseService.shared.getCredits(userEmail: email)

                await MainActor.run {
                    isLinking = false
                    userSession.linkAccount(email: email)
                    userSession.fileCredits = credits
                    creditsFound = credits
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isLinking = false

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
        ZStack {
            Color.neatlifyBg.ignoresSafeArea()

            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.neatlifyYellow)
                            .frame(width: 70, height: 70)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.neatlifyDark, lineWidth: 3)
                            )
                            .shadow(color: Color.neatlifyDark.opacity(0.2), radius: 0, x: 4, y: 4)
                        Image(systemName: "checkmark.shield")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.neatlifyDark)
                    }

                    Text("Verify Payment")
                        .font(.system(size: 24, weight: .black))
                        .foregroundColor(.neatlifyDark)

                    Text("Paste your Stripe checkout session ID")
                        .font(.subheadline)
                        .foregroundColor(.neatlifyDark.opacity(0.6))
                }

                // Info card
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.neatlifyGreen)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Where to find your session ID")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.neatlifyDark)
                        Text("Check your email confirmation or paste the success URL")
                            .font(.caption)
                            .foregroundColor(.neatlifyDark.opacity(0.6))
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.neatlifyGreen.opacity(0.1))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.neatlifyDark, lineWidth: 2)
                )

                // Session ID input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Session ID")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.neatlifyDark.opacity(0.6))

                    HStack {
                        Image(systemName: "key")
                            .foregroundColor(.neatlifyDark.opacity(0.4))
                        TextField("Stripe session ID", text: $sessionIdInput)
                            .textFieldStyle(.plain)
                            .font(.system(.body, design: .monospaced))
                    }
                    .padding(14)
                    .background(Color.white)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.neatlifyDark, lineWidth: 2)
                    )
                }

                // Buttons
                VStack(spacing: 12) {
                    Button(action: verifyPayment) {
                        HStack {
                            if isVerifying {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "checkmark.circle")
                                Text("Verify & Add Credits")
                                    .fontWeight(.bold)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(!sessionIdInput.isEmpty && !isVerifying ? Color.neatlifyGreen : Color.neatlifyDark.opacity(0.3))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.neatlifyDark, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(sessionIdInput.isEmpty || isVerifying)

                    Button(action: {
                        isPresented = false
                    }) {
                        Text("Cancel")
                            .fontWeight(.semibold)
                            .foregroundColor(.neatlifyDark.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(32)
        }
        .frame(width: 420, height: 480)
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
        var sessionId = sessionIdInput.trimmingCharacters(in: .whitespacesAndNewlines)

        if sessionId.contains("session_id=") {
            if let range = sessionId.range(of: "session_id=") {
                sessionId = String(sessionId[range.upperBound...])
                if let endRange = sessionId.range(of: "&") {
                    sessionId = String(sessionId[..<endRange.lowerBound])
                }
            }
        }

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
        ZStack {
            Color.neatlifyBg.ignoresSafeArea()

            VStack(spacing: 24) {
                // Logo
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.neatlifyGreen)
                        .frame(width: 100, height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.neatlifyDark, lineWidth: 3)
                        )
                        .shadow(color: Color.neatlifyDark.opacity(0.2), radius: 0, x: 5, y: 5)
                    Text("N")
                        .font(.system(size: 54, weight: .black))
                        .foregroundColor(.white)
                }

                VStack(spacing: 8) {
                    Text("Neatlify")
                        .font(.system(size: 32, weight: .black))
                        .foregroundColor(.neatlifyDark)

                    Text("Version 1.0.0")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.neatlifyDark.opacity(0.5))

                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .foregroundColor(.neatlifyYellow)
                        Text("Organize your files with AI")
                            .font(.subheadline)
                            .foregroundColor(.neatlifyDark.opacity(0.7))
                    }
                    .padding(.top, 4)
                }

                // Links card
                VStack(spacing: 0) {
                    AboutLinkRow(icon: "lock.shield", title: "Privacy Policy", url: "https://neatlify.com/privacy")
                    Divider()
                        .background(Color.neatlifyDark.opacity(0.2))
                    AboutLinkRow(icon: "doc.text", title: "Terms of Service", url: "https://neatlify.com/terms")
                    Divider()
                        .background(Color.neatlifyDark.opacity(0.2))
                    AboutLinkRow(icon: "questionmark.circle", title: "Support", url: "https://neatlify.com/support")
                    Divider()
                        .background(Color.neatlifyDark.opacity(0.2))
                    AboutLinkRow(icon: "globe", title: "Visit Website", url: "https://clarencejohnson126.github.io/Neatlify_Desktop/")
                }
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.neatlifyDark, lineWidth: 2)
                )

                // Tech badge
                HStack(spacing: 8) {
                    Text("Powered by")
                        .font(.caption)
                        .foregroundColor(.neatlifyDark.opacity(0.5))
                    Text("Claude AI")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.neatlifyDark)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.neatlifyYellow.opacity(0.3))
                        .cornerRadius(6)
                }

                Spacer()
            }
            .padding(24)
        }
    }
}

struct AboutLinkRow: View {
    let icon: String
    let title: String
    let url: String

    var body: some View {
        Link(destination: URL(string: url)!) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.neatlifyGreen)
                    .frame(width: 24)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.neatlifyDark)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundColor(.neatlifyDark.opacity(0.4))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }
}

extension Notification.Name {
    static let showPaywall = Notification.Name("showPaywall")
}
