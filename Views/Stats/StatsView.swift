//
//  StatsView.swift
//  GameLogger
//
//  Created by Justin Gain on 7/10/25.
//
import SwiftUI
import SwiftData
import Charts

struct ValueCategory: Identifiable {
    let id: String // Use platform name as ID
    let label: String
    let value: Double
    let color: Color
}

struct PlatformValue: Identifiable {
    let id = UUID()
    let platformName: String
    let value: Double
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
            Text(value)
                .font(.title3.bold())
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, minHeight: 60)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
    }
}

struct StatsView: View {
    @Query(filter: #Predicate<Game> { !$0.isWishlisted }) private var games: [Game]
    @Query(sort: \Hardware.name) private var hardwareItems: [Hardware]

    private var totalPurchasePrice: Double { games.reduce(0) { $0 + $1.purchasePrice } }
    private var totalMSRP: Double { games.reduce(0) { $0 + $1.msrp } }
    private var totalDifference: Double { totalMSRP - totalPurchasePrice }
    private var totalTimePlayed: Double { games.reduce(0) { $0 + $1.totalTimePlayed } }
    private var fiveStarGamesCount: Int { games.filter { $0.starRating == 5 }.count }
    private var gamesByStatus: [(status: GameStatus, count: Int)] { Dictionary(grouping: games, by: { $0.status }).mapValues { $0.count }.sorted { $0.key.rawValue < $1.key.rawValue }.map { (status: $0.key, count: $0.value) } }
    private var recentlyPurchased: [Game] { Array(games.sorted { $0.purchaseDate > $1.purchaseDate }.prefix(5)) }
    private var oldestBacklogGames: [Game] { Array(games.filter { $0.status != .completed }.sorted { $0.purchaseDate < $1.purchaseDate }.prefix(5)) }
    private var recentlyCompleted: [Game] { 
        Array(games.compactMap { game in
            guard game.status == .completed else { return nil }
            return game
        }.sorted { $0.completionDate > $1.completionDate }.prefix(5))
    }

    // Hardware stats
    private var hardwarePurchasePrice: Double { hardwareItems.reduce(0) { $0 + $1.purchasePrice } }
    private var hardwareMSRP: Double { hardwareItems.reduce(0) { $0 + $1.msrp } }
    private var hardwareDifference: Double { hardwareMSRP - hardwarePurchasePrice }
    private var combinedPurchasePrice: Double { totalPurchasePrice + hardwarePurchasePrice }
    private var combinedMSRP: Double { totalMSRP + hardwareMSRP }
    private var combinedDifference: Double { combinedMSRP - combinedPurchasePrice }

    private let currencyFormatter: NumberFormatter = { let formatter = NumberFormatter(); formatter.numberStyle = .currency; formatter.maximumFractionDigits = 2; return formatter }()

    private var valueCategories: [ValueCategory] {
        [
            ValueCategory(id: "Games", label: "Games", value: totalPurchasePrice, color: .blue),
            ValueCategory(id: "Hardware", label: "Hardware", value: hardwarePurchasePrice, color: .orange),
            ValueCategory(id: "Savings", label: "Savings", value: max(0, combinedDifference), color: .green)
        ]
    }

    private var platformValues: [PlatformValue] {
        guard !games.isEmpty else { return [] }
        let dict = Dictionary(grouping: games, by: { $0.platform?.name ?? "No Platform" })
        return dict.map { PlatformValue(platformName: $0.key, value: $0.value.reduce(0) { $0 + $1.purchasePrice }) }
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { $0 }
    }

    private var platformValueCategories: [ValueCategory] {
        guard !games.isEmpty else { return [] }
        let palette: [Color] = [.blue, .orange, .green, .purple, .pink, .teal, .red, .yellow]
        let dict = Dictionary(grouping: games, by: { $0.platform?.name ?? "No Platform" })
        return dict.sorted { $0.value.reduce(0) { $0 + $1.purchasePrice } > $1.value.reduce(0) { $0 + $1.purchasePrice } }
            .filter { $0.value.reduce(0) { $0 + $1.purchasePrice } > 0 } // Hide platforms with $0.00 value
            .prefix(6)
            .enumerated()
            .map { (idx, entry) in
                let (platform, games) = entry
                return ValueCategory(
                    id: platform,
                    label: platform,
                    value: games.reduce(0) { $0 + $1.purchasePrice },
                    color: palette[idx % palette.count]
                )
            }
    }

    // Add this helper struct for the play time chart
    struct GamePlayTime: Identifiable {
        let id = UUID()
        let index: Int
        let hours: Double
        let game: Game
    }

    private var topPlayTimeGames: [GamePlayTime] {
        Array(
            games.filter { $0.totalTimePlayed > 0 }
                .sorted { $0.totalTimePlayed > $1.totalTimePlayed }
                .prefix(5)
                .enumerated()
                .map { (idx, game) in
                    GamePlayTime(index: idx, hours: game.totalTimePlayed, game: game)
                }
        )
    }

    private var topRatedGames: [Game] {
        games.filter { $0.starRating == 5 }
            .sorted { ($0.completionDate ?? .distantPast) > ($1.completionDate ?? .distantPast) }
            .prefix(5)
            .map { $0 }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Summary Cards
                    HStack(spacing: 12) {
                        StatCard(title: "Collection Value", value: currencyFormatter.string(from: NSNumber(value: combinedPurchasePrice)) ?? "$0.00", color: .blue)
                        StatCard(title: "Savings", value: currencyFormatter.string(from: NSNumber(value: combinedDifference)) ?? "$0.00", color: combinedDifference >= 0 ? .green : .red)
                        StatCard(title: "Games", value: "\(games.count)", color: .primary)
                        StatCard(title: "Hardware", value: "\(hardwareItems.count)", color: .primary)
                    }
                    .padding(.horizontal)

                    // Donut Chart for Value Breakdown
                    Text("Collection Value by Platform")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if platformValueCategories.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "chart.donut")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            Text("No data to display")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("Add purchase amounts to your games to see the value breakdown by platform")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(height: 200)
                        .padding(.horizontal)
                    } else {
                        Chart(platformValueCategories) { category in
                            SectorMark(
                                angle: .value("Value", category.value),
                                innerRadius: .ratio(0.5)
                            )
                            .foregroundStyle(category.color)
                            .annotation(position: .overlay) {
                                VStack(spacing: 2) {
                                    Text(category.label)
                                        .font(.caption2)
                                        .foregroundColor(Color.primary)
                                    Text(currencyFormatter.string(from: NSNumber(value: category.value)) ?? "")
                                        .font(.caption2)
                                        .foregroundColor(Color.secondary)
                                }
                                .padding(6)
                                .background(Color(.systemBackground))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(.separator), lineWidth: 1)
                                )
                                .cornerRadius(8)
                                .shadow(radius: 1, y: 1)
                            }
                        }
                        .frame(height: 200)
                        .padding(.horizontal)
                    }

                    // Bar Chart for Game Status
                    Text("Games by Status")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if gamesByStatus.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "chart.bar.xaxis")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            Text("No data to display")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("Add games to your collection to see status breakdown")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(height: 200)
                        .padding(.horizontal)
                    } else {
                        Chart(gamesByStatus, id: \.status) { item in
                            BarMark(
                                x: .value("Status", item.status.rawValue),
                                y: .value("Count", item.count)
                            )
                            .foregroundStyle(by: .value("Status", item.status.rawValue))
                        }
                        .frame(height: 200)
                        .padding(.horizontal)
                    }

                    // Bar Chart for Top Platforms
                    Text("Top Platforms by Value")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if platformValues.filter({ $0.value > 0 }).isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "chart.bar.xaxis")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            Text("No data to display")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("Add purchase amounts to your games to see platform value breakdown")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(height: 200)
                        .padding(.horizontal)
                    } else {
                        Chart(platformValues) { item in
                            BarMark(
                                x: .value("Platform", item.platformName),
                                y: .value("Value", item.value)
                            )
                            .foregroundStyle(.blue)
                            .annotation(position: .top) {
                                Text(currencyFormatter.string(from: NSNumber(value: item.value)) ?? "")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(height: 200)
                        .padding(.horizontal)
                    }

                    // Other stats (optional)
                    HStack(spacing: 8) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.title2)
                            .foregroundColor(.accentColor)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Total Time Played")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("\(totalTimePlayed, specifier: "%.1f") hours")
                                .font(.title3.bold())
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.horizontal)

                    Text("Top 5 Games by Play Time")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if topPlayTimeGames.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "chart.bar.xaxis")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            Text("No data to display")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("Add play log entries to your games to see play time statistics")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(height: 200)
                        .padding(.horizontal)
                    } else {
                        Chart(topPlayTimeGames) { item in
                            BarMark(
                                x: .value("Index", item.index),
                                y: .value("Hours", item.hours)
                            )
                            .foregroundStyle(.purple)
                            .annotation(position: .overlay, alignment: .center) {
                                if let data = item.game.customCoverArt, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 40, height: 60)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                        .shadow(radius: 2)
                                } else if let url = item.game.coverArtURL {
                                    AsyncImage(url: url) { image in
                                        image.resizable()
                                    } placeholder: {
                                        Image(systemName: "photo")
                                    }
                                    .scaledToFit()
                                    .frame(width: 40, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .shadow(radius: 2)
                                } else {
                                    Image(systemName: "photo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 40, height: 60)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                        .shadow(radius: 2)
                                }
                            }
                            .annotation(position: .top) {
                                Text("\(item.hours, specifier: "%.1f")h")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(height: 200)
                        .padding(.horizontal)
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .font(.title2)
                            .foregroundColor(.yellow)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("5-Star Rated Games")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("\(fiveStarGamesCount)")
                                .font(.title3.bold())
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        if topRatedGames.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "star.slash")
                                    .font(.system(size: 48))
                                    .foregroundColor(.gray)
                                Text("No 5-star games yet")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                Text("Rate your completed games 5 stars to see them here")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 120)
                            .padding(.horizontal)
                        } else {
                            HStack(spacing: 16) {
                                ForEach(topRatedGames) { game in
                                    VStack(spacing: 4) {
                                        if let data = game.customCoverArt, let uiImage = UIImage(data: data) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 60, height: 90)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                .shadow(radius: 2)
                                        } else if let url = game.coverArtURL {
                                            AsyncImage(url: url) { image in
                                                image.resizable()
                                            } placeholder: {
                                                Image(systemName: "photo")
                                            }
                                            .scaledToFit()
                                            .frame(width: 60, height: 90)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .shadow(radius: 2)
                                        } else {
                                            Image(systemName: "photo")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 60, height: 90)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                .shadow(radius: 2)
                                        }
                                        if game.status == .completed {
                                            Text(game.completionDate.formatted(date: .abbreviated, time: .omitted))
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        } else {
                                            Text(game.status.rawValue)
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Statistics")
        }
    }
}
