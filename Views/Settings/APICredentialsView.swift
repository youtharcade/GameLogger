//
//  APICredentialsView.swift
//  GameLoggr
//
//  Created by Justin Gain on 7/18/25.
//

import SwiftUI

struct APICredentialsView: View {
    @State private var clientId: String = ""
    @State private var clientSecret: String = ""
    @State private var isSecretVisible: Bool = false
    @State private var showingAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Text("GameLoggr uses the IGDB (Internet Game Database) API to search for games and retrieve game information.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } header: {
                    Text("About IGDB API")
                }
                
                Section {
                    Link("1. Visit IGDB API Website", destination: URL(string: "https://api.igdb.com/")!)
                    Link("2. Create a Twitch Account", destination: URL(string: "https://dev.twitch.tv/login")!)
                    Text("3. Register a new application")
                    Text("4. Copy your Client ID and Client Secret")
                    Text("5. Enter them below")
                } header: {
                    Text("How to Get API Credentials")
                } footer: {
                    Text("IGDB requires a free Twitch developer account. Your credentials are stored securely in your device's Keychain.")
                }
                
                Section {
                    TextField("Client ID", text: $clientId)
                        .textContentType(.none)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    
                    HStack {
                        if isSecretVisible {
                            TextField("Client Secret", text: $clientSecret)
                                .textContentType(.none)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        } else {
                            SecureField("Client Secret", text: $clientSecret)
                                .textContentType(.none)
                        }
                        
                        Button(action: { isSecretVisible.toggle() }) {
                            Image(systemName: isSecretVisible ? "eye.slash" : "eye")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("API Credentials")
                } footer: {
                    Text("These credentials will be stored securely in your device's Keychain and never shared.")
                }
                
                Section {
                    if Config.hasIGDBCredentials {
                        Label("API credentials are configured", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        
                        Button("Remove Stored Credentials", role: .destructive) {
                            removeCredentials()
                        }
                    } else {
                        Label("No API credentials stored", systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                    }
                } header: {
                    Text("Current Status")
                }
                
                Section {
                    Button("Save Credentials") {
                        saveCredentials()
                    }
                    .disabled(clientId.isEmpty || clientSecret.isEmpty)
                } footer: {
                    Text("Without API credentials, you won't be able to search for games using IGDB. You can still add games manually.")
                }
            }
            .navigationTitle("IGDB API Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                loadExistingCredentials()
            }
        }
    }
    
    private func loadExistingCredentials() {
        clientId = Config.igdbClientId
        clientSecret = Config.igdbClientSecret
    }
    
    private func saveCredentials() {
        let success = Config.storeIGDBCredentials(
            clientId: clientId.trimmingCharacters(in: .whitespacesAndNewlines),
            clientSecret: clientSecret.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        if success {
            alertTitle = "Success"
            alertMessage = "API credentials have been saved securely to your device's Keychain."
        } else {
            alertTitle = "Error"
            alertMessage = "Failed to save API credentials. Please try again."
        }
        
        showingAlert = true
    }
    
    private func removeCredentials() {
        let success = Config.removeIGDBCredentials()
        
        if success {
            clientId = ""
            clientSecret = ""
            alertTitle = "Removed"
            alertMessage = "API credentials have been removed from your device."
        } else {
            alertTitle = "Error"
            alertMessage = "Failed to remove API credentials. Please try again."
        }
        
        showingAlert = true
    }
}

#Preview {
    APICredentialsView()
}
