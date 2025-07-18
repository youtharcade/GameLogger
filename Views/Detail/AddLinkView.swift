//
//  AddLinkView.swift
//  GameLogger
//
//  Created by Justin Gain on 7/12/25.
//
import SwiftUI

struct AddLinkView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    @State private var urlString: String = ""
    
    // This closure passes the new data back to the detail view
    var onSave: (String, String) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Link Name (e.g., IGN Walkthrough)", text: $name)
                TextField("URL (e.g., https://ign.com/...)", text: $urlString)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
            }
            .navigationTitle("Add Website Link")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // Ensure the URL is not empty
                        guard !urlString.isEmpty else { return }
                        onSave(name, urlString)
                        dismiss()
                    }
                }
            }
        }
    }
}
