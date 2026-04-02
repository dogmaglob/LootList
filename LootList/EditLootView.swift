import SwiftUI
import SwiftData

struct EditLootView: View {
    @Bindable var item: LootItem

    @State private var weight: String
    @State private var value: String

    @Query(sort: \Carrier.name) private var carriers: [Carrier]

    init(item: LootItem) {
        self.item = item
        self._weight = State(initialValue: item.weight > 0 ? "\(item.weight)" : "")
        self._value = State(initialValue: item.value > 0 ? "\(item.value)" : "")
    }

    var body: some View {
        Form {
            Section("Item Details") {
                TextField("Item name", text: $item.name)
                Picker("Category", selection: $item.category) {
                    ForEach(LootCategory.allCases) { cat in
                        Text("\(cat.icon) \(cat.rawValue)").tag(cat)
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
                    CarrierPickerView(selection: $item.carrier)
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
