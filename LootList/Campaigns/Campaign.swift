import Foundation
import SwiftData

/// A campaign groups its own loot, carriers, and event log.
@Model
final class Campaign {
    var id: UUID = UUID()
    var name: String = ""
    var createdAt = Date.now

    @Relationship(deleteRule: .cascade, inverse: \LootItem.campaign)
    var loot: [LootItem]? = []

    @Relationship(deleteRule: .cascade, inverse: \Carrier.campaign)
    var carriers: [Carrier]? = []

    @Relationship(deleteRule: .cascade, inverse: \LootEvent.campaign)
    var events: [LootEvent]? = []

    init(name: String = "") {
        self.name = name
    }
}
