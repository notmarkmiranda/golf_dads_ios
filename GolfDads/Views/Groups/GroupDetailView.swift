//
//  GroupDetailView.swift
//  GolfDads
//
//  View for displaying group details, members, and postings
//

import SwiftUI

struct GroupDetailView: View {

    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss

    let authManager: AuthenticationManager
    @State private var group: Group

    @State private var teeTimePostings: [TeeTimePosting] = []
    @State private var isLoadingPostings = false
    @State private var errorMessage: String?
    @State private var showCopiedMessage = false
    @State private var showRegenerateConfirmation = false
    @State private var isRegenerating = false
    @State private var regenerateErrorMessage: String?
    @State private var showCreateTeeTime = false

    // Group member management
    @State private var groupMembers: [GroupMember] = []
    @State private var isLoadingMembers = false

    // Owner privilege actions
    @State private var showEditGroup = false
    @State private var showTransferOwnership = false
    @State private var showDeleteConfirmation = false
    @State private var showLeaveConfirmation = false
    @State private var isDeleting = false

    private let teeTimeService: TeeTimeServiceProtocol
    private let groupService: GroupServiceProtocol

    private var isCurrentUserOwner: Bool {
        group.isOwner(userId: authManager.currentUser?.id)
    }

    // MARK: - Initialization

    init(
        authManager: AuthenticationManager,
        group: Group,
        teeTimeService: TeeTimeServiceProtocol = TeeTimeService(),
        groupService: GroupServiceProtocol = GroupService()
    ) {
        self.authManager = authManager
        self._group = State(initialValue: group)
        self.teeTimeService = teeTimeService
        self.groupService = groupService
    }

    // MARK: - Body

