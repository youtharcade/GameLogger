//
//  GraveyardView.swift
//  GameLogger
//
//  Created by Justin Gain on 7/14/25.
//
import SwiftUI
import SwiftData

struct GraveyardView: View {
    // This query fetches all games that are NOT marked as "owned" and are NOT wishlisted
    @Query(filter: #Predicate<Game> {
        $0.ownershipStatusValue != "In Collection" && !$0.isWishlisted
    }, sort: \.title) private var graveyardGames: [Game]
    
    var body: some View {
        List {
            ForEach(graveyardGames) { game in
                GraveyardGameRow(game: game)
            }
        }
        .navigationTitle("Graveyard")
    }
}
