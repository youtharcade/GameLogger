//
//  ManualAddGameView.swift
//  GameLogger
//
//  Created by Justin Gain on 7/10/25.
//
import SwiftUI
import SwiftData

struct ManualAddGameView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @State private var newGame: Game

    init() {
        let platform = Platform(id: 0, name: "Unknown")
        let game = Game(title: "New Game", platform: platform, purchaseDate: Date(), isDigital: false, purchasePrice: 0.0, msrp: 0.0, status: .backlog)
        _newGame = State(initialValue: game)
    }

    var body: some View {
        GameDetailView(game: newGame)
            .navigationTitle("Add Manually")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { 
                    Button("Save") { 
                        modelContext.insert(newGame)
                        do {
                            try modelContext.save()
                        } catch {
                            print("Error saving new game: \(error)")
                        }
                        dismiss() 
                    } 
                }
            }
    }
}
