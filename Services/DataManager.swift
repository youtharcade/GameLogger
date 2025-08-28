//
//  DataManager.swift
//  GameLoggr
//
//  Created by Justin Gain on 7/18/25.
//

import Foundation
import SwiftData

/// Manages import/export of game collection data
class DataManager {
    
    // MARK: - Export Data Structure
    
    struct GameLoggrExport: Codable {
        let version: String
        let exportDate: Date
        let games: [ExportedGame]
        let platforms: [ExportedPlatform]
        let hardware: [ExportedHardware]
        
        static let currentVersion = "1.0"
    }
    
    struct ExportedGame: Codable {
        // Basic properties
        let id: String
        let title: String
        let coverArtURL: String?
        
        // Game properties
        let releaseDate: Date
        let purchaseDate: Date
        let startDate: Date
        let completionDate: Date
        let isDigital: Bool
        let purchasePrice: Double
        let msrp: Double
        let status: String
        let starRating: Double
        let isWishlisted: Bool
        let ownershipStatus: String
        let isInstalled: Bool
        let gameSizeInMB: Double
        let totalTimePlayed: Double
        let manuallySetTotalTime: Double
        
        // Physical properties
        let hasCase: Bool
        let hasManual: Bool
        let hasInserts: Bool
        let isSealed: Bool
        let collectorsGrade: String
        
        // HLTB properties
        let userHLTBMain: Double
        let userHLTBExtra: Double
        let userHLTBCompletionist: Double
        
        // String data
        let genresString: String
        let developersString: String
        let publishersString: String
        
        // Collection properties
        let isSubGame: Bool
        let isCollection: Bool
        let parentCollectionID: String?
        
        // Relationships (IDs only)
        let platformID: Int?
        let linkedHardwareID: String?
        let playLogEntries: [ExportedPlayLogEntry]
        let helpfulLinks: [ExportedHelpfulLink]
    }
    
    struct ExportedPlayLogEntry: Codable {
        let timestamp: Date
        let timeSpent: TimeInterval
        let notes: String
        let checkpoint: Bool
        let title: String?
    }
    
    struct ExportedHelpfulLink: Codable {
        let name: String
        let urlString: String
    }
    
    struct ExportedPlatform: Codable {
        let id: Int
        let name: String
        let logoURL: String?
    }
    
    struct ExportedHardware: Codable {
        let id: String
        let name: String
        let serialNumber: String?
        let purchasePrice: Double
        let purchaseDate: Date
        let msrp: Double
        let releaseDate: Date?
        let platformID: Int?
        let internalStorageInGB: Double
        let externalStorageInGB: Double
    }
    
    // MARK: - Export Functions
    
