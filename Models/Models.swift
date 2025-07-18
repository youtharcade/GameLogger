//
//  Models.swift
//  GameLogger
//
//  Created by Justin Gain on 7/10/25.
//
import Foundation
import SwiftData
import SwiftUI

// MARK: - Enums
enum GameStatus: String, Codable, CaseIterable {
    case backlog = "Backlog"
    case inProgress = "In Progress"
    case completed = "Completed"
    case onHold = "On Hold"
    case dropped = "Dropped"
}

enum OwnershipStatus: String, Codable, CaseIterable {
    case owned = "In Collection"
    case sold = "Sold"
    case lentOut = "Lent Out"
}

// MARK: - SwiftData Models

@Model
class Game {
    @Attribute(.unique) var id: UUID = UUID()
    // Core Properties
    var title: String
    var coverArtURL: URL?
    var platform: Platform?
    var purchaseDate: Date
    var isDigital: Bool
    var purchasePrice: Double
    var msrp: Double
    
    // Status & Backlog
    var statusValue: String
    var startDate: Date?
    var completionDate: Date?
    
    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \PlayLogEntry.game)
    var playLog: [PlayLogEntry] = []
    
    // External Data
    var hltbMain: Double = 0
    var hltbExtra: Double = 0
    var hltbCompletionist: Double = 0
    
    // User-Tracked Data
    var manuallySetTotalTime: Double = 0
    var starRating: Double = 0
    var userHLTBMain: Double = 0
    var userHLTBExtra: Double = 0
    var userHLTBCompletionist: Double = 0
    
    // Categorization
    var isWishlisted: Bool = false
    
    // External Files
    @Attribute(.externalStorage) var customCoverArt: Data?
    @Attribute(.externalStorage) var manualPDFsData: Data?
    
    // Physical Collector's Grade
    var hasCase: Bool = false
    var hasManual: Bool = false
    var hasInserts: Bool = false
    var isSealed: Bool = false
    
    // Digital Edition
    var isInstalled: Bool = false
    var gameSizeInMB: Double = 0
    
    // IGDB Info
    var releaseDate: Date?
    var genresString: String = ""
    var developersString: String = ""
    var publishersString: String = ""
    
    // Hardware & Game Collection Relationships
    var linkedHardware: Hardware?
    var isSubGame: Bool = false
    var parentCollection: Game?
    @Relationship(deleteRule: .cascade)
    var includedGames: [Game]? = nil
    var isCollection: Bool = false
    
    // Walkthrough Links Relationship
    @Relationship(deleteRule: .cascade, inverse: \HelpfulLink.game)
    var helpfulLinks: [HelpfulLink] = []
    
    // Ownership Status
    var ownershipStatusValue: String = OwnershipStatus.owned.rawValue

    // --- COMPUTED PROPERTIES ---
    
    var status: GameStatus {
        get { GameStatus(rawValue: statusValue) ?? .backlog }
        set { statusValue = newValue.rawValue }
    }
    
    var totalTimePlayed: Double {
        if manuallySetTotalTime > 0 {
            return manuallySetTotalTime
        } else {
            return playLog.reduce(0) { $0 + $1.timeSpent } / 3600 // Return in hours
        }
    }
    
    var collectorsGrade: String {
        if isSealed { return "Sealed" }
        if hasCase && hasManual && hasInserts { return "CIB+" }
        if hasCase && hasManual { return "CIB (Complete in Box)" }
        if hasCase { return "In Case" }
        return "Loose"
    }
    
    var genres: [String] {
        get { genresString.split(separator: ",").map(String.init) }
        set { genresString = newValue.joined(separator: ",") }
    }
    
    var developers: [String] {
        get { developersString.split(separator: ",").map(String.init) }
        set { developersString = newValue.joined(separator: ",") }
    }
    
    var publishers: [String] {
        get { publishersString.split(separator: ",").map(String.init) }
        set { publishersString = newValue.joined(separator: ",") }
    }
    
    var ownershipStatus: OwnershipStatus {
        get { OwnershipStatus(rawValue: ownershipStatusValue) ?? .owned }
        set { ownershipStatusValue = newValue.rawValue }
    }
    
    var manualPDFs: [Data] {
        get {
            guard let data = manualPDFsData else { return [] }
            return (try? JSONDecoder().decode([Data].self, from: data)) ?? []
        }
        set {
            manualPDFsData = try? JSONEncoder().encode(newValue)
        }
    }
    
    var overlayIcon: (name: String, color: Color)? {
            if self.ownershipStatus != .owned {
                return ("archivebox.fill", .gray) // For "Graveyard" games
            }
            if self.isSubGame {
                return ("link", .white) // For games included in a collection
            }
            // Add other cases here if you want more indicators
            
            return nil // No icon for standard collection games
        }
    
    // --- INITIALIZER ---
    
    init(title: String, coverArtURL: URL? = nil, platform: Platform?, purchaseDate: Date, isDigital: Bool, purchasePrice: Double, msrp: Double, status: GameStatus, startDate: Date? = nil, completionDate: Date? = nil, playLog: [PlayLogEntry] = [], hltbMain: Double = 0, hltbExtra: Double = 0, hltbCompletionist: Double = 0, manuallySetTotalTime: Double = 0, isWishlisted: Bool = false, manualPDF: Data? = nil, hasCase: Bool = false, hasManual: Bool = false, hasInserts: Bool = false, isSealed: Bool = false, isInstalled: Bool = false, gameSizeInMB: Double = 0, starRating: Double = 0, customCoverArt: Data? = nil, releaseDate: Date? = nil, genres: [String] = [], developers: [String] = [], publishers: [String] = [], linkedHardware: Hardware? = nil, isSubGame: Bool = false, parentCollection: Game? = nil, helpfulLinks: [HelpfulLink] = [], ownershipStatus: OwnershipStatus = .owned) {
        self.title = title
        self.coverArtURL = coverArtURL
        self.platform = platform
        self.purchaseDate = purchaseDate
        self.isDigital = isDigital
        self.purchasePrice = purchasePrice
        self.msrp = msrp
        self.statusValue = status.rawValue
        self.startDate = startDate
        self.completionDate = completionDate
        self.playLog = playLog
        self.hltbMain = hltbMain
        self.hltbExtra = hltbExtra
        self.hltbCompletionist = hltbCompletionist
        self.manuallySetTotalTime = manuallySetTotalTime
        self.isWishlisted = isWishlisted
        self.manualPDFs = manualPDFs
        self.hasCase = hasCase
        self.hasManual = hasManual
        self.hasInserts = hasInserts
        self.isSealed = isSealed
        self.isInstalled = isInstalled
        self.gameSizeInMB = gameSizeInMB
        self.starRating = starRating
        self.customCoverArt = customCoverArt
        self.releaseDate = releaseDate
        self.linkedHardware = linkedHardware
        self.isSubGame = isSubGame
        self.parentCollection = parentCollection
        self.helpfulLinks = helpfulLinks
        self.ownershipStatusValue = ownershipStatus.rawValue
        
        self.genres = genres
        self.developers = developers
        self.publishers = publishers
    }
}

