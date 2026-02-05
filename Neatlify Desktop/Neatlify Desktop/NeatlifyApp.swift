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

                    // Check if user has active Supabase Auth session
                    userSession.checkAuthStatus()

                    // Attempt to auto-sync credits from server
                    // This helps users see their purchased credits without manual linking
                    Task {
                        // Check if we have cached credits - if so, try to sync server version
                        if userSession.fileCredits > 0 {
                            Logger.shared.info("Found cached credits: \(userSession.fileCredits), syncing from server...")
                            await userSession.syncCreditsFromServer()
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
        // Handle Stripe checkout redirects:
        // Success: neatlify://checkout/success?session_id=cs_xxx
        // Cancel: neatlify://checkout/cancel
        Logger.shared.info("Received URL: \(url.absoluteString)")

        guard url.scheme == "neatlify" else { return }

        let path = url.path

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
}
