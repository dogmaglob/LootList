import Foundation
import SwiftData

/// A loot category with a name and emoji icon.
/// The seven default categories are seeded on first launch but can be modified or deleted.
@Model
final class LootCategory {
    var id: UUID = UUID()
    var name: String = ""
    var emoji: String = ""

    init(name: String = "", emoji: String = "") {
        self.name = name
        self.emoji = emoji
    }
}

extension LootCategory {
    /// Default categories inserted on first launch.
    static let seedData: [(name: String, emoji: String)] = [
        ("Weapon", "⚔️"),
        ("Armor",  "🛡️"),
        ("Potion", "🧪"),
        ("Gold",   "🪙"),
        ("Gem",    "💎"),
        ("Scroll", "📜"),
        ("Misc",   "🎒"),
    ]
}