    /// Export all game data to JSON
    static func exportData(from context: ModelContext) throws -> Data {
        // Fetch all data
        let games = try context.fetch(FetchDescriptor<Game>())
        let platforms = try context.fetch(FetchDescriptor<Platform>())
        let hardware = try context.fetch(FetchDescriptor<Hardware>())
        
        // Convert to exportable format
        let exportedGames = games.map { game in
            ExportedGame(
                id: game.id,
                title: game.title,
                coverArtURL: game.coverArtURL?.absoluteString,
                releaseDate: game.releaseDate,
                purchaseDate: game.purchaseDate,
                startDate: game.startDate,
                completionDate: game.completionDate,
                isDigital: game.isDigital,
                purchasePrice: game.purchasePrice,
                msrp: game.msrp,
                status: game.status.rawValue,
                starRating: game.starRating,
                isWishlisted: game.isWishlisted,
                ownershipStatus: game.ownershipStatus.rawValue,
                isInstalled: game.isInstalled,
                gameSizeInMB: game.gameSizeInMB,
                totalTimePlayed: game.totalTimePlayed,
                manuallySetTotalTime: game.manuallySetTotalTime,
                hasCase: game.hasCase,
                hasManual: game.hasManual,
                hasInserts: game.hasInserts,
                isSealed: game.isSealed,
                collectorsGrade: game.collectorsGrade,
                userHLTBMain: game.userHLTBMain,
                userHLTBExtra: game.userHLTBExtra,
                userHLTBCompletionist: game.userHLTBCompletionist,
                genresString: game.genresString,
                developersString: game.developersString,
                publishersString: game.publishersString,
                isSubGame: game.isSubGame,
                isCollection: game.isCollection,
                parentCollectionID: game.parentCollectionID,
                platformID: game.platform?.id,
                linkedHardwareID: game.linkedHardware?.name, // Using name as ID for hardware
                playLogEntries: game.playLog.map { entry in
                    ExportedPlayLogEntry(
                        timestamp: entry.timestamp,
                        timeSpent: entry.timeSpent,
                        notes: entry.notes,
                        checkpoint: entry.checkpoint,
                        title: entry.title
                    )
                },
                helpfulLinks: game.helpfulLinks.map { link in
                    ExportedHelpfulLink(
                        name: link.name,
                        urlString: link.urlString
                    )
                }
            )
        }
        
        let exportedPlatforms = platforms.map { platform in
            ExportedPlatform(
                id: platform.id,
                name: platform.name,
                logoURL: platform.logoURL?.absoluteString
            )
        }
        
        let exportedHardware = hardware.map { hw in
            ExportedHardware(
                id: hw.name, // Using name as ID
                name: hw.name,
                serialNumber: hw.serialNumber,
                purchasePrice: hw.purchasePrice,
                purchaseDate: hw.purchaseDate,
                msrp: hw.msrp,
                releaseDate: hw.releaseDate,
                platformID: hw.platform?.id,
                internalStorageInGB: hw.internalStorageInGB,
                externalStorageInGB: hw.externalStorageInGB
            )
        }
        
        let exportData = GameLoggrExport(
            version: GameLoggrExport.currentVersion,
            exportDate: Date(),
            games: exportedGames,
            platforms: exportedPlatforms,
            hardware: exportedHardware
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        return try encoder.encode(exportData)
    }
    
    // MARK: - Import Functions
    
    /// Import game data from JSON, with option to merge or replace
    static func importData(_ data: Data, to context: ModelContext, replaceExisting: Bool = false) throws -> ImportResult {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let importData = try decoder.decode(GameLoggrExport.self, from: data)
        
        var result = ImportResult()
        
        // If replacing, clear existing data
        if replaceExisting {
            try clearAllData(from: context)
        }
        
        // Import platforms first (needed for games)
        for exportedPlatform in importData.platforms {
            let existingPlatform = try context.fetch(
                FetchDescriptor<Platform>(predicate: #Predicate { $0.id == exportedPlatform.id })
            ).first
            
            if existingPlatform == nil {
                let platform = Platform(
                    id: exportedPlatform.id,
                    name: exportedPlatform.name,
                    logoURL: exportedPlatform.logoURL.flatMap { URL(string: $0) }
                )
                context.insert(platform)
                result.platformsImported += 1
            }
        }
        
        // Import hardware
        for exportedHardware in importData.hardware {
            let existingHardware = try context.fetch(
                FetchDescriptor<Hardware>(predicate: #Predicate { $0.name == exportedHardware.name })
            ).first
            
            if existingHardware == nil {
                let platform = try context.fetch(
                    FetchDescriptor<Platform>(predicate: #Predicate { $0.id == (exportedHardware.platformID ?? -1) })
                ).first
                
                let hardware = Hardware(
                    name: exportedHardware.name,
                    serialNumber: exportedHardware.serialNumber,
                    purchasePrice: exportedHardware.purchasePrice,
                    purchaseDate: exportedHardware.purchaseDate,
                    msrp: exportedHardware.msrp,
                    releaseDate: exportedHardware.releaseDate,
                    imageData: nil,
                    platform: platform,
                    internalStorageInGB: exportedHardware.internalStorageInGB,
                    externalStorageInGB: exportedHardware.externalStorageInGB
                )
                context.insert(hardware)
                result.hardwareImported += 1
            }
        }
        
        // Import games
        for exportedGame in importData.games {
            let existingGame = try context.fetch(
                FetchDescriptor<Game>(predicate: #Predicate { $0.id == exportedGame.id })
            ).first
            
            if existingGame == nil || replaceExisting {
                // Find platform and hardware
                let platform = try context.fetch(
                    FetchDescriptor<Platform>(predicate: #Predicate { $0.id == (exportedGame.platformID ?? -1) })
                ).first
                
                let hardware = try context.fetch(
                    FetchDescriptor<Hardware>(predicate: #Predicate { $0.name == (exportedGame.linkedHardwareID ?? "") })
                ).first
                
                let game = Game(
                    title: exportedGame.title,
                    platform: platform,
                    purchaseDate: exportedGame.purchaseDate,
                    isDigital: exportedGame.isDigital,
                    purchasePrice: exportedGame.purchasePrice,
                    msrp: exportedGame.msrp,
                    status: GameStatus(rawValue: exportedGame.status) ?? .backlog
                )
                
                // Set all other properties
                game.id = exportedGame.id
                game.coverArtURL = exportedGame.coverArtURL.flatMap { URL(string: $0) }
                game.releaseDate = exportedGame.releaseDate
                game.startDate = exportedGame.startDate
                game.completionDate = exportedGame.completionDate
                game.starRating = exportedGame.starRating
                game.isWishlisted = exportedGame.isWishlisted
                game.ownershipStatus = OwnershipStatus(rawValue: exportedGame.ownershipStatus) ?? .owned
                game.isInstalled = exportedGame.isInstalled
                game.gameSizeInMB = exportedGame.gameSizeInMB
                game.totalTimePlayed = exportedGame.totalTimePlayed
                game.manuallySetTotalTime = exportedGame.manuallySetTotalTime
                game.hasCase = exportedGame.hasCase
                game.hasManual = exportedGame.hasManual
                game.hasInserts = exportedGame.hasInserts
                game.isSealed = exportedGame.isSealed
                game.collectorsGrade = exportedGame.collectorsGrade
                game.userHLTBMain = exportedGame.userHLTBMain
                game.userHLTBExtra = exportedGame.userHLTBExtra
                game.userHLTBCompletionist = exportedGame.userHLTBCompletionist
                game.genresString = exportedGame.genresString
                game.developersString = exportedGame.developersString
                game.publishersString = exportedGame.publishersString
                game.isSubGame = exportedGame.isSubGame
                game.isCollection = exportedGame.isCollection
                game.parentCollectionID = exportedGame.parentCollectionID
                game.linkedHardware = hardware
                
                // Add play log entries
                for exportedEntry in exportedGame.playLogEntries {
                    let playLogEntry = PlayLogEntry(
                        timestamp: exportedEntry.timestamp,
                        timeSpent: exportedEntry.timeSpent,
                        notes: exportedEntry.notes,
                        checkpoint: exportedEntry.checkpoint,
                        title: exportedEntry.title
                    )
                    playLogEntry.game = game
                    game.playLog.append(playLogEntry)
                    context.insert(playLogEntry)
                }
                
                // Add helpful links
                for exportedLink in exportedGame.helpfulLinks {
                    let helpfulLink = HelpfulLink(
                        name: exportedLink.name,
                        urlString: exportedLink.urlString
                    )
                    helpfulLink.game = game
                    game.helpfulLinks.append(helpfulLink)
                    context.insert(helpfulLink)
                }
                
                if existingGame != nil {
                    context.delete(existingGame!)
                }
                context.insert(game)
                result.gamesImported += 1
            }
        }
        
        try context.save()
        return result
    }
    
    /// Clear all data from the context
    private static func clearAllData(from context: ModelContext) throws {
        // Delete in order to respect relationships
        let games = try context.fetch(FetchDescriptor<Game>())
        let playLogEntries = try context.fetch(FetchDescriptor<PlayLogEntry>())
        let helpfulLinks = try context.fetch(FetchDescriptor<HelpfulLink>())
        let hardware = try context.fetch(FetchDescriptor<Hardware>())
        let platforms = try context.fetch(FetchDescriptor<Platform>())
        
        games.forEach { context.delete($0) }
        playLogEntries.forEach { context.delete($0) }
        helpfulLinks.forEach { context.delete($0) }
        hardware.forEach { context.delete($0) }
        platforms.forEach { context.delete($0) }
        
        try context.save()
    }
    
    // MARK: - Import Result
    
    struct ImportResult {
        var gamesImported: Int = 0
        var platformsImported: Int = 0
        var hardwareImported: Int = 0
        
        var totalItems: Int {
            gamesImported + platformsImported + hardwareImported
        }
    }
}
