import Foundation
import SwiftData

@Model
final class Carrier {
    var id: UUID = UUID()
    var name: String?

    @Relationship(deleteRule: .nullify, inverse: \LootItem.carrier)
    var loot: [LootItem]? = []

    var campaign: Campaign?

    init(name: String) {
        self.name = name
    }
}
