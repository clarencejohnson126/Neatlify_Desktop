//
//  AppTab.swift
//  Neatlify
//
//  Tab navigation model
//

import Foundation

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
