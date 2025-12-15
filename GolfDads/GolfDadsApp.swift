//
//  GolfDadsApp.swift
//  GolfDads
//
//  Created by Mark Miranda on 11/24/25.
//

import SwiftUI

@main
struct GolfDadsApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var deepLinkHandler = DeepLinkHandler()
    @StateObject private var calendarSyncManager = CalendarSyncManager()
    @StateObject private var notificationManager = NotificationManager.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(deepLinkHandler)
                .environmentObject(calendarSyncManager)
                .environmentObject(notificationManager)
                .onOpenURL { url in
                    deepLinkHandler.handle(url: url)
                }
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    if newPhase == .active {
                        // App became active - check calendar permission
                        Task {
                            await calendarSyncManager.checkPermission()
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .navigateToTeeTime)) { notification in
                    // Handle navigation from push notification tap
                    if let teeTimeId = notification.userInfo?["teeTimeId"] as? Int {
                        deepLinkHandler.navigateToTeeTime(id: teeTimeId)
                    }
                }
                .alert("Group Invitation", isPresented: $deepLinkHandler.showJoinGroupAlert) {
                    Button("OK") {
                        deepLinkHandler.showJoinGroupAlert = false
                    }
                } message: {
                    if let message = deepLinkHandler.alertMessage {
                        Text(message)
                    }
                }
        }
    }
}
