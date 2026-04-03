import Foundation

// Sparkle auto-update integration
// To enable:
// 1. Add Sparkle via Xcode → File → Add Package → https://github.com/sparkle-project/Sparkle
// 2. Uncomment the Sparkle imports and code below
// 3. Host an appcast.xml file at your update URL

/*
import Sparkle

class UpdateChecker {
    static let shared = UpdateChecker()
    private let updater: SPUStandardUpdaterController

    private init() {
        updater = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    func checkForUpdates() {
        updater.checkForUpdates(nil)
    }
}
*/

// Placeholder until Sparkle is added
class UpdateChecker {
    static let shared = UpdateChecker()

    func checkForUpdates() {
        NSLog("[Kodomon] Auto-updates not configured yet. Add Sparkle via SPM.")
    }
}
