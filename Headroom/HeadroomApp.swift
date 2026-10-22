import SwiftUI

@main
struct HeadroomApp: App {
    @State private var service = UsageDataService()
    @State private var launchAtLogin = LaunchAtLogin()

    var body: some Scene {
        MenuBarExtra {
            UsagePopoverView(service: service, launchAtLogin: launchAtLogin)
        } label: {
            HStack(spacing: 3) {
                Image(systemName: "sparkle")
                Text(service.fiveHourPercent.map { "\($0)%" } ?? "–")
                    .monospacedDigit()
            }
        }
        .menuBarExtraStyle(.window)
    }
}
