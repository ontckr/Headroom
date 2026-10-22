import Foundation
import Testing

@MainActor
@Suite("UsageDataService")
final class UsageDataServiceTests {
    private let directory: URL
    private let fileURL: URL

    init() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        fileURL = directory.appendingPathComponent("plan-usage-history.json")
    }

    deinit {
        try? FileManager.default.removeItem(at: directory)
    }

    // MARK: - Reading

    @Test("Shows a message when the file does not exist")
    func missingFile() {
        let service = UsageDataService(fileURL: fileURL)

        #expect(service.latestSample == nil)
        #expect(service.errorMessage != nil)
    }

    @Test("Reads usage from the newest sample")
    func readsValues() throws {
        try write([sample(#""fh":10,"sd":3,"xu":4.94"#)])

        let service = UsageDataService(fileURL: fileURL)

        #expect(service.fiveHourPercent == 10)
        #expect(service.weeklyPercent == 3)
        #expect(service.extraUsagePercent == 4.94)
        #expect(service.errorMessage == nil)
    }

    @Test("Uses the newest sample even when samples are out of order")
    func outOfOrderSamples() throws {
        try write([
            sample(#""fh":50,"sd":20"#),
            sample(#""fh":10,"sd":5"#, ageHours: 1),
        ])

        let service = UsageDataService(fileURL: fileURL)

        #expect(service.fiveHourPercent == 50)
    }

    @Test("Shows a message when the file has no samples")
    func emptySamples() throws {
        try write([])

        let service = UsageDataService(fileURL: fileURL)

        #expect(service.latestSample == nil)
        #expect(service.errorMessage != nil)
    }

    @Test("Rounds fractional percentages")
    func roundsFractions() throws {
        try write([sample(#""fh":37.6,"sd":9.2"#)])

        let service = UsageDataService(fileURL: fileURL)

        #expect(service.fiveHourPercent == 38)
        #expect(service.weeklyPercent == 9)
    }

    // MARK: - Missing fields

    @Test("Reads a newest sample that leaves out extra usage")
    func missingExtraUsage() throws {
        try write([
            sample(#""fh":20,"sd":4,"xu":3.5"#, ageHours: 1),
            sample(#""fh":44,"sd":11"#),
        ])

        let service = UsageDataService(fileURL: fileURL)

        #expect(service.errorMessage == nil)
        #expect(service.fiveHourPercent == 44)
        #expect(service.extraUsagePercent == 3.5)
    }

    @Test("Shows no 5-hour value when no sample reports one")
    func missingFiveHour() throws {
        try write([sample(#""sd":12"#)])

        let service = UsageDataService(fileURL: fileURL)

        #expect(service.fiveHourPercent == nil)
        #expect(service.weeklyPercent == 12)
    }

    // MARK: - Switching accounts

    @Test("Ignores values left over from a previous account")
    func ignoresPreviousAccount() throws {
        try write([
            sample(#""fh":70,"sd":40,"xu":25"#, ageHours: 1, org: "old"),
            sample(#""fh":5"#, org: "new"),
        ])

        let service = UsageDataService(fileURL: fileURL)

        #expect(service.fiveHourPercent == 5)
        #expect(service.weeklyPercent == nil)
        #expect(service.extraUsagePercent == nil)
    }

    @Test("Shows the original account again after switching back")
    func switchesBack() throws {
        try write([
            sample(#""fh":30,"sd":20,"xu":8"#, ageHours: 2, org: "first"),
            sample(#""fh":70,"sd":60,"xu":50"#, ageHours: 1, org: "second"),
            sample(#""fh":35,"sd":21"#, org: "first"),
        ])

        let service = UsageDataService(fileURL: fileURL)

        #expect(service.fiveHourPercent == 35)
        #expect(service.weeklyPercent == 21)
        #expect(service.extraUsagePercent == 8)
    }

    @Test("Reads samples that have no account")
    func samplesWithoutAccount() throws {
        try write([
            sample(#""fh":12,"sd":4,"xu":2"#, ageHours: 1, org: nil),
            sample(#""fh":15,"sd":5"#, org: nil),
        ])

        let service = UsageDataService(fileURL: fileURL)

        #expect(service.fiveHourPercent == 15)
        #expect(service.extraUsagePercent == 2)
    }

    @Test("Switches to the new account while running")
    func switchesWhileRunning() async throws {
        let oldAccount = sample(#""fh":70,"sd":40,"xu":25"#, ageHours: 1, org: "old")
        try write([oldAccount])
        let service = UsageDataService(fileURL: fileURL)
        #expect(service.extraUsagePercent == 25)

        try write([oldAccount, sample(#""fh":3,"sd":1"#, org: "new")])

        #expect(await waitUntil { service.fiveHourPercent == 3 })
        #expect(service.extraUsagePercent == nil)
    }

    // MARK: - Stale data

    @Test("Hides 5-hour usage once its window has passed")
    func staleFiveHour() throws {
        try write([sample(#""fh":80,"sd":9"#, ageHours: 6)])

        let service = UsageDataService(fileURL: fileURL)

        #expect(service.fiveHourPercent == nil)
        #expect(service.weeklyPercent == 9)
    }

    @Test("Hides weekly usage once its window has passed")
    func staleWeekly() throws {
        try write([sample(#""fh":80,"sd":9"#, ageHours: 8 * 24)])

        let service = UsageDataService(fileURL: fileURL)

        #expect(service.weeklyPercent == nil)
    }

    // MARK: - Watching

    @Test("Updates when the file is written in place")
    func inPlaceWrite() async throws {
        try write([sample(#""fh":10,"sd":3"#)])
        let service = UsageDataService(fileURL: fileURL)

        try write([sample(#""fh":42,"sd":5"#)], atomically: false)

        #expect(await waitUntil { service.fiveHourPercent == 42 })
    }

    @Test("Keeps watching after the file is replaced")
    func atomicReplace() async throws {
        try write([sample(#""fh":10,"sd":3"#)])
        let service = UsageDataService(fileURL: fileURL)

        try write([sample(#""fh":55,"sd":6"#)])
        #expect(await waitUntil { service.fiveHourPercent == 55 })

        try write([sample(#""fh":61,"sd":7"#)])
        #expect(await waitUntil { service.fiveHourPercent == 61 })
    }

    @Test("Keeps the last good data when the file becomes unreadable")
    func corruptFile() async throws {
        try write([sample(#""fh":30,"sd":9"#)])
        let service = UsageDataService(fileURL: fileURL)

        try "not json".write(to: fileURL, atomically: true, encoding: .utf8)

        #expect(await waitUntil { service.errorMessage != nil })
        #expect(service.weeklyPercent == 9)
    }

    // MARK: - Helpers

    private func sample(
        _ values: String,
        ageHours: Double = 0,
        org: String? = "test"
    ) -> String {
        let seconds = Date.now.timeIntervalSince1970 - ageHours * 3600
        let account = org.map { #""\#($0)""# } ?? "null"
        return #"{"t":\#(Int64(seconds * 1000)),"org":\#(account),"u":{\#(values)}}"#
    }

    private func write(_ samples: [String], atomically: Bool = true) throws {
        let json = #"{"version":2,"samples":[\#(samples.joined(separator: ","))]}"#
        if atomically {
            try json.write(to: fileURL, atomically: true, encoding: .utf8)
        } else {
            let handle = try FileHandle(forWritingTo: fileURL)
            try handle.truncate(atOffset: 0)
            try handle.write(contentsOf: Data(json.utf8))
            try handle.close()
        }
    }

    /// Polls until `condition` holds, letting the file watcher run meanwhile.
    private func waitUntil(
        timeout: Duration = .seconds(2),
        _ condition: () -> Bool
    ) async -> Bool {
        let deadline = ContinuousClock.now + timeout
        while ContinuousClock.now < deadline {
            if condition() { return true }
            try? await Task.sleep(for: .milliseconds(20))
        }
        return condition()
    }
}
