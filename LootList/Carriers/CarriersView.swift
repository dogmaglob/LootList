import SwiftUI
import SwiftData

struct CarriersView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var carriers: [Carrier]
    @State private var newName = ""

    private let campaign: Campaign?

    init(campaign: Campaign?) {
        self.campaign = campaign
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
        .navigationTitle("Carriers")
    }

    private func deleteCarriers(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(carriers[index])
        }
    }
}

#Preview {
    NavigationStack {
        CarriersView(campaign: nil)
    }
    .modelContainer(for: Carrier.self, inMemory: true)
}
