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
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [LootItem.self, Carrier.self])
    }
}
