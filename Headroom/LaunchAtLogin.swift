import Foundation
import Observation
import os
import ServiceManagement

/// Controls whether Headroom opens automatically when you log in.
@Observable
final class LaunchAtLogin {
    private static let didConfigureKey = "didConfigureLaunchAtLogin"

    /// Whether Headroom is registered as a login item.
    private(set) var isEnabled: Bool

    @ObservationIgnored
    private let logger = Logger(
        subsystem: "io.github.ontckr.Headroom",
        category: "LaunchAtLogin"
    )

    init() {
        isEnabled = SMAppService.mainApp.status == .enabled
        enableOnFirstRunIfInstalled()
    }

    /// Registers or unregisters the login item.
    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            logger.error(
                "Could not update login item: \(error.localizedDescription)"
            )
        }
        isEnabled = SMAppService.mainApp.status == .enabled
    }

    /// Menu bar apps are expected to survive a restart, so this turns the
    /// login item on once after installation. Builds run from elsewhere,
    /// such as Xcode, are left alone.
    private func enableOnFirstRunIfInstalled() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: Self.didConfigureKey),
              Bundle.main.bundlePath.hasPrefix("/Applications/")
        else { return }

        defaults.set(true, forKey: Self.didConfigureKey)
        setEnabled(true)
    }
}
