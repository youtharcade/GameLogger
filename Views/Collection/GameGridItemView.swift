//
//  GameGridItemView.swift
//  GameLogger
//
//  Created by Justin Gain on 7/10/25.
//
import SwiftUI

struct GameGridItemView: View {
    let game: Game
    let subtitle: String

    var body: some View {
        VStack {
            ZStack(alignment: .topLeading) {
                Group {
                    if let imageData = game.customCoverArt, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage).resizable().scaledToFit()
                    } else {
                        AsyncImage(url: game.coverArtURL) { $0.resizable().scaledToFit() }
                            placeholder: {
                                ZStack {
                                    Rectangle().fill(.secondary.opacity(0.3))
                                    Image(systemName: "photo").foregroundColor(.gray)
                                }
                            }
                    }
                }
                .aspectRatio(3/4, contentMode: .fit)
                .cornerRadius(8)
                .shadow(radius: 4)
                .frame(minHeight: 150)
                
                // TEMPORARY: Simplified overlay logic (overlayIcon property was removed)
                if shouldShowOverlay(for: game) {
                    let overlay = getOverlayInfo(for: game)
                    Image(systemName: overlay.name)
                        .font(.footnote.bold())
                        .foregroundStyle(overlay.color)
                        .padding(6)
                        .background(.black.opacity(0.6))
                        .clipShape(Circle())
                        .padding(4)
                }
            }
            
            VStack(alignment: .center) {
                Text(game.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }
    
    // TEMPORARY: Helper functions to replace overlayIcon computed property
    private func shouldShowOverlay(for game: Game) -> Bool {
        return game.ownershipStatus != .owned || game.isSubGame
    }
    
    private func getOverlayInfo(for game: Game) -> (name: String, color: Color) {
        if game.ownershipStatus != .owned {
            return ("archivebox.fill", .gray) // For "Graveyard" games
        }
        if game.isSubGame {
            return ("link", .white) // For games included in a collection
        }
        return ("questionmark", .gray) // Fallback
    }
}
