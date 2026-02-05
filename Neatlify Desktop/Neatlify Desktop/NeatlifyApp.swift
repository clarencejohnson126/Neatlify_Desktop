//
//  NeatlifyApp.swift
//  Neatlify
//
//  macOS file organization app with Claude AI
//

import SwiftUI
import AppKit

@main
struct NeatlifyApp: App {
    @StateObject private var userSession = UserSession.load()
    @State private var showPaymentSuccess = false
    @State private var creditsAdded = 0
    @State private var showPaymentError = false
    @State private var paymentErrorMessage = ""
    @State private var shouldReset = false

    var body: some Scene {
        WindowGroup {
            Group {
                if userSession.isAccountLinked {
                    ContentView()
                        .environmentObject(userSession)
                        .frame(minWidth: 900, minHeight: 600)
                } else {
                    AuthenticationView()
                        .environmentObject(userSession)
                        .frame(minWidth: 500, minHeight: 600)
                }
            }
                .onAppear {
                    // Initialize StoreKit transaction listener for App Store version
                    _ = StoreKitManager.shared

                    // CRITICAL: Clean up any stale cached data from previous users
                    UserSession.cleanupStaleCache()

                    // CRITICAL: Check auth FIRST before using cached data
                    userSession.checkAuthStatus()

                    Task {
                        // Brief delay for auth verification
                        try? await Task.sleep(nanoseconds: 100_000_000)

                        // Only sync if valid authenticated session
                        if userSession.isAccountLinked,
                           let email = AuthSessionStorage.shared.getUserEmail() {
                            Logger.shared.info("Valid session for \(email), syncing credits...")
                            await userSession.syncCreditsFromServer()
                        } else {
                            Logger.shared.info("No valid session - skipping credit sync")
                            await MainActor.run {
                                if userSession.fileCredits > 0 {
                                    Logger.shared.warning("Clearing stale credits on launch")
                                    userSession.fileCredits = 0
                                    userSession.save()
                                }
                            }
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserDidSignOut"))) { _ in
                    // User signed out - restart the app to reload fresh session
                    Logger.shared.info("Sign out notification received, restarting app...")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        NSApplication.shared.terminate(nil)
                    }
                }
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                    // Sync credits when app becomes active (in case user paid and returned)
                    if userSession.isAccountLinked {
                        Task {
                            await userSession.syncCreditsFromServer()
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .creditsDidChange)) { _ in
                    // Refresh credits from saved UserDefaults after organization completes
                    let savedSession = UserSession.load()
                    userSession.fileCredits = savedSession.fileCredits
                    Logger.shared.info("Credits refreshed in UI: \(userSession.fileCredits)")
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AccountDidSwitch"))) { notification in
                    // Account was switched (via deep link auth or login)
                    if let userInfo = notification.userInfo,
                       let newEmail = userInfo["email"] as? String {
                        Logger.shared.info("🔄 Account switched to: \(newEmail)")
                        // Reload session and sync credits
                        DispatchQueue.main.async {
                            let newSession = UserSession.load()
                            userSession.userEmail = newSession.userEmail
                            userSession.fileCredits = newSession.fileCredits
                            userSession.isAuthenticatedWithSupabase = newSession.isAuthenticatedWithSupabase
                            Task {
                                await userSession.syncCreditsFromServer()
                            }
                        }
                    }
                }
                .alert("Payment Successful!", isPresented: $showPaymentSuccess) {
                    Button("Start Organizing", role: .cancel) {}
                } message: {
                    Text("\(creditsAdded) credits have been added to your account! You can now organize your files.")
                }
                .alert("Payment Error", isPresented: $showPaymentError) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(paymentErrorMessage)
                }
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }

        Settings {
            SettingsView()
                .environmentObject(userSession)
        }
    }

