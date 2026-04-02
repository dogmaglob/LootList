import SwiftUI
import SwiftData

struct AddLootView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var category: LootCategory = .misc
    @State private var quantity = 1
    @State private var weight = ""
    @State private var value = ""
    @State private var selectedCarrier: Carrier?
    @State private var notes = ""

    @Query(sort: \Carrier.name) private var carriers: [Carrier]

    var body: some View {
        NavigationStack {
            Form {
                Section("Item Details") {
                    TextField("Item name", text: $name)
                    Picker("Category", selection: $category) {
                        ForEach(LootCategory.allCases) { cat in
                            Text("\(cat.icon) \(cat.rawValue)").tag(cat)
                        }
                    }
                    Stepper("Quantity: \(quantity)", value: $quantity, in: 1...999)
                    TextField("Weight", text: $weight)
                        .keyboardType(.decimalPad)
                    TextField("Value", text: $value)
                        .keyboardType(.numberPad)
                    NavigationLink {
                        CarrierPickerView(selection: $selectedCarrier)
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
                            category: category,
                            quantity: quantity,
                            weight: Double(weight) ?? 0,
                            value: Int(value) ?? 0,
                            carrier: selectedCarrier,
                            notes: notes
                        )
                        modelContext.insert(item)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

#Preview {
    AddLootView()
        .modelContainer(for: LootItem.self, inMemory: true)
}
