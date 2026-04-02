import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LootItem.dateAdded, order: .reverse) private var loot: [LootItem]
    @State private var showingAddSheet = false
    @State private var selectedItem: LootItem?

    var body: some View {
        NavigationStack {
            Group {
                if loot.isEmpty {
                    ContentUnavailableView(
                        "No Loot Yet",
                        systemImage: "bag",
                        description: Text("Tap + to add loot from your adventure.")
                    )
                } else {
                    List {
                        ForEach(loot) { item in
                            Button {
                                selectedItem = item
                            } label: {
                                HStack {
                                    Text(item.category.icon)
                                        .font(.title2)
                                    VStack(alignment: .leading) {
                                        Text(item.name)
                                            .font(.headline)
                                        HStack(spacing: 12) {
                                            if item.weight > 0 {
                                                Text("Wt: \(item.weight, specifier: "%g")")
                                            }
                                            if item.value > 0 {
                                                Text("Val: \(item.value)")
                                            }
                                        }
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        if let carrier = item.carrier {
                                            Text(carrier.name)
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
                                        Text("×\(item.quantity)")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .tint(.primary)
                        }
                        .onDelete(perform: deleteLoot)
                    }
                }
            }
            .navigationTitle("D&D Loot")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigation) {
                    NavigationLink {
                        CarriersView()
                    } label: {
                        Image(systemName: "person.2")
                    }
                }
            }
            .navigationDestination(item: $selectedItem) { item in
                EditLootView(item: item)
            }
            .sheet(isPresented: $showingAddSheet) {
                AddLootView()
            }
        }
    }

    private func deleteLoot(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(loot[index])
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: LootItem.self, Carrier.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let carrier = Carrier(name: "Gandalf")
    container.mainContext.insert(carrier)
    let item = LootItem(
        name: "Flame Tongue Sword",
        category: .weapon,
        quantity: 2,
        weight: 3.5,
        value: 5000,
        carrier: carrier,
        notes: "Deals extra 2d6 fire damage"
    )
    container.mainContext.insert(item)
    return ContentView()
        .modelContainer(container)
}
