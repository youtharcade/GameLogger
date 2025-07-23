//
//  SettingsView.swift
//  GameLogger
//
//  Created by Justin Gain on 7/14/25.
//
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("defaultGameSort") private var defaultGameSort: String = "title"
    @AppStorage("showCompletedGames") private var showCompletedGames: Bool = true
    @AppStorage("enableNotifications") private var enableNotifications: Bool = false
    @AppStorage("autoBackup") private var autoBackup: Bool = false
    @AppStorage("showDeveloperOptions") private var showDeveloperOptions: Bool = false
    
    @State private var showingExportSheet = false
    @State private var showingAbout = false
    @State private var showOnboarding = false
    
    var body: some View {
        NavigationStack {
            Form {
                // App Information Section
                appInfoSection
                
                // Display Preferences
                displayPreferencesSection
                
                // Data Management
                dataManagementSection
                
                // Notifications
                notificationsSection
                
                // Privacy & Security
                privacySection
                
                // Help & Support
                helpSection
                
                // About & Attribution
                aboutSection
                
                // Developer Options (hidden by default)
                if showDeveloperOptions {
                    developerSection
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAbout) {
                aboutDetailView
            }
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingView(showOnboarding: $showOnboarding)
            }
        }
    }
    
    // MARK: - Sections
    
    private var appInfoSection: some View {
        Section(header: 
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text("App Information")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
        ) {
            HStack {
                Image(systemName: "gamecontroller.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text("GameLoggr")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("Your personal game collection manager")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("v1.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
            
            Button(action: { showingAbout = true }) {
                HStack {
                    Image(systemName: "book.circle")
                        .foregroundColor(.blue)
                    Text("About & Credits")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
        }
    }
    
    private var displayPreferencesSection: some View {
        Section(header: 
            HStack {
                Image(systemName: "eye.fill")
                    .foregroundColor(.purple)
                Text("Display Preferences")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
        ) {
            HStack {
                Image(systemName: "arrow.up.arrow.down")
                    .foregroundColor(.orange)
                Text("Default Game Sort")
                Spacer()
                Picker("Sort", selection: $defaultGameSort) {
                    Text("Title").tag("title")
                    Text("Date Added").tag("dateAdded")
                    Text("Rating").tag("rating")
                    Text("Platform").tag("platform")
                }
                .pickerStyle(.menu)
            }
            
            HStack {
                Image(systemName: "checkmark.circle")
                    .foregroundColor(.green)
                Toggle("Show Completed Games in Collection", isOn: $showCompletedGames)
            }
        }
    }
    
    private var dataManagementSection: some View {
        Section(header: 
            HStack {
                Image(systemName: "externaldrive.fill")
                    .foregroundColor(.indigo)
                Text("Data Management")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
        ) {
            HStack {
                Image(systemName: "icloud.and.arrow.up")
                    .foregroundColor(.blue)
                Toggle("Auto Backup to iCloud", isOn: $autoBackup)
            }
            
            Button(action: { showingExportSheet = true }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.green)
                    Text("Export Game Data")
                    Spacer()
                }
            }
            
            Button(action: { importGameData() }) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundColor(.blue)
                    Text("Import Game Data")
                    Spacer()
                }
            }
            
            Button(action: { generateJSON() }) {
                HStack {
                    Image(systemName: "terminal")
                        .foregroundColor(.secondary)
                    Text("Generate Platform JSON")
                    Spacer()
                }
            }
        }
    }
    
    private var notificationsSection: some View {
        Section(header: 
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(.red)
                Text("Notifications")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
        ) {
            HStack {
                Image(systemName: "bell.badge")
                    .foregroundColor(.red)
                Toggle("Game Release Reminders", isOn: $enableNotifications)
            }
            
            if enableNotifications {
                Text("Get notified about upcoming game releases in your wishlist")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var privacySection: some View {
        Section(header: 
            HStack {
                Image(systemName: "hand.raised.fill")
                    .foregroundColor(.orange)
                Text("Privacy & Security")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
        ) {
            Button(action: { clearAllData() }) {
                HStack {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                    Text("Clear All Data")
                    Spacer()
                }
            }
            .foregroundColor(.red)
            
            Text("This will permanently delete all your games, play logs, and settings.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var helpSection: some View {
        Section(header: 
            HStack {
                Image(systemName: "questionmark.circle.fill")
                    .foregroundColor(.blue)
                Text("Help & Support")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
        ) {
            Button(action: { showOnboarding = true }) {
                HStack {
                    Image(systemName: "play.circle")
                        .foregroundColor(.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("View App Tutorial")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Text("See how to use GameLoggr's features")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "arrow.right")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
            }
        }
    }
    
    private var aboutSection: some View {
        Section(header: 
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.pink)
                Text("Attribution")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
        ) {
            Button(action: { 
                if let url = URL(string: "https://www.igdb.com/") {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Image(systemName: "globe")
                        .foregroundColor(.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Powered by IGDB")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Text("Game data provided by the Internet Game Database")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
            }
            
            // Secret tap to enable developer options
            Button(action: { 
                showDeveloperOptions.toggle()
            }) {
                HStack {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(.secondary)
                    Text("GameLoggr Support")
                    Spacer()
                    if showDeveloperOptions {
                        Text("Dev Mode: ON")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            .foregroundColor(.primary)
        }
    }
    
    private var developerSection: some View {
        Section(header: 
            HStack {
                Image(systemName: "hammer.fill")
                    .foregroundColor(.gray)
                Text("Developer Options")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
        ) {
            Button("Reset All Settings") {
                resetAllSettings()
            }
            .foregroundColor(.orange)
            
            // Debug functionality removed for App Store release
            
            Button("Reset Onboarding") {
                UserDefaults.standard.set(false, forKey: "hasSeenOnboarding")
            }
            .foregroundColor(.blue)
        }
    }
    
    // MARK: - About Detail View
    
    private var aboutDetailView: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // App Icon & Title
                    VStack(spacing: 12) {
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("GameLoggr")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Version 1.0")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Description
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About GameLoggr")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Text("GameLoggr is your personal game collection manager. Track your games, log your playtime, rate your experiences, and manage your gaming backlog all in one place.")
                            .font(.body)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal)
                    
                    // IGDB Attribution (prominent)
                    VStack(spacing: 12) {
                        Text("Powered by IGDB")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        
                        Text("Game information, artwork, and metadata provided by the Internet Game Database (IGDB). IGDB is the ultimate destination for game discovery and information.")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                        
                        Button("Visit IGDB.com") {
                            if let url = URL(string: "https://www.igdb.com/") {
                                UIApplication.shared.open(url)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Developer Info
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Developer")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Text("Created with ❤️ for gamers who love to track their gaming journey.")
                            .font(.body)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingAbout = false
                    }
                }
            }
        }
    }
    
    // MARK: - Functions
    
    private func generateJSON() {
        Task {
            let client = IGDBClient()
            
            client.getAccessToken { success in
                guard success else {
                    print("Could not get access token.")
                    return
                }
                
                Task {
                    do {
                        let platforms = try await client.fetchAllPlatforms()
                        
                        let encoder = JSONEncoder()
                        encoder.outputFormatting = .prettyPrinted
                        
                        let jsonData = try encoder.encode(platforms)
                        
                        if let jsonString = String(data: jsonData, encoding: .utf8) {
                            print("--- COPY THE JSON BELOW ---")
                            print(jsonString)
                            print("--- END OF JSON ---")
                        }
                    } catch {
                        print("Failed to generate platform JSON: \(error)")
                    }
                }
            }
        }
    }
    
    private func importGameData() {
        // Implement import functionality
        print("Import functionality would be implemented here")
    }
    
    private func clearAllData() {
        // Implement clear all data functionality
        print("Clear all data functionality would be implemented here")
    }
    
    private func resetAllSettings() {
        defaultGameSort = "title"
        showCompletedGames = true
        enableNotifications = false
        autoBackup = false
        showDeveloperOptions = false
    }
    
    // Debug functionality removed for App Store release
}
