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
                
                // Display the icon if one exists
                if let icon = game.overlayIcon {
                    Image(systemName: icon.name)
                        .font(.footnote.bold())
                        .foregroundStyle(icon.color)
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
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .multilineTextAlignment(.center)
            .frame(height: 50, alignment: .top)
        }
    }
}
