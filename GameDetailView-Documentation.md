# GameDetailView Documentation

## Overview

The `GameDetailView.swift` file defines the main detail screen for viewing and editing individual games in the GameLoggr app. This is one of the most complex views in the app, containing over 1800 lines of code and handling everything from basic game information to advanced features like play logging, file management, and external integrations.

## Key Technologies Used

### SwiftUI Framework
- **What it is**: Apple's modern UI framework for building user interfaces
- **Key components used**:
  - `Form`: Main container for structured input fields
  - `Section`: Groups related form elements with headers
  - `NavigationView`: Handles navigation and toolbar items
  - `Sheet`: Modal presentations for additional views
  - `Binding`: Two-way data connections between UI and data

### SwiftData Integration
- **Environment objects**: `@Environment(\.modelContext)` for database operations
- **Queries**: `@Query` for fetching related data (platforms, hardware, games)
- **State management**: Direct manipulation of SwiftData objects

### External Integrations
- **PhotosPicker**: For selecting custom cover art from photo library
- **PDFKit**: For viewing imported game manuals
- **URL schemes**: Deep linking to Spotify and Apple Music

## Architecture Overview

### Data Flow Pattern
The view follows a **unidirectional data flow** pattern:
1. **Input**: User interacts with UI elements
2. **State Update**: Binding updates the underlying data model
3. **UI Refresh**: SwiftUI automatically refreshes affected UI components
4. **Persistence**: SwiftData automatically saves changes to the database

### Initialization Strategy
The view uses a flexible initialization pattern:
- Primary initializer takes `PersistentIdentifier` (recommended)
- Convenience initializer takes `Game` object (backward compatibility)
- Lazy loading of the actual game object using `@State`

## State Management

### Core State Properties
- `@State private var game: Game?`: The main game object being displayed/edited
- `@State private var isLoading`: Loading state for async game fetching
- `@State private var selectedStatus`: Current game playing status
- `@State private var activeSheet`: Controls which modal sheet is presented

### Text Field State
The view maintains separate string states for numeric inputs to provide better user experience:
- `purchasePriceString`: String representation of purchase price
- `msrpString`: String representation of MSRP
- `totalTimePlayedString`: Manual time override input
- `gameSizeString`: Digital game size input

### Complex Bindings
Due to SwiftUI's binding requirements, the view creates numerous computed binding properties:
```swift
private var titleBinding: Binding<String>
private var platformBinding: Binding<Platform?>
private var ownershipStatusBinding: Binding<OwnershipStatus>
```

## Major UI Sections

### 1. Cover Art Section
- **Purpose**: Display and edit game cover art
- **Features**: 
  - Shows custom cover art or fetched cover art from IGDB
  - PhotosPicker integration for custom images
  - Aspect ratio preservation (3:4)
- **Data**: Uses `@Attribute(.externalStorage)` for image data

### 2. Game Information Section
- **Purpose**: Basic game metadata display
- **Content**: Release date, genres, developers, publishers
- **Special feature**: Links to parent collection for sub-games

### 3. Collection Details Section
- **Purpose**: Core game identification and categorization
- **Components**:
  - Game title (editable)
  - Platform selection (searchable)
  - Ownership status picker
  - Physical/Digital toggle buttons
  - Individual/Collection type selector

### 4. Purchase Information Section
- **Purpose**: Financial and acquisition tracking
- **Features**: Custom date/price input boxes
- **Components**: `PurchaseInfoBox` and `ReleaseInfoBox` custom views

### 5. Physical/Digital Specific Sections
- **Physical Edition**:
  - Component selector grid (Case, Manual, Inserts, Sealed)
  - Collector's grade computation and display
- **Digital Edition**:
  - Game size input with MB/GB conversion
  - Installation status toggle
  - Hardware association for storage management

### 6. Collection Games Section
- **Purpose**: Manage games within collections
- **Features**:
  - List of included sub-games
  - Navigation to sub-game details
  - Add new games to collection

### 7. Backlog Details Section
- **Purpose**: Progress tracking and status management
- **Components**:
  - Game status picker
  - Total time played display
  - Manual time override
  - Start/completion date pickers

### 8. Rating Section
- **Purpose**: User rating input
- **Features**: Interactive 5-star rating system with half-star support
- **Interaction**: Tap once for full star, twice for half star, thrice to clear

### 9. HLTB (How Long To Beat) Section
- **Purpose**: Time estimation tracking
- **Components**: Three custom `HLTBBox` views for different completion types
- **Features**: Smart input parsing (supports "75½" format)

### 10. Walkthroughs & Guides Section
- **Purpose**: Reference material management
- **Features**:
  - PDF import and viewing
  - Web link management
  - External PDF viewer integration

### 11. Play Log Section
- **Purpose**: Gaming session tracking
- **Features**:
  - Filterable entry list (All/Checkpoints/Normal)
  - Add new play sessions
  - View/edit existing entries
  - Navigation to detailed entry views

### 12. Music Integration Section
- **Purpose**: Soundtrack discovery
- **Features**: Direct links to Spotify and Apple Music searches
- **Implementation**: URL scheme handling with fallback to web versions

### 13. Danger Zone Section
- **Purpose**: Destructive operations
- **Feature**: Game deletion with immediate dismissal

