//
//  GameLoggrApp.swift
//  GameLoggr
//
//  Created by Justin Gain on 7/10/25.
//
import SwiftUI
import SwiftData

@main
struct GameLoggrApp: App {
    let container: ModelContainer = {
        print("🚀 Starting GameLoggr with local storage...")
        
        // Using local storage only - no CloudKit sync
        
        // Try local storage first
        do {
            print("💾 Creating local ModelContainer...")
            let localConfig = ModelConfiguration(
                schema: Schema([Game.self, Platform.self, PlayLogEntry.self, Hardware.self, HelpfulLink.self]),
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none
            )
            let container = try ModelContainer(for: Game.self, Platform.self, PlayLogEntry.self, Hardware.self, HelpfulLink.self, configurations: localConfig)
            print("✅ SUCCESS: Local ModelContainer created!")
            print("📱 Data will be stored locally on this device")
            return container
        } catch {
            print("❌ Local storage failed: \(error)")
            print("❌ Detailed error: \(error.localizedDescription)")
            print("🔄 Falling back to in-memory storage...")
        }
        
        // Final fallback to in-memory
        do {
            print("🧠 Creating in-memory ModelContainer...")
            let memoryConfig = ModelConfiguration(
                schema: Schema([Game.self, Platform.self, PlayLogEntry.self, Hardware.self, HelpfulLink.self]),
                isStoredInMemoryOnly: true,
                cloudKitDatabase: .none
            )
            let container = try ModelContainer(for: Game.self, Platform.self, PlayLogEntry.self, Hardware.self, HelpfulLink.self, configurations: memoryConfig)
            print("⚡ SUCCESS: In-memory ModelContainer created!")
            print("⚠️ NOTE: Data will not persist between app launches")
            return container
        } catch {
            print("💥 CRITICAL: Even in-memory storage failed!")
            print("💥 Error: \(error)")
            print("💥 This indicates a fundamental SwiftData model issue")
            
            // Log the specific error details
            if let swiftDataError = error as? SwiftData.SwiftDataError {
                print("💥 SwiftData Error Type: \(swiftDataError)")
            }
            
            fatalError("Unable to create any ModelContainer. Check model definitions: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
