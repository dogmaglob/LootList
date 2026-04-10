import Testing
import SwiftData
@testable import LootList

struct CategorySeederTests {
    
    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: LootCategory.self, configurations: config)
    }

    // MARK: - Tests

    @Test func seedsCorrectNumberOfCategories() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        seedCategoriesIfNeeded(in: context)
        let count = try context.fetchCount(FetchDescriptor<LootCategory>())
        #expect(count == LootCategory.seedData.count)
    }

    @Test func seededNamesMatchSeedData() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        seedCategoriesIfNeeded(in: context)
        let categories = try context.fetch(FetchDescriptor<LootCategory>())
        let seededNames = Set(categories.map(\.name))
        let expectedNames = Set(LootCategory.seedData.map(\.name))
        #expect(seededNames == expectedNames)
    }

    @Test func seededEmojisMatchSeedData() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        seedCategoriesIfNeeded(in: context)
        let categories = try context.fetch(FetchDescriptor<LootCategory>())
        let seededEmojis = Set(categories.map(\.emoji))
        let expectedEmojis = Set(LootCategory.seedData.map(\.emoji))
        #expect(seededEmojis == expectedEmojis)
    }

    @Test func seedingIsIdempotent() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        seedCategoriesIfNeeded(in: context)
        seedCategoriesIfNeeded(in: context)
        let count = try context.fetchCount(FetchDescriptor<LootCategory>())
        #expect(count == LootCategory.seedData.count)
    }

    @Test func doesNotSeedWhenCategoriesAlreadyExist() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        context.insert(LootCategory(name: "Custom", emoji: "🧿"))
        seedCategoriesIfNeeded(in: context)
        let count = try context.fetchCount(FetchDescriptor<LootCategory>())
        #expect(count == 1)
    }
}
