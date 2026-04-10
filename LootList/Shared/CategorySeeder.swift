import SwiftData

/// Inserts the default categories into `context` if no categories exist yet.
/// Safe to call on every launch — does nothing if categories are already present.
func seedCategoriesIfNeeded(in context: ModelContext) {
    let count = (try? context.fetchCount(FetchDescriptor<LootCategory>())) ?? 0
    guard count == 0 else { return }
    for (name, emoji) in LootCategory.seedData {
        context.insert(LootCategory(name: name, emoji: emoji))
    }
}
