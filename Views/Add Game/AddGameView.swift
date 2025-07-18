//
//  AddGameView.swift
//  GameLogger
//
//  Created by Justin Gain on 7/10/25.
//
import SwiftUI
import SwiftData

struct AddGameView: View {
    @Environment(\.dismiss) var dismiss
    
    private let igdbClient = IGDBClient()
    
    // Accepts an optional parent game for context
    var parentGame: Game?
    
    @State private var searchText = ""
    @State private var searchResults: [IGDBGame] = []
    @State private var isLoading = false

    @State private var gameToConfirm: IGDBGame?
    @State private var hasSearched = false

    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !hasSearched {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("Search for games")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Type a game name and press Enter to search IGDB")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if searchResults.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("No games found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Try a different search term or add the game manually")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(searchResults) { game in
                        Button(action: { gameToConfirm = game }) {
                            HStack {
                                AsyncImage(url: game.cover?.highResURL) { $0.resizable() } placeholder: { Image(systemName: "photo.on.rectangle") }
                                .aspectRatio(3/4, contentMode: .fit).frame(width: 50).cornerRadius(4)
                                VStack(alignment: .leading) {
                                    Text(game.name).font(.headline).foregroundColor(.primary)
                                    Text(game.platforms?.first?.name ?? "No platform info").font(.subheadline).foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                        }
                    }
                }
                
                // Hide manual add button when adding a sub-game
                if parentGame == nil {
                    NavigationLink(destination: ManualAddGameView()) {
                        Label("Can't find it? Add Manually", systemImage: "pencil.and.scribble")
                    }
                    .padding()
                }
            }
            .navigationTitle(parentGame == nil ? "Add New Game" : "Add Included Game")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search IGDB")
            .onSubmit(of: .search) {
                performSearch()
            }
            .sheet(item: $gameToConfirm) { igdbGame in
                // Pass the parent game along to the confirmation view
                ConfirmAddGameView(igdbGame: igdbGame, parentGame: self.parentGame)
            }
        }
    }
    
    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else { 
            searchResults = []
            hasSearched = false
            return 
        }
        
        isLoading = true
        hasSearched = true
        
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            igdbClient.searchGames(query: searchText) { results in
                DispatchQueue.main.async {
                    self.searchResults = results
                    self.isLoading = false
                }
            }
        }
    }
}
