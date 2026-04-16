import Foundation
import Observation

/// Tracks how many times the user has tapped each carrier filter chip,
/// scoped per campaign. Used to sort carrier chips by frequency (most-used first).
/// Counts are persisted in UserDefaults so ordering improves across sessions.
@Observable
@MainActor
final class CarrierUsageStore {
    private(set) var counts: [String: Int] = [:]
    private let defaultsKey = "carrierFilterCounts"

    init() {
        counts = UserDefaults.standard.dictionary(forKey: defaultsKey) as? [String: Int] ?? [:]
    }

    func record(carrierID: UUID, campaignID: UUID) {
        let key = storageKey(carrierID: carrierID, campaignID: campaignID)
        counts[key, default: 0] += 1
        UserDefaults.standard.set(counts, forKey: defaultsKey)
    }

    func count(for carrierID: UUID, campaignID: UUID) -> Int {
        counts[storageKey(carrierID: carrierID, campaignID: campaignID)] ?? 0
    }

    private func storageKey(carrierID: UUID, campaignID: UUID) -> String {
        "\(campaignID.uuidString):\(carrierID.uuidString)"
    }
}
