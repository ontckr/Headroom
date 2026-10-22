import Foundation

/// Raw JSON structure from Claude's local usage history file.
struct UsageHistory: Decodable {
    let samples: [UsageSample]
}

/// A single usage snapshot recorded by the Claude desktop app.
struct UsageSample: Decodable {
    let t: Int64
    /// The Claude account the sample belongs to. Older files leave it empty.
    let org: String?
    let u: UsageValues

    var date: Date {
        Date(timeIntervalSince1970: Double(t) / 1000.0)
    }
}

/// Usage percentages at a point in time.
///
/// Claude omits a field when it has nothing to report for it, so every value
/// is optional.
struct UsageValues: Decodable {
    /// Five-hour rolling window usage percentage (0–100).
    let fh: Double?
    /// Seven-day rolling window usage percentage (0–100).
    let sd: Double?
    /// Extra usage consumed, as a percent of the monthly extra usage limit.
    let xu: Double?
}
