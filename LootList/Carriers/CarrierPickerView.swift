import SwiftUI
import SwiftData

struct CarrierPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var carriers: [Carrier]
    @Binding var selection: Carrier?
    @State private var newName = ""

    private let campaign: Campaign?

    init(campaign: Campaign?, selection: Binding<Carrier?>) {
        self.campaign = campaign
        _selection = selection
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
                Button {
                    selection = nil
                    dismiss()
                } label: {
                    HStack {
                        Text("None")
                            .foregroundStyle(.primary)
                        Spacer()
                        if selection == nil {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                        }
                    }
                }

                ForEach(carriers) { carrier in
                    Button {
                        selection = carrier
                        dismiss()
                    } label: {
                        HStack {
                            Text(carrier.name ?? "")
                                .foregroundStyle(.primary)
                            Spacer()
                            if selection == carrier {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.tint)
                            }
                        }
                    }
                }
                .onDelete(perform: deleteCarriers)
            }
        }
        .navigationTitle("Carrier")
    }

    private func deleteCarriers(at offsets: IndexSet) {
        for index in offsets {
            let carrier = carriers[index]
            if selection == carrier {
                selection = nil
            }
            modelContext.delete(carrier)
        }
    }
}
