import Foundation

enum DistributionMethod {
    case appStore
    case direct
}

/// Detects whether the app was distributed via Mac App Store or as a direct download (DMG).
/// Used at runtime to determine which payment method to present to users.
class DistributionDetector {
    static let shared = DistributionDetector()

    let method: DistributionMethod

    private init() {
        #if DEBUG
        // In debug builds, always assume direct distribution for testing
        method = .direct
        #else
        // In release builds, check for App Store receipt
        if let receiptURL = Bundle.main.appStoreReceiptURL,
           FileManager.default.fileExists(atPath: receiptURL.path) {
            method = .appStore
        } else {
            method = .direct
        }
        #endif
    }

    var isAppStoreDistribution: Bool {
        return method == .appStore
    }

    var isDirectDistribution: Bool {
        return method == .direct
    }
}
