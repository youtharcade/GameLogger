# GameLoggr Models Documentation

## Overview

The `Models.swift` file defines the core data structure for the GameLoggr app. It uses **SwiftData**, Apple's modern data persistence framework, to manage data storage and relationships. Think of this file as the blueprint that describes what information the app can store and how different pieces of data relate to each other.

## Key Technologies Used

### SwiftData
- **What it is**: Apple's framework for data persistence (saving and retrieving data)
- **Key decorators**:
  - `@Model`: Marks a class as a data model that can be saved to the database
  - `@Attribute`: Customizes how individual properties are stored
  - `@Relationship`: Defines how different models connect to each other

## Enums (Data Categories)

### GameStatus
Represents the current playing status of a game:
- `backlog`: Game owned but not started
- `inProgress`: Currently playing
- `completed`: Finished the game
- `onHold`: Started but paused indefinitely
- `dropped`: Started but abandoned

### OwnershipStatus
Tracks the physical/digital ownership state:
- `owned`: Currently in collection
- `sold`: Previously owned but sold
- `lentOut`: Owned but temporarily given to someone else

## Core Models

### 1. Game (Primary Model)
The central model representing a video game entry. Contains extensive information about each game.

#### Core Properties
- `title`: Game name
- `coverArtURL`: Link to cover art image
- `platform`: What system the game runs on (PlayStation, Xbox, etc.)
- `purchaseDate`: When the game was acquired
- `isDigital`: Whether it's a digital or physical copy
- `purchasePrice`/`msrp`: Cost information

#### Status & Progress Tracking
- `statusValue`: Current playing status (stored as string, converted to enum)
- `startDate`/`completionDate`: When gameplay began/ended
- `playLog`: Collection of individual play sessions

#### External Data (from IGDB - Internet Game Database)
- `hltbMain`/`hltbExtra`/`hltbCompletionist`: How Long To Beat completion times
- `releaseDate`: Official release date
- `genresString`/`developersString`/`publishersString`: Metadata stored as comma-separated strings

#### User Tracking
- `manuallySetTotalTime`: User-entered total play time (overrides calculated time)
- `starRating`: User's rating of the game
- `userHLTB*`: User's personal completion times

#### Physical Collection Data
- `hasCase`/`hasManual`/`hasInserts`/`isSealed`: Physical condition tracking
- `collectorsGrade`: Computed property that determines condition rating

#### Digital-Specific Data
- `isInstalled`: Whether digital game is currently installed
- `gameSizeInMB`: Storage space used

#### Relationships
- `playLog`: Array of individual play sessions
- `linkedHardware`: What console/device this game belongs to
- `parentCollection`: For games that are part of a collection
- `includedGames`: For collection games that contain other games
- `helpfulLinks`: Walkthrough and guide URLs

#### Key Computed Properties
- `status`: Converts string to GameStatus enum
- `totalTimePlayed`: Calculates total hours played (manual override or sum of play sessions)
- `genres`/`developers`/`publishers`: Converts comma-separated strings to arrays
- `overlayIcon`: Determines what icon to show on game covers

### 2. PlayLogEntry
Individual gaming session records linked to games.

- `timestamp`: When the session occurred
- `timeSpent`: Duration in seconds
- `notes`: User notes about the session
- `checkpoint`: Whether this was a significant progress point
- `title`: Optional name for the session
- `game`: Which game this session belongs to

### 3. Platform
Represents gaming systems (PlayStation 5, Nintendo Switch, etc.).

- `id`: Unique identifier (matches IGDB database)
- `name`: Human-readable platform name
- `logoURL`: Link to platform logo image
- `hardware`: Array of physical consoles for this platform

### 4. Hardware
Physical gaming consoles/devices owned by the user.

- `name`: Custom name for the device
- `platform`: What type of system this is
- `serialNumber`: Device identifier
- `purchasePrice`/`msrp`/`purchaseDate`: Acquisition details
- `internalStorageInGB`/`externalStorageInGB`: Storage capacity
- `linkedGames`: Games associated with this device
- Storage calculations: `totalStorageInGB`, `usedStorageInGB`, `availableStorageInGB`

### 5. HelpfulLink
URLs for guides, walkthroughs, or other game-related resources.

- `name`: Display name for the link
- `urlString`: The actual URL
- `game`: Which game this link helps with

## Data Relationships Explained

### One-to-Many Relationships
- **Game → PlayLogEntry**: One game can have many play sessions
- **Platform → Hardware**: One platform type can have multiple physical consoles
- **Game → HelpfulLink**: One game can have multiple helpful links

### One-to-One Relationships
- **Game → Hardware**: Each game copy is linked to one specific console
- **Game → Platform**: Each game copy runs on one specific platform

### Hierarchical Relationships
- **Game Collections**: Some games can contain other games (parent → children)
- **Sub-games**: Individual games can be part of a larger collection

## Special SwiftData Features Used

### External Storage
Large data like images and PDFs are stored using `@Attribute(.externalStorage)`:
- `customCoverArt`: Custom cover art images
- `manualPDFsData`: Digital game manuals
- `imageData` (Hardware): Photos of consoles

### Cascade Delete Rules
When deleting records, related data is automatically removed:
- Delete a game → all its play log entries are deleted
- Delete a game → all its helpful links are deleted

### Unique Attributes
Prevents duplicate records:
- Game IDs are unique
- Platform IDs are unique

## Common Troubleshooting Scenarios

### Data Not Saving
1. Check that classes are marked with `@Model`
2. Verify relationships use proper inverse declarations
3. Ensure the model context is properly configured in the app

### Relationship Issues
1. Make sure both sides of relationships are properly defined
2. Check that `@Relationship(inverse: \...)` points to the correct property
3. Verify cascade delete rules are appropriate

### Performance Issues
1. Large arrays in computed properties (like `totalTimePlayed`) recalculate frequently
2. External storage attributes may cause loading delays
3. Complex relationship queries can be slow

### Data Migration
When changing model structure:
1. Properties can be added easily
2. Removing properties requires careful consideration
3. Changing property types may require migration code

## Usage Patterns

### Creating New Games
```swift
let newGame = Game(
    title: "Example Game",
    platform: selectedPlatform,
    purchaseDate: Date(),
    isDigital: true,
    purchasePrice: 59.99,
    msrp: 59.99,
    status: .backlog
)
```

### Querying Data
The app uses SwiftData queries to filter and sort:
- Games by status (backlog, completed, etc.)
- Games by platform
- Games by ownership status
- Hardware by platform

### Updating Relationships
When connecting games to hardware or adding play log entries, both sides of the relationship are automatically maintained due to the inverse declarations.

## File Structure Context
This models file works with:
- **Views**: SwiftUI views display and edit this data
- **Services**: IGDBClient.swift fetches external game data
- **App**: GameLoggrApp.swift sets up the data container
- **Extensions**: Bundle+Decodable.swift helps load static data

The models serve as the foundation that all other parts of the app build upon. 