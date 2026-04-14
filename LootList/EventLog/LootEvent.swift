import Foundation
import SwiftData

/// A single entry in the loot history log.
///
/// `itemName` is a snapshot of the item name at the time of the event so the
/// log remains intact even if the item name is later changed.
/// `itemID` is the `id` of the source `LootItem` and is used by `undo(in:)` to
/// locate the item.
@Model
final class LootEvent {
    var id: UUID = UUID()
    var type: LootEventType = LootEventType.found
    var itemName: String = ""
    var itemID: UUID = UUID()
    var timestamp = Date.now

    var campaign: Campaign?

    init(type: LootEventType = .found, itemName: String = "", itemID: UUID = UUID(), campaign: Campaign? = nil) {
        self.type = type
        self.itemName = itemName
        self.itemID = itemID
        self.campaign = campaign
    }

    /// Reverses the action recorded by this event and removes it from the log.
    ///
    /// - `.found`: soft-deletes the item (`isDeleted = true`).
    /// - `.used` / `.sold`: increments the item's quantity by 1.
    /// - `.deleted`: clears the item's soft-delete flag (`isDeleted = false`).
    func undo(in context: ModelContext) {
        let itemID = self.itemID
        let descriptor = FetchDescriptor<LootItem>(
            predicate: #Predicate { $0.id == itemID }
        )
        let item = (try? context.fetch(descriptor))?.first

        switch type {
        case .found:
            item?.isDeleted = true
        case .used, .sold:
            if let item {
                item.quantity += 1
            }
        case .deleted:
            item?.isDeleted = false
        }

        context.delete(self)
    }
}
