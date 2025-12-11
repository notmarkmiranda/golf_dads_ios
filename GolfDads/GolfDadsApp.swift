//
//  GolfDadsApp.swift
//  GolfDads
//
//  Created by Mark Miranda on 11/24/25.
//

import SwiftUI

@main
struct GolfDadsApp: App {

    @StateObject private var deepLinkHandler = DeepLinkHandler()
    @StateObject private var calendarSyncManager = CalendarSyncManager()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(deepLinkHandler)
                .environmentObject(calendarSyncManager)
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
