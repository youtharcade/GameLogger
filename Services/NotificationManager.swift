//
//  NotificationManager.swift
//  GameLoggr
//
//  Created by Justin Gain on 7/18/25.
//

import Foundation
import UserNotifications
import SwiftData

/// Manages local notifications for GameLoggr
class NotificationManager: ObservableObject {
    
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    private init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    /// Check current notification authorization status
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    /// Request notification permissions
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            
            await MainActor.run {
                self.isAuthorized = granted
                self.authorizationStatus = granted ? .authorized : .denied
            }
            
            return granted
        } catch {
            print("Failed to request notification authorization: \(error)")
            return false
        }
    }
    
    // MARK: - Game Release Reminders
    
    /// Schedule a release reminder for a game
    func scheduleReleaseReminder(for game: Game, daysBeforeRelease: Int = 1) {
        guard isAuthorized else {
            print("Notifications not authorized")
            return
        }
        
        let releaseDate = game.releaseDate
        let reminderDate = Calendar.current.date(byAdding: .day, value: -daysBeforeRelease, to: releaseDate)
        
        guard let reminderDate = reminderDate, reminderDate > Date() else {
            print("Release date is in the past or reminder date is invalid")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Game Release Reminder"
        content.body = "\(game.title) releases \(daysBeforeRelease == 1 ? "tomorrow" : "in \(daysBeforeRelease) days")!"
        content.sound = .default
        content.badge = 1
        
        // Add game information to user info for handling when tapped
        content.userInfo = [
            "gameID": game.id,
            "gameTitle": game.title,
            "releaseDate": ISO8601DateFormatter().string(from: releaseDate),
            "notificationType": "gameRelease"
        ]
        
        // Create calendar-based trigger
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        // Create request with unique identifier
        let identifier = "gameRelease_\(game.id)_\(daysBeforeRelease)days"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Schedule notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule release reminder: \(error)")
            } else {
                print("Scheduled release reminder for \(game.title) on \(reminderDate)")
            }
        }
    }
    
    /// Cancel release reminder for a specific game
    func cancelReleaseReminder(for gameID: String, daysBeforeRelease: Int = 1) {
        let identifier = "gameRelease_\(gameID)_\(daysBeforeRelease)days"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        print("Cancelled release reminder for game: \(gameID)")
    }
    
    /// Cancel all release reminders for a game
    func cancelAllReleaseReminders(for gameID: String) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiersToRemove = requests
                .filter { $0.identifier.hasPrefix("gameRelease_\(gameID)_") }
                .map { $0.identifier }
            
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
            print("Cancelled all release reminders for game: \(gameID)")
        }
    }
    
    /// Schedule reminders for all wishlisted games with future release dates
    func scheduleRemindersForWishlistedGames(games: [Game]) {
        let wishlistedGames = games.filter { $0.isWishlisted && $0.releaseDate > Date() }
        
        for game in wishlistedGames {
            // Schedule 1 day and 1 week before release
            scheduleReleaseReminder(for: game, daysBeforeRelease: 1)
            scheduleReleaseReminder(for: game, daysBeforeRelease: 7)
        }
        
        print("Scheduled reminders for \(wishlistedGames.count) wishlisted games")
    }
    
    // MARK: - Backlog Reminders
    
    /// Schedule a reminder to check backlog
    func scheduleBacklogReminder(intervalDays: Int = 7) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Gaming Time!"
        content.body = "You have games in your backlog waiting to be played. Check out what's next!"
        content.sound = .default
        content.badge = 1
        content.userInfo = ["notificationType": "backlogReminder"]
        
        // Schedule weekly reminder
        var dateComponents = DateComponents()
        dateComponents.weekday = 6 // Friday
        dateComponents.hour = 18   // 6 PM
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "backlogReminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule backlog reminder: \(error)")
            } else {
                print("Scheduled weekly backlog reminder")
            }
        }
    }
    
    /// Cancel backlog reminders
    func cancelBacklogReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["backlogReminder"])
    }
    
    // MARK: - Automatic Scheduling Helpers
    
    /// Call this when a game is added to wishlist to schedule reminders
    func onGameAddedToWishlist(_ game: Game) {
        // Only schedule if user has enabled release reminders
        guard UserDefaults.standard.bool(forKey: "enableReleaseReminders") else { return }
        
        let reminderDays = UserDefaults.standard.integer(forKey: "releaseReminderDays")
        
        switch reminderDays {
        case 0: // Both 1 day and 1 week
            scheduleReleaseReminder(for: game, daysBeforeRelease: 1)
            scheduleReleaseReminder(for: game, daysBeforeRelease: 7)
        case 1, 3, 7: // Specific number of days
            scheduleReleaseReminder(for: game, daysBeforeRelease: reminderDays)
        default:
            scheduleReleaseReminder(for: game, daysBeforeRelease: 1) // Default to 1 day
        }
    }
    
    /// Call this when a game is removed from wishlist to cancel reminders
    func onGameRemovedFromWishlist(_ game: Game) {
        cancelAllReleaseReminders(for: game.id)
    }
    
    // MARK: - Notification Management
    
    /// Get all pending notifications
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await UNUserNotificationCenter.current().pendingNotificationRequests()
    }
    
    /// Clear all notifications
    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        print("Cleared all notifications")
    }
    
    /// Handle notification tap (call from AppDelegate or SceneDelegate)
    func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        guard let notificationType = userInfo["notificationType"] as? String else { return }
        
        switch notificationType {
        case "gameRelease":
            if let gameTitle = userInfo["gameTitle"] as? String {
                print("User tapped release reminder for: \(gameTitle)")
                // Handle navigation to game detail or wishlist
            }
        case "backlogReminder":
            print("User tapped backlog reminder")
            // Handle navigation to backlog view
        default:
            print("Unknown notification type: \(notificationType)")
        }
    }
}

// MARK: - Notification Settings Helper
extension NotificationManager {
    
    /// Get user-friendly authorization status description
    var authorizationStatusDescription: String {
        switch authorizationStatus {
        case .notDetermined:
            return "Not Set"
        case .denied:
            return "Denied"
        case .authorized:
            return "Authorized"
        case .provisional:
            return "Provisional"
        case .ephemeral:
            return "Ephemeral"
        @unknown default:
            return "Unknown"
        }
    }
    
    /// Check if we can schedule notifications
    var canScheduleNotifications: Bool {
        return authorizationStatus == .authorized || authorizationStatus == .provisional
    }
}
