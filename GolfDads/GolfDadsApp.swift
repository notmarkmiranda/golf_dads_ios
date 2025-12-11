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

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(deepLinkHandler)
                .onOpenURL { url in
                    deepLinkHandler.handle(url: url)
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
