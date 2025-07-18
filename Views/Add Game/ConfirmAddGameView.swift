//
//  ConfirmAddGameView.swift
//  GameLogger
//
//  Created by Justin Gain on 7/10/25.
//
import SwiftUI
import SwiftData

struct ConfirmAddGameView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    let igdbGame: IGDBGame
    let availablePlatforms: [Platform]
    var parentGame: Game?
    
    @State private var selectedPlatform: Platform
    @State private var addToWishlist = false
    
    init(igdbGame: IGDBGame, parentGame: Game? = nil) {
        self.igdbGame = igdbGame
        self.parentGame = parentGame
        
        let platforms = igdbGame.platforms?.compactMap { p in
            Platform(id: p.id, name: p.name, logoURL: p.platform_logo?.highResURL)
        } ?? []
        self.availablePlatforms = platforms
        
        _selectedPlatform = State(initialValue: platforms.first ?? Platform(id: 0, name: "Unknown"))
    }
    
    var body: some View {
        // --- The body of the view is unchanged ---
        NavigationStack {
            Form {
                VStack {
                    AsyncImage(url: igdbGame.cover?.highResURL) { $0.resizable() } placeholder: { Image(systemName: "photo.fill").font(.largeTitle) }
                    .aspectRatio(3/4, contentMode: .fit)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                    Text(igdbGame.name)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
                
                Section("Add to") {
                    Toggle("Add to Wishlist", isOn: $addToWishlist)
                        .disabled(parentGame != nil)
                }
                
                Section("Platform") {
                    Picker("Select Platform", selection: $selectedPlatform) {
                        ForEach(availablePlatforms) { platform in
                            Text(platform.name).tag(platform)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
            }
            .navigationTitle("Add to Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Add") { addGame() } }
            }
        }
    }
    
    // --- This function contains the corrected platform logic ---
    private func addGame() {
        let platformID = selectedPlatform.id
        
        let fetchDescriptor = FetchDescriptor<Platform>(predicate: #Predicate { $0.id == platformID })
        let existingPlatform = (try? modelContext.fetch(fetchDescriptor))?.first
        
        let platformToAssign: Platform
        if let foundPlatform = existingPlatform {
            // If we found the platform in our database, use that managed instance.
            if foundPlatform.logoURL == nil {
                foundPlatform.logoURL = selectedPlatform.logoURL
            }
            platformToAssign = foundPlatform
        } else {
            // If we didn't find it, create a brand new Platform object
            // using the data from our temporary selection.
            let newPlatform = Platform(
                id: selectedPlatform.id,
                name: selectedPlatform.name,
                logoURL: selectedPlatform.logoURL
            )
            // Insert it into the database FIRST.
            modelContext.insert(newPlatform)
            // Then use this newly saved instance.
            platformToAssign = newPlatform
        }
        
        let releaseDate = igdbGame.first_release_date != nil ? Date(timeIntervalSince1970: TimeInterval(igdbGame.first_release_date!)) : nil
        let genres = igdbGame.genres?.map { $0.name } ?? []
        let developers = igdbGame.involved_companies?.filter { $0.developer }.map { $0.company.name } ?? []
        let publishers = igdbGame.involved_companies?.filter { $0.publisher }.map { $0.company.name } ?? []

        let newGame = Game(
            title: igdbGame.name,
            coverArtURL: igdbGame.cover?.highResURL,
            platform: platformToAssign, // Assign the definitive, saved platform instance.
            purchaseDate: Date(),
            isDigital: false,
            purchasePrice: 0.0,
            msrp: 0.0,
            status: .backlog,
            isWishlisted: self.addToWishlist,
            releaseDate: releaseDate,
            genres: genres,
            developers: developers,
            publishers: publishers,
            isSubGame: self.parentGame != nil,
            parentCollection: self.parentGame
        )
        modelContext.insert(newGame)
        // --- Add to parent collection's includedGames if this is a subgame ---
        if let parent = self.parentGame {
            if parent.includedGames == nil {
                parent.includedGames = []
            }
            parent.includedGames?.append(newGame)
        }
        // --- End block ---
        dismiss()
    }
}
