//
//  GroupDetailView.swift
//  GolfDads
//
//  View for displaying group details, members, and postings
//

import SwiftUI

struct GroupDetailView: View {

    // MARK: - Properties

    let group: Group

    @State private var teeTimePostings: [TeeTimePosting] = []
    @State private var isLoadingPostings = false
    @State private var errorMessage: String?
    @State private var showCopiedMessage = false

    private let teeTimeService: TeeTimeServiceProtocol

    // MARK: - Initialization

    init(
        group: Group,
        teeTimeService: TeeTimeServiceProtocol = TeeTimeService()
    ) {
        self.group = group
        self.teeTimeService = teeTimeService
    }

    // MARK: - Body

    var body: some View {
        List {
            // Group Info Section
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    if let description = group.description {
                        Text(description)
                            .font(.body)
                    }

                    Text("Created \(group.createdAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("About")
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
                    }

                    Spacer()

                    Button {
                        copyInviteCode()
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                            .labelStyle(.iconOnly)
                    }
                    .buttonStyle(.borderless)

                    ShareLink(item: group.inviteCode) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .labelStyle(.iconOnly)
                    }
                    .buttonStyle(.borderless)
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
                Text("Tee Times")
            }
        }
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(for: TeeTimePosting.self) { posting in
            TeeTimeDetailView(posting: posting)
        }
        .refreshable {
            await loadGroupPostings()
        }
        .task {
            await loadGroupPostings()
        }
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
                createdAt: Date(),
                updatedAt: Date()
            )
        )
    }
}
