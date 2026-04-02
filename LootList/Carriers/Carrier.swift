import Foundation
import SwiftData

@Model
final class Carrier {
    @Attribute(.unique) var name: String
    @Relationship(deleteRule: .nullify, inverse: \LootItem.carrier) var loot: [LootItem]

    init(name: String) {
        self.name = name
        self.loot = []
    }
}
