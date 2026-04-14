import SwiftUI
import SwiftData

struct AddLootView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let campaign: Campaign?

    @State private var name = ""
    @State private var selectedCategory: LootCategory?
    @State private var quantity = 1
    @State private var weight = ""
    @State private var value = ""
    @State private var selectedCarrier: Carrier?
    @State private var notes = ""

    @Query(sort: \Carrier.name) private var carriers: [Carrier]
    @Query(sort: \LootCategory.name) private var categories: [LootCategory]

    init(campaign: Campaign?) {
        self.campaign = campaign
    }

    var body: some View {
        NavigationStack {
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
            .navigationTitle("Add Loot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let item = LootItem(
                            name: name,
                            category: selectedCategory,
                            quantity: quantity,
                            weight: Double(weight) ?? 0,
                            value: Int(value) ?? 0,
                            carrier: selectedCarrier,
                            notes: notes
                        )
                        item.campaign = campaign
                        modelContext.insert(item)
                        let event = LootEvent(type: .found, itemName: name, itemID: item.id, campaign: campaign)
                        modelContext.insert(event)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: LootItem.self, Carrier.self, LootCategory.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    for (name, emoji) in LootCategory.seedData {
        container.mainContext.insert(LootCategory(name: name, emoji: emoji))
    }
    return AddLootView(campaign: nil)
        .modelContainer(container)
}
