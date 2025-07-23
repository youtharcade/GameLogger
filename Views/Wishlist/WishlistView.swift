//
//  WishlistView.swift
//  GameLogger
//
//  Created by Justin Gain on 7/11/25.
//
import SwiftUI
import SwiftData

struct WishlistView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Game.title) private var allGames: [Game]
    
    private var wishlistGames: [Game] {
        allGames.filter { $0.isWishlisted }
    }
    
    var body: some View {
            List {
                ForEach(wishlistGames) { game in
                    HStack {
                        AsyncImage(url: game.coverArtURL) { $0.resizable() } placeholder: { Image(systemName: "photo") }
                            .aspectRatio(contentMode: .fit).frame(width: 45, height: 60).cornerRadius(4)
                        VStack(alignment: .leading) {
                            // Release Date
                            // Non-optional release date
                            Text(game.releaseDate, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            // Game Title
                            Text(game.title)
                                .font(.headline)
                            
                            // Platform
                            Text(game.platform?.name ?? "No Platform")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button { moveToCollection(game) } label: { Image(systemName: "plus.circle.fill").foregroundStyle(.green).font(.title2) }
                            .buttonStyle(.plain)
                    }
                }
                .onDelete(perform: deleteGame)
            }
            .navigationTitle("Wishlist")
    }
    
    private func moveToCollection(_ game: Game) {
        game.isWishlisted = false
    }
    
    private func deleteGame(at offsets: IndexSet) {
        for index in offsets {
            let game = wishlistGames[index]
            modelContext.delete(game)
        }
    }
}