## Sheet Management System

### ActiveSheet Enum
Centralizes all modal presentation logic:
```swift
enum ActiveSheet: Identifiable {
    case playLog(PlayLogSheetMode)
    case addPlayLog
    case addSubGame
    case addLink
    case platformSearch
    case pdfViewer(Int)
}
```

### Sheet Presentation Pattern
- Uses `@State private var activeSheet: ActiveSheet?`
- Single `.sheet(item: $activeSheet)` modifier handles all modals
- Switch statement routes to appropriate view

## Data Binding Strategies

### String-to-Number Conversion
For better user experience with numeric inputs:
1. Maintain string state for text fields
2. Use `onChange` modifiers to convert and update model
3. Format display values appropriately (currency, decimals, units)

### Complex Computed Bindings
For nested object properties:
```swift
private var platformBinding: Binding<Platform?> {
    Binding(
        get: { game?.platform },
        set: { newValue in 
            guard let game = game else { return }
            game.platform = newValue 
        }
    )
}
```

## Custom UI Components

### ComponentSelectorView
- **Purpose**: Toggle buttons for physical game components
- **Usage**: Case, Manual, Inserts, Sealed status
- **Design**: Grid layout with consistent styling

### HLTBBox
- **Purpose**: Time input with special formatting
- **Features**: Supports fractional hours with "½" symbol
- **Styling**: Blue background with white text

### PurchaseInfoBox & ReleaseInfoBox
- **Purpose**: Compact date/price display
- **Layout**: Side-by-side information boxes

## Performance Considerations

### Query Optimization
- Uses targeted `@Query` for specific data needs
- Avoids fetching unnecessary related objects
- Implements lazy loading for the main game object

### State Updates
- Minimizes unnecessary UI refreshes through targeted bindings
- Uses computed properties for derived values
- Implements efficient filtering for play log entries

### Memory Management
- External storage for large data (images, PDFs)
- Proper cleanup of file access permissions
- Efficient image loading and caching

## Common Troubleshooting Scenarios

### Sheet Not Appearing
1. Check that `activeSheet` is being set correctly
2. Verify the `ActiveSheet` enum case exists
3. Ensure the sheet modifier is properly configured
4. Check for competing sheet presentations

### Bindings Not Updating
1. Verify the game object is loaded (`game != nil`)
2. Check binding getter/setter logic
3. Ensure proper `@State` vs `@Binding` usage
4. Look for race conditions during game loading

### Performance Issues
1. Check for excessive `@Query` usage
2. Look for complex computed properties in body
3. Verify efficient list rendering for large play logs
4. Monitor external storage access patterns

### Navigation Problems
1. Ensure `PersistentIdentifier` is valid
2. Check navigation stack management
3. Verify dismissal logic in sheets
4. Look for memory leaks in navigation

### Data Persistence Issues
1. Verify `modelContext.save()` is called when needed
2. Check for proper error handling in save operations
3. Ensure relationship consistency
4. Look for concurrent modification issues

## Integration Points

### File System Integration
- **PDF Import**: Uses `fileImporter` modifier with `.pdf` content type
- **Photo Selection**: PhotosPicker with `Data` transfer type
- **Security**: Proper security-scoped resource access

### External App Integration
- **Music Services**: URL scheme with fallback logic
- **Deep Linking**: Handles both app-specific and web URLs
- **Platform Detection**: Checks `canOpenURL` before attempting

### Database Integration
- **CRUD Operations**: Create, read, update, delete through SwiftData
- **Relationship Management**: Handles complex parent/child relationships
- **Query Performance**: Optimized fetch descriptors

## Usage Patterns

### Creating New Games
The view supports both standalone games and sub-games within collections:
```swift
// Standalone game
GameDetailView(gameID: game.persistentModelID)

// Sub-game with parent collection
AddGameView(parentGame: parentCollection)
```

### Navigation Patterns
- **From Lists**: Pass `PersistentIdentifier` for efficient loading
- **From Search**: Create new games then navigate to detail
- **Between Related**: Navigate between collection and sub-games

### State Management Best Practices
1. Load game asynchronously on appear
2. Use defensive coding for optional game object
3. Implement proper error handling for missing games
4. Maintain UI responsiveness during loading

## File Structure Context

This view integrates with multiple other components:
- **Models**: Uses all data models from `Models.swift`
- **Services**: Integrates with `IGDBClient.swift` for game data
- **Shared Components**: Uses various shared UI components
- **Detail Views**: Presents specialized detail views for play logs
- **Add Views**: Presents add/edit views for various data types

## Future Maintenance Considerations

### Code Organization
- Consider breaking large sections into separate view files
- Extract complex computed properties to extensions
- Move shared logic to dedicated helper classes

### Performance Optimization
- Monitor for SwiftUI performance antipatterns
- Consider lazy loading for complex sections
- Implement virtualization for large lists

### Testing Strategy
- Unit tests for complex computed properties
- Integration tests for data persistence
- UI tests for critical user flows
- Performance tests for large datasets

The GameDetailView serves as the central hub for game management in the app, handling everything from basic information display to complex file management and external integrations. Understanding its structure and patterns is crucial for maintaining and extending the app's functionality. 