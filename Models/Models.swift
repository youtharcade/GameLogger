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
    var id: String = UUID().uuidString
    var title: String = ""
    var coverArtURL: URL?
    var customCoverArt: Data?
    
    // Basic Game Properties
    var releaseDate: Date = Date()
    var purchaseDate: Date = Date()
    var startDate: Date = Date()
    var completionDate: Date = Date()
    var isDigital: Bool = false
    var purchasePrice: Double = 0.0
    var msrp: Double = 0.0
    var status: GameStatus = GameStatus.backlog
    var starRating: Double = 0
    var isWishlisted: Bool = false
    var ownershipStatus: OwnershipStatus = OwnershipStatus.owned
    var isInstalled: Bool = false
    var gameSizeInMB: Double = 0
    var totalTimePlayed: Double = 0
    var manuallySetTotalTime: Double = 0
    
    // Physical Game Properties
    var hasCase: Bool = false
    var hasManual: Bool = false
    var hasInserts: Bool = false
    var isSealed: Bool = false
    var collectorsGrade: String = "Near Mint"
    
    // HLTB Properties
    var userHLTBMain: Double = 0
    var userHLTBExtra: Double = 0
    var userHLTBCompletionist: Double = 0
    
    // String Properties for JSON Data (SwiftData compatible)
    var genresString: String = ""
    var developersString: String = ""
    var publishersString: String = ""
    
    // Computed Properties for Array Access (SwiftData compatible)
    var genres: [String] {
        get { genresString.isEmpty ? [] : genresString.components(separatedBy: ",") }
        set { genresString = newValue.joined(separator: ",") }
    }
    
    var developers: [String] {
        get { developersString.isEmpty ? [] : developersString.components(separatedBy: ",") }
        set { developersString = newValue.joined(separator: ",") }
    }
    
    var publishers: [String] {
        get { publishersString.isEmpty ? [] : publishersString.components(separatedBy: ",") }
        set { publishersString = newValue.joined(separator: ",") }
    }
    
    // Status Value Computed Property
    var statusValue: String {
        return status.rawValue
    }
    
    var ownershipStatusValue: String {
        return ownershipStatus.rawValue
    }
    
    // Platform Relationship
    var platform: Platform?
    
    // Play Log Relationship
    var playLog: [PlayLogEntry] = []
    
    // PDF Data
    var manualPDFs: [Data] = []
    
    // Hardware Relationship
    var linkedHardware: Hardware?
    
    // Collection Properties (simplified - no complex relationships yet)
    var isSubGame: Bool = false
    var isCollection: Bool = false
    
    // Collection Relationships - RE-ENABLED with caution
    var parentCollection: Game?
    var includedGames: [Game]? = nil
    
    // Walkthrough Links Relationship
    var helpfulLinks: [HelpfulLink] = []
    
    // Calculated Total Time Played
    var calculatedTotalTime: Double {
        return playLog.reduce(0) { $0 + $1.timeSpent }
    }
    
    // Use manual time if set, otherwise calculated
    var effectiveTotalTime: Double {
        return manuallySetTotalTime > 0 ? manuallySetTotalTime : calculatedTotalTime
    }
    
    init(title: String, platform: Platform? = nil, purchaseDate: Date = Date(), isDigital: Bool = false, purchasePrice: Double = 0.0, msrp: Double = 0.0, status: GameStatus = GameStatus.backlog) {
        self.title = title
        self.platform = platform
        self.purchaseDate = purchaseDate
        self.isDigital = isDigital
        self.purchasePrice = purchasePrice
        self.msrp = msrp
        self.status = status
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
class Platform {
    @Attribute(.unique) var id: Int
    var name: String
    var logoURL: URL?
    
    @Relationship(inverse: \Hardware.platform)
    var hardware: [Hardware]? = []
    
    init(id: Int, name: String, logoURL: URL? = nil) {
        self.id = id
        self.name = name
        self.logoURL = logoURL
    }
}

// Separate struct for JSON loading from platforms.json
struct PlatformData: Codable {
    let id: Int
    let name: String
    let logoURL: URL?
    
    enum CodingKeys: String, CodingKey {
        case id, name, logoURL
    }
    
    init(from decoder: Decoder) throws {
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
    
    // Convert to SwiftData Platform
    func toPlatform() -> Platform {
        return Platform(id: id, name: name, logoURL: logoURL)
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
        guard !linkedGames.isEmpty else { return 0.0 }
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
