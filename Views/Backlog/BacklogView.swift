//
//  BacklogView.swift
//  GameLogger
//
//  Created by Justin Gain on 7/10/25.
//
import SwiftUI
import SwiftData

struct BacklogView: View {
    @Environment(\.modelContext) private var modelContext
    
    // 1. Fetch all games, filter in-memory for backlog logic.
    @Query(sort: \Game.title) private var allGames: [Game]
    
    // 2. State to hold the user's selected filter status.
    @State private var selectedStatus: GameStatus
    
    // 3. The list of statuses for the picker, excluding "Completed".
    private let filterableStatuses: [GameStatus] = GameStatus.allCases.filter { $0 != .completed }
    
    // 4. A computed property that filters the games based on the selected status and backlog logic.
    private var filteredGames: [Game] {
        guard !allGames.isEmpty else { return [] }
        return allGames.filter {
            !$0.isWishlisted &&
            !$0.isSubGame &&
            $0.statusValue != "Completed" &&
            $0.status == selectedStatus
        }
    }
    
    // 5. Define the grid layout.
    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]

    // This initializer lets us pre-select a status.
    // It defaults to .inProgress if no status is provided.
    init(preselectedStatus: GameStatus = .inProgress) {
        _selectedStatus = State(initialValue: preselectedStatus)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Colored summary header with icon
                    HStack {
                        ZStack {
                            Circle()
                                .fill(summaryColor(for: selectedStatus).gradient)
                                .frame(width: 32, height: 32)
                            Image(systemName: summaryIcon(for: selectedStatus))
                                .foregroundColor(.white)
                                .font(.headline)
                        }
                        Text(summaryTitle(for: selectedStatus))
                            .font(.headline)
                            .fontWeight(.bold)
                        Spacer()
                        Text("\(filteredGames.count)")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                    }
                    .padding(12)
                    .background(summaryColor(for: selectedStatus).opacity(1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.top)
                    .padding(.horizontal)

                    // Filter picker
                    Picker("Filter by Status", selection: $selectedStatus) {
                        ForEach(filterableStatuses, id: \.self) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)

                    // Card-like grid background
                    VStack {
                        if filteredGames.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "hourglass")
                                    .font(.system(size: 40))
                                    .foregroundColor(.orange)
                                Text("No games in this backlog status.")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, minHeight: 180)
                        } else {
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(filteredGames) { game in
                                    NavigationLink(destination: GameDetailView(game: game)) {
                                        GameGridItemView(
                                            game: game,
                                            subtitle: backlogSubtitle(for: game)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical)
                        }
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Backlog")
        }
    }

    // Helper for subtitle
    private func backlogSubtitle(for game: Game) -> String {
        let time = game.totalTimePlayed > 0 ? String(format: "%.1f hrs", game.totalTimePlayed) : nil
        let start = game.startDate?.formatted(date: .abbreviated, time: .omitted)
        if let time, let start {
            return "\(time) • Started \(start)"
        } else if let time {
            return time
        } else if let start {
            return "Started \(start)"
        } else {
            return "No play data"
        }
    }

    // Helper for dynamic summary title
    private func summaryTitle(for status: GameStatus) -> String {
        switch status {
        case .backlog: return "Games in Backlog"
        case .inProgress: return "Games in Progress"
        case .onHold: return "Games On Hold"
        case .completed: return "Games Completed"
        case .dropped: return "Games Dropped"
        }
    }

    // Helper for summary color
    private func summaryColor(for status: GameStatus) -> Color {
        switch status {
        case .backlog: return Color.orange
        case .inProgress: return Color.mint
        case .onHold: return Color.yellow
        case .completed: return Color.green
        case .dropped: return Color.red
        }
    }

    // Helper for summary icon
    private func summaryIcon(for status: GameStatus) -> String {
        switch status {
        case .backlog: return "hourglass"
        case .inProgress: return "bolt.fill"
        case .onHold: return "pause.fill"
        case .completed: return "checkmark"
        case .dropped: return "xmark"
        }
    }
}

// Removed BacklogGridItem struct
