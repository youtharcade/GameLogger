import SwiftUI
import SwiftData
import PhotosUI

struct HardwareDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    @State private var hardware: Hardware
    private var isNew: Bool
    
    @Query private var existingPlatforms: [Platform]
    private let commonPlatforms: [Platform] = Bundle.main.decode("platforms.json")
    
    // State for pickers and text fields
    @State private var selectedPlatform: Platform?
    @State private var showingPlatformSearch = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var purchasePriceString: String = ""
    @State private var msrpString: String = ""
    @State private var internalStorageString: String = ""
    @State private var externalStorageString: String = ""
    @State private var selectedInstalledGames: Bool = false
    @State private var miscDataString: String = "0"
    @State private var installedSizeString: String = "0.00"
    
    private var allAvailablePlatforms: [Platform] {
        var combined = existingPlatforms
        let savedIDs = Set(existingPlatforms.map { $0.id })
        
        for commonPlatform in commonPlatforms {
            if !savedIDs.contains(commonPlatform.id) {
                combined.append(commonPlatform)
            }
        }
        return combined.sorted { $0.name < $1.name }
    }
    
    init(hardware: Hardware?) {
        if let hardware = hardware {
            _hardware = State(initialValue: hardware)
            _selectedPlatform = State(initialValue: hardware.platform)
            isNew = false
        } else {
            let newHardware = Hardware(name: "New Console")
            _hardware = State(initialValue: newHardware)
            _selectedPlatform = State(initialValue: nil)
            isNew = true
        }
    }
    
    var body: some View {
        Form {
            Section(header: 
                HStack {
                    Image(systemName: "photo.fill")
                        .foregroundColor(.blue)
                    Text("Image")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            ) {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    if let data = hardware.imageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage).resizable().scaledToFit()
                    } else {
                        Label("Select Image", systemImage: "photo.on.rectangle")
                    }
                }
            }
            
            Section(header: 
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.green)
                    Text("Hardware Information")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            ) {
                // Hardware Name
                HStack {
                    Image(systemName: "gamecontroller.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Hardware Name")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        TextField("Enter hardware name", text: $hardware.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                }
                
                // Platform Type
                HStack {
                    Image(systemName: "tv.fill")
                        .foregroundColor(.purple)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Platform Type")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        HStack {
                            Text(selectedPlatform?.name ?? "Select Platform")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(selectedPlatform != nil ? .primary : .secondary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            showingPlatformSearch = true
                        }
                        .sheet(isPresented: $showingPlatformSearch) {
                            PlatformSearchView(allPlatforms: allAvailablePlatforms, selectedPlatform: $selectedPlatform)
                        }
                    }
                }
                
                // Serial Number
                HStack {
                    Image(systemName: "barcode")
                        .foregroundColor(.orange)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Serial Number")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        TextField("Enter serial number", text: Binding($hardware.serialNumber, default: ""))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                }
            }
            
            Section(header: 
                HStack {
                    Image(systemName: "creditcard.fill")
                        .foregroundColor(.orange)
                    Text("Purchase Information")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            ) {
                HStack(spacing: 8) {
                    PurchaseInfoBox(purchaseDate: $hardware.purchaseDate, purchasePrice: $purchasePriceString)
                    ReleaseInfoBox(releaseDate: Binding($hardware.releaseDate, default: Date()), msrp: $msrpString)
                }
                .frame(maxWidth: .infinity)
                .listRowInsets(EdgeInsets())
            }
            
            Section(header: 
                HStack {
                    Image(systemName: "externaldrive.fill")
                        .foregroundColor(.purple)
                    Text("Storage Capacity")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            ) {
                HStack(spacing: 8) {
                    StorageBox(label: "Internal Storage", value: $internalStorageString, unit: "GB")
                    StorageBox(label: "External Storage", value: $externalStorageString, unit: "GB")
                }
                .frame(maxWidth: .infinity)
                .listRowInsets(EdgeInsets())
            }
            
            if !isNew {
                Section(header:
                    HStack {
                        Image(systemName: "gamecontroller.fill")
                            .foregroundColor(.red)
                        Text("Installed Digital Games")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                ) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            StorageBox(label: "Installed Size", value: $installedSizeString, unit: "GB", isReadOnly: true)
                            StorageBox(label: "Misc Data", value: $miscDataString, unit: "GB")
                            AvailableSpaceBox(
                                available: hardware.availableStorageInGB - (Double(miscDataString) ?? 0),
                                total: hardware.internalStorageInGB + hardware.externalStorageInGB
                            )
                        }
                        .frame(height: 110)
                        .padding(.vertical, 2)
                    }
                    .listRowInsets(EdgeInsets())
                    Button(action: { selectedInstalledGames = true }) {
                        HStack {
                            Image(systemName: "gamecontroller.fill")
                                .font(.title2)
                            Text("View Installed Games")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                        .shadow(color: Color.blue.opacity(0.3), radius: 6, x: 0, y: 3)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .background(
                        NavigationLink(destination: CollectionPageView(hardwareFilter: hardware), isActive: $selectedInstalledGames) { EmptyView() }
                            .hidden()
                    )
                }
            }
        }
        .navigationTitle(isNew ? "Add Hardware" : "Edit Hardware")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isNew {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
        }
        .onChange(of: selectedPhoto) {
            Task {
                if let data = try? await selectedPhoto?.loadTransferable(type: Data.self) {
                    hardware.imageData = data
                }
            }
        }
        .onAppear {
            purchasePriceString = String(format: "%.2f", hardware.purchasePrice)
            msrpString = String(format: "%.2f", hardware.msrp)
            internalStorageString = String(format: "%.0f", hardware.internalStorageInGB)
            externalStorageString = String(format: "%.0f", hardware.externalStorageInGB)
            installedSizeString = String(format: "%.2f", hardware.usedStorageInGB)
        }
        .onChange(of: hardware.linkedGames) { _, _ in
            installedSizeString = String(format: "%.2f", hardware.usedStorageInGB)
        }
        .onChange(of: purchasePriceString) { _, newValue in if let value = Double(newValue) { hardware.purchasePrice = value } }
        .onChange(of: msrpString) { _, newValue in if let value = Double(newValue) { hardware.msrp = value } }
        .onChange(of: internalStorageString) { _, newValue in if let value = Double(newValue) { hardware.internalStorageInGB = value } }
        .onChange(of: externalStorageString) { _, newValue in if let value = Double(newValue) { hardware.externalStorageInGB = value } }
    }
    
    private func save() {
        // Fetch or create the selected platform
        if let platformToSave = selectedPlatform {
            let platformID = platformToSave.id
            let fetchDescriptor = FetchDescriptor<Platform>(predicate: #Predicate { $0.id == platformID })
            let existingPlatform = (try? modelContext.fetch(fetchDescriptor))?.first
            
            if let foundPlatform = existingPlatform {
                hardware.platform = foundPlatform
            } else {
                let newPlatform = platformToSave
                modelContext.insert(newPlatform)
                hardware.platform = newPlatform
            }
        } else {
            hardware.platform = nil
        }
        
        if isNew {
            modelContext.insert(hardware)
        }
        dismiss()
    }
}

// Custom Binding extension for optional properties
fileprivate extension Binding {
    init<T>(_ source: Binding<T?>, default: T) where Value == T {
        self.init(get: { source.wrappedValue ?? `default` }, set: { source.wrappedValue = $0 })
    }
}

// MARK: - StorageBox View
struct StorageBox: View {
    let label: String
    @Binding var value: String
    let unit: String
    var isReadOnly: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                if isReadOnly {
                    Text(value)
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .frame(minWidth: 30, maxWidth: 60, alignment: .leading)
                } else {
                    TextField("0", text: $value)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .keyboardType(.decimalPad)
                        .frame(minWidth: 30, maxWidth: 60, alignment: .leading)
                }
                Text(unit)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
            }
            Text(" ") // Placeholder for height match
                .font(.caption)
                .opacity(0)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.accentColor, lineWidth: 3)
        )
    }
}

