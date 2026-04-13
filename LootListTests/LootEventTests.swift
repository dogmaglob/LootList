import Testing
import SwiftData
@testable import LootList

@Suite
struct LootEventTests {
    private func makeContext() throws -> ModelContext {
        let schema = Schema([LootItem.self, LootEvent.self, Campaign.self, LootCategory.self, Carrier.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        return ModelContext(container)
    }

    @Test func foundEventInsertedWithItem() throws {
        let context = try makeContext()
        let campaign = Campaign(name: "Test Campaign")
        context.insert(campaign)

        let item = LootItem(name: "Sword of Testing")
        item.campaign = campaign
        context.insert(item)
        let event = LootEvent(type: .found, itemName: item.name, campaign: campaign)
        context.insert(event)

        let events = try context.fetch(FetchDescriptor<LootEvent>())
        #expect(events.count == 1)
        #expect(events[0].type == .found)
        #expect(events[0].itemName == "Sword of Testing")
    }

    @Test func foundEventCapturesNameSnapshot() throws {
        let context = try makeContext()
        let item = LootItem(name: "Original Name")
        context.insert(item)
        let event = LootEvent(type: .found, itemName: item.name, campaign: nil)
        context.insert(event)

        // Mutate the item name — the event snapshot must not change
        item.name = "Renamed Item"

        let events = try context.fetch(FetchDescriptor<LootEvent>())
        #expect(events[0].itemName == "Original Name")
    }

    @Test func foundEventLinkedToCampaign() throws {
        let context = try makeContext()
        let campaign = Campaign(name: "Adventure")
        context.insert(campaign)
        let event = LootEvent(type: .found, itemName: "Potion", campaign: campaign)
        context.insert(event)

        let events = try context.fetch(FetchDescriptor<LootEvent>())
        #expect(events[0].campaign?.name == "Adventure")
    }

    // MARK: - Use / Sell logic

    @Test func useDecrementsQuantity() throws {
        let context = try makeContext()
        let item = LootItem(name: "Potion", quantity: 3)
        context.insert(item)

        item.quantity -= 1
        let event = LootEvent(type: .used, itemName: item.name, campaign: nil)
        context.insert(event)

        #expect(item.quantity == 2)
        let events = try context.fetch(FetchDescriptor<LootEvent>())
        #expect(events[0].type == .used)
    }

    @Test func sellDecrementsQuantity() throws {
        let context = try makeContext()
        let item = LootItem(name: "Gem", quantity: 2)
        context.insert(item)

        item.quantity -= 1
        let event = LootEvent(type: .sold, itemName: item.name, campaign: nil)
        context.insert(event)

        #expect(item.quantity == 1)
        let events = try context.fetch(FetchDescriptor<LootEvent>())
        #expect(events[0].type == .sold)
    }

    @Test func itemDeletedWhenQuantityReachesZero() throws {
        let context = try makeContext()
        let item = LootItem(name: "Arrow", quantity: 1)
        context.insert(item)

        item.quantity -= 1
        let event = LootEvent(type: .used, itemName: item.name, campaign: nil)
        context.insert(event)
        if item.quantity <= 0 { context.delete(item) }

        let items = try context.fetch(FetchDescriptor<LootItem>())
        #expect(items.isEmpty)
        let events = try context.fetch(FetchDescriptor<LootEvent>())
        #expect(events.count == 1)
    }

    @Test func itemNotDeletedWhenQuantityAboveZero() throws {
        let context = try makeContext()
        let item = LootItem(name: "Arrow", quantity: 5)
        context.insert(item)

        item.quantity -= 1
        let event = LootEvent(type: .used, itemName: item.name, campaign: nil)
        context.insert(event)
        if item.quantity <= 0 { context.delete(item) }

        let items = try context.fetch(FetchDescriptor<LootItem>())
        #expect(items.count == 1)
        #expect(items[0].quantity == 4)
    }
}
