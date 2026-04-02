import Foundation
import SwiftData

/// A single entry in the loot history log.
///
/// `itemName` is a snapshot of the item name at the time of the event so the
/// log remains intact after an item is deleted.
@Model
final class LootEvent {
    var id: UUID = UUID()
    var type: LootEventType = LootEventType.found
    var itemName: String = ""
    var timestamp = Date.now

    var campaign: Campaign?

    init(type: LootEventType = .found, itemName: String = "", campaign: Campaign? = nil) {
        self.type = type
        self.itemName = itemName
        self.campaign = campaign
    }
}
