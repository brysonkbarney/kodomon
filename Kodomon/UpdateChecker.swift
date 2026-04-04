import Foundation
import Sparkle

class UpdateChecker {
    static let shared = UpdateChecker()
    private let updaterController: SPUStandardUpdaterController

    private init() {
        // startingUpdater: true → automatic background check on launch
        // (Sparkle defers first auto-check to second launch, by design)
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }
}
