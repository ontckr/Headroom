import SwiftUI

/// The window shown when the menu bar item is clicked.
struct UsagePopoverView: View {
    let service: UsageDataService
    let launchAtLogin: LaunchAtLogin

    var body: some View {
        VStack(spacing: 14) {
            PopoverHeader(lastUpdated: service.lastUpdated)

            if service.latestSample != nil {
                HStack(spacing: 10) {
                    UsageGaugeView(
                        title: "5-hour",
                        caption: "Current session",
                        percent: service.fiveHourPercent
                    )
                    UsageGaugeView(
                        title: "Weekly",
                        caption: "All models",
                        percent: service.weeklyPercent
                    )
                }

                if let percent = service.extraUsagePercent, percent > 0 {
                    ExtraUsageRow(percent: percent)
                }
            } else {
                EmptyStateView(
                    message: service.errorMessage ?? "No usage data yet."
                )
            }

            Divider()

            PopoverFooter(
                launchAtLogin: launchAtLogin,
                onRefresh: service.refresh
            )
        }
        .padding(16)
        .frame(width: 300)
    }
}

private struct PopoverHeader: View {
    let lastUpdated: Date?

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "sparkle")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(Color.orange.gradient, in: .rect(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 1) {
                Text("Claude Usage")
                    .font(.headline)
                if let lastUpdated {
                    Text(
                        "Synced \(lastUpdated, format: .relative(presentation: .named))"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
    }
}

private struct EmptyStateView: View {
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.system(size: 28))
                .foregroundStyle(.tertiary)
            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(.background.secondary, in: .rect(cornerRadius: 16))
    }
}

private struct PopoverFooter: View {
    let launchAtLogin: LaunchAtLogin
    let onRefresh: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Button {
                launchAtLogin.setEnabled(!launchAtLogin.isEnabled)
            } label: {
                Label {
                    Text("Open at login")
                } icon: {
                    Image(
                        systemName: launchAtLogin.isEnabled
                            ? "checkmark.circle.fill" : "circle"
                    )
                    .foregroundStyle(
                        launchAtLogin.isEnabled ? Color.accentColor : .secondary
                    )
                }
            }
            .accessibilityValue(launchAtLogin.isEnabled ? "On" : "Off")

            Spacer()

            Button(action: onRefresh) {
                Image(systemName: "arrow.clockwise")
            }
            .keyboardShortcut("r")
            .help("Refresh")
            .accessibilityLabel("Refresh")

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Image(systemName: "power")
            }
            .keyboardShortcut("q")
            .help("Quit Headroom")
            .accessibilityLabel("Quit Headroom")
        }
        .buttonStyle(.plain)
        .font(.callout)
        .foregroundStyle(.secondary)
    }
}
