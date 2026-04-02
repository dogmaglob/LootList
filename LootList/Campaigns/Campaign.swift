import Foundation
import SwiftData

/// A campaign groups its own loot, carriers, and event log.
@Model
final class Campaign {
    var id: UUID = UUID()
    var name: String = ""
    var createdAt = Date.now

    // Inverses for loot and carriers are specified on the child side in Task 3.
    @Relationship(deleteRule: .cascade)
    var loot: [LootItem]? = []

    @Relationship(deleteRule: .cascade)
    var carriers: [Carrier]? = []

    @Relationship(deleteRule: .cascade, inverse: \LootEvent.campaign)
    var events: [LootEvent]? = []

    init(name: String = "") {
        self.name = name
    }
}
