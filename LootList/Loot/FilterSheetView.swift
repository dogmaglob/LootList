import SwiftUI
import SwiftData

struct FilterSheetView: View {
    @Bindable var filterState: LootFilterState
    @Query(sort: \LootCategory.name) private var categories: [LootCategory]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                categoriesSection
                dateSection
                valueSection
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Reset") { filterState.reset() }
                        .disabled(!filterState.isActive)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private var categoriesSection: some View {
        if !categories.isEmpty {
            Section("Category") {
                ForEach(categories) { category in
                    Button {
                        if filterState.selectedCategories.contains(category.id) {
                            filterState.selectedCategories.remove(category.id)
                        } else {
                            filterState.selectedCategories.insert(category.id)
                        }
                    } label: {
                        HStack {
                            Text(category.emoji)
                            Text(category.name)
                            Spacer()
                            if filterState.selectedCategories.contains(category.id) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        .foregroundStyle(Color.primary)
                    }
                }
            }
        }
    }

    private var dateSection: some View {
        Section("Date Found") {
            Toggle("From", isOn: Binding(
                get: { filterState.dateFrom != nil },
                set: { filterState.dateFrom = $0 ? Calendar.current.startOfDay(for: .now) : nil }
            ))
            if filterState.dateFrom != nil {
                DatePicker(
                    "From",
                    selection: Binding(
                        get: { filterState.dateFrom ?? Calendar.current.startOfDay(for: .now) },
                        set: { filterState.dateFrom = $0 }
                    ),
                    displayedComponents: .date
                )
                .labelsHidden()
            }

            Toggle("To", isOn: Binding(
                get: { filterState.dateTo != nil },
                set: { filterState.dateTo = $0 ? Calendar.current.startOfDay(for: .now) : nil }
            ))
            if filterState.dateTo != nil {
                DatePicker(
                    "To",
                    selection: Binding(
                        get: { filterState.dateTo ?? Calendar.current.startOfDay(for: .now) },
                        set: { filterState.dateTo = $0 }
                    ),
                    in: (filterState.dateFrom ?? .distantPast)...,
                    displayedComponents: .date
                )
                .labelsHidden()
            }
        }
    }

    private var valueSection: some View {
        Section("Value") {
            HStack {
                Text("Min")
                Spacer()
                TextField("Any", text: $filterState.minValue)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.numberPad)
                    .frame(maxWidth: 100)
            }
            HStack {
                Text("Max")
                Spacer()
                TextField("Any", text: $filterState.maxValue)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.numberPad)
                    .frame(maxWidth: 100)
            }
        }
    }
}
