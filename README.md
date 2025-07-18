# GameLogger

A comprehensive iOS app for tracking and managing your video game collection built with SwiftUI and SwiftData.

## Features

### Game Collection Management
- Add games from IGDB database or manually
- Track purchase information (price, date, platform)
- Manage digital and physical game collections
- Support for game collections and sub-games

### Backlog & Progress Tracking
- Track game status (Backlog, In Progress, Completed, On Hold, Dropped)
- Log playtime with detailed session tracking
- Set completion dates and track progress
- Rate games with 5-star rating system

### Hardware Integration
- Track gaming hardware and storage
- Link digital games to specific hardware
- Monitor storage usage and available space

### Wishlist & Organization
- Maintain a wishlist of games to purchase
- Filter and search through your collection
- View games by platform, status, or custom filters

### Statistics & Analytics
- View collection statistics and insights
- Track spending and collection value
- Analyze playtime patterns
- Visual charts and summaries

## Technical Details

- **Platform**: iOS 18.5+
- **Framework**: SwiftUI
- **Database**: SwiftData
- **External API**: IGDB (Internet Game Database)
- **Dependencies**: 
  - SwiftUI Markdown for rich text display

## Requirements

- iOS 18.5 or later
- Xcode 16.0 or later
- Swift 5.0 or later

## Getting Started

1. Clone the repository
2. Open `GameLogger.xcodeproj` in Xcode
3. Build and run the project

## Architecture

The app follows a clean SwiftUI architecture with:
- **Models**: SwiftData models for Core Data persistence
- **Views**: SwiftUI views organized by feature
- **Services**: External API clients and data services
- **Extensions**: Utility extensions for common functionality

## Contributing

Feel free to contribute to this project by submitting issues or pull requests.

## License

This project is available under the MIT License. 