    private func handleIncomingURL(_ url: URL) {
        // Handle deep links:
        // Auth callback: neatlify://auth-callback?access_token=...&refresh_token=...&user_email=...&exp=...&iat=...
        // Checkout success: neatlify://checkout/success?session_id=cs_xxx
        // Checkout cancel: neatlify://checkout/cancel
        Logger.shared.info("Received URL: \(url.absoluteString)")

        guard url.scheme == "neatlify" else { return }

        let path = url.path

        // Handle auth callback (landing page → desktop app authentication)
        if path.contains("auth-callback") {
            handleAuthCallback(url)
            return
        }

        // Handle checkout paths
        if path.contains("checkout/success") {
            // Parse query parameters
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let queryItems = components.queryItems else {
                showError("Invalid payment URL")
                return
            }

            // Look for session_id parameter
            if let sessionId = queryItems.first(where: { $0.name == "session_id" })?.value {
                verifyPayment(sessionId: sessionId)
            } else {
                showError("Missing session ID in payment URL")
            }
        } else if path.contains("checkout/cancel") {
            // User cancelled payment - just sync to see if they have credits
            Logger.shared.info("Payment cancelled, syncing credits...")
            Task {
                await userSession.syncCreditsFromServer()
            }
        }
    }

    private func verifyPayment(sessionId: String) {
        Task {
            do {
                let result = try await StripeService.shared.verifyCheckoutSession(sessionId)

                await MainActor.run {
                    switch result {
                    case .success(let credits):
                        // Sync credits from server instead of adding locally
                        // (credits were already added server-side by the success page)
                        Task {
                            await userSession.syncCreditsFromServer()
                        }
                        creditsAdded = credits
                        showPaymentSuccess = true
                        Logger.shared.info("Payment verified! Synced \(credits) credits from server")

                    case .notPaid:
                        showError("Payment not completed. Please try again.")

                    case .alreadyUsed:
                        // Already processed - just sync credits from server
                        Task {
                            await userSession.syncCreditsFromServer()
                        }
                        Logger.shared.info("Payment already activated - syncing credits from server")

                    case .unknownProduct:
                        showError("Unknown product. Please contact support.")
                    }
                }
            } catch {
                await MainActor.run {
                    // If verification fails, still try to sync from server
                    // (in case payment was already processed)
                    Task {
                        await userSession.syncCreditsFromServer()
                    }
                    showError("Failed to verify payment: \(error.localizedDescription)")
                }
            }
        }
    }

    private func showError(_ message: String) {
        paymentErrorMessage = message
        showPaymentError = true
        Logger.shared.error("Payment error: \(message)")
    }

    private func handleAuthCallback(_ url: URL) {
        Logger.shared.info("🔐 Received auth-callback from landing page")

        // Parse query parameters
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            Logger.shared.error("Invalid auth-callback URL format")
            showError("Authentication failed: Invalid URL format")
            return
        }

        // Extract parameters
        let params = Dictionary(uniqueKeysWithValues: queryItems.map { ($0.name, $0.value) })
        let accessToken = params["access_token"]
        let refreshToken = params["refresh_token"]
        let userEmail = params["user_email"]
        let exp = params["exp"]
        let iat = params["iat"]

        Logger.shared.info("Auth params received - email: \(userEmail ?? "unknown")")

        // Validate all parameters
        let validationResult = AuthTokenValidator.validateDeepLinkParams(
            accessToken: accessToken,
            refreshToken: refreshToken,
            userEmail: userEmail,
            exp: exp,
            iat: iat
        )

        switch validationResult {
        case .success(let params):
            Logger.shared.info("✅ Auth tokens validated successfully")
            authenticateFromDeepLink(params)

        case .failure(let error):
            Logger.shared.error("❌ Auth token validation failed: \(error)")
            showError("Authentication failed: \(error.localizedDescription)")
        }
    }

    private func authenticateFromDeepLink(_ params: AuthTokenValidator.DeepLinkParams) {
        Logger.shared.info("🔄 Authenticating from deep link for: \(params.userEmail)")

        // Check if switching users
        let currentEmail = AuthSessionStorage.shared.getUserEmail()
        if let currentEmail = currentEmail, currentEmail != params.userEmail {
            Logger.shared.warning("🔄 User switch detected: \(currentEmail) → \(params.userEmail)")
            // The UserSession.checkAuthStatus() will handle the cleanup
        }

        // Save session to AuthSessionStorage
        AuthSessionStorage.shared.saveAccessToken(params.accessToken)
        AuthSessionStorage.shared.saveRefreshToken(params.refreshToken)
        AuthSessionStorage.shared.saveUserEmail(params.userEmail)

        Logger.shared.info("💾 Session saved to Keychain for: \(params.userEmail)")

        // Update UserSession
        userSession.checkAuthStatus()

        // Sync credits from server
        Task {
            await userSession.syncCreditsFromServer()
        }

        Logger.shared.info("✅ Desktop app authenticated from web login")
    }
}
