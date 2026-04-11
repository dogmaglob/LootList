import Foundation
import SwiftData

@Model
final class LootItem {
    var id: UUID = UUID()
    var name: String = ""
    var quantity: Int = 1
    var weight: Double = 0
    var value: Int = 0
    var notes: String = ""
    var dateAdded = Date.now

    var category: LootCategory?
    var carrier: Carrier?
    var campaign: Campaign?

    init(
        name: String = "",
        category: LootCategory? = nil,
        quantity: Int = 1,
        weight: Double = 0,
        value: Int = 0,
        carrier: Carrier? = nil,
        notes: String = ""
    ) {
        self.name = name
        self.category = category
        self.quantity = quantity
        self.weight = weight
        self.value = value
        self.carrier = carrier
        self.notes = notes
    }
}