@Model
class PlayLogEntry {
    var timestamp: Date
    var timeSpent: TimeInterval
    var notes: String
    var checkpoint: Bool = false
    var title: String? = nil
    var game: Game?

    init(timestamp: Date, timeSpent: TimeInterval, notes: String, checkpoint: Bool = false, title: String? = nil) {
        self.timestamp = timestamp
        self.timeSpent = timeSpent
        self.notes = notes
        self.checkpoint = checkpoint
        self.title = title
    }
}

@Model
class Platform: Codable {
    @Attribute(.unique) var id: Int
    var name: String
    var logoURL: URL?
    
    @Relationship(inverse: \Hardware.platform)
    var hardware: [Hardware]? = []
    
    enum CodingKeys: String, CodingKey {
        case id, name, logoURL
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.logoURL = try container.decodeIfPresent(URL.self, forKey: .logoURL)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(logoURL, forKey: .logoURL)
    }

    init(id: Int, name: String, logoURL: URL? = nil) {
        self.id = id
        self.name = name
        self.logoURL = logoURL
    }
}

@Model
class Hardware {
    var name: String
    var platform: Platform?
    var serialNumber: String?
    var purchasePrice: Double
    var purchaseDate: Date
    var msrp: Double
    var releaseDate: Date?
    
    @Attribute(.externalStorage) var imageData: Data?
    
    var internalStorageInGB: Double = 0.0
    var externalStorageInGB: Double = 0.0
    
    @Relationship(inverse: \Game.linkedHardware)
    var linkedGames: [Game] = []
    
    var totalStorageInGB: Double {
        internalStorageInGB + externalStorageInGB
    }
    
    var usedStorageInGB: Double {
        let totalMB = linkedGames.filter { $0.isInstalled }.reduce(0) { $0 + $1.gameSizeInMB }
        return totalMB / 1000 // Convert MB to GB
    }
    
    var availableStorageInGB: Double {
        totalStorageInGB - usedStorageInGB
    }
    
    init(name: String, serialNumber: String? = nil, purchasePrice: Double = 0.0, purchaseDate: Date = Date(), msrp: Double = 0.0, releaseDate: Date? = nil, imageData: Data? = nil, platform: Platform? = nil, internalStorageInGB: Double = 0.0, externalStorageInGB: Double = 0.0) {
        self.name = name
        self.serialNumber = serialNumber
        self.purchasePrice = purchasePrice
        self.purchaseDate = purchaseDate
        self.msrp = msrp
        self.releaseDate = releaseDate
        self.imageData = imageData
        self.platform = platform
        self.internalStorageInGB = internalStorageInGB
        self.externalStorageInGB = externalStorageInGB
    }
}

@Model
class HelpfulLink {
    var name: String
    var urlString: String
    var game: Game?
    
    init(name: String, urlString: String) {
        self.name = name
        self.urlString = urlString
    }
}
