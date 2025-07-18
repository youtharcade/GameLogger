//
//  HardwareListView.swift
//  GameLogger
//
//  Created by Justin Gain on 7/12/25.
//
import SwiftUI
import SwiftData

struct HardwareListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Hardware.name) private var hardwareItems: [Hardware]
    @State private var showingAddSheet = false

    // Grid layout configuration
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(hardwareItems) { hardware in
                        NavigationLink(destination: HardwareDetailView(hardware: hardware)) {
                            HardwareGridCard(hardware: hardware)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
            .navigationTitle("Hardware")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                NavigationStack {
                    HardwareDetailView(hardware: nil)
                }
            }
        }
    }
    
    private func deleteHardware(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(hardwareItems[index])
        }
    }
}

struct HardwareGridCard: View {
    let hardware: Hardware
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Wide Hardware Image
            Group {
                if let data = hardware.imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    // Default placeholder with gradient background
                    ZStack {
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        
                        Image(systemName: "desktopcomputer")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                    }
                }
            }
            .frame(height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Hardware Information
            VStack(alignment: .leading, spacing: 4) {
                // Console Name
                Text(hardware.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                // Platform
                Text(hardware.platform?.name ?? "Unknown Platform")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // Storage Information
                HStack(spacing: 4) {
                    Image(systemName: "internaldrive")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Text(formatStorage(hardware.availableStorageInGB))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    
                    Text("available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private func formatStorage(_ storage: Double) -> String {
        if storage >= 1000 {
            return String(format: "%.1f TB", storage / 1000)
        } else if storage >= 1 {
            return String(format: "%.0f GB", storage)
        } else {
            return "< 1 GB"
        }
    }
}
