import SwiftUI
import SwiftData

struct EditLootView: View {
    private let item: LootItem
    private let campaign: Campaign?

    @State private var name: String
    @State private var selectedCategory: LootCategory?
    @State private var quantity: Int
    @State private var weight: String
    @State private var value: String
    @State private var selectedCarrier: Carrier?
    @State private var notes: String

    @Query(sort: \LootCategory.name) private var categories: [LootCategory]

    init(item: LootItem, campaign: Campaign?) {
        self.item = item
        self.campaign = campaign
        _name = State(initialValue: item.name)
        _selectedCategory = State(initialValue: item.category)
        _quantity = State(initialValue: item.quantity)
        _weight = State(initialValue: item.weight > 0 ? item.weight.formatted(.number) : "")
        _value = State(initialValue: item.value > 0 ? item.value.formatted(.number) : "")
        _selectedCarrier = State(initialValue: item.carrier)
        _notes = State(initialValue: item.notes)
    }

    var body: some View {
        Form {
            Section("Item Details") {
                TextField("Item name", text: $name)
                Picker("Category", selection: $selectedCategory) {
                    Text("None").tag(nil as LootCategory?)
                    ForEach(categories) { cat in
                        Text("\(cat.emoji) \(cat.name)").tag(cat as LootCategory?)
                    }
                }
                Stepper("Quantity: \(quantity)", value: $quantity, in: 1...999)
                TextField("Weight", text: $weight)
                    .keyboardType(.decimalPad)
                TextField("Value", text: $value)
                    .keyboardType(.numberPad)
                NavigationLink {
                    CarriersView(campaign: campaign, selection: $selectedCarrier)
                } label: {
                    HStack {
                        Text("Carrier")
                        Spacer()
                        Text(selectedCarrier?.name ?? "None")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Notes") {
                TextField("Optional notes", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            }
        }
        .navigationTitle("Edit Loot")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            item.name = name
            item.category = selectedCategory
            item.quantity = quantity
            item.weight = Double(weight) ?? 0
            item.value = Int(value) ?? 0
            item.carrier = selectedCarrier
            item.notes = notes
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
    return NavigationStack {
        EditLootView(item: item, campaign: nil)
    }
    .modelContainer(container)
}
