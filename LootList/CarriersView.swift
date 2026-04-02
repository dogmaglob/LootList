import SwiftUI
import SwiftData

struct CarriersView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Carrier.name) private var carriers: [Carrier]
    @State private var newName = ""

    var body: some View {
        List {
            Section {
                HStack {
                    TextField("New carrier name", text: $newName)
                    Button("Add") {
                        let carrier = Carrier(name: newName.trimmingCharacters(in: .whitespaces))
                        modelContext.insert(carrier)
                        newName = ""
                    }
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            Section {
                if carriers.isEmpty {
                    Text("No carriers yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(carriers) { carrier in
                        HStack {
                            Text(carrier.name)
                            Spacer()
                            Text("\(carrier.loot.count) items")
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
        CarriersView()
    }
    .modelContainer(for: Carrier.self, inMemory: true)
}
