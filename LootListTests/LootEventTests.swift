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
}
