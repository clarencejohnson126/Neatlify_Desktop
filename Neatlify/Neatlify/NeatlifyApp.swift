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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userSession)
                .frame(minWidth: 800, minHeight: 600)
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
}
