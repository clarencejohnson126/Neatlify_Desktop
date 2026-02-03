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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userSession)
                .frame(minWidth: 800, minHeight: 600)
                .onAppear {
                    // Initialize StoreKit transaction listener for App Store version
                    _ = StoreKitManager.shared

                    // Sync credits from server on app launch to ensure fresh data
                    if userSession.isAccountLinked {
                        Task {
                            await userSession.syncCreditsFromServer()
                        }
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
        // Expected URL: neatlify://activate?session_id=cs_xxx
        Logger.shared.info("Received URL: \(url.absoluteString)")

        guard url.scheme == "neatlify" else { return }

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
