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
            PlayLogEntry.self
        ])
        
        // Use this for local-only storage.
        // To enable iCloud sync, you must have a paid Apple Developer account,
        // enable the iCloud capability, and use a ModelConfiguration with a
        // cloudKitDatabase parameter.
        let localConfiguration = ModelConfiguration("GameCollection", schema: schema)
        
        do {
            return try ModelContainer(for: schema, configurations: [localConfiguration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
