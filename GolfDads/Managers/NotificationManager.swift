//
//  NotificationManager.swift
//  GolfDads
//
//  Created by Claude Code on 12/13/24.
//

import Foundation
import UIKit
import Combine
import UserNotifications
import FirebaseMessaging

@MainActor
class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()

    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var deviceToken: String?

    private let networkService: NetworkService
    private let center = UNUserNotificationCenter.current()

    override init() {
        self.networkService = NetworkService.shared
        super.init()

        // Set messaging delegate
        Messaging.messaging().delegate = self

        // Check current authorization status
        Task {
            await checkAuthorizationStatus()
        }

        // Listen for app becoming active to refresh notification status
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    @objc private func appDidBecomeActive() {
        Task {
            await checkAuthorizationStatus()
        }
    }

    // MARK: - Authorization

    /// Request notification permissions from the user
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            await checkAuthorizationStatus()
            return granted
        } catch {
            print("❌ Failed to request authorization: \(error)")
            return false
        }
    }

    /// Check current notification authorization status
    func checkAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus

        // If authorized, register for remote notifications
        if settings.authorizationStatus == .authorized {
            await registerForRemoteNotifications()
        }
    }

    /// Register for remote notifications (called from AppDelegate)
    @MainActor
    private func registerForRemoteNotifications() async {
        await UIApplication.shared.registerForRemoteNotifications()
    }

    // MARK: - Device Token Handling

    /// Called when APNs device token is received
    func didRegisterForRemoteNotifications(deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("📱 APNs Device Token: \(token)")

        // Firebase will automatically map APNs token to FCM token
        // We'll get the FCM token in the messaging delegate
    }

    /// Called when registration fails
    func didFailToRegisterForRemoteNotifications(error: Error) {
        print("❌ Failed to register for remote notifications: \(error)")
    }

    /// Register FCM token with backend
    private func registerTokenWithBackend(_ token: String) {
        Task {
            do {
                try await networkService.registerDeviceToken(token: token, platform: "ios")
                print("✅ Device token registered with backend")
            } catch {
                print("❌ Failed to register device token: \(error)")
            }
        }
    }

    // MARK: - Notification Handling

    /// Handle notification when app is in foreground
    func handleForegroundNotification(
        _ notification: UNNotification,
        completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        print("📬 Received notification in foreground: \(userInfo)")

        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    /// Handle notification tap (when user taps on notification)
    func handleNotificationTap(_ response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo
        print("👆 User tapped notification: \(userInfo)")

        // Extract notification data
        if let notificationType = userInfo["type"] as? String,
           let teeTimeId = userInfo["tee_time_id"] as? Int {

            print("🔔 Notification type: \(notificationType), Tee Time ID: \(teeTimeId)")

            // Post notification for navigation
            NotificationCenter.default.post(
                name: .navigateToTeeTime,
                object: nil,
                userInfo: ["teeTimeId": teeTimeId]
            )
        }
    }
}

// MARK: - MessagingDelegate

extension NotificationManager: MessagingDelegate {
    /// Called when FCM token is refreshed
    nonisolated func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else { return }

        print("🔥 FCM Token: \(fcmToken)")

        Task { @MainActor in
            self.deviceToken = fcmToken
            self.registerTokenWithBackend(fcmToken)
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let navigateToTeeTime = Notification.Name("navigateToTeeTime")
}
