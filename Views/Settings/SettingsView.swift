//
//  SettingsView.swift
//  GameLogger
//
//  Created by Justin Gain on 7/14/25.
//
import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("defaultGameSort") private var defaultGameSort: String = "title"
    @AppStorage("showCompletedGames") private var showCompletedGames: Bool = true
    @AppStorage("enableNotifications") private var enableNotifications: Bool = false
    @AppStorage("enableReleaseReminders") private var enableReleaseReminders: Bool = false
    @AppStorage("enableBacklogReminders") private var enableBacklogReminders: Bool = false
    @AppStorage("releaseReminderDays") private var releaseReminderDays: Int = 1
    
    @StateObject private var notificationManager = NotificationManager.shared

    @AppStorage("showDeveloperOptions") private var showDeveloperOptions: Bool = false
    
    @State private var showingExportSheet = false
    @State private var showingImportSheet = false
    @State private var showingAbout = false
    @State private var showOnboarding = false
    @State private var showingImportAlert = false
    @State private var importAlertMessage = ""
    @State private var importAlertTitle = ""
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var exportDocument: GameLoggrDocument?
    
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
            .fileExporter(
                isPresented: $showingExportSheet,
                document: exportDocument,
                contentType: .json,
                defaultFilename: "GameLoggr-Export-\(DateFormatter.fileNameFormatter.string(from: Date()))"
            ) { result in
                switch result {
                case .success(let url):
                    print("Export saved to: \(url)")
                case .failure(let error):
                    importAlertTitle = "Export Failed"
                    importAlertMessage = "Failed to save export file: \(error.localizedDescription)"
                    showingImportAlert = true
                }
                exportDocument = nil
            }
            .fileImporter(
                isPresented: $showingImportSheet,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleImportResult(result)
            }
            .alert(importAlertTitle, isPresented: $showingImportAlert) {
                Button("OK") { }
            } message: {
                Text(importAlertMessage)
            }
            .onAppear {
                notificationManager.checkAuthorizationStatus()
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
        Section(
            header: HStack {
                Image(systemName: "externaldrive.fill")
                    .foregroundColor(.indigo)
                Text("Data Management")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            },
            footer: Text("Export your game collection to a JSON file for backup or transfer. Import data from a previous export to restore your collection."),
            content: {
            Button(action: { exportData() }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.green)
                    Text("Export Game Data")
                    Spacer()
                    if isExporting {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            .disabled(isExporting)
            
            Button(action: { showingImportSheet = true }) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundColor(.blue)
                    Text("Import Game Data")
                    Spacer()
                    if isImporting {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            .disabled(isImporting)
            }
        )
    }
    
    private var notificationsSection: some View {
        Section(
            header: HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(.red)
                Text("Notifications")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            },
            footer: Text("Notifications require permission. Tap 'Enable Notifications' to set up reminders for game releases and backlog management.")
        ) {
            // Notification permission status
            HStack {
                Image(systemName: notificationManager.isAuthorized ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(notificationManager.isAuthorized ? .green : .orange)
                Text("Permission Status")
                Spacer()
                Text(notificationManager.authorizationStatusDescription)
                    .foregroundColor(.secondary)
            }
            
            // Enable notifications button/toggle
            if !notificationManager.isAuthorized {
                Button(action: {
                    Task {
                        await enableNotifications()
                    }
                }) {
                    HStack {
                        Image(systemName: "bell.badge")
                            .foregroundColor(.blue)
                        Text("Enable Notifications")
                        Spacer()
                    }
                }
            }
            
            // Release reminders
            if notificationManager.canScheduleNotifications {
                Toggle(isOn: $enableReleaseReminders) {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Game Release Reminders")
                                .font(.subheadline)
                            Text("Get notified about upcoming releases in your wishlist")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onChange(of: enableReleaseReminders) { _, newValue in
                    if newValue {
                        scheduleReleaseReminders()
                    } else {
                        cancelReleaseReminders()
                    }
                }
                
                // Release reminder timing
                if enableReleaseReminders {
                    Picker("Reminder Timing", selection: $releaseReminderDays) {
                        Text("1 day before").tag(1)
                        Text("3 days before").tag(3)
                        Text("1 week before").tag(7)
                        Text("Both 1 day & 1 week").tag(0) // Special case for both
                    }
                    .pickerStyle(.menu)
                    .onChange(of: releaseReminderDays) { _, _ in
                        if enableReleaseReminders {
                            scheduleReleaseReminders()
                        }
                    }
                }
                
                // Backlog reminders
                Toggle(isOn: $enableBacklogReminders) {
                    HStack {
                        Image(systemName: "books.vertical")
                            .foregroundColor(.purple)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Backlog Reminders")
                                .font(.subheadline)
                            Text("Weekly reminders to check your game backlog")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onChange(of: enableBacklogReminders) { _, newValue in
                    if newValue {
                        notificationManager.scheduleBacklogReminder()
                    } else {
                        notificationManager.cancelBacklogReminder()
                    }
                }
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
            
            NavigationLink(destination: PrivacyPolicyView()) {
                HStack {
                    Image(systemName: "lock.shield")
                        .foregroundColor(.green)
                    Text("Privacy Policy")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "arrow.forward")
                        .foregroundColor(.secondary)
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
            NavigationLink(destination: APICredentialsView()) {
                HStack {
                    Image(systemName: "key.fill")
                        .foregroundColor(.blue)
                    Text("IGDB API Credentials")
                    Spacer()
                    if Config.hasIGDBCredentials {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                    }
                }
            }
            
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
        enableReleaseReminders = false
        enableBacklogReminders = false
        showDeveloperOptions = false
    }
    
    // MARK: - Notification Functions
    
    private func enableNotifications() async {
        let granted = await notificationManager.requestAuthorization()
        if granted {
            await MainActor.run {
                enableNotifications = true
            }
        }
    }
    
    private func scheduleReleaseReminders() {
        Task {
            do {
                let fetchDescriptor = FetchDescriptor<Game>()
                let games = try modelContext.fetch(fetchDescriptor)
                let wishlistedGames = games.filter { $0.isWishlisted && $0.releaseDate > Date() }
                
                // Cancel existing reminders first
                for game in wishlistedGames {
                    notificationManager.cancelAllReleaseReminders(for: game.id)
                }
                
                // Schedule new reminders based on user preference
                for game in wishlistedGames {
                    switch releaseReminderDays {
                    case 0: // Both 1 day and 1 week
                        notificationManager.scheduleReleaseReminder(for: game, daysBeforeRelease: 1)
                        notificationManager.scheduleReleaseReminder(for: game, daysBeforeRelease: 7)
                    case 1, 3, 7: // Specific number of days
                        notificationManager.scheduleReleaseReminder(for: game, daysBeforeRelease: releaseReminderDays)
                    default:
                        break
                    }
                }
                
                print("Scheduled release reminders for \(wishlistedGames.count) games")
            } catch {
                print("Failed to fetch games for release reminders: \(error)")
            }
        }
    }
    
    private func cancelReleaseReminders() {
        Task {
            do {
                let fetchDescriptor = FetchDescriptor<Game>()
                let games = try modelContext.fetch(fetchDescriptor)
                for game in games {
                    notificationManager.cancelAllReleaseReminders(for: game.id)
                }
                print("Cancelled all release reminders")
            } catch {
                print("Failed to fetch games for cancelling reminders: \(error)")
            }
        }
    }
    
    // MARK: - Data Management Functions
    
    private func exportData() {
        isExporting = true
        
        Task {
            do {
                let exportData = try DataManager.exportData(from: modelContext)
                
                await MainActor.run {
                    // Create document and trigger file exporter
                    exportDocument = GameLoggrDocument(data: exportData)
                    showingExportSheet = true
                    isExporting = false
                }
            } catch {
                await MainActor.run {
                    importAlertTitle = "Export Failed"
                    importAlertMessage = "Failed to export game data: \(error.localizedDescription)"
                    showingImportAlert = true
                    isExporting = false
                }
            }
        }
    }
    
    private func handleImportResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            importDataFromURL(url)
        case .failure(let error):
            importAlertTitle = "Import Failed"
            importAlertMessage = "Failed to select file: \(error.localizedDescription)"
            showingImportAlert = true
        }
    }
    
    private func importDataFromURL(_ url: URL) {
        isImporting = true
        
        Task {
            do {
                let data = try Data(contentsOf: url)
                let result = try DataManager.importData(data, to: modelContext, replaceExisting: false)
                
                await MainActor.run {
                    importAlertTitle = "Import Successful"
                    importAlertMessage = "Successfully imported \(result.totalItems) items:\n• \(result.gamesImported) games\n• \(result.platformsImported) platforms\n• \(result.hardwareImported) hardware"
                    showingImportAlert = true
                    isImporting = false
                }
            } catch {
                await MainActor.run {
                    importAlertTitle = "Import Failed"
                    importAlertMessage = "Failed to import data: \(error.localizedDescription)"
                    showingImportAlert = true
                    isImporting = false
                }
            }
        }
    }
    
    // Debug functionality removed for App Store release
}