// MARK: - AvailableSpaceBox View
struct AvailableSpaceBox: View {
    let available: Double
    let total: Double

    var percentUsed: Double {
        guard total > 0 else { return 0 }
        return (1 - (available / total)) * 100
    }

    var fillColor: Color {
        switch percentUsed {
        case 0...30:
            return .green
        case 31...60:
            return .yellow
        default:
            return .red
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Available Space")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(String(format: "%.2f", available))
                    .font(.headline)
                    .foregroundColor(.primary)
                    .frame(minWidth: 30, maxWidth: 60, alignment: .leading)
                Text("GB")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
            }
            Text("\(Int(percentUsed))% Used")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(fillColor.opacity(0.2))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(fillColor, lineWidth: 2)
        )
    }
}

// MARK: - PurchaseInfoBox View
struct PurchaseInfoBox: View {
    @Binding var purchaseDate: Date
    @Binding var purchasePrice: String
    @State private var showingDatePicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Purchase Date
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Image(systemName: "calendar.circle.fill")
                        .foregroundColor(.blue)
                        .font(.body)
                    Text("Purchase Date")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
                Text(purchaseDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                showingDatePicker = true
            }
            
            // Purchase Price
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(.green)
                        .font(.body)
                    Text("Purchase Price")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("$")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    TextField("0.00", text: $purchasePrice)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .sheet(isPresented: $showingDatePicker) {
            NavigationStack {
                VStack {
                    DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .padding()
                }
                .navigationTitle("Select Purchase Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            showingDatePicker = false
                        }
                    }
                }
            }
        }
    }
}

// MARK: - ReleaseInfoBox View
struct ReleaseInfoBox: View {
    @Binding var releaseDate: Date
    @Binding var msrp: String
    @State private var showingDatePicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Release Date
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundColor(.purple)
                        .font(.body)
                    Text("Release Date")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
                Text(releaseDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                showingDatePicker = true
            }
            
            // MSRP
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Image(systemName: "tag.circle.fill")
                        .foregroundColor(.orange)
                        .font(.body)
                    Text("MSRP")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("$")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    TextField("0.00", text: $msrp)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .sheet(isPresented: $showingDatePicker) {
            NavigationStack {
                VStack {
                    DatePicker("Release Date", selection: $releaseDate, displayedComponents: .date)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .padding()
                }
                .navigationTitle("Select Release Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            showingDatePicker = false
                        }
                    }
                }
            }
        }
    }
}

