import SwiftUI
import SwiftData
import PhotosUI
import PDFKit
import Markdown
// import MarkdownDisplayView

// Single PlayLogFilter enum at the top level
enum PlayLogFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case checkpoint = "Checkpoints"
    case normal = "Normal"
    var id: String { rawValue }
}

// Move PlayLogSheetMode to the top level, above ActiveSheet
enum PlayLogSheetMode: Identifiable, Equatable {
    case view(PlayLogEntry)
    case edit(PlayLogEntry)
    var id: PersistentIdentifier {
        switch self {
        case .view(let entry): return entry.persistentModelID
        case .edit(let entry): return entry.persistentModelID
        }
    }
}

// ActiveSheet uses PlayLogSheetMode
enum ActiveSheet: Identifiable {
    case playLog(PlayLogSheetMode)
    case addPlayLog
    case addSubGame
    case addLink
    case platformSearch
    case pdfViewer(Int)
    
    var id: String {
        switch self {
        case .playLog(let mode):
            switch mode {
            case .view(let entry): return "playLogView-\(entry.persistentModelID)"
            case .edit(let entry): return "playLogEdit-\(entry.persistentModelID)"
            }
        case .addPlayLog: return "addPlayLog"
        case .addSubGame: return "addSubGame"
        case .addLink: return "addLink"
        case .platformSearch: return "platformSearch"
        case .pdfViewer(let idx): return "pdfViewer-\(idx)"
        }
    }
}

