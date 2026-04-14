import Foundation

/// The type of action recorded in the loot event log.
enum LootEventType: String, Codable, CaseIterable {
    case found
    case sold
    case used
    case deleted
}
