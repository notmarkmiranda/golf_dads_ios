//
//  GroupDetailView.swift
//  GolfDads
//
//  View for displaying group details, members, and postings
//

import SwiftUI

struct GroupDetailView: View {

    // MARK: - Properties

    @State private var group: Group

    @State private var teeTimePostings: [TeeTimePosting] = []
    @State private var isLoadingPostings = false
    @State private var errorMessage: String?
    @State private var showCopiedMessage = false
    @State private var showRegenerateConfirmation = false
    @State private var isRegenerating = false
    @State private var regenerateErrorMessage: String?
    @State private var showCreateTeeTime = false

    private let teeTimeService: TeeTimeServiceProtocol
    private let groupService: GroupServiceProtocol

    // MARK: - Initialization

    init(
        group: Group,
        teeTimeService: TeeTimeServiceProtocol = TeeTimeService(),
        groupService: GroupServiceProtocol = GroupService()
    ) {
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
                        Text("Members (\(group.memberNames.count))")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        if group.memberNames.isEmpty {
                            Text("No members yet")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        } else {
                            ForEach(group.memberNames, id: \.self) { memberName in
                                HStack {
                                    Image(systemName: "person.circle.fill")
                                        .foregroundStyle(.blue)
                                        .imageScale(.small)
                                    Text(memberName)
                                        .font(.subheadline)
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
        .refreshable {
            await loadGroupPostings()
        }
        .task {
            await loadGroupPostings()
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
}

// MARK: - Preview

#Preview {
    NavigationStack {
        GroupDetailView(
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