struct GameDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    // Change to accept PersistentIdentifier instead of Game
    private let gameID: PersistentIdentifier
    
    // Use @State to directly store the game
    @State private var game: Game?
    @State private var isLoading = true
    
    // Helper computed properties for bindings
    private var gameBinding: Binding<Game?> {
        Binding(
            get: { game },
            set: { _ in }
        )
    }
    
    private var titleBinding: Binding<String> {
        Binding(
            get: { game?.title ?? "" },
            set: { newValue in 
                guard let game = game else { return }
                game.title = newValue 
            }
        )
    }
    
    private var platformBinding: Binding<Platform?> {
        Binding(
            get: { game?.platform },
            set: { newValue in 
                guard let game = game else { return }
                game.platform = newValue 
            }
        )
    }
    
    private var ownershipStatusBinding: Binding<OwnershipStatus> {
        Binding(
            get: { game?.ownershipStatus ?? .owned },
            set: { newValue in 
                guard let game = game else { return }
                game.ownershipStatus = newValue 
            }
        )
    }
    
    private var purchaseDateBinding: Binding<Date> {
        Binding(
            get: { game?.purchaseDate ?? Date() },
            set: { newValue in 
                guard let game = game else { return }
                game.purchaseDate = newValue 
            }
        )
    }
    
    private var releaseDateBinding: Binding<Date> {
        Binding(
            get: { game?.releaseDate ?? Date() },
            set: { newValue in 
                guard let game = game else { return }
                game.releaseDate = newValue 
            }
        )
    }
    
    private var startDateBinding: Binding<Date> {
        Binding(
            get: { game?.startDate ?? Date() },
            set: { newValue in 
                guard let game = game else { return }
                game.startDate = newValue 
            }
        )
    }
    
    private var completionDateBinding: Binding<Date> {
        Binding(
            get: { game?.completionDate ?? Date() },
            set: { newValue in 
                guard let game = game else { return }
                game.completionDate = newValue 
            }
        )
    }
    
    private var isInstalledBinding: Binding<Bool> {
        Binding(
            get: { game?.isInstalled ?? false },
            set: { newValue in 
                guard let game = game else { return }
                game.isInstalled = newValue 
            }
        )
    }
    
    private var linkedHardwareBinding: Binding<Hardware?> {
        Binding(
            get: { game?.linkedHardware },
            set: { newValue in 
                guard let game = game else { return }
                game.linkedHardware = newValue 
            }
        )
    }
    
    private var hasCaseBinding: Binding<Bool> {
        Binding(
            get: { game?.hasCase ?? false },
            set: { newValue in 
                guard let game = game else { return }
                game.hasCase = newValue 
            }
        )
    }
    
    private var hasManualBinding: Binding<Bool> {
        Binding(
            get: { game?.hasManual ?? false },
            set: { newValue in 
                guard let game = game else { return }
                game.hasManual = newValue 
            }
        )
    }
    
    private var hasInsertsBinding: Binding<Bool> {
        Binding(
            get: { game?.hasInserts ?? false },
            set: { newValue in 
                guard let game = game else { return }
                game.hasInserts = newValue 
            }
        )
    }
    
    private var isSealedBinding: Binding<Bool> {
        Binding(
            get: { game?.isSealed ?? false },
            set: { newValue in 
                guard let game = game else { return }
                game.isSealed = newValue 
            }
        )
    }
    
    private var userHLTBMainBinding: Binding<Double> {
        Binding(
            get: { game?.userHLTBMain ?? 0 },
            set: { newValue in 
                guard let game = game else { return }
                game.userHLTBMain = newValue 
            }
        )
    }
    
    private var userHLTBExtraBinding: Binding<Double> {
        Binding(
            get: { game?.userHLTBExtra ?? 0 },
            set: { newValue in 
                guard let game = game else { return }
                game.userHLTBExtra = newValue 
            }
        )
    }
    
    private var userHLTBCompletionistBinding: Binding<Double> {
        Binding(
            get: { game?.userHLTBCompletionist ?? 0 },
            set: { newValue in 
                guard let game = game else { return }
                game.userHLTBCompletionist = newValue 
            }
        )
    }
    
    // MARK: - Queries
    @Query(sort: \Game.title) private var allGames: [Game]
    @Query(sort: \Platform.name) private var savedPlatforms: [Platform]
    @Query(sort: \Hardware.name) private var hardwareItems: [Hardware]
    // Use allGames for any in-memory filtering needed (e.g., for linkedGames).
    
    // MARK: - State
    @State private var isAddingPlayLog = false
    @State private var showFileImporter = false
    @State private var showPDFViewer = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isAddingSubGame = false
    @State private var showCompletionAlert = false
    @State private var isAddingLink = false
    @State private var showingPlatformSearch = false
    @State private var showStorageAlert = false
    
    @State private var selectedStatus: GameStatus
    
    @State private var purchasePriceString: String = ""
    @State private var msrpString: String = ""
    @State private var totalTimePlayedString: String = ""
    @State private var gameSizeString: String = ""
    @State private var selectedSizeUnit: SizeUnit = .megabytes
    
    enum SizeUnit: String, CaseIterable {
        case megabytes = "MB"
        case gigabytes = "GB"
    }
    @State private var selectedPDFIndex: Int? = nil
    
    // Add this state for filtering
    @State private var playLogFilter: PlayLogFilter = .all
    
    @State private var activeSheet: ActiveSheet? = nil
    
    // Add this enum at the top level (outside the struct)
    enum PlayLogSheetMode: Identifiable, Equatable {
        case view(PlayLogEntry)
        case edit(PlayLogEntry)
        var id: PersistentIdentifier {
            switch self {
            case .view(let entry): return entry.persistentModelID
            case .edit(let entry): return entry.persistentModelID
            }
        }
    }
    
    @State private var selectedPlayLogEntryID: PersistentIdentifier? = nil
    @State private var editingEntry: PlayLogEntry? = nil
    
    @State private var playLogRefreshID = UUID()
    
    // MARK: - Properties
    private let commonPlatforms: [Platform] = Bundle.main.decode("platforms.json")
    
    private var allAvailablePlatforms: [Platform] {
        var combined = savedPlatforms
        let savedIDs = Set(savedPlatforms.map { $0.id })
        
        for commonPlatform in commonPlatforms {
            if !savedIDs.contains(commonPlatform.id) {
                combined.append(commonPlatform)
            }
        }
        return combined.sorted { $0.name < $1.name }
    }
    
    init(gameID: PersistentIdentifier) {
        self.gameID = gameID
        self.selectedStatus = .backlog
    }
    
    // Convenience initializer for backward compatibility
    init(game: Game) {
        self.gameID = game.persistentModelID
        self.selectedStatus = game.status
    }
    
    // MARK: - Computed Properties
    private var linkedGames: [Game] {
        guard let game = game else { return [] }
        return allGames.filter { $0.parentCollection?.id == game.id }
    }
    
    private var isGameCollection: Bool {
        return game?.includedGames != nil
    }
    
    private var hasIncludedGames: Bool {
        return game?.includedGames != nil && !(game?.includedGames?.isEmpty ?? true)
    }
    
    private var collectorsGradeColor: Color {
        switch game?.collectorsGrade.lowercased() {
        case "sealed":
            return .purple // Royal purple for perfection
        case "mint":
            return .blue // Blue for excellent condition
        case "near mint":
            return .green // Green for very good condition
        case "excellent":
            return .orange // Orange for good condition
        case "very good":
            return .yellow // Yellow for acceptable condition
        case "good":
            return .red // Red for poor condition
        case "fair":
            return .brown // Brown for very poor condition
        case "poor":
            return .gray // Gray for terrible condition
        case "loose":
            return .black // Black for garbage/sadness
        default:
            return .secondary
        }
    }

    // MARK: - Main Body
    var body: some View {
        Group {
            if game != nil {
                gameDetailForm
            } else {
                VStack(spacing: 16) {
                    if isLoading {
                        // Still loading game
                        ProgressView("Loading game...")
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.2)
                    } else {
                        // Game not found
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.red)
                        Text("Game not found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("The game may have been deleted or moved.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
            }
        }
        .navigationTitle(game?.title ?? "Game")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadGame()
        }
        .onChange(of: purchasePriceString) { _, newValue in if let value = Double(newValue) { game?.purchasePrice = value } }
        .onChange(of: msrpString) { _, newValue in if let value = Double(newValue) { game?.msrp = value } }
        .onChange(of: totalTimePlayedString) { _, newValue in if let value = Double(newValue) { game?.manuallySetTotalTime = value } }
        .onChange(of: gameSizeString) { _, newValue in 
            if let value = Double(newValue) { 
                game?.gameSizeInMB = convertToMB(value) 
            } 
        }
        .onChange(of: selectedSizeUnit) { _, newUnit in
            // Convert the current value to the new unit
            if let currentValue = Double(gameSizeString), currentValue > 0 {
                let sizeInMB = convertToMB(currentValue)
                switch newUnit {
                case .megabytes:
                    gameSizeString = String(format: "%.0f", sizeInMB)
                case .gigabytes:
                    gameSizeString = String(format: "%.2f", sizeInMB / 1024)
                }
            }
        }
    }
    
    @ViewBuilder
    private var gameDetailForm: some View {
        Form {
            coverArtSection
            gameInfoSection
            collectionDetailsSection
            if !(game?.isSubGame ?? false) {
                purchaseInformationSection
                physicalOrDigitalSection
                if !(game?.isDigital ?? false) {
                    collectorsGradeSection
                }
            }
            if game?.isCollection ?? false && (!linkedGames.isEmpty || (game?.includedGames != nil && (game?.includedGames?.isEmpty ?? false))) {
                collectionGamesSection
            }
            backlogDetailsSection
            ratingSection
            
            hltbSection
            walkthroughSection
            playLogSectionMinimal
            deleteGameSection
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .playLog(let mode):
                switch mode {
                case .view(let entry):
                    PlayLogEntryDetailView(entry: entry, onEdit: {
                        activeSheet = .playLog(.edit(entry))
                    })
                case .edit(let entry):
                    AddPlayLogView(
                        date: entry.timestamp,
                        hours: Int(entry.timeSpent) / 3600,
                        minutes: Int(entry.timeSpent) / 60 % 60,
                        notes: entry.notes,
                        isCheckpoint: entry.checkpoint,
                        title: entry.title ?? "",
                        onSave: { updatedEntry in
                            if let idx = game?.playLog.firstIndex(where: { $0.persistentModelID == entry.persistentModelID }) {
                                game?.playLog[idx] = updatedEntry
                            }
                            activeSheet = nil
                        },
                        onCancel: { activeSheet = nil }
                    )
                }
            case .addPlayLog:
                AddPlayLogView(onAdd: { newEntry in addPlayLogEntry(newEntry); activeSheet = nil }, onCancel: { activeSheet = nil })
            case .addSubGame:
                AddGameView(parentGame: game)
            case .addLink:
                AddLinkView { name, urlString in
                    let newLink = HelpfulLink(name: name, urlString: urlString)
                    game?.helpfulLinks.append(newLink)
                    activeSheet = nil
                }
            case .platformSearch:
                PlatformSearchView(allPlatforms: allAvailablePlatforms, selectedPlatform: platformBinding)
            case .pdfViewer(let idx):
                if game?.manualPDFs.indices.contains(idx) ?? false {
                    PDFViewer(data: game?.manualPDFs[idx] ?? Data())
                }
            }
        }
        .alert("Cannot Complete Collection", isPresented: $showCompletionAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("You must complete all included games before marking the entire collection as 'Completed'.")
        }
        .alert("Not Enough Storage!", isPresented: $showStorageAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("There is not enough available space on the selected hardware to install this game. Please free up space or select different hardware.")
        }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.pdf]) { result in handleFileImport(result: result) }
        .onChange(of: selectedPhoto) { handlePhotoSelection() }
        .onChange(of: selectedStatus) { _, newStatus in handleStatusChange(to: newStatus) }
        .onAppear {
            setupTextFields()
            selectedStatus = game?.status ?? .backlog
            
            // Defensive: treat empty includedGames as nil
            if let included = game?.includedGames, included.isEmpty {
                game?.includedGames = nil
            }
        }
        .onChange(of: purchasePriceString) { _, newValue in if let value = Double(newValue) { game?.purchasePrice = value } }
        .onChange(of: msrpString) { _, newValue in if let value = Double(newValue) { game?.msrp = value } }
        .onChange(of: totalTimePlayedString) { _, newValue in if let value = Double(newValue) { game?.manuallySetTotalTime = value } }
        .onChange(of: gameSizeString) { _, newValue in 
            if let value = Double(newValue) { 
                game?.gameSizeInMB = convertToMB(value) 
            } 
        }
        .onChange(of: selectedSizeUnit) { _, newUnit in
            // Convert the current value to the new unit
            if let currentValue = Double(gameSizeString), currentValue > 0 {
                let sizeInMB = convertToMB(currentValue)
                switch newUnit {
                case .megabytes:
                    gameSizeString = String(format: "%.0f", sizeInMB)
                case .gigabytes:
                    gameSizeString = String(format: "%.2f", sizeInMB / 1024)
                }
            }
        }
    }
    
    // MARK: - Subviews (Now inside the main struct)
    var coverArtSection: some View {
        Section {
            ZStack(alignment: .bottomTrailing) {
                if let imageData = game?.customCoverArt, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage).resizable().scaledToFit()
                } else {
                    AsyncImage(url: game?.coverArtURL) { $0.resizable().scaledToFit() } placeholder: {
                        ZStack { Rectangle().fill(.secondary.opacity(0.1)); Image(systemName: "photo.fill").font(.largeTitle).foregroundColor(.gray) }
                    }
                }
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Image(systemName: "pencil.circle.fill").font(.title).symbolRenderingMode(.multicolor)
                        .padding(8).background(.ultraThickMaterial).clipShape(Circle())
                }
            }
            .aspectRatio(3/4, contentMode: .fit).cornerRadius(12).listRowInsets(EdgeInsets()).padding(.vertical)
        }
    }
    
    var gameInfoSection: some View {
        Section(header: 
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text("Game Info")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
        ) {
            if let releaseDate = game?.releaseDate { HStack { Text("Release Date"); Spacer(); Text(releaseDate.formatted(date: .long, time: .omitted)).foregroundStyle(.secondary) } }
            if !(game?.genres.isEmpty ?? true) { HStack { Text("Genre(s)"); Spacer(); Text(game?.genres.joined(separator: ", ") ?? "").foregroundStyle(.secondary).multilineTextAlignment(.trailing) } }
            if !(game?.developers.isEmpty ?? true) { HStack { Text("Developer(s)"); Spacer(); Text(game?.developers.joined(separator: ", ") ?? "").foregroundStyle(.secondary).multilineTextAlignment(.trailing) } }
            if !(game?.publishers.isEmpty ?? true) { HStack { Text("Publisher(s)"); Spacer(); Text(game?.publishers.joined(separator: ", ") ?? "").foregroundStyle(.secondary).multilineTextAlignment(.trailing) } }
            // Add link to parent collection if this is a subgame
            if game?.isSubGame ?? false, let parent = game?.parentCollection {
                NavigationLink(destination: GameDetailView(gameID: parent.persistentModelID)) {
                    Text("Part of Collection ") + Text(parent.title).fontWeight(.semibold).foregroundColor(.primary)
                }
            }
        }
    }
    
    var collectionDetailsSection: some View {
        Section(header: 
            HStack {
                Image(systemName: "gamecontroller.fill")
                    .foregroundColor(.green)
                Text("Game Information")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
        ) {
            // Game Title
            HStack {
                Image(systemName: "gamecontroller.fill")
                    .foregroundColor(.blue)
                    .font(.body)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Game Title")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    TextField("Enter game title", text: titleBinding)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }
            
            // Platform
            HStack {
                Image(systemName: "tv.fill")
                    .foregroundColor(.purple)
                    .font(.body)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Platform")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    HStack {
                        Text(game?.platform?.name ?? "Select Platform")
                            .font(.body)
                            // .fontWeight(.semibold)
                            .foregroundColor(game?.platform != nil ? .primary : .secondary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        activeSheet = .platformSearch
                    }
                }
            }
            
            if !(game?.isSubGame ?? false) {
                // Ownership Status
                HStack {
                    Image(systemName: "person.crop.circle.fill")
                        .foregroundColor(.orange)
                        .font(.body)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ownership Status")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        Picker("", selection: ownershipStatusBinding) { 
                            ForEach(OwnershipStatus.allCases, id: \.self) { 
                                Text($0.rawValue).tag($0) 
                            } 
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }
                }
                
                // Edition Type
                HStack {
                    Image(systemName: "shippingbox.fill")
                        .foregroundColor(.indigo)
                        .font(.body)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Edition Type")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        HStack(spacing: 0) {
                            // Physical Option
                            Button(action: {
                                game?.isDigital = false
                            }) {
                                HStack {
                                    Image(systemName: "shippingbox.fill")
                                        .font(.caption)
                                    Text("Physical")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(game?.isDigital ?? false ? .secondary : .white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(game?.isDigital ?? false ? Color(.systemGray5) : Color.indigo)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Digital Option
                            Button(action: {
                                game?.isDigital = true
                            }) {
                                HStack {
                                    Image(systemName: "desktopcomputer")
                                        .font(.caption)
                                    Text("Digital")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(game?.isDigital ?? false ? .white : .secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(game?.isDigital ?? false ? Color.indigo : Color(.systemGray5))
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                    }
                }
                
                // Collection Type
                HStack {
                    Image(systemName: "rectangle.stack.fill")
                        .foregroundColor(.cyan)
                        .font(.body)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Collection Type")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        HStack(spacing: 0) {
                            // Individual Game Option
                            Button(action: {
                                guard let game = game else { return }
                                
                                // Clear any existing subgame relationships first
                                if let subgames = game.includedGames {
                                    for subgame in subgames {
                                        subgame.parentCollection = nil
                                        subgame.isSubGame = false
                                    }
                                }
                                
                                // Reset all collection-related properties
                                game.isSubGame = false
                                game.parentCollection = nil
                                game.includedGames = nil
                                game.isCollection = false
                                
                                // Save once at the end with proper error handling
                                do {
                                    try modelContext.save()
                                } catch {
                                    print("Error saving individual game changes: \(error)")
                                }
                            }) {
                                HStack {
                                    Image(systemName: "gamecontroller.fill")
                                        .font(.caption)
                                    Text("Individual")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(!(game?.isCollection ?? false) ? .white : .secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(!(game?.isCollection ?? false) ? Color.cyan : Color(.systemGray5))
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Collection Option
                            Button(action: {
                                guard let game = game else { return }
                                
                                // Set collection-related properties
                                game.isSubGame = false
                                game.parentCollection = nil
                                game.isCollection = true
                                
                                // Initialize includedGames if needed (SwiftData will handle the relationship)
                                if game.includedGames == nil {
                                    game.includedGames = []
                                }
                                
                                // Save with proper error handling
                                do {
                                    try modelContext.save()
                                } catch {
                                    print("Error saving collection changes: \(error)")
                                    // Reset on error
                                    game.isCollection = false
                                    game.includedGames = nil
                                }
                            }) {
                                HStack {
                                    Image(systemName: "rectangle.stack.fill")
                                        .font(.caption)
                                    Text("Collection")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor((game?.isCollection ?? false) ? .white : .secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill((game?.isCollection ?? false) ? Color.cyan : Color(.systemGray5))
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                    }
                }
            }
        }
    }
    
    var purchaseInformationSection: some View {
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
                PurchaseInfoBox(purchaseDate: purchaseDateBinding, purchasePrice: $purchasePriceString)
                ReleaseInfoBox(releaseDate: releaseDateBinding, msrp: $msrpString)
            }
            .frame(maxWidth: .infinity)
            .listRowInsets(EdgeInsets())
        }
    }
    
    var physicalOrDigitalSection: some View {
        Group {
            if game?.isDigital ?? false {
                Section(header: 
                    HStack {
                        Image(systemName: "desktopcomputer")
                            .foregroundColor(.purple)
                        Text("Digital Edition")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                ) {
                    // Game Size Input with MB/GB conversion
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "externaldrive.fill")
                                .foregroundColor(.blue)
                                .font(.body)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Game Size")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    TextField("Size", text: $gameSizeString)
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(width: 80)
                                    
                                    Picker("Unit", selection: $selectedSizeUnit) {
                                        ForEach(SizeUnit.allCases, id: \.self) { unit in
                                            Text(unit.rawValue).tag(unit)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                    .frame(width: 100)
                                    
                                    Spacer()
                                }
                                
                                // Show conversion in smaller text
                                if let inputValue = Double(gameSizeString), inputValue > 0 {
                                    Text(formatSizeConversion(inputValue))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    Toggle("Currently Installed", isOn: isInstalledBinding)
                        .onChange(of: game?.isInstalled ?? false) { _, isNowInstalled in
                            if isNowInstalled {
                                checkStorage()
                            } else {
                                game?.linkedHardware = nil // Remove hardware association when toggled off
                            }
                        }
                    if game?.isInstalled ?? false {
                        Picker("Installed On", selection: linkedHardwareBinding) {
                            Text("None").tag(nil as Hardware?)
                            ForEach(hardwareItems) { Text($0.name).tag($0 as Hardware?) }
                        }
                        .onChange(of: game?.linkedHardware ?? nil) { _, _ in
                            checkStorage()
                        }
                    }
                }
            } else {
                Section(header: 
                    HStack {
                        Image(systemName: "shippingbox.fill")
                            .foregroundColor(.orange)
                        Text("Physical Edition")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                ) {
                    Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                        GridRow {
                            ComponentSelectorView(title: "Case", iconName: "case.fill", isSelected: hasCaseBinding)
                            ComponentSelectorView(title: "Manual", iconName: "book.fill", isSelected: hasManualBinding)
                        }
                        GridRow {
                            ComponentSelectorView(title: "Inserts", iconName: "menucard.fill", isSelected: hasInsertsBinding)
                            ComponentSelectorView(title: "Sealed", iconName: "seal.fill", isSelected: isSealedBinding)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }
    
    var collectorsGradeSection: some View {
        Section(header: 
            HStack {
                Image(systemName: "star.circle.fill")
                    .foregroundColor(.yellow)
                Text("Collector's Grade")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
        ) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(collectorsGradeColor)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Condition Rating")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Text(game?.collectorsGrade ?? "")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(collectorsGradeColor)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(collectorsGradeColor.opacity(0.3), lineWidth: 1)
                        )
                }
            }
        }
    }
    
    var collectionGamesSection: some View {
        Section(header:
            HStack {
                Image(systemName: "rectangle.stack.fill")
                    .foregroundColor(.cyan)
                Text("Games in This Collection")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
        ) {
            Text("This collection contains the following games:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            if !linkedGames.isEmpty {
                ForEach(linkedGames) { subGame in
                    NavigationLink(destination: GameDetailView(gameID: subGame.persistentModelID)) {
                        HStack {
                            Image(systemName: "gamecontroller.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                            Text(subGame.title)
                                .foregroundColor(.primary)
                            Spacer()
                            // Removed manual chevron
                        }
                        .padding(.vertical, 4)
                    }
                }
            } else {
                Text("No games added to this collection yet.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
            }
            // Add Game button is now outside the ForEach/VStack
            Button(action: { activeSheet = .addSubGame }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.cyan)
                    Text("Add Game to Collection")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.cyan)
            }
            .padding(.top, 4)
        }
    }
    
    var backlogDetailsSection: some View {
        Section(header: 
            HStack {
                Image(systemName: "list.bullet.clipboard.fill")
                    .foregroundColor(.red)
                Text("Backlog Details")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
        ) {
            // Game Status
            HStack {
                Image(systemName: "flag.fill")
                    .foregroundColor(.blue)
                    .font(.body)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Game Status")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Picker("", selection: $selectedStatus) { 
                        ForEach(GameStatus.allCases, id: \.self) { 
                            Text($0.rawValue).tag($0) 
                        } 
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
            }
            
            // Total Time Played
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.green)
                    .font(.body)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total Time Played")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    HStack {
                        Text(String(format: "%.2f Hours", game?.totalTimePlayed ?? 0))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Spacer()
                        Text("Auto-calculated")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Manual Time Override
            HStack {
                Image(systemName: "pencil.circle.fill")
                    .foregroundColor(.orange)
                    .font(.body)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Manual Time Override")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    TextField("Enter hours manually", text: $totalTimePlayedString)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .keyboardType(.decimalPad)
                }
            }
            
            // Start Date
            HStack {
                Image(systemName: "calendar.badge.plus")
                    .foregroundColor(.purple)
                    .font(.body)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Start Date")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    DatePicker("", selection: startDateBinding, displayedComponents: .date)
                        .labelsHidden()
                }
            }
            
            // Completion Date (only show if completed)
            if selectedStatus == .completed {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.body)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Completion Date")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        DatePicker("", selection: completionDateBinding, displayedComponents: .date)
                            .labelsHidden()
                    }
                }
            }
        }
    }
    
    var ratingSection: some View {
        Section(header: 
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("Rating")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
        ) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Your Rating")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                HStack(spacing: 4) {
                    ForEach(1..<6) { number in 
                        Image(systemName: starImageName(for: number))
                            .foregroundStyle(.yellow)
                            .font(.title2)
                            .onTapGesture { 
                                handleStarTap(for: number)
                            }
                    }
                    Spacer()
                    Text("\(String(format: "%.1f", game?.starRating ?? 0))/5")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    var hltbSection: some View {
        Section(header: 
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.indigo)
                Text("Time to Beat (HLTB)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
        ) {
            HStack(spacing: 8) {
                HLTBBox(
                    label: "Main Story", 
                    userValue: userHLTBMainBinding
                )
                .frame(width: 120, height: 90)
                
                HLTBBox(
                    label: "Main + Sides", 
                    userValue: userHLTBExtraBinding
                )
                .frame(width: 120, height: 90)
                
                HLTBBox(
                    label: "Completionist", 
                    userValue: userHLTBCompletionistBinding
                )
                .frame(width: 120, height: 90)
            }
            .frame(maxWidth: .infinity)
            .listRowInsets(EdgeInsets())
        }
    }
    
    var walkthroughSection: some View {
        Section(header: 
            HStack {
                Image(systemName: "book.closed.fill")
                    .foregroundColor(.brown)
                Text("Walkthroughs & Guides")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
        ) {
            ForEach(Array((game?.manualPDFs ?? []).enumerated()), id: \ .offset) { index, pdfData in
                Button(action: { activeSheet = .pdfViewer(index) }) {
                    Label {
                        Text("View PDF #\(index + 1)")
                    } icon: {
                        Image(systemName: "book.closed.fill")
                            .foregroundColor(.accentColor)
                            .font(.title3)
                    }
                }
            }
            .onDelete { offsets in
                game?.manualPDFs.remove(atOffsets: offsets)
            }
            Button("Add PDF") { showFileImporter = true }
            Button("Add Website Link") { activeSheet = .addLink }
            ForEach(game?.helpfulLinks ?? []) { link in
                if let url = URL(string: link.urlString) {
                    Link(destination: url) {
                        Label {
                            Text(link.name.isEmpty ? link.urlString : link.name)
                        } icon: {
                            Image(systemName: "globe")
                                .foregroundColor(.accentColor)
                                .font(.title3)
                        }
                    }
                } else {
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(.accentColor)
                            .font(.title3)
                        Text(link.name.isEmpty ? link.urlString : link.name)
                            .foregroundStyle(.secondary)
                            .strikethrough()
                    }
                }
            }.onDelete(perform: deleteLink)
        }
    }
    
    private var filteredPlayLogEntries: [PlayLogEntry] {
        switch playLogFilter {
        case .all: return game?.playLog ?? []
        case .checkpoint: return game?.playLog.filter { $0.checkpoint } ?? []
        case .normal: return game?.playLog.filter { !$0.checkpoint } ?? []
        }
    }
    
    private var filterIcon: String {
        switch playLogFilter {
        case .all: return "list.bullet"
        case .checkpoint: return "flag.checkered"
        case .normal: return "note.text"
        }
    }

    private var playLogSectionMinimal: some View {
        Section(header: 
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.green)
                Text("Play Log")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    // Cycle through filter options
                    switch playLogFilter {
                    case .all:
                        playLogFilter = .checkpoint
                    case .checkpoint:
                        playLogFilter = .normal
                    case .normal:
                        playLogFilter = .all
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: filterIcon)
                            .font(.caption)
                        Text(playLogFilter.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
            }
        ) {
            Button(action: { activeSheet = .addPlayLog }) {
                Label("Add New Play Log Entry", systemImage: "plus.circle.fill")
            }
            
            if filteredPlayLogEntries.isEmpty {
                Text("No play log entries.")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 80)
            } else {
                ForEach(filteredPlayLogEntries) { entry in
                    NavigationLink(destination: PlayLogEntryDetailView(entry: entry, onEdit: {
                        activeSheet = .playLog(.edit(entry))
                    })) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                // Date and Time
                                Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                // Checkpoint icon if applicable
                                if entry.checkpoint {
                                    Image(systemName: "flag.checkered")
                                        .foregroundColor(.orange)
                                        .font(.caption)
                                }
                            }
                            
                            // Title (or notes if no title)
                            if let title = entry.title, !title.isEmpty {
                                Text(title)
                                    .font(.headline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)
                            } else {
                                Text(entry.notes)
                                    .font(.headline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(2)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                .id(playLogRefreshID)
            }
        }
    }

    var deleteGameSection: some View {
        Section(header: 
            HStack {
                Image(systemName: "trash.fill")
                    .foregroundColor(.red)
                Text("Danger Zone")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
        ) { 
            Button("Delete Game", role: .destructive) { 
                guard let game = game else { return }
                modelContext.delete(game)
                dismiss()
            } 
        }
    }
    
    // MARK: - Helper Functions
    private func loadGame() {
        isLoading = true
        
        // Try to find the game by ID
        Task {
            do {
                // First try to find in the allGames query
                if let foundGame = allGames.first(where: { $0.persistentModelID == gameID }) {
                    await MainActor.run {
                        self.game = foundGame
                        self.isLoading = false
                        self.selectedStatus = foundGame.status
                        self.setupTextFields()
                        
                        // Defensive: treat empty includedGames as nil
                        if let included = foundGame.includedGames, included.isEmpty {
                            foundGame.includedGames = nil
                        }
                    }
                    return
                }
                
                // If not found in allGames, try direct fetch
                let descriptor = FetchDescriptor<Game>()
                let fetchedGames = try modelContext.fetch(descriptor)
                
                if let foundGame = fetchedGames.first(where: { $0.persistentModelID == gameID }) {
                    await MainActor.run {
                        self.game = foundGame
                        self.isLoading = false
                        self.selectedStatus = foundGame.status
                        self.setupTextFields()
                        
                        // Defensive: treat empty includedGames as nil
                        if let included = foundGame.includedGames, included.isEmpty {
                            foundGame.includedGames = nil
                        }
                    }
                } else {
                    // Game truly not found
                    await MainActor.run {
                        self.isLoading = false
                        print("DEBUG: Game not found with ID: \(gameID)")
                        print("DEBUG: Available games: \(fetchedGames.map { $0.title })")
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    print("DEBUG: Error loading game: \(error)")
                }
            }
        }
    }
    
    private func setupTextFields() {
        purchasePriceString = String(format: "%.2f", game?.purchasePrice ?? 0)
        msrpString = String(format: "%.2f", game?.msrp ?? 0)
        totalTimePlayedString = String(format: "%.2f", game?.manuallySetTotalTime ?? 0)
        
        // Setup game size with smart unit selection
        let sizeInMB = game?.gameSizeInMB ?? 0
        if sizeInMB >= 1024 {
            selectedSizeUnit = .gigabytes
            gameSizeString = String(format: "%.2f", sizeInMB / 1024)
        } else {
            selectedSizeUnit = .megabytes
            gameSizeString = String(format: "%.0f", sizeInMB)
        }
    }
    
    private func formatSizeConversion(_ inputValue: Double) -> String {
        switch selectedSizeUnit {
        case .megabytes:
            let gb = inputValue / 1024
            return "≈ \(String(format: "%.2f", gb)) GB"
        case .gigabytes:
            let mb = inputValue * 1024
            return "≈ \(String(format: "%.0f", mb)) MB"
        }
    }
    
    private func convertToMB(_ value: Double) -> Double {
        switch selectedSizeUnit {
        case .megabytes:
            return value
        case .gigabytes:
            return value * 1024
        }
    }
    
    private func handlePhotoSelection() {
        Task {
            if let data = try? await selectedPhoto?.loadTransferable(type: Data.self) {
                game?.customCoverArt = data
            }
        }
    }
    
    private func handleFileImport(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            let isAccessing = url.startAccessingSecurityScopedResource()
            defer { url.stopAccessingSecurityScopedResource() }
            if isAccessing, let pdfData = try? Data(contentsOf: url) {
                game?.manualPDFs.append(pdfData)
            }
        case .failure(let error):
            print("PDF ERROR: Failed to import file: \(error.localizedDescription)")
        }
    }
    
    private func handleStatusChange(to newStatus: GameStatus) {
        guard let game = game else { return }
        
        if newStatus == .completed, let subGames = game.includedGames, !subGames.isEmpty {
            let allSubGamesCompleted = subGames.allSatisfy { $0.status == .completed }
            if !allSubGamesCompleted {
                showCompletionAlert = true
                selectedStatus = game.status
            } else {
                game.status = newStatus
            }
        } else {
            game.status = newStatus
        }
    }
    
    private func addPlayLogEntry(_ entry: PlayLogEntry) { 
        modelContext.insert(entry)
        game?.playLog.insert(entry, at: 0) 
    }
    
    private func deletePlayLogEntry(at offsets: IndexSet) {
        guard let game = game else { return }
        for index in offsets { 
            let entry = game.playLog[index]
            modelContext.delete(entry) 
        }
        game.playLog.remove(atOffsets: offsets)
    }
    
    private func deleteLink(at offsets: IndexSet) {
        guard let game = game else { return }
        for index in offsets { 
            let linkToDelete = game.helpfulLinks[index]
            modelContext.delete(linkToDelete) 
        }
        game.helpfulLinks.remove(atOffsets: offsets)
    }
    
    // MARK: - Star Rating Helper Functions
    private func starImageName(for starNumber: Int) -> String {
        let currentRating = game?.starRating ?? 0
        let starNumberDouble = Double(starNumber)
        
        if currentRating >= starNumberDouble {
            return "star.fill"
        } else if currentRating >= starNumberDouble - 0.5 {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }
    
    private func handleStarTap(for starNumber: Int) {
        guard let game = game else { return }
        let currentRating = game.starRating
        let starNumberDouble = Double(starNumber)
        
        if currentRating == starNumberDouble {
            // Second tap: set to half star
            game.starRating = starNumberDouble - 0.5
        } else if currentRating == starNumberDouble - 0.5 {
            // Third tap: set to zero
            game.starRating = 0
        } else {
            // First tap: set to full star
            game.starRating = starNumberDouble
        }
    }
    
    private func checkStorage() {
        guard let game = game else { return }
        if let hardware = game.linkedHardware {
            let gameSizeGB = game.gameSizeInMB / 1000
            if hardware.availableStorageInGB < gameSizeGB {
                showStorageAlert = true
                game.isInstalled = false
                game.linkedHardware = nil // Clear the hardware association if install fails
            }
        }
    }
}

fileprivate func formatTimeInterval(_ interval: TimeInterval) -> String {
    let hours = Int(interval) / 3600
    let minutes = Int(interval) / 60 % 60
    return "\(hours)h \(minutes)m"
}

fileprivate func formatHLTB(hours: Double) -> String {
    if hours == 0 { return "N/A" }
    return String(format: "%.1f", hours) + " Hours"
}

// MARK: - Binding Helper
// Note: Custom Binding extension removed for Swift 6 compatibility

struct HLTBBox: View {
    let label: String
    @Binding var userValue: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                TextField("H", text: Binding(
                    get: { formattedInput(userValue) },
                    set: { newValue in
                        if let parsed = parseHLTBInput(newValue) {
                            userValue = parsed
                        }
                    })
                )
                .font(.headline)
                .foregroundColor(.white)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.leading)
                .accentColor(.white)
                .frame(minWidth: 30, maxWidth: 60)
                Text("H")
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 41/255, green: 121/255, blue: 183/255).opacity(0.85))
        .cornerRadius(8)
    }

    // Formats the value for display, e.g. 75.5 -> "75½"
    private func formattedInput(_ value: Double) -> String {
        if value == floor(value) {
            return String(Int(value))
        } else if value.truncatingRemainder(dividingBy: 1) == 0.5 {
            return "\(Int(value))½"
        } else {
            return String(format: "%.1f", value)
        }
    }

    // Parses input like "75½" or "75.5" to Double
    private func parseHLTBInput(_ input: String) -> Double? {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        if trimmed.hasSuffix("½") {
            let numberPart = trimmed.dropLast()
            if let intPart = Int(numberPart) {
                return Double(intPart) + 0.5
            }
        }
        return Double(trimmed.replacingOccurrences(of: ",", with: "."))
    }
}

struct PlayLogEntryDetailView: View {
    let entry: PlayLogEntry
    var onEdit: (() -> Void)?
    var onSave: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Date, Time, and Checkpoint indicators
            HStack {
                Text(entry.timestamp, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(formatTimeInterval(entry.timeSpent))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                if entry.checkpoint {
                    Label("Checkpoint", systemImage: "flag.checkered")
                        .font(.caption2.bold())
                        .foregroundColor(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                }
                Spacer()
            }
            if let title = entry.title, !title.isEmpty {
                Text(title)
                    .font(.title)
                    .padding(.bottom, 8)
            }
            Markdown(content: .constant(entry.notes))
                .font(.body)
                .padding()
        }
        .padding()
        .navigationTitle("Play Log Entry")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if let onEdit = onEdit {
                    Button("Edit") { onEdit() }
                }
            }
        }
    }
}

// Add this struct near the bottom of the file or after PlayLogEntryDetailView
struct PlayLogRow: View {
    let entry: PlayLogEntry
    let onEdit: () -> Void

    var body: some View {
        NavigationLink(destination: PlayLogEntryDetailView(entry: entry, onEdit: { onEdit() })) {
            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(entry.timestamp, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatTimeInterval(entry.timeSpent))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        if entry.checkpoint {
                            Label("Checkpoint", systemImage: "flag.checkered")
                                .font(.caption2.bold())
                                .foregroundColor(.blue)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(6)
                        }
                        Spacer()
                    }
                    if let title = entry.title, !title.isEmpty {
                        Text(title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }
                }
                Spacer()
            }
            .padding(10)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Shared Helper Functions
