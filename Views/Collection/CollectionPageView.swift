import SwiftUI
import SwiftData

struct CollectionPageView: View {
    @Environment(\.modelContext) private var modelContext
    
    var platformFilter: Platform?
    var hardwareFilter: Hardware?
    
    @Query(sort: \Game.title) private var allGames: [Game]
    
    @State private var layout: LayoutStyle = .grid
    @State private var searchText = ""
    @State private var searchResults: [PlatformGames] = []
    @State private var selectedGameID: PersistentIdentifier? = nil
    
    enum LayoutStyle {
        case list
        case grid
    }

    init(platformFilter: Platform? = nil, hardwareFilter: Hardware? = nil) {
        self.platformFilter = platformFilter
        self.hardwareFilter = hardwareFilter
        
        // Use simple predicate and filter in-memory
    }

    var body: some View {
        Group {
            if layout == .list {
                listView
            } else {
                gridView
            }
        }
        .navigationTitle(hardwareFilter?.name ?? platformFilter?.name ?? "All Games")
        .searchable(text: $searchText, prompt: "Search for a game")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                layoutToggleButton
            }
        }
        .onChange(of: allGames, initial: true) { _, _ in updateSearchResults() }
        .onChange(of: searchText, initial: true) { _, _ in updateSearchResults() }
        .navigationDestination(item: $selectedGameID) { gameID in
            GameDetailView(gameID: gameID)
        }
    }
    
    private func deleteGame(at offsets: IndexSet, in platformGames: PlatformGames) {
        for index in offsets {
            let gameToDelete = platformGames.games[index]
            modelContext.delete(gameToDelete)
        }
    }
    
    private func updateSearchResults() {
        // Early return if no games are loaded yet
        guard !allGames.isEmpty else { 
            searchResults = []
            return 
        }
        
        // First filter by ownership status and sub-game status (previously in predicate)
        let filteredByStatus = allGames.filter { game in
            game.ownershipStatusValue == "In Collection" && !game.isSubGame
        }
        
        // Then filter by platform if specified
        let filteredByPlatform = platformFilter != nil ?
            filteredByStatus.filter { $0.platform?.id == platformFilter?.id } :
            filteredByStatus
        
        // Then filter by hardware if specified
        let filteredByHardware = hardwareFilter != nil ?
            filteredByPlatform.filter { $0.linkedHardware?.persistentModelID == hardwareFilter?.persistentModelID } :
            filteredByPlatform
        
        // Then filter by search text
        let filteredBySearch: [Game]
        if searchText.isEmpty {
            filteredBySearch = filteredByHardware
        } else {
            filteredBySearch = filteredByHardware.filter { $0.title.lowercased().contains(searchText.lowercased()) }
        }
        
        let groupedByPlatform = Dictionary(grouping: filteredBySearch, by: { $0.platform })
        
        self.searchResults = groupedByPlatform.compactMap { platform, games in
            guard let platform = platform else { return nil }
            return PlatformGames(id: platform.id, platform: platform, games: games.sorted(by: { $0.title < $1.title }))
        }.sorted { $0.platform.name < $1.platform.name }
    }
    
    struct PlatformGames: Identifiable {
        let id: Int
        let platform: Platform
        let games: [Game]
    }

    private var layoutToggleButton: some View {
        Button(action: { withAnimation { layout = .list == layout ? .grid : .list } }) {
            Image(systemName: layout == .list ? "square.grid.2x2" : "list.bullet")
        }
    }
    
    private var listView: some View {
        List {
            if platformFilter == nil && hardwareFilter == nil {
                // Linked Games section for subgames
                let linkedGames = allGames.filter { $0.isSubGame }
                if !linkedGames.isEmpty {
                    Section(header: Text("Linked Games").font(.headline)) {
                        ForEach(linkedGames) { game in
                            GameRow(game: game)
                        }
                    }
                }
                // Platform sections for regular games
                ForEach(searchResults) { platformGames in
                    Section(header: Text(platformGames.platform.name).font(.headline)) {
                        ForEach(platformGames.games) { game in
                            GameRow(game: game)
                        }
                        .onDelete { offsets in
                            deleteGame(at: offsets, in: platformGames)
                        }
                    }
                }
            } else {
                ForEach(searchResults.flatMap { $0.games }) { game in
                    GameRow(game: game)
                }
                .onDelete { offsets in
                    if let platformGames = searchResults.first {
                        deleteGame(at: offsets, in: platformGames)
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        // The .navigationDestination modifier is removed
    }

    private var gridView: some View {
        let columns = [GridItem(.adaptive(minimum: 120), spacing: 20)]
        return ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if platformFilter == nil && hardwareFilter == nil {
                    // Linked Games section for subgames
                    let linkedGames = allGames.filter { $0.isSubGame }
                    if !linkedGames.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Linked Games")
                                .font(.headline)
                                .padding(.leading)
                            LazyVGrid(columns: columns, spacing: 20) {
                                ForEach(linkedGames) { game in
                                    GameGridItemView(game: game, subtitle: "Linked Game")
                                        .onTapGesture {
                                            selectedGameID = game.persistentModelID
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    // Platform sections for regular games
                    ForEach(searchResults) { platformGames in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(platformGames.platform.name)
                                .font(.headline)
                                .padding(.leading)
                            LazyVGrid(columns: columns, spacing: 20) {
                                ForEach(platformGames.games) { game in
                                    GameGridItemView(game: game, subtitle: platformGames.platform.name)
                                        .onTapGesture {
                                            selectedGameID = game.persistentModelID
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                } else {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(searchResults.flatMap { $0.games }) { game in
                            let subtitle = (platformFilter == nil) ? (game.platform?.name ?? "No Platform") : game.status.rawValue
                            GameGridItemView(game: game, subtitle: subtitle)
                                .onTapGesture {
                                    selectedGameID = game.persistentModelID
                                }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

// MARK: - GAMEROW
struct GameRow: View {
    let game: Game
    
    var body: some View {
        NavigationLink(destination: GameDetailView(gameID: game.persistentModelID)) {
            HStack {
                ZStack(alignment: .topLeading) {
                    Group {
                        if let imageData = game.customCoverArt, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage).resizable().scaledToFit()
                        } else {
                            AsyncImage(url: game.coverArtURL) { $0.resizable().scaledToFit() }
                                placeholder: { Image(systemName: "photo") }
                        }
                    }
                    .frame(width: 45, height: 60)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(4)
                    
                    // Display the icon if one exists
                    if let icon = game.overlayIcon {
                        Image(systemName: icon.name)
                            .font(.caption2.bold())
                            .foregroundStyle(icon.color)
                            .padding(4)
                            .background(.black.opacity(0.6))
                            .clipShape(Circle())
                            .padding(2)
                    }
                }
                
                VStack(alignment: .leading) {
                    Text(game.title)
                    Text(game.status.rawValue).font(.caption).foregroundColor(.secondary)
                }
                
                if game.status == .completed {
                    Spacer()
                    Image(systemName: "trophy.fill").foregroundStyle(.yellow)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - GRAVEYARD GAMEROW
struct GraveyardGameRow: View {
    let game: Game
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack(alignment: .topLeading) {
                Group {
                    if let imageData = game.customCoverArt, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage).resizable().scaledToFit()
                    } else {
                        AsyncImage(url: game.coverArtURL) { $0.resizable().scaledToFit() }
                            placeholder: { Image(systemName: "photo") }
                    }
                }
                .frame(width: 45, height: 60)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(4)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(game.title)
                Text("\(game.platform?.name ?? "No Platform") • \(game.ownershipStatus.rawValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
