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
        }
        .modelContainer(container)
    }
}