    var body: some View {
        List {
            // About Section
            DisclosureGroup("About") {
                VStack(alignment: .leading, spacing: 16) {
                    // Description
                    if let description = group.description {
                        Text(description)
                            .font(.body)
                    }

                    // Members
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Members (\(groupMembers.count))")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Spacer()

                            if isLoadingMembers {
                                ProgressView()
                                    .scaleEffect(0.7)
                            }
                        }

                        if groupMembers.isEmpty {
                            Text("No members yet")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        } else {
                            ForEach(groupMembers) { member in
                                HStack {
                                    Image(systemName: "person.circle.fill")
                                        .foregroundStyle(.blue)
                                        .imageScale(.small)

                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(spacing: 4) {
                                            Text(member.name)
                                                .font(.subheadline)

                                            if member.id == group.ownerId {
                                                Text("Owner")
                                                    .font(.caption2)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(.blue.opacity(0.2))
                                                    .foregroundStyle(.blue)
                                                    .clipShape(Capsule())
                                            }
                                        }

                                        Text(member.email)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    // Remove button (owner only, can't remove self or owner)
                                    if isCurrentUserOwner && member.id != group.ownerId {
                                        Button(role: .destructive) {
                                            Task {
                                                await removeMember(member)
                                            }
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundStyle(.red)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }

                    // Created Date
                    Text("Created \(group.createdAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }

            // Invite Code Section
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(group.inviteCode)
                            .font(.system(.title2, design: .monospaced))
                            .fontWeight(.semibold)

                        if showCopiedMessage {
                            Text("Copied!")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }

                        if let errorMsg = regenerateErrorMessage {
                            Text(errorMsg)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }

                    Spacer()

                    Button {
                        copyInviteCode()
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                            .labelStyle(.iconOnly)
                    }
                    .buttonStyle(.borderless)

                    ShareLink(item: shareMessage, subject: Text("Join my golf group!")) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .labelStyle(.iconOnly)
                    }
                    .buttonStyle(.borderless)

                    Button {
                        showRegenerateConfirmation = true
                    } label: {
                        if isRegenerating {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .controlSize(.small)
                        } else {
                            Label("Regenerate", systemImage: "arrow.clockwise")
                                .labelStyle(.iconOnly)
                        }
                    }
                    .buttonStyle(.borderless)
                    .disabled(isRegenerating)
                }
            } header: {
                Text("Invite Code")
            } footer: {
                Text("Share this code with others to invite them to the group")
            }

            // Tee Time Postings Section
            Section {
                if isLoadingPostings {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.caption)
                } else if teeTimePostings.isEmpty {
                    ContentUnavailableView {
                        Label("No Tee Times", systemImage: "calendar.badge.clock")
                    } description: {
                        Text("No tee times posted for this group yet")
                    }
                } else {
                    ForEach(teeTimePostings) { posting in
                        NavigationLink(value: posting) {
                            TeeTimePostingRow(posting: posting)
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Tee Times")
                    Spacer()
                    Button {
                        showCreateTeeTime = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if isCurrentUserOwner {
                        // Owner-only actions
                        Button {
                            showEditGroup = true
                        } label: {
                            Label("Edit Group", systemImage: "pencil")
                        }

                        Button {
                            showTransferOwnership = true
                        } label: {
                            Label("Transfer Ownership", systemImage: "arrow.right.circle")
                        }

                        Divider()

                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete Group", systemImage: "trash")
                        }

                        Divider()
                    }

                    // Leave Group - available to everyone (but owners will get an error)
                    Button(role: .destructive) {
                        showLeaveConfirmation = true
                    } label: {
                        Label("Leave Group", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .refreshable {
            await loadGroupPostings()
        }
        .task {
            await loadGroupPostings()
            await loadMembers()
        }
        .confirmationDialog("Delete Group", isPresented: $showDeleteConfirmation) {
            Button("Delete Group and Exclusive Tee Times", role: .destructive) {
                Task {
                    await deleteGroup()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete the group and all tee times posted ONLY to this group. This cannot be undone.")
        }
        .confirmationDialog("Leave Group", isPresented: $showLeaveConfirmation) {
            Button("Leave Group", role: .destructive) {
                Task {
                    await leaveGroup()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You will need a new invite code to rejoin this group.")
        }
        .confirmationDialog(
            "Regenerate Invite Code?",
            isPresented: $showRegenerateConfirmation,
            titleVisibility: .visible
        ) {
            Button("Regenerate", role: .destructive) {
                Task {
                    await regenerateInviteCode()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will invalidate the current code. Anyone with the old code will no longer be able to join the group.")
        }
        .sheet(isPresented: $showCreateTeeTime) {
            CreateTeeTimeView()
                .onDisappear {
                    Task {
                        await loadGroupPostings()
                    }
                }
        }
        .sheet(isPresented: $showEditGroup) {
            EditGroupView(group: group) { name, description in
                Task {
                    do {
                        let updated = try await groupService.updateGroup(
                            id: group.id,
                            name: name,
                            description: description
                        )
                        group = updated
                        // Notify GroupsView to update its list
                        NotificationCenter.default.post(name: .groupUpdated, object: updated)
                    } catch {
                        if let apiError = error as? APIError {
                            errorMessage = apiError.userMessage
                        } else {
                            errorMessage = "Failed to update group: \(error.localizedDescription)"
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showTransferOwnership) {
            TransferOwnershipView(group: group, members: groupMembers) { newOwnerId in
                Task {
                    do {
                        let updated = try await groupService.transferOwnership(
                            groupId: group.id,
                            newOwnerId: newOwnerId
                        )
                        group = updated
                        await loadMembers()  // Refresh to show new owner badge
                        // Notify GroupsView to update its list
                        NotificationCenter.default.post(name: .groupUpdated, object: updated)
                    } catch {
                        if let apiError = error as? APIError {
                            errorMessage = apiError.userMessage
                        } else {
                            errorMessage = "Failed to transfer ownership: \(error.localizedDescription)"
                        }
                    }
                }
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil), presenting: errorMessage) { _ in
            Button("OK") {
                errorMessage = nil
            }
        } message: { message in
            Text(message)
        }
    }

    // MARK: - Computed Properties

    private var shareMessage: String {
        let deepLink = "threeputt://groups/join?code=\(group.inviteCode)"
        return """
        Join "\(group.name)" on Three Putt!

        Tap this link if you have the app:
        \(deepLink)

        Or manually enter code: \(group.inviteCode)

        Don't have Three Putt yet? Download it from the App Store!
        """
    }

    // MARK: - Methods

    private func loadGroupPostings() async {
        isLoadingPostings = true
        errorMessage = nil

        do {
            // Fetch tee time postings for this specific group
            teeTimePostings = try await teeTimeService.getGroupTeeTimePostings(groupId: group.id)
        } catch {
            if let apiError = error as? APIError {
                errorMessage = apiError.userMessage
            } else {
                errorMessage = error.localizedDescription
            }
        }

        isLoadingPostings = false
    }

    private func copyInviteCode() {
        UIPasteboard.general.string = group.inviteCode
        showCopiedMessage = true

        Task {
            try? await Task.sleep(for: .seconds(2))
            showCopiedMessage = false
        }
    }

    private func regenerateInviteCode() async {
        isRegenerating = true
        regenerateErrorMessage = nil

        do {
            // Call the service to regenerate the invite code
            let updatedGroup = try await groupService.regenerateInviteCode(groupId: group.id)

            // Update the local group state with the new invite code
            group = updatedGroup

        } catch {
            // Show error message
            if let apiError = error as? APIError {
                regenerateErrorMessage = apiError.userMessage
            } else {
                regenerateErrorMessage = "Failed to regenerate code"
            }

            // Clear error message after 3 seconds
            Task {
                try? await Task.sleep(for: .seconds(3))
                regenerateErrorMessage = nil
            }
        }

        isRegenerating = false
    }

    private func loadMembers() async {
        isLoadingMembers = true

        do {
            groupMembers = try await groupService.getGroupMembers(groupId: group.id)
        } catch {
            print("Failed to load members: \(error)")
            // Fallback to member names from group
            groupMembers = group.memberNames.enumerated().map { index, name in
                GroupMember(id: -index, email: name, name: name, joinedAt: nil)
            }
        }

        isLoadingMembers = false
    }

    private func removeMember(_ member: GroupMember) async {
        do {
            try await groupService.removeMember(groupId: group.id, userId: member.id)
            groupMembers.removeAll { $0.id == member.id }
        } catch {
            if let apiError = error as? APIError {
                errorMessage = apiError.userMessage
            } else {
                errorMessage = "Failed to remove member: \(error.localizedDescription)"
            }
        }
    }

    private func deleteGroup() async {
        isDeleting = true

        do {
            try await groupService.deleteGroup(id: group.id)
            NotificationCenter.default.post(name: .groupDeleted, object: group.id)
            dismiss()
        } catch {
            if let apiError = error as? APIError {
                errorMessage = apiError.userMessage
            } else {
                errorMessage = "Failed to delete group: \(error.localizedDescription)"
            }
        }

        isDeleting = false
    }

    private func leaveGroup() async {
        do {
            try await groupService.leaveGroup(id: group.id)
            NotificationCenter.default.post(name: .groupLeft, object: group.id)
            dismiss()
        } catch {
            if let apiError = error as? APIError {
                errorMessage = apiError.userMessage
            } else {
                errorMessage = "Failed to leave group: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        GroupDetailView(
            authManager: AuthenticationManager(),
            group: Group(
                id: 1,
                name: "Weekend Warriors",
                description: "Saturday morning golf group",
                ownerId: 1,
                inviteCode: "ABC12XYZ",
                memberNames: ["john@example.com", "jane@example.com", "bob@example.com"],
                createdAt: Date(),
                updatedAt: Date()
            )
        )
    }
}
