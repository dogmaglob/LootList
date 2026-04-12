import SwiftUI
import SwiftData

struct CarriersView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var carriers: [Carrier]
    @State private var newName = ""

    private let campaign: Campaign?
    private let selection: Binding<Carrier?>?

    init(campaign: Campaign?, selection: Binding<Carrier?>? = nil) {
        self.campaign = campaign
        self.selection = selection
        let campaignID = campaign?.id
        _carriers = Query(
            filter: #Predicate<Carrier> { carrier in
                carrier.campaign?.id == campaignID
            },
            sort: \Carrier.name
        )
    }

    private var trimmedName: String { newName.trimmingCharacters(in: .whitespaces) }

    private var nameIsDuplicate: Bool {
        carriers.contains { $0.name?.localizedCaseInsensitiveCompare(trimmedName) == .orderedSame }
    }

    var body: some View {
        List {
            Section {
                HStack {
                    TextField("New carrier name", text: $newName)
                    Button("Add") {
                        let carrier = Carrier(name: trimmedName)
                        carrier.campaign = campaign
                        modelContext.insert(carrier)
                        newName = ""
                    }
                    .disabled(trimmedName.isEmpty || nameIsDuplicate)
                }
            }

            Section {
                if let selection {
                    Button {
                        selection.wrappedValue = nil
                        dismiss()
                    } label: {
                        HStack {
                            Text("None")
                                .foregroundStyle(.primary)
                            Spacer()
                            if selection.wrappedValue == nil {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.tint)
                            }
                        }
                    }

                    ForEach(carriers) { carrier in
                        Button {
                            selection.wrappedValue = carrier
                            dismiss()
                        } label: {
                            HStack {
                                Text(carrier.name ?? "")
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selection.wrappedValue == carrier {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.tint)
                                }
                            }
                        }
                    }
                    .onDelete(perform: deleteCarriers)
                } else {
                    if carriers.isEmpty {
                        Text("No carriers yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(carriers) { carrier in
                            HStack {
                                Text(carrier.name ?? "")
                                Spacer()
                                Text("\((carrier.loot?.count ?? 0).formatted(.number)) items")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .onDelete(perform: deleteCarriers)
                    }
                }
            }
        }
        .navigationTitle(selection != nil ? "Carrier" : "Carriers")
    }

    private func deleteCarriers(at offsets: IndexSet) {
        for index in offsets {
            let carrier = carriers[index]
            if selection?.wrappedValue == carrier {
                selection?.wrappedValue = nil
            }
            modelContext.delete(carrier)
        }
    }
}

#Preview {
    NavigationStack {
        CarriersView(campaign: nil)
    }
    .modelContainer(for: Carrier.self, inMemory: true)
}
