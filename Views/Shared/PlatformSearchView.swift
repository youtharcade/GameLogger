//
//  PlatformSearchView.swift
//  GameLogger
//
//  Created by Justin Gain on 7/14/25.
//
import SwiftUI
import SwiftData

struct PlatformSearchView: View {
    @Environment(\.dismiss) var dismiss
    
    // The full list of platforms to search from
    let allPlatforms: [Platform]
    // A binding to update the selection in the parent view
    @Binding var selectedPlatform: Platform?
    
    @State private var searchText = ""
    
    private var searchResults: [Platform] {
        if searchText.isEmpty {
            return allPlatforms
        }
        return allPlatforms.filter { $0.name.lowercased().contains(searchText.lowercased()) }
    }
    
    var body: some View {
        NavigationStack {
            List(searchResults) { platform in
                Button(platform.name) {
                    selectedPlatform = platform
                    dismiss()
                }
                .foregroundStyle(.primary)
            }
            .navigationTitle("Select Platform")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search Platforms")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
