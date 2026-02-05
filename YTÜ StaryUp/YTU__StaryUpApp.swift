//
//  YTU__StaryUpApp.swift
//  YTÜ StaryUp
//
//  Created by Fatih Kadir Akın on 5.02.2026.
//

import SwiftUI
import SwiftData

@main
struct YTU__StaryUpApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
