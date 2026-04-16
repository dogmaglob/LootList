import SwiftUI
import SwiftData

struct LootListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var loot: [LootItem]
    @State private var showingAddSheet = false
    @State private var selectedItem: LootItem?
    @State private var searchText = ""

    private let campaign: Campaign?

    init(campaign: Campaign?) {
        self.campaign = campaign
        let campaignID = campaign?.id
        _loot = Query(
            filter: #Predicate<LootItem> { item in
                item.campaign?.id == campaignID &&
                item.isDeleted == false &&
                item.quantity > 0
            },
            sort: \LootItem.dateAdded,
            order: .reverse
        )
    }

    private var filteredLoot: [LootItem] {
        guard !searchText.isEmpty else { return loot }
        return loot.filter { $0.name.localizedStandardContains(searchText) }
    }

    var body: some View {
        Group {
            if loot.isEmpty {
                ContentUnavailableView(
                    "No Loot Yet",
                    systemImage: "bag",
                    description: Text("Tap + to add loot from your adventure.")
                )
            } else if filteredLoot.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                List {
                    ForEach(filteredLoot) { item in
                        Button {
                            selectedItem = item
                        } label: {
                            LootRowView(item: item)
                        }
                        .tint(.primary)
                        .swipeActions(edge: .trailing) {
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                let event = LootEvent(type: .deleted, itemName: item.name, itemID: item.id, campaign: campaign)
                                modelContext.insert(event)
                                item.isDeleted = true
                            }
                            Button("Sell", systemImage: "tag") {
                                perform(.sold, on: item)
                            }
                            .tint(.green)
                            Button("Use", systemImage: "checkmark") {
                                perform(.used, on: item)
                            }
                            .tint(.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle("D&D Loot")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add Loot", systemImage: "plus") {
                    showingAddSheet = true
                }
            }
            ToolbarItem(placement: .navigation) {
                NavigationLink {
                    CarriersView(campaign: campaign)
                } label: {
                    Label("Carriers", systemImage: "person.2")
                }
            }
            ToolbarItem(placement: .navigation) {
                NavigationLink {
                    EventLogView(campaign: campaign)
                } label: {
                    Label("Event Log", systemImage: "scroll")
                }
            }
        }
        .navigationDestination(item: $selectedItem) { item in
            EditLootView(item: item, campaign: campaign)
        }
        .searchable(text: $searchText, prompt: "Search loot")
        .sheet(isPresented: $showingAddSheet) {
            AddLootView(campaign: campaign)
        }
    }

    private func perform(_ eventType: LootEventType, on item: LootItem) {
        let event = LootEvent(type: eventType, itemName: item.name, itemID: item.id, campaign: campaign)
        modelContext.insert(event)
        item.quantity -= 1
    }
}

struct LootRowView: View {
    let item: LootItem

    var body: some View {
        HStack {
            Text(item.category?.emoji ?? "🎒")
                .font(.title2)
            VStack(alignment: .leading) {
                Text(item.name)
                    .font(.headline)
                HStack(spacing: 12) {
                    if item.weight > 0 {
                        Text("Wt: \(item.weight.formatted(.number))")
                    }
                    if item.value > 0 {
                        Text("Val: \(item.value.formatted(.number))")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                if let carrier = item.carrier {
                    Text(carrier.name ?? "")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if !item.notes.isEmpty {
                    Text(item.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if item.quantity > 1 {
                Text("×\(item.quantity.formatted(.number))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: LootItem.self, Carrier.self, LootCategory.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let category = LootCategory(name: "Weapon", emoji: "⚔️")
    let carrier = Carrier(name: "Gandalf")
    container.mainContext.insert(category)
    container.mainContext.insert(carrier)
    let item = LootItem(
        name: "Flame Tongue Sword",
        category: category,
        quantity: 2,
        weight: 3.5,
        value: 5000,
        carrier: carrier,
        notes: "Deals extra 2d6 fire damage"
    )
    container.mainContext.insert(item)
    return LootListView(campaign: nil)
        .modelContainer(container)
}
