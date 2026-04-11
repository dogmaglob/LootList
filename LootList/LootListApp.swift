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
    @State private var appState = AppState()

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
            // Migration failed — wipe the store and start fresh.
            // This is acceptable during development; replace with a proper
            // migration plan before shipping.
            let storeURL = URL.applicationSupportDirectory.appending(path: "default.store")
            for suffix in ["", "-shm", "-wal"] {
                try? FileManager.default.removeItem(atPath: storeURL.path + suffix)
            }
            do {
                return try ModelContainer(for: schema)
            } catch {
                preconditionFailure("Failed to create ModelContainer after store reset: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            CampaignListView()
                .environment(appState)
                .onAppear { seedCategoriesIfNeeded(in: container.mainContext) }
        }
        .modelContainer(container)
    }
}
