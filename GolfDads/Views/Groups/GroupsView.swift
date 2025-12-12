//
//  GroupsView.swift
//  GolfDads
//
//  View for browsing and managing groups
//

import SwiftUI

struct GroupsView: View {

    // MARK: - Properties

    let authManager: AuthenticationManager

    @State private var groups: [Group] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingCreateGroup = false
    @State private var showingJoinWithCode = false
    @State private var navigationPath = NavigationPath()

    @EnvironmentObject private var deepLinkHandler: DeepLinkHandler

    private let groupService: GroupServiceProtocol

    // MARK: - Initialization

    init(authManager: AuthenticationManager, groupService: GroupServiceProtocol = GroupService()) {
        self.authManager = authManager
        self.groupService = groupService
    }

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $navigationPath) {
            SwiftUI.Group {
                if isLoading {
                    ProgressView("Loading groups...")
                } else if let errorMessage = errorMessage {
                    ContentUnavailableView {
                        Label("Error", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(errorMessage)
                    } actions: {
                        Button("Try Again") {
                            Task {
                                await loadGroups()
                            }
                        }
                    }
                } else if groups.isEmpty {
                    ContentUnavailableView {
                        Label("No Groups", systemImage: "person.3")
                    } description: {
                        Text("Create a group to get started")
                    } actions: {
                        Button("Create Group") {
                            showingCreateGroup = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    groupsList
                }
            }
            .navigationTitle("Groups")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingJoinWithCode = true
                    } label: {
                        Label("Join with Code", systemImage: "number")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreateGroup = true
                    } label: {
                        Label("Create Group", systemImage: "plus")
                    }
                }
            }
            .refreshable {
                await loadGroups()
            }
            .sheet(isPresented: $showingCreateGroup) {
                CreateGroupView { newGroup in
                    groups.insert(newGroup, at: 0)
                }
            }
            .sheet(isPresented: $showingJoinWithCode) {
                JoinWithCodeView { newGroup in
                    groups.insert(newGroup, at: 0)
                    // Navigate to the newly joined group
                    navigationPath.append(newGroup)
                }
            }
        }
        .task {
            await loadGroups()
        }
        .onChange(of: deepLinkHandler.joinedGroup) { oldValue, newGroup in
            if let group = newGroup {
                // Add to groups list if not already present
                if !groups.contains(where: { $0.id == group.id }) {
                    groups.insert(group, at: 0)
                }
                // Navigate to the group
                navigationPath.append(group)
                // Clear the joined group
                deepLinkHandler.joinedGroup = nil
            }
        }
        .onAppear {
            // Listen for group deleted/left notifications
            NotificationCenter.default.addObserver(
                forName: .groupDeleted,
                object: nil,
                queue: .main
            ) { notification in
                if let groupId = notification.object as? Int {
                    groups.removeAll { $0.id == groupId }
                }
            }

            NotificationCenter.default.addObserver(
                forName: .groupLeft,
                object: nil,
                queue: .main
            ) { notification in
                if let groupId = notification.object as? Int {
                    groups.removeAll { $0.id == groupId }
                }
            }

            // Listen for group updated notifications
            NotificationCenter.default.addObserver(
                forName: .groupUpdated,
                object: nil,
                queue: .main
            ) { notification in
                if let updatedGroup = notification.object as? Group {
                    if let index = groups.firstIndex(where: { $0.id == updatedGroup.id }) {
                        groups[index] = updatedGroup
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    private var groupsList: some View {
        List(groups) { group in
            NavigationLink(value: group) {
                GroupRowView(group: group)
            }
        }
        .navigationDestination(for: Group.self) { group in
            GroupDetailView(authManager: authManager, group: group)
        }
        .navigationDestination(for: TeeTimePosting.self) { posting in
            TeeTimeDetailView(posting: posting)
        }
    }

    // MARK: - Methods

    private func loadGroups() async {
        isLoading = true
        errorMessage = nil

        do {
            groups = try await groupService.getGroups()
        } catch {
            if let apiError = error as? APIError {
                errorMessage = apiError.userMessage
            } else {
                errorMessage = error.localizedDescription
            }
        }

        isLoading = false
    }
}

// MARK: - Group Row View

struct GroupRowView: View {
    let group: Group

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(group.name)
                .font(.headline)

            if let description = group.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    GroupsView(authManager: AuthenticationManager())
        .environmentObject(DeepLinkHandler())
}
