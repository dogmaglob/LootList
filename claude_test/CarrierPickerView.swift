import SwiftUI
import SwiftData

struct CarrierPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Carrier.name) private var carriers: [Carrier]
    @Binding var selection: Carrier?
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
                            Text(carrier.name)
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
