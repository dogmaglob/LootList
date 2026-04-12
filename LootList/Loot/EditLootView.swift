import SwiftUI
import SwiftData

struct EditLootView: View {
    @Bindable var item: LootItem

    @State private var weight: String
    @State private var value: String

    @Query private var carriers: [Carrier]
    @Query(sort: \LootCategory.name) private var categories: [LootCategory]

    init(item: LootItem) {
        self.item = item
        self._weight = State(initialValue: item.weight > 0 ? item.weight.formatted(.number) : "")
        self._value = State(initialValue: item.value > 0 ? item.value.formatted(.number) : "")
        let campaignID = item.campaign?.id
        _carriers = Query(
            filter: #Predicate<Carrier> { carrier in
                carrier.campaign?.id == campaignID
            },
            sort: \Carrier.name
        )
    }

    var body: some View {
        Form {
            Section("Item Details") {
                TextField("Item name", text: $item.name)
                Picker("Category", selection: $item.category) {
                    Text("None").tag(nil as LootCategory?)
                    ForEach(categories) { cat in
                        Text("\(cat.emoji) \(cat.name)").tag(cat as LootCategory?)
                    }
                }
                Stepper("Quantity: \(item.quantity)", value: $item.quantity, in: 1...999)
                TextField("Weight", text: $weight)
                    .keyboardType(.decimalPad)
                    .onChange(of: weight) { _, newValue in
                        item.weight = Double(newValue) ?? 0
                    }
                TextField("Value", text: $value)
                    .keyboardType(.numberPad)
                    .onChange(of: value) { _, newValue in
                        item.value = Int(newValue) ?? 0
                    }
                NavigationLink {
                    CarrierPickerView(campaign: item.campaign, selection: $item.carrier)
                } label: {
                    HStack {
                        Text("Carrier")
                        Spacer()
                        Text(item.carrier?.name ?? "None")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Notes") {
                TextField("Optional notes", text: $item.notes, axis: .vertical)
                    .lineLimit(3...6)
            }
        }
        .navigationTitle("Edit Loot")
        .navigationBarTitleDisplayMode(.inline)
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
    return NavigationStack {
        EditLootView(item: item)
    }
    .modelContainer(container)
}
