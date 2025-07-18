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

    var body: some View {
        NavigationStack {
            List {
                ForEach(hardwareItems) { hardware in
                    // Use the older NavigationLink(destination:label:) style
                    NavigationLink(destination: HardwareDetailView(hardware: hardware)) {
                        HStack {
                            Group {
                                if let data = hardware.imageData, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                } else {
                                    Image(systemName: "desktopcomputer")
                                        .resizable()
                                        .scaledToFit()
                                        .padding(4)
                                }
                            }
                            .frame(width: 50, height: 40)
                            .foregroundStyle(.secondary)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            
                            Text(hardware.name)
                        }
                    }
                }
                .onDelete(perform: deleteHardware)
            }
            .navigationTitle("Hardware")
            // The .navigationDestination modifier is now REMOVED
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
