//
//  CreateGroupView.swift
//  GolfDads
//
//  View for creating a new group
//

import SwiftUI

struct CreateGroupView: View {

    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var description: String = ""
    @State private var isCreating = false
    @State private var errorMessage: String?

    private let groupService: GroupServiceProtocol
    private let onGroupCreated: (Group) -> Void

    // MARK: - Initialization

    init(
        groupService: GroupServiceProtocol = GroupService(),
        onGroupCreated: @escaping (Group) -> Void
    ) {
        self.groupService = groupService
        self.onGroupCreated = onGroupCreated
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Group Name", text: $name)
                        .textInputAutocapitalization(.words)

                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .textInputAutocapitalization(.sentences)
                        .lineLimit(3...5)
                } header: {
                    Text("Group Details")
                } footer: {
                    Text("Create a group to organize tee times with your regular golf buddies")
                }

                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("New Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isCreating)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            await createGroup()
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isCreating)
                }
            }
            .disabled(isCreating)
        }
    }

    // MARK: - Methods

    private func createGroup() async {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            errorMessage = "Group name is required"
            return
        }

        isCreating = true
        errorMessage = nil

        do {
            let newGroup = try await groupService.createGroup(
                name: trimmedName,
                description: trimmedDescription.isEmpty ? nil : trimmedDescription
            )

            onGroupCreated(newGroup)
            dismiss()
        } catch {
            if let apiError = error as? APIError {
                errorMessage = apiError.userMessage
            } else {
                errorMessage = error.localizedDescription
            }
        }

        isCreating = false
    }
}

// MARK: - Preview

#Preview {
    CreateGroupView { _ in }
}
