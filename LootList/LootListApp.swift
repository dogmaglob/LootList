//
//  LootListApp.swift
//  LootList
//
//  Created by Kelley Rogers on 3/27/26.
//

import SwiftUI
import SwiftData

@main
struct LootListApp: App {
    let container: ModelContainer = {
        let schema = Schema([
            LootItem.self,
            Carrier.self,
            LootCategory.self,
            Campaign.self,
            LootEvent.self,
        ])
        do {
            return try ModelContainer(for: schema)
        } catch {
            preconditionFailure("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear(perform: seedCategoriesIfNeeded)
        }
        .modelContainer(container)
    }

    private func seedCategoriesIfNeeded() {
        let context = container.mainContext
        let count = (try? context.fetchCount(FetchDescriptor<LootCategory>())) ?? 0
        guard count == 0 else { return }
        for (name, emoji) in LootCategory.seedData {
            context.insert(LootCategory(name: name, emoji: emoji))
        }
    }
}
