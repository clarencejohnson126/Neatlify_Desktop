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

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if userSession.hasActiveSubscription {
                // Active subscription
                VStack(alignment: .leading, spacing: 8) {
                    Text("Subscription Status")
                        .font(.headline)

                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)

                        if let type = userSession.subscriptionType {
                            Text(type == .lifetime ? "Lifetime Access" : "Monthly Subscription")
                        }
                    }

                    if let expiryDate = userSession.subscriptionExpiryDate {
                        Text("Renews: \(expiryDate, style: .date)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Usage")
                        .font(.headline)

                    Text("Total cleanups: \(userSession.totalCleanupsPerformed)")
                        .font(.body)

                    if let lastDate = userSession.lastCleanupDate {
                        Text("Last cleanup: \(lastDate, style: .date)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                // Free trial
                VStack(alignment: .leading, spacing: 8) {
                    Text("Free Trial")
                        .font(.headline)

                    Text("\(userSession.freeTrialCleanupsRemaining) cleanups remaining")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)

                    Text("Upgrade to unlock unlimited cleanups")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Button("Upgrade Now") {
                    // Open paywall
                    NotificationCenter.default.post(name: .showPaywall, object: nil)
                }
                .buttonStyle(.borderedProminent)
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
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
