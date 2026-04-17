import SwiftUI
import SwiftData

struct CategoryManagerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LootCategory.name) private var categories: [LootCategory]

    @State private var newEmoji = ""
    @State private var newName = ""

    var body: some View {
        List {
            Section {
                HStack(spacing: 8) {
                    TextField("🎒", text: $newEmoji)
                        .frame(width: 44)
                        .multilineTextAlignment(.center)
                    TextField("Category name", text: $newName)
                    Button("Add") {
                        let category = LootCategory(
                            name: newName.trimmingCharacters(in: .whitespaces),
                            emoji: newEmoji
                        )
                        modelContext.insert(category)
                        newName = ""
                        newEmoji = ""
                    }
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty || newEmoji.isEmpty)
                }
            }

            Section {
                ForEach(categories) { category in
                    HStack {
                        Text(category.emoji)
                        Text(category.name)
                    }
                }
                .onDelete { offsets in
                    offsets.forEach { modelContext.delete(categories[$0]) }
                }
            }
        }
        .navigationTitle("Categories")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            EditButton()
        }
    }
}
