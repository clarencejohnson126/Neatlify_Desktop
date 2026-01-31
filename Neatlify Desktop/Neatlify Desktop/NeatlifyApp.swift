//
//  NeatlifyApp.swift
//  Neatlify
//
//  macOS file organization app with Claude AI
//

import SwiftUI

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
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
                .alert("Payment Successful!", isPresented: $showPaymentSuccess) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("\(creditsAdded) credits have been added to your account!")
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
                        userSession.fileCredits += credits
                        userSession.save()
                        creditsAdded = credits
                        showPaymentSuccess = true
                        Logger.shared.info("Payment verified! Added \(credits) credits")

                    case .notPaid:
                        showError("Payment not completed. Please try again.")

                    case .alreadyUsed:
                        showError("This payment has already been activated.")

                    case .unknownProduct:
                        showError("Unknown product. Please contact support.")
                    }
                }
            } catch {
                await MainActor.run {
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
