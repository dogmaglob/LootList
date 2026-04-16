import SwiftUI
import SwiftData

struct LootListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(CarrierUsageStore.self) private var usageStore
    @Query private var loot: [LootItem]
    @Query private var carriers: [Carrier]
    @State private var showingAddSheet = false
    @State private var selectedItem: LootItem?
    @State private var searchText = ""
    @State private var carrierFilter: CarrierFilter = .all

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
        _carriers = Query(
            filter: #Predicate<Carrier> { $0.campaign?.id == campaignID },
            sort: \Carrier.name
        )
    }

    private var filteredLoot: [LootItem] {
        var result = loot
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedStandardContains(searchText) }
        }
        switch carrierFilter {
        case .all:
            break
        case .unassigned:
            result = result.filter { $0.carrier == nil }
        case .specific(let carrier):
            result = result.filter { $0.carrier?.id == carrier.id }
        }
        return result
    }

    private var sortedCarriers: [Carrier] {
        guard let campaignID = campaign?.id else { return carriers }
        return carriers.sorted { a, b in
            let countA = usageStore.count(for: a.id, campaignID: campaignID)
            let countB = usageStore.count(for: b.id, campaignID: campaignID)
            if countA != countB { return countA > countB }
            return (a.name ?? "") < (b.name ?? "")
        }
    }

    var body: some View {
        Group {
            if loot.isEmpty {
                ContentUnavailableView(
                    "No Loot Yet",
                    systemImage: "bag",
                    description: Text("Tap + to add loot from your adventure.")
                )
            } else {
                VStack(spacing: 0) {
                    if !carriers.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                FilterChip("All", isSelected: carrierFilter == .all) {
                                    carrierFilter = .all
                                }
                                FilterChip("Unassigned", isSelected: carrierFilter == .unassigned) {
                                    carrierFilter = .unassigned
                                }
                                ForEach(sortedCarriers) { carrier in
                                    FilterChip(carrier.name ?? "Unknown", isSelected: carrierFilter == .specific(carrier)) {
                                        if let campaignID = campaign?.id {
                                            usageStore.record(carrierID: carrier.id, campaignID: campaignID)
                                        }
                                        carrierFilter = .specific(carrier)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        }
                        Divider()
                    }
                    
                    if filteredLoot.isEmpty {
                        if searchText.isEmpty {
                            ContentUnavailableView(
                                "No Items",
                                systemImage: "person.crop.circle.badge.xmark",
                                description: Text("No loot is assigned to this carrier.")
                            )
                        } else {
                            ContentUnavailableView.search(text: searchText)
                        }
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

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    init(_ label: String, isSelected: Bool, action: @escaping () -> Void) {
        self.label = label
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
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
