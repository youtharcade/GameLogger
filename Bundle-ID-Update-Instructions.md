# GameLoggr Rebrand: Bundle ID & Project Updates

## Overview

This document outlines the steps needed to complete the rebrand from "GameLogger" to "GameLoggr" in your Xcode project. The code files have been updated, but you'll need to make these changes in Xcode itself.

## Required Xcode Changes

### 1. Update Bundle Identifier

**Current**: `com.justingain.GameLogger`  
**New**: `com.justingain.GameLoggr`

#### Steps:
1. Open your project in Xcode
2. Select your project file in the navigator
3. Select the **GameLoggr** target (you may need to rename the target first)
4. Go to **General** tab
5. Under **Identity**, change:
   - **Bundle Identifier**: `com.justingain.GameLoggr`

### 2. Update Display Name

#### Steps:
1. In the **General** tab, under **Identity**
2. Change **Display Name** to: `GameLoggr`
3. This is what users will see on their home screen

### 3. Rename Target (Optional but Recommended)

#### Steps:
1. In the project navigator, click on your target name
2. Press Enter to rename it
3. Change from "GameLogger" to "GameLoggr"
4. Xcode will ask if you want to rename the scheme - choose **Rename**

### 4. Update Scheme Name

#### Steps:
1. Go to **Product** → **Scheme** → **Manage Schemes**
2. Double-click your scheme name
3. Change the name to "GameLoggr"
4. Click **Close**

### 5. Update App Icons and Launch Screen (If Needed)

If your app icons or launch screen contain the "GameLogger" text:
1. Go to **Assets.xcassets**
2. Update any images that show the old name
3. Create new icon variants if needed

## Apple Developer Console Updates

### 1. Create New App Identifier

Since you're changing the bundle ID, you'll need a new App ID:

#### Steps:
1. Go to [Apple Developer Console](https://developer.apple.com)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Select **Identifiers**
4. Click **+** to create new identifier
5. Choose **App IDs**
6. Fill in:
   - **Description**: GameLoggr
   - **Bundle ID**: `com.justingain.GameLoggr`
7. Enable capabilities:
   - ☑️ **iCloud**
   - ☑️ **Push Notifications**

### 2. Create New CloudKit Container

#### Option A: Create New Container (Recommended for Clean Start)
1. In Developer Console, go to **CloudKit Console**
2. Click **+** to create new container
3. Name it: `iCloud.com.justingain.GameLoggr`
4. This will start fresh (users will need to re-sync data)

#### Option B: Rename Existing Container (If Possible)
1. Check if Apple allows container renaming
2. This would preserve existing user data
3. May not be available - Apple typically doesn't allow this

### 3. Update Provisioning Profiles

1. Delete old provisioning profiles for the GameLogger bundle ID
2. Create new ones for the GameLoggr bundle ID
3. Download and install them in Xcode

## App Store Connect Updates

### 1. Create New App Record

Since bundle IDs are unique, you'll need a new app record:

#### Steps:
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click **My Apps** → **+** → **New App**
3. Fill in:
   - **Platform**: iOS
   - **Name**: GameLoggr
   - **Primary Language**: English
   - **Bundle ID**: `com.justingain.GameLoggr`
   - **SKU**: `gameloggr-ios-2025`

**Note**: You cannot reuse the same app name if you had "GameLogger" previously published. Consider variations like:
- "GameLoggr - Game Collection"
- "GameLoggr: Game Tracker"
- Or wait for the old app to be removed

### 2. Transfer Metadata (If Applicable)

If you had an existing GameLogger app:
1. Copy description, keywords, screenshots from old app
2. Update any text references to use "GameLoggr"
3. Consider if you want to keep both apps or replace the old one

## Testing Checklist

After making these changes:

### Build & Test
- ☑️ App builds without errors
- ☑️ Bundle ID is correct in built app
- ☑️ Display name shows as "GameLoggr"
- ☑️ App icon displays correctly
- ☑️ All functionality works as expected

### iCloud Sync Testing
- ☑️ New CloudKit container is created
- ☑️ Data syncs between devices
- ☑️ No conflicts with old GameLogger data

### Archive & Upload
- ☑️ Archive builds successfully
- ☑️ Upload to TestFlight works
- ☑️ No bundle ID conflicts

## Data Migration Considerations

### For Existing Users

If you had users with the old GameLogger app:

#### Option 1: Fresh Start
- New bundle ID = new app
- Users would need to download new app
- Data doesn't automatically transfer
- Cleaner approach, no legacy issues

#### Option 2: Export/Import Feature
- Add data export feature to old app
- Add data import feature to new app
- Users can manually transfer their data
- More user-friendly but requires development

#### Option 3: CloudKit Migration
- Complex process involving server-side migration
- Usually not worth the effort for indie apps
- Consider only for large user bases

## Recommended Approach

For an indie app like GameLoggr:

1. **Fresh Start**: Create everything new with GameLoggr branding
2. **Clean Slate**: New bundle ID, new CloudKit container
3. **Simple Launch**: Focus on new users rather than complex migration
4. **Version 1.0**: Treat this as your official launch

## Timeline Considerations

- **Development**: 1-2 hours to make Xcode changes
- **Testing**: 1-2 days to thoroughly test new configuration
- **App Store Review**: 1-7 days for approval
- **Launch**: Coordinate launch timing if replacing existing app

## Files Already Updated ✅

The following files have been updated with GameLoggr branding:
- `GameLogger.entitlements` - CloudKit container updated
- `iCloud-Setup-Guide.md` - All references updated
- `Privacy-Policy-Template.md` - Branding updated
- `Models-Documentation.md` - App name updated
- `GameDetailView-Documentation.md` - App name updated

## Next Steps

1. **Make Xcode Changes**: Follow the steps above to update your project
2. **Test Thoroughly**: Ensure everything builds and runs correctly
3. **Update Developer Console**: Create new identifiers and containers
4. **Update App Store Connect**: Create new app record
5. **Upload to TestFlight**: Test the complete rebrand
6. **Launch**: Submit for App Store review when ready

The rebrand is now complete in the code - the Xcode project configuration is the final step! 