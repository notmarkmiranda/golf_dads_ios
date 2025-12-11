//
//  DeepLinkHandler.swift
//  GolfDads
//
//  Handles deep links for group invitations and other app features
//

import SwiftUI
import Combine

@MainActor
class DeepLinkHandler: ObservableObject {

    @Published var pendingInviteCode: String?
    @Published var showJoinGroupAlert = false
    @Published var alertMessage: String?

    private let groupService: GroupServiceProtocol

    init(groupService: GroupServiceProtocol = GroupService()) {
        self.groupService = groupService
    }

    /// Handle incoming URL
    func handle(url: URL) {
        print("🔗 Deep link received: \(url.absoluteString)")

        // Parse the URL
        guard url.scheme == "threeputt" else {
            print("❌ Invalid URL scheme: \(url.scheme ?? "nil")")
            return
        }

        // Handle different paths
        if url.host == "groups" {
            handleGroupsDeepLink(url: url)
        } else {
            print("❌ Unknown deep link path: \(url.host ?? "nil")")
        }
    }

    private func handleGroupsDeepLink(url: URL) {
        let path = url.path

        // threeputt://groups/join?code=ABC12XYZ
        if path == "/join" || path.isEmpty {
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
               let queryItems = components.queryItems,
               let code = queryItems.first(where: { $0.name == "code" })?.value {

                print("📨 Invite code from deep link: \(code)")
                pendingInviteCode = code

                // Auto-join the group
                Task {
                    await joinGroup(with: code)
                }
            } else {
                print("❌ No invite code found in URL")
            }
        }
    }

    private func joinGroup(with code: String) async {
        do {
            let group = try await groupService.joinWithInviteCode(code)

            // Show success message
            alertMessage = "Successfully joined \"\(group.name)\"!"
            showJoinGroupAlert = true

            // Clear pending code
            pendingInviteCode = nil

            print("✅ Successfully joined group: \(group.name)")

        } catch let error as APIError {
            // Show error message
            alertMessage = error.userMessage
            showJoinGroupAlert = true

            print("❌ Failed to join group: \(error.userMessage)")

        } catch {
            // Show generic error
            alertMessage = "Failed to join group. Please try again."
            showJoinGroupAlert = true

            print("❌ Failed to join group: \(error.localizedDescription)")
        }
    }
}
