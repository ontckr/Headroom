import Foundation

/// Raw JSON structure from Claude's local usage history file.
struct UsageHistory: Codable {
    let version: Int
    let samples: [UsageSample]
}

/// A single usage snapshot recorded by the Claude desktop app.
struct UsageSample: Codable {
    let t: Int64
    let org: String
    let u: UsageValues

    var date: Date {
        Date(timeIntervalSince1970: Double(t) / 1000.0)
    }
}

/// Usage percentages and extra spending at a point in time.
struct UsageValues: Codable {
    /// Five-hour rolling window usage percentage (0–100).
    let fh: Int
    /// Seven-day rolling window usage percentage (0–100).
    let sd: Int
    /// Extra usage consumed, as a percent of the monthly extra usage limit.
    let xu: Double
}
