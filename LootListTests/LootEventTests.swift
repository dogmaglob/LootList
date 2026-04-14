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

    // MARK: - Found event

    @Test func foundEventInsertedWithItem() throws {
        let context = try makeContext()
        let campaign = Campaign(name: "Test Campaign")
        context.insert(campaign)
        let item = LootItem(name: "Sword of Testing")
        item.campaign = campaign
        context.insert(item)
        let event = LootEvent(type: .found, itemName: item.name, itemID: item.id, campaign: campaign)
        context.insert(event)

        let events = try context.fetch(FetchDescriptor<LootEvent>())
        #expect(events.count == 1)
        #expect(events[0].type == .found)
        #expect(events[0].itemName == "Sword of Testing")
        #expect(events[0].itemID == item.id)
    }

    @Test func foundEventCapturesNameSnapshot() throws {
        let context = try makeContext()
        let item = LootItem(name: "Original Name")
        context.insert(item)
        let event = LootEvent(type: .found, itemName: item.name, itemID: item.id, campaign: nil)
        context.insert(event)

        item.name = "Renamed Item"

        let events = try context.fetch(FetchDescriptor<LootEvent>())
        #expect(events[0].itemName == "Original Name")
    }

    @Test func foundEventLinkedToCampaign() throws {
        let context = try makeContext()
        let campaign = Campaign(name: "Adventure")
        context.insert(campaign)
        let item = LootItem(name: "Potion")
        context.insert(item)
        let event = LootEvent(type: .found, itemName: item.name, itemID: item.id, campaign: campaign)
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
        context.insert(LootEvent(type: .used, itemName: item.name, itemID: item.id, campaign: nil))

        #expect(item.quantity == 2)
        let events = try context.fetch(FetchDescriptor<LootEvent>())
        #expect(events[0].type == .used)
    }

    @Test func sellDecrementsQuantity() throws {
        let context = try makeContext()
        let item = LootItem(name: "Gem", quantity: 2)
        context.insert(item)

        item.quantity -= 1
        context.insert(LootEvent(type: .sold, itemName: item.name, itemID: item.id, campaign: nil))

        #expect(item.quantity == 1)
        let events = try context.fetch(FetchDescriptor<LootEvent>())
        #expect(events[0].type == .sold)
    }

    @Test func itemHiddenNotDeletedWhenQuantityReachesZero() throws {
        let context = try makeContext()
        let item = LootItem(name: "Arrow", quantity: 1)
        context.insert(item)

        item.quantity -= 1
        context.insert(LootEvent(type: .used, itemName: item.name, itemID: item.id, campaign: nil))

        let items = try context.fetch(FetchDescriptor<LootItem>())
        #expect(items.count == 1)
        #expect(items[0].quantity == 0)
        #expect(items[0].isDeleted == false)
    }

    @Test func itemNotHiddenWhenQuantityAboveZero() throws {
        let context = try makeContext()
        let item = LootItem(name: "Arrow", quantity: 5)
        context.insert(item)

        item.quantity -= 1
        context.insert(LootEvent(type: .used, itemName: item.name, itemID: item.id, campaign: nil))

        let items = try context.fetch(FetchDescriptor<LootItem>())
        #expect(items.count == 1)
        #expect(items[0].quantity == 4)
    }

    // MARK: - Undo

    @Test func undoFoundSoftDeletesItem() throws {
        let context = try makeContext()
        let item = LootItem(name: "Sword")
        context.insert(item)
        let event = LootEvent(type: .found, itemName: item.name, itemID: item.id, campaign: nil)
        context.insert(event)

        event.undo(in: context)

        let items = try context.fetch(FetchDescriptor<LootItem>())
        #expect(items.count == 1)
        #expect(items[0].isDeleted == true)
        #expect(try context.fetch(FetchDescriptor<LootEvent>()).isEmpty)
    }

    @Test func undoUsedIncrementsQuantity() throws {
        let context = try makeContext()
        let item = LootItem(name: "Potion", quantity: 3)
        context.insert(item)
        let event = LootEvent(type: .used, itemName: item.name, itemID: item.id, campaign: nil)
        context.insert(event)
        item.quantity -= 1

        event.undo(in: context)

        let items = try context.fetch(FetchDescriptor<LootItem>())
        #expect(items[0].quantity == 3)
        #expect(try context.fetch(FetchDescriptor<LootEvent>()).isEmpty)
    }

    @Test func undoUsedRestoresZeroQuantityItem() throws {
        let context = try makeContext()
        let item = LootItem(name: "Last Arrow", quantity: 1)
        context.insert(item)
        let event = LootEvent(type: .used, itemName: item.name, itemID: item.id, campaign: nil)
        context.insert(event)
        item.quantity -= 1

        event.undo(in: context)

        let items = try context.fetch(FetchDescriptor<LootItem>())
        #expect(items[0].quantity == 1)
        #expect(try context.fetch(FetchDescriptor<LootEvent>()).isEmpty)
    }

    @Test func undoDeletedClearsFlag() throws {
        let context = try makeContext()
        let item = LootItem(name: "Shield")
        context.insert(item)
        let event = LootEvent(type: .deleted, itemName: item.name, itemID: item.id, campaign: nil)
        context.insert(event)
        item.isDeleted = true

        event.undo(in: context)

        let items = try context.fetch(FetchDescriptor<LootItem>())
        #expect(items[0].isDeleted == false)
        #expect(try context.fetch(FetchDescriptor<LootEvent>()).isEmpty)
    }
}
