//
//  CollectionHomePageView.swift
//  GameLogger
//
//  Created by Justin Gain on 7/10/25.
//
import SwiftUI
import SwiftData

struct CollectionHomePageView: View {
    // --- QUERIES ---
    @Query(sort: \Game.title) private var allGames: [Game]
    @Query(sort: \Platform.name) private var platforms: [Platform]
    
    // --- COMPUTED PROPERTIES FOR FILTERING ---
    private var collectionGames: [Game] {
        guard !allGames.isEmpty else { return [] }
        return allGames.filter { !$0.isWishlisted && !$0.isSubGame && $0.ownershipStatusValue == "In Collection" }
    }
    
    private var graveyardGames: [Game] {
        guard !allGames.isEmpty else { return [] }
        return allGames.filter { $0.ownershipStatusValue != "In Collection" }
    }
    
    private var wishlistedGames: [Game] {
        guard !allGames.isEmpty else { return [] }
        return allGames.filter { $0.isWishlisted }
    }
    
    private var inProgressGames: [Game] {
        guard !allGames.isEmpty else { return [] }
        return allGames.filter { $0.statusValue == "In Progress" && !$0.isWishlisted && !$0.isSubGame }
    }
    
    private var fiveStarGames: [Game] {
        guard !allGames.isEmpty else { return [] }
        return allGames.filter { $0.starRating == 5 && !$0.isWishlisted && !$0.isSubGame }
    }
    
    // --- STATE ---
    @State private var isAddingGame = false
    @State private var showingSettings = false
    
    // --- GRID LAYOUT ---
    private let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
    
    private var platformsInCollection: [Platform] {
        // Create a set of platform IDs from your game collection for efficient lookup.
        let platformIDsInCollection = Set(collectionGames.compactMap { $0.platform?.id })
        // Filter the main platform list.
        return platforms.filter { platformIDsInCollection.contains($0.id) }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading) {
                    // This LazyVGrid creates the new dashboard
                    LazyVGrid(columns: columns, spacing: 16) {
                        NavigationLink(destination: CollectionPageView()) {
                            SummaryBoxView(title: "All Games", count: collectionGames.count, iconName: "gamecontroller.fill", iconColor: Color.blue, backgroundColor: Color.blue.opacity(0.4))
                        }
                        
                        NavigationLink(destination: WishlistView()) {
                            SummaryBoxView(title: "Wishlist", count: wishlistedGames.count, iconName: "wand.and.stars", iconColor: Color.purple, backgroundColor: Color.purple.opacity(0.4))
                        }
                        
                        NavigationLink(destination: BacklogView(preselectedStatus: .inProgress)) {
                            SummaryBoxView(title: "In Progress", count: inProgressGames.count, iconName: "hourglass", iconColor: Color.orange, backgroundColor: Color.orange.opacity(0.4))
                        }
                        
                        NavigationLink(destination: GraveyardView()) {
                            SummaryBoxView(title: "Graveyard", count: graveyardGames.count, iconName: "x.circle.fill", iconColor: Color.gray, backgroundColor: Color.gray.opacity(0.4))
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Text("Platforms")
                        .font(.title2.bold())
                        .padding(.top)
                    
                    VStack {
                        // The ForEach now iterates over the pre-filtered list
                        ForEach(platformsInCollection) { platform in
                            // The divider is now inside the loop
                            if platform != platformsInCollection.first {
                                Divider()
                            }
                            
                            NavigationLink(destination: CollectionPageView(platformFilter: platform)) {
                                HStack {
                                    if platform.name.localizedCaseInsensitiveContains("playstation") || platform.name.localizedCaseInsensitiveContains("ps") {
                                        Image(systemName: "playstation.logo")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 30, height: 30)
                                            .foregroundStyle(.secondary)
                                    } else if platform.name.localizedCaseInsensitiveContains("xbox") {
                                        Image(systemName: "xbox.logo")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 30, height: 30)
                                            .foregroundStyle(.secondary)
                                    } else if platform.name.localizedCaseInsensitiveContains("nintendo") {
                                        Image("NintendoLogo")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 30, height: 30)
                                    } else {
                                        AsyncImage(url: platform.logoURL) { $0.resizable().scaledToFit() } placeholder: { Image(systemName: "gamecontroller") }
                                            .frame(width: 30, height: 30)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Text(platform.name)
                                    Spacer()
                                    let gameCount = collectionGames.filter { $0.platform == platform }.count
                                    Text("\(gameCount)")
                                        .foregroundStyle(.secondary)
                                }
                                // These modifiers expand the tappable area to the whole row
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
            }
            .navigationTitle("Collection")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isAddingGame = true }) {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingSettings = true}) {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .sheet(isPresented: $isAddingGame) {
                AddGameView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
}
