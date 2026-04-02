import Foundation
import SwiftData

enum LootCategory: String, CaseIterable, Identifiable, Codable {
    case weapon = "Weapon"
    case armor = "Armor"
    case potion = "Potion"
    case gold = "Gold"
    case gem = "Gem"
    case scroll = "Scroll"
    case misc = "Misc"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .weapon: return "⚔️"
        case .armor: return "🛡️"
        case .potion: return "🧪"
        case .gold: return "🪙"
        case .gem: return "💎"
        case .scroll: return "📜"
        case .misc: return "🎒"
        }
    }
}

@Model
final class LootItem {
    var name: String
    var category: LootCategory
    var quantity: Int
    var weight: Double
    var value: Int
    var carrier: Carrier?
    var notes: String
    var dateAdded: Date

    init(name: String, category: LootCategory, quantity: Int, weight: Double = 0, value: Int = 0, carrier: Carrier? = nil, notes: String) {
        self.name = name
        self.category = category
        self.quantity = quantity
        self.weight = weight
        self.value = value
        self.carrier = carrier
        self.notes = notes
        self.dateAdded = .now
    }
}
