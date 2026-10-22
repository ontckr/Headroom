import Foundation
import Observation

/// Reads the usage history the Claude desktop app keeps on disk.
///
/// Claude periodically records plan usage to `plan-usage-history.json`. This
/// service reads the newest sample from that file and watches it for changes.
/// It makes no network requests and consumes no tokens.
@Observable
final class UsageDataService {
    static let defaultFileURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(
            "Library/Application Support/Claude/plan-usage-history.json"
        )

    private static let fiveHourWindow: TimeInterval = 5 * 60 * 60
    private static let weeklyWindow: TimeInterval = 7 * 24 * 60 * 60
    private static let refreshInterval: TimeInterval = 60

    /// The most recent sample recorded by the Claude app.
    private(set) var latestSample: UsageSample?
    /// A human-readable reason when the file cannot be read.
    private(set) var errorMessage: String?

    private let fileURL: URL
    private var fileMonitor: DispatchSourceFileSystemObject?
    private var refreshTimer: Timer?

    init(fileURL: URL = UsageDataService.defaultFileURL) {
        self.fileURL = fileURL
        refresh()
        refreshTimer = Timer.scheduledTimer(
            withTimeInterval: Self.refreshInterval,
            repeats: true
        ) { [weak self] _ in
            self?.refresh()
        }
    }

    deinit {
        refreshTimer?.invalidate()
        fileMonitor?.cancel()
    }

    /// Five-hour usage, or `nil` if that window has reset since the last sync.
    var fiveHourPercent: Int? {
        currentValue(\.fh, window: Self.fiveHourWindow)
    }

    /// Weekly usage, or `nil` if that window has reset since the last sync.
    var weeklyPercent: Int? {
        currentValue(\.sd, window: Self.weeklyWindow)
    }

    /// Extra usage consumed, as a percent of the monthly limit.
    var extraUsagePercent: Double? {
        latestSample?.u.xu
    }

    /// When the Claude app last recorded usage.
    var lastUpdated: Date? {
        latestSample?.date
    }

    /// Re-reads the file from disk.
    ///
    /// Also re-attaches the file watcher if the file appeared after launch.
    func refresh() {
        if fileMonitor == nil {
            startMonitoring()
        }
        loadData()
    }

    // MARK: - Private

    /// A sample older than its window is stale: the window has since reset.
    private func currentValue(
        _ keyPath: KeyPath<UsageValues, Int>,
        window: TimeInterval
    ) -> Int? {
        guard let latestSample,
              Date.now.timeIntervalSince(latestSample.date) < window
        else { return nil }
        return latestSample.u[keyPath: keyPath]
    }

    private func loadData() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            errorMessage = "Claude usage file not found.\n"
                + "Open the Claude desktop app once to create it."
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let history = try JSONDecoder().decode(UsageHistory.self, from: data)
            guard let newest = history.samples.max(by: { $0.t < $1.t }) else {
                errorMessage = "No usage recorded yet."
                return
            }
            latestSample = newest
            errorMessage = nil
        } catch {
            errorMessage = "Could not read the usage file."
        }
    }

    /// Watches the file for writes.
    ///
    /// Apps often save by writing a new file and renaming it over the old one,
    /// which leaves this descriptor pointing at a deleted file. On rename or
    /// delete the watcher is torn down and rebuilt on the new file.
    private func startMonitoring() {
        let descriptor = open(fileURL.path, O_EVTONLY)
        guard descriptor != -1 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.write, .rename, .delete],
            queue: .main
        )

        source.setEventHandler { [weak self, unowned source] in
            guard let self else { return }
            if !source.data.isDisjoint(with: [.rename, .delete]) {
                source.cancel()
                fileMonitor = nil
            }
            refresh()
        }
        source.setCancelHandler {
            close(descriptor)
        }

        fileMonitor = source
        source.resume()
    }
}
