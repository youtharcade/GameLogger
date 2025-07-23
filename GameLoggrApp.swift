//
//  GameLoggerApp.swift
//  GameLogger
//
//  Created by Justin Gain on 7/10/25.
//
import SwiftUI
import SwiftData

@main
struct GameLoggerApp: App {
    let container: ModelContainer = {
        let schema = Schema([
            Game.self,
            Platform.self,
            PlayLogEntry.self,
            Hardware.self,
            HelpfulLink.self
        ])
        
        // CloudKit configuration for iCloud sync
        let cloudKitConfiguration = ModelConfiguration(
            "GameCollection",
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            cloudKitDatabase: .automatic
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [cloudKitConfiguration])
        } catch {
            fatalError("Failed to create ModelContainer with CloudKit: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
