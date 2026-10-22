import SwiftUI

/// A circular gauge showing how much of a usage window has been consumed.
struct UsageGaugeView: View {
    let title: String
    let caption: String
    /// Percent used, or `nil` when the window has reset since the last sync.
    let percent: Int?

    private let lineWidth: CGFloat = 9

    private var progress: Double {
        Double(min(max(percent ?? 0, 0), 100)) / 100
    }

    private var tint: Color {
        usageTint(for: percent ?? 0)
    }

    var body: some View {
        VStack(spacing: 12) {
            ring
            VStack(spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(percent == nil ? "Reset since last sync" : caption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.background.secondary, in: .rect(cornerRadius: 16))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title) usage")
        .accessibilityValue(
            percent.map { "\($0) percent" } ?? "Reset since last sync"
        )
    }

    private var ring: some View {
        ZStack {
            Circle()
                .stroke(.quaternary, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    tint.gradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: tint.opacity(0.45), radius: 5)
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(percent.map(String.init) ?? "–")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                if percent != nil {
                    Text("%")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: 88, height: 88)
        .animation(.smooth, value: percent)
    }
}

/// A compact row showing how much of the monthly extra usage limit is used.
struct ExtraUsageRow: View {
    /// Percent of the monthly extra usage limit (0–100).
    let percent: Double

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Label("Extra usage", systemImage: "creditcard")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(percent.rounded()))%")
                .fontWeight(.semibold)
                .monospacedDigit()
                Text("of monthly limit")
                    .foregroundStyle(.secondary)
            }
            UsageBar(fraction: min(max(percent, 0), 100) / 100)
        }
        .font(.callout)
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(.background.secondary, in: .rect(cornerRadius: 12))
    }
}

/// A thin horizontal bar filled to `fraction` (0–1).
private struct UsageBar: View {
    let fraction: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.quaternary)
                Capsule()
                    .fill(Color.blue.gradient)
                    .frame(width: max(proxy.size.width * fraction, 5))
            }
        }
        .frame(height: 5)
    }
}

/// Maps a usage percentage to a calm-to-urgent color.
func usageTint(for percent: Int) -> Color {
    switch percent {
    case ..<50: .green
    case 50..<80: .orange
    default: .red
    }
}
