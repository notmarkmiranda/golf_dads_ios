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
    @State private var showInviteSheet = false

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
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showInviteSheet = true
                } label: {
                    Label("Invite Members", systemImage: "person.badge.plus")
                }
            }
        }
        .sheet(isPresented: $showInviteSheet) {
            SendInvitationView(group: group)
        }
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
            // Filter tee time postings for this group
            let allPostings = try await teeTimeService.getTeeTimePostings()
            teeTimePostings = allPostings.filter { posting in
                // Check if the posting belongs to this group
                // Note: This assumes TeeTimePosting has a groupIds property
                // If not available, we'll need to update the model
                true // Placeholder - will need to be updated based on API response
            }
        } catch {
            if let apiError = error as? APIError {
                errorMessage = apiError.userMessage
            } else {
                errorMessage = error.localizedDescription
            }
        }

        isLoadingPostings = false
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
                createdAt: Date(),
                updatedAt: Date()
            )
        )
    }
}
