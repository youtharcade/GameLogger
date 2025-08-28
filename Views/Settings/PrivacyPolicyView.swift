//
//  PrivacyPolicyView.swift
//  GameLoggr
//
//  Created by Justin Gain on 7/18/25.
//

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    
                    Text("GameLoggr Privacy Policy")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 8)
                    
                    Text("Effective Date: December 18, 2024")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 16)
                    
                    Group {
                        privacySummarySection
                        dataCollectionSection
                        dataStorageSection
                        thirdPartyServicesSection
                        yourRightsSection
                        contactSection
                    }
                }
                .padding()
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var privacySummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Privacy-First Design")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("All data stored locally on your device")
                        .font(.subheadline)
                }
                
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("No data transmitted to our servers")
                        .font(.subheadline)
                }
                
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("We have no access to your data")
                        .font(.subheadline)
                }
                
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("API credentials stored securely in Keychain")
                        .font(.subheadline)
                }
            }
            .padding(.leading, 8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var dataCollectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What Data We Store")
                .font(.headline)
                .fontWeight(.bold)
            
            Text("GameLoggr stores the following information locally on your device:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("• Your game collection (titles, platforms, ratings)")
                Text("• Purchase information and play time")
                Text("• Custom images and PDF manuals you add")
                Text("• App preferences and settings")
                Text("• IGDB API credentials (if you provide them)")
            }
            .font(.subheadline)
            .padding(.leading, 8)
        }
    }
    
    private var dataStorageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How We Protect Your Data")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("• All data encrypted using iOS built-in encryption")
                Text("• API credentials stored in iOS Keychain (most secure)")
                Text("• Protected by your device passcode/biometrics")
                Text("• No cloud storage or external servers")
                Text("• Data never leaves your device")
            }
            .font(.subheadline)
            .padding(.leading, 8)
        }
    }
    
    private var thirdPartyServicesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Third-Party Services")
                .font(.headline)
                .fontWeight(.bold)
            
            Text("IGDB (Internet Game Database)")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("• Optional service for searching game information")
                Text("• You provide your own API credentials")
                Text("• Only public game data is retrieved")
                Text("• Your personal collection data is never shared")
            }
            .font(.subheadline)
            .padding(.leading, 8)
        }
    }
    
    private var yourRightsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Rights")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("• View, edit, or delete any data within the app")
                Text("• Export your data at any time")
                Text("• Manage API credentials in Settings")
                Text("• Delete all data by removing the app")
                Text("• No account required")
            }
            .font(.subheadline)
            .padding(.leading, 8)
        }
    }
    
    private var contactSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Contact Information")
                .font(.headline)
                .fontWeight(.bold)
            
            Text("If you have questions about this Privacy Policy:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Email: justingain.dev@gmail.com")
                Text("Developer: Justin Gain")
                Text("App: GameLoggr for iOS")
            }
            .font(.subheadline)
            .padding(.leading, 8)
            
            Link("View Full Privacy Policy", destination: URL(string: "https://github.com/justingain/GameLoggr")!)
                .font(.subheadline)
                .padding(.top, 8)
        }
    }
}

#Preview {
    PrivacyPolicyView()
}